//
//  AddNoteViewController.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 29.09.25.
//

import UIKit
import SnapKit
import Alamofire
import Speech
import AVFoundation
import Accelerate

struct GeneratedNotesResponse: Sendable {
    let generatedNotes: [Note]
}

struct Note: Sendable {
    var category: String
    var title: String
    var content: String
}

// MARK: - Request Model
struct DailyStoryRequest: Sendable {
    let dailyStory: String
}

// Provide nonisolated Codable conformances via extensions to avoid inheriting any actor isolation.
nonisolated extension GeneratedNotesResponse: Codable { }
nonisolated extension Note: Codable { }
nonisolated extension DailyStoryRequest: Codable { }

// MARK: - POST /api/notes models
struct PostDailyNotesRequest: Sendable {
    let dailyNotes: [Note]
}

struct NoteWithMeta: Sendable {
    let id: Int
    let category: String
    let title: String
    let content: String
    let createdAt: Date
    let editedAt: Date
}

struct PostDailyNotesResponse: Sendable {
    let dailyNotes: [NoteWithMeta]
}

// Provide nonisolated Codable conformances for POST models as well.
nonisolated extension PostDailyNotesRequest: Codable { }
nonisolated extension NoteWithMeta: Codable { }
nonisolated extension PostDailyNotesResponse: Codable { }

final class AddNoteViewController: UIViewController {
    private let viewModel: AddNoteViewModel
    
    // MARK: - API
    private let url = "https://dayday.azurewebsites.net/api/notes/generate"
    private let postNotesURL = "https://dayday.azurewebsites.net/api/notes"
    
    // MARK: - State
    private var text: String = "" {
        didSet {
            updatePlaceholderVisibility()
            updateCharCounter()
        }
    }
    
    // Копим распознанный текст и показываем только по завершении
    private var lastPartialText: String = ""
    
    // Insets state for keyboard handling
    private var originalContentInset: UIEdgeInsets = .zero
    private var originalScrollIndicatorInsets: UIEdgeInsets = .zero
    
    // Speech recognition state
    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isRecording = false
    private var speechAuthStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    private var micGranted: Bool = false
    
    // Для визуализации уровня
    private var currentLevelSmoothed: CGFloat = 0
    private var levelSmoothingFactor: CGFloat = 0.3
    
    // MARK: - UI
    
    // Контейнер-скролл для стабильного поведения при клавиатуре
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .interactive
        return sv
    }()
    
    private let contentStack: UIStackView = {
        let st = UIStackView()
        st.axis = .vertical
        st.spacing = 12
        return st
    }()
    
    // Заголовок и счётчик символов
    private let headerStack: UIStackView = {
        let st = UIStackView()
        st.axis = .horizontal
        st.alignment = .center
        st.distribution = .fill
        return st
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Ваш день"
        l.font = .systemFont(ofSize: 20, weight: .semibold)
        l.textColor = .label
        return l
    }()
    
    private let charCounterLabel: UILabel = {
        let l = UILabel()
        l.text = "0"
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()
    
    // Карточка для ввода текста
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        return v
    }()
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 17)
        tv.alwaysBounceVertical = true
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        tv.keyboardDismissMode = .interactive
        return tv
    }()
    
    private let placeholderLabel: UILabel = {
        let l = UILabel()
        l.text = "Опишите ваш день..."
        l.textColor = .placeholderText
        l.font = .systemFont(ofSize: 17)
        l.numberOfLines = 0
        return l
    }()
    
    // Нижний бар с кнопками
    private let bottomBar = UIView()
    private let bottomSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        return v
    }()
    private let bottomStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 12
        return s
    }()
    
    private lazy var clearButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Очистить", for: .normal)
        b.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        return b
    }()
    
    private lazy var micButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        b.setImage(UIImage(systemName: "mic", withConfiguration: config), for: .normal)
        b.tintColor = .white
        b.backgroundColor = .systemPurple
        b.layer.cornerRadius = 19
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        b.snp.makeConstraints { make in
            make.width.height.equalTo(38)
        }
        return b
    }()
    
    // Пульсирующие круги вокруг микрофона
    private let micPulseView: PulsingMicView = {
        let v = PulsingMicView()
        v.alpha = 0
        return v
    }()
    
    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Сохранить", for: .normal)
        b.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .systemPurple
        b.layer.cornerRadius = 10
        b.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        return b
    }()
    
    private var bottomBarBottomConstraint: Constraint?
    
    // Полноэкранный оверлей прослушивания
    private var listeningOverlay: ListeningOverlayView?
    
    // MARK: - Init
    init(viewModel: AddNoteViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = viewModel.title
        
        setupNavBar()
        setupViews()
        setupKeyboardObservers()
        requestPermissions()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopRecording()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - UI Setup
    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отмена",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
    }
    
    private func setupViews() {
        textView.delegate = self
        
        // Иерархия
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(UIView()) // spacer
        headerStack.addArrangedSubview(charCounterLabel)
        
        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(cardView)
        cardView.addSubview(textView)
        cardView.addSubview(placeholderLabel)
        
        view.addSubview(bottomBar)
        bottomBar.addSubview(bottomSeparator)
        bottomBar.addSubview(bottomStack)
        
        // Пульсация — под кнопкой, но внутри того же контейнера
        bottomBar.addSubview(micPulseView)
        
        bottomStack.addArrangedSubview(clearButton)
        bottomStack.addArrangedSubview(UIView()) // spacer
        bottomStack.addArrangedSubview(micButton)
        bottomStack.addArrangedSubview(saveButton)
        
        // Layout
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view)
            make.bottom.equalTo(bottomBar.snp.top)
        }
        
        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(16)
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width).offset(-32)
        }
        
        cardView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(200) // комфортная стартовая высота
        }
        
        textView.snp.makeConstraints { make in
            make.edges.equalTo(cardView).inset(4) // внутри карточки ещё небольшой отступ
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.top).offset(16)
            make.leading.equalTo(textView.snp.leading).offset(16)
            make.trailing.lessThanOrEqualTo(textView.snp.trailing).offset(-16)
        }
        
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            bottomBarBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
        }
        
        bottomSeparator.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        bottomStack.snp.makeConstraints { make in
            make.top.equalTo(bottomBar.snp.top).offset(8)
            make.bottom.equalTo(bottomBar.snp.bottom).inset(8)
            make.leading.equalTo(bottomBar.snp.leading).offset(16)
            make.trailing.equalTo(bottomBar.snp.trailing).inset(16)
        }
        
        // Пульсация должна быть центрирована на месте микрофона (38x38), чуть больше
        micPulseView.snp.makeConstraints { make in
            // Привяжем к micButton через layout pass
            make.centerY.equalTo(micButton.snp.centerY)
            make.centerX.equalTo(micButton.snp.centerX)
            make.width.height.equalTo(56) // шире кнопки, чтобы видны были круги
        }
        
        // Сохраняем начальные insets и устанавливаем нижний отступ под панель
        originalContentInset = scrollView.contentInset
        originalScrollIndicatorInsets = scrollView.verticalScrollIndicatorInsets
        applyBottomPaddingForBottomBarOnly()
        
        updatePlaceholderVisibility()
        updateCharCounter()
    }
    
    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func updateCharCounter() {
        charCounterLabel.text = "\(text.count)"
    }
    
    private func applyBottomPaddingForBottomBarOnly() {
        let bottomPadding = bottomBar.bounds.height
        scrollView.contentInset = UIEdgeInsets(
            top: originalContentInset.top,
            left: originalContentInset.left,
            bottom: originalContentInset.bottom + bottomPadding,
            right: originalContentInset.right
        )
        scrollView.verticalScrollIndicatorInsets = UIEdgeInsets(
            top: originalScrollIndicatorInsets.top,
            left: originalScrollIndicatorInsets.left,
            bottom: originalScrollIndicatorInsets.bottom + bottomPadding,
            right: originalScrollIndicatorInsets.right
        )
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        view.endEditing(true)
        sendDailyStory(story: text) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                // Если пусто — просто показать, что заметок нет
                if response.generatedNotes.isEmpty {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Сгенерированные заметки", message: "Нет сгенерированных заметок.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ок", style: .default))
                        self.present(alert, animated: true)
                    }
                    return
                }
                
                // Формируем превью сообщения
                let previewMessage: String = response.generatedNotes.enumerated().map { index, note in
                    var parts: [String] = []
                    let header = "\(index + 1)) [\(note.category)] \(note.title)"
                    parts.append(header)
                    if !note.content.isEmpty {
                        parts.append(note.content)
                    }
                    return parts.joined(separator: "\n")
                }.joined(separator: "\n\n")
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Сгенерированные заметки", message: previewMessage, preferredStyle: .alert)
                    
                    // Подтвердить — сразу POST как есть
                    alert.addAction(UIAlertAction(title: "Подтвердить", style: .default, handler: { [weak self] _ in
                        guard let self else { return }
                        self.postDailyNotes(dailyNotes: response.generatedNotes) { postResult in
                            switch postResult {
                            case .success:
                                DispatchQueue.main.async {
                                    let ok = UIAlertController(title: "Готово", message: "Заметки сохранены.", preferredStyle: .alert)
                                    ok.addAction(UIAlertAction(title: "Ок", style: .default))
                                    self.present(ok, animated: true)
                                }
                            case .failure(let error):
                                print("Post error: \(error)")
                                DispatchQueue.main.async {
                                    let err = UIAlertController(title: "Ошибка", message: "Не удалось сохранить заметки: \(error.localizedDescription)", preferredStyle: .alert)
                                    err.addAction(UIAlertAction(title: "Ок", style: .default))
                                    self.present(err, animated: true)
                                }
                            }
                        }
                    }))
                    
                    // Редактировать — откроем пошаговый редактор по одной заметке
                    alert.addAction(UIAlertAction(title: "Редактировать", style: .cancel, handler: { [weak self] _ in
                        guard let self else { return }
                        let editableNotes = response.generatedNotes // значение (копия)
                        self.presentEditFlow(for: editableNotes, startIndex: 0) { [weak self] finalNotes in
                            guard let self else { return }
                            self.postDailyNotes(dailyNotes: finalNotes) { postResult in
                                switch postResult {
                                case .success:
                                    DispatchQueue.main.async {
                                        let ok = UIAlertController(title: "Готово", message: "Заметки сохранены.", preferredStyle: .alert)
                                        ok.addAction(UIAlertAction(title: "Ок", style: .default))
                                        self.present(ok, animated: true)
                                    }
                                case .failure(let error):
                                    print("Post error: \(error)")
                                    DispatchQueue.main.async {
                                        let err = UIAlertController(title: "Ошибка", message: "Не удалось сохранить заметки: \(error.localizedDescription)", preferredStyle: .alert)
                                        err.addAction(UIAlertAction(title: "Ок", style: .default))
                                        self.present(err, animated: true)
                                    }
                                }
                            }
                        }
                    }))
                    
                    self.present(alert, animated: true)
                }
            case .failure(let failure):
                print(failure)
            }
        }
    }
    
    @objc private func clearTapped() {
        text = ""
        textView.text = ""
    }
    
    @objc private func micTapped() {
        if isRecording {
            stopRecording()
        } else {
            guard speechAuthStatus == .authorized else {
                showSpeechPermissionAlert()
                return
            }
            guard micGranted else {
                showMicPermissionAlert()
                return
            }
            startRecording()
        }
    }
    
    // MARK: - Keyboard handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillChange(_ note: Notification) {
        guard
            let userInfo = note.userInfo,
            let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        
        let curve = UIView.AnimationOptions(rawValue: curveRaw << 16)
        let kbHeightInView = view.convert(frame, from: nil).intersection(view.bounds).height
        let safeBottom = view.safeAreaInsets.bottom
        let effectiveKB = max(0, kbHeightInView - safeBottom)
        let bottomPadding = bottomBar.bounds.height + effectiveKB
        
        // Двигаем нижнюю панель
        UIView.animate(withDuration: duration, delay: 0, options: [curve]) {
            self.bottomBarBottomConstraint?.update(inset: kbHeightInView)
            self.view.layoutIfNeeded()
        }
        
        // Обновляем инсет скролла (не через layoutIfNeeded, чтобы не было “подскока”)
        var newContentInset = originalContentInset
        newContentInset.bottom = originalContentInset.bottom + bottomPadding
        scrollView.contentInset = newContentInset
        
        var newIndicatorInset = originalScrollIndicatorInsets
        newIndicatorInset.bottom = originalScrollIndicatorInsets.bottom + bottomPadding
        scrollView.verticalScrollIndicatorInsets = newIndicatorInset
    }
    
    @objc private func keyboardWillHide(_ note: Notification) {
        guard
            let userInfo = note.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        
        let curve = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: [curve]) {
            self.bottomBarBottomConstraint?.update(inset: 0)
            self.view.layoutIfNeeded()
        }
        
        // Возвращаем инсет только под нижнюю панель
        applyBottomPaddingForBottomBarOnly()
    }
}

// MARK: - UITextViewDelegate
extension AddNoteViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        text = textView.text
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
}

// MARK: - Networking
extension AddNoteViewController {
    func sendDailyStory(story: String, completion: @escaping (Result<GeneratedNotesResponse, Error>) -> Void) {
        let parameters = DailyStoryRequest(dailyStory: story)
        
        AF.request(url,
                   method: .post,
                   parameters: parameters,
                   encoder: JSONParameterEncoder.default,
                   headers: ["Content-Type": "application/json"])
            .validate()
            .responseDecodable(of: GeneratedNotesResponse.self) { response in
                switch response.result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    func postDailyNotes(dailyNotes: [Note], completion: @escaping (Result<PostDailyNotesResponse, Error>) -> Void) {
        let body = PostDailyNotesRequest(dailyNotes: dailyNotes)
        
        // Сериализуем для логов
        if let jsonData = try? JSONEncoder().encode(body),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("POST \(postNotesURL) body:\n\(jsonString)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        AF.request(postNotesURL,
                   method: .post,
                   parameters: body,
                   encoder: JSONParameterEncoder.default,
                   headers: ["Content-Type": "application/json"])
            .responseData { response in
                let status = response.response?.statusCode ?? -1
                let textBody = response.data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
                print("POST /api/notes status=\(status)\nresponse body=\n\(textBody)")
                
                // Non-2xx: return a descriptive error without attempting to decode.
                guard (200..<300).contains(status) else {
                    let error = NSError(
                        domain: "DayDay.API",
                        code: status,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Server error \(status)",
                            "responseBody": textBody
                        ]
                    )
                    completion(.failure(error))
                    return
                }
                
                // 2xx with empty body: treat as success with empty payload
                if response.data == nil || response.data?.isEmpty == true {
                    let empty = PostDailyNotesResponse(dailyNotes: [])
                    completion(.success(empty))
                    return
                }
                
                // 2xx with body: decode
                switch response.result {
                case .success(let data):
                    do {
                        let model = try decoder.decode(PostDailyNotesResponse.self, from: data)
                        completion(.success(model))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}

// MARK: - Editing flow for generated notes
private extension AddNoteViewController {
    // Пошаговый редактор: редактируем по одной заметке
    func presentEditFlow(for notes: [Note], startIndex: Int, completion: @escaping ([Note]) -> Void) {
        guard !notes.isEmpty else {
            completion(notes)
            return
        }
        presentEditAlert(for: notes, index: startIndex, completion: completion)
    }
    
    func presentEditAlert(for notes: [Note], index: Int, completion: @escaping ([Note]) -> Void) {
        var idx = index
        guard notes.indices.contains(idx) else {
            completion(notes)
            return
        }
        
        let current = notes[idx]
        let alert = UIAlertController(title: "Редактирование \(idx + 1)/\(notes.count)", message: "Измените поля и сохраните.", preferredStyle: .alert)
        
        alert.addTextField { tf in
            tf.placeholder = "Категория"
            tf.text = current.category
            tf.autocapitalizationType = .sentences
        }
        alert.addTextField { tf in
            tf.placeholder = "Заголовок"
            tf.text = current.title
            tf.autocapitalizationType = .sentences
        }
        alert.addTextField { tf in
            tf.placeholder = "Содержание"
            tf.text = current.content
            tf.autocapitalizationType = .sentences
        }
        
        // Кнопка: Сохранить и далее
        alert.addAction(UIAlertAction(title: idx < notes.count - 1 ? "Сохранить и далее" : "Сохранить", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let newCategory = alert.textFields?[0].text ?? ""
            let newTitle = alert.textFields?[1].text ?? ""
            let newContent = alert.textFields?[2].text ?? ""
            
            var updatedNotes = notes
            updatedNotes[idx] = Note(category: newCategory, title: newTitle, content: newContent)
            
            if idx < updatedNotes.count - 1 {
                self.presentEditAlert(for: updatedNotes, index: idx + 1, completion: completion)
            } else {
                completion(updatedNotes)
            }
        }))
        
        // Кнопка: Готово и отправить (в любой момент)
        alert.addAction(UIAlertAction(title: "Готово и отправить", style: .default, handler: { _ in
            let newCategory = alert.textFields?[0].text ?? ""
            let newTitle = alert.textFields?[1].text ?? ""
            let newContent = alert.textFields?[2].text ?? ""
            
            var updatedNotes = notes
            updatedNotes[idx] = Note(category: newCategory, title: newTitle, content: newContent)
            completion(updatedNotes)
        }))
        
        // Отмена — просто закрыть без отправки
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
}

// MARK: - Speech Recognition
private extension AddNoteViewController {
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.speechAuthStatus = status
                if status != .authorized {
                    self?.showSpeechPermissionAlert()
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.micGranted = granted
                if !granted {
                    self?.showMicPermissionAlert()
                }
            }
        }
    }
    
    func showSpeechPermissionAlert() {
        let alert = UIAlertController(
            title: "Нет доступа к распознаванию речи",
            message: "Разрешите распознавание речи в Настройках, чтобы использовать ввод голосом.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        if presentedViewController == nil {
            present(alert, animated: true)
        }
    }
    
    func showMicPermissionAlert() {
        let alert = UIAlertController(
            title: "Нет доступа к микрофону",
            message: "Разрешите доступ к микрофону в Настройках, чтобы использовать ввод голосом.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        if presentedViewController == nil {
            present(alert, animated: true)
        }
    }
    
    func startRecording() {
        stopRecognitionTaskIfNeeded()
        
        guard let recognizer = speechRecognizer else {
            showSimpleAlert(title: "Ошибка", message: "Распознаватель речи не инициализирован.")
            return
        }
        guard recognizer.isAvailable else {
            showSimpleAlert(title: "Распознавание недоступно", message: "Попробуйте позже.")
            return
        }
        guard speechAuthStatus == .authorized, micGranted == true else {
            showSimpleAlert(title: "Нет разрешений", message: "Проверьте доступ к микрофону и распознаванию речи.")
            return
        }
        
        // Настройка аудиосессии
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            showSimpleAlert(title: "Аудиосессия", message: "Не удалось активировать аудиосессию: \(error.localizedDescription)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            showSimpleAlert(title: "Ошибка", message: "Не удалось создать запрос распознавания.")
            return
        }
        // Получаем промежуточные, но не показываем в UI до завершения
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        
        // Полноэкранный оверлей "как в GPT"
        showListeningOverlay()
        
        // Устанавливаем tap и считаем уровень сигнала
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }
            self.recognitionRequest?.append(buffer)
            self.updateLevelFrom(buffer: buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            showSimpleAlert(title: "Запись", message: "Не удалось запустить аудиодвижок: \(error.localizedDescription)")
            hideListeningOverlay()
            return
        }
        
        // UI: включаем анимацию, меняем иконку
        micPulseView.start()
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        isRecording = true
        lastPartialText = ""
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            if let result = result {
                // только сохраняем последнюю версию текста
                self.lastPartialText = result.bestTranscription.formattedString
            }
            
            // Завершение — ошибка или финал
            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.async {
                    self.stopRecording()
                }
            }
        }
    }
    
    func stopRecording() {
        if isRecording {
            isRecording = false
        }
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        // UI: выключаем анимацию, возвращаем иконку
        micPulseView.stop()
        micButton.setImage(UIImage(systemName: "mic"), for: .normal)
        hideListeningOverlay()
        
        // Подставляем финальный текст один раз
        if !lastPartialText.isEmpty {
            textView.text = lastPartialText
            text = lastPartialText
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    func stopRecognitionTaskIfNeeded() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
    
    func showSimpleAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ок", style: .default))
            if self.presentedViewController == nil {
                self.present(alert, animated: true)
            }
        }
    }
}

// MARK: - Listening overlay + level metering
private extension AddNoteViewController {
    func showListeningOverlay() {
        if listeningOverlay == nil {
            let overlay = ListeningOverlayView()
            overlay.onStop = { [weak self] in
                self?.stopRecording()
            }
            listeningOverlay = overlay
        }
        if let overlay = listeningOverlay {
            overlay.present(in: view)
        }
    }
    
    func hideListeningOverlay() {
        listeningOverlay?.dismiss()
    }
    
    // Обновляем уровень из аудиобуфера и прокидываем в overlay и мини-пульс
    func updateLevelFrom(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?.pointee else { return }
        let frameLength = Int(buffer.frameLength)
        if frameLength == 0 { return }
        
        // Вычисляем RMS
        var rms: Float = 0
        vDSP_measqv(channelData, 1, &rms, vDSP_Length(frameLength))
        rms = sqrtf(rms) // RMS амплитуда (0...1 при нормализации)
        
        // Переведём в дБFS и нормализуем в 0...1
        // dbFS ~ 20 * log10(rms), где 0 дБ = full scale, -80 дБ ~ тишина
        let minDb: Float = -60 // нижний порог
        let maxDb: Float = 0
        var db = 20 * log10f(max(rms, 0.000_000_1))
        db = max(minDb, min(maxDb, db))
        let normalized = CGFloat((db - minDb) / (maxDb - minDb)) // 0...1
        
        // Сглаживание
        currentLevelSmoothed = currentLevelSmoothed * (1 - levelSmoothingFactor) + normalized * levelSmoothingFactor
        
        DispatchQueue.main.async {
            self.listeningOverlay?.update(level: self.currentLevelSmoothed)
            self.micPulseView.updateLevel(self.currentLevelSmoothed)
        }
    }
}


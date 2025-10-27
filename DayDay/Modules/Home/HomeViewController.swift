//
//  HomeViewController.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 29.09.25.
//

import UIKit
import SnapKit
import Alamofire

final class HomeViewController: UIViewController {
    // MARK: - ViewModel
    private let viewModel: HomeViewModel
    
    // Data (Категории)
    private var strings: [String] = [] {
        didSet {
            updateTodayProgress()
            applyFilterAndReload()
            updateEmptyState()
        }
    }
    private var subtitles: [String] = []
    
    // Notes
    private var allNotes: [NoteWithMeta] = [] {
        didSet {
            rebuildDaySections()
        }
    }
    private var daySections: [DaySection] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    // Filtered data source for search (только для категорий)
    private var filteredNames: [String] = []
    private var filteredSubtitles: [String] = []
    private var isSearching: Bool {
        !(searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = .secondaryLabel
        return indicator
    }()
    
    // Полноэкранный оверлей на время загрузки (чтобы не было видно фон/контент)
    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.isHidden = true
        return v
    }()
    
    // Empty state (для категорий)
    private let emptyStack = UIStackView()
    private let emptyIcon = UIImageView(image: UIImage(systemName: "tray"))
    private let emptyTitle = UILabel()
    private let emptySubtitle = UILabel()
    private let emptyAction = UIButton(type: .system)
    
    // Search
    private let searchController = UISearchController(searchResultsController: nil)
    
    // Collection
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.alwaysBounceVertical = true
        cv.backgroundColor = .clear
        cv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return cv
    }()
    
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Header (Сегодня)
    private let headerContainer = UIView()
    private let headerTitle = UILabel()
    private let headerSubtitle = UILabel()
    private let progress = UIProgressView(progressViewStyle: .default)
    private let headerButtonsStack = UIStackView()
    private let headerAddButton = UIButton(type: .system)
    private let headerAnalyticsButton = UIButton(type: .system)
    
    // Прогресс (мок): текущие/цель
    private var todayCurrent: Int = 0
    private var todayGoal: Int = 5
    
    // MARK: - Grouping model
    private struct DaySection {
        let date: Date // startOfDay
        let title: String
        let items: [NoteWithMeta]
    }
    
    // MARK: - Init
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = viewModel.title
        
        setupCollection()
        setupSearch()
        setupHeader()
        setupEmptyState()
        addSubViews()
        configureContraints()
        
        startLoading()
        fetchCategoriesAndNotes()
    }
    
    // MARK: - Setup
    private func setupCollection() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CategoryCollectionViewCell.self, forCellWithReuseIdentifier: CategoryCollectionViewCell.identifier)
        collectionView.register(NoteCollectionViewCell.self, forCellWithReuseIdentifier: NoteCollectionViewCell.identifier)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "HeaderCell")
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.reuseID)
        
        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    private func setupSearch() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Поиск категорий"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
    }
    
    private func setupHeader() {
        headerContainer.backgroundColor = .secondarySystemBackground
        headerContainer.layer.cornerRadius = 12
        headerContainer.layer.masksToBounds = true
        
        headerTitle.text = "Сегодня"
        headerTitle.font = .systemFont(ofSize: 20, weight: .semibold)
        
        headerSubtitle.text = "Создавайте заметки и отслеживайте прогресс"
        headerSubtitle.font = .systemFont(ofSize: 13)
        headerSubtitle.textColor = .secondaryLabel
        headerSubtitle.numberOfLines = 2
        
        progress.progressTintColor = .systemPurple
        progress.trackTintColor = .tertiarySystemFill
        progress.layer.cornerRadius = 2
        progress.clipsToBounds = true
        
        headerButtonsStack.axis = .horizontal
        headerButtonsStack.spacing = 12
        headerButtonsStack.distribution = .fillEqually
        
        headerAddButton.setTitle("Рассказать о дне", for: .normal)
        headerAddButton.setTitleColor(.white, for: .normal)
        headerAddButton.backgroundColor = .systemPurple
        headerAddButton.layer.cornerRadius = 8
        headerAddButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        headerAddButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        
        headerAnalyticsButton.setTitle("Аналитика", for: .normal)
        headerAnalyticsButton.setTitleColor(.systemPurple, for: .normal)
        headerAnalyticsButton.backgroundColor = .systemPurple.withAlphaComponent(0.12)
        headerAnalyticsButton.layer.cornerRadius = 8
        headerAnalyticsButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        headerAnalyticsButton.addTarget(self, action: #selector(openAnalyticsFromHeader), for: .touchUpInside)
        
        headerButtonsStack.addArrangedSubview(headerAddButton)
        headerButtonsStack.addArrangedSubview(headerAnalyticsButton)
        
        let vStack = UIStackView(arrangedSubviews: [headerTitle, headerSubtitle, progress, headerButtonsStack])
        vStack.axis = .vertical
        vStack.spacing = 8
        
        headerContainer.addSubview(vStack)
        vStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 12),
            vStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 12),
            vStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -12),
            vStack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -12),
        ])
        
        updateTodayProgress()
    }
    
    private func setupEmptyState() {
        emptyStack.axis = .vertical
        emptyStack.spacing = 8
        emptyStack.alignment = .center
        
        emptyIcon.tintColor = .tertiaryLabel
        emptyIcon.contentMode = .scaleAspectFit
        emptyIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
        
        emptyTitle.text = "Нет категорий"
        emptyTitle.font = .systemFont(ofSize: 18, weight: .semibold)
        emptyTitle.textColor = .secondaryLabel
        
        emptySubtitle.text = "Создайте заметки — и категории появятся автоматически."
        emptySubtitle.font = .systemFont(ofSize: 14)
        emptySubtitle.textColor = .darkGray
        emptySubtitle.numberOfLines = 0
        emptySubtitle.textAlignment = .center
        
        emptyAction.setTitle("Рассказать о дне", for: .normal)
        emptyAction.setTitleColor(.white, for: .normal)
        emptyAction.backgroundColor = .systemPurple
        emptyAction.layer.cornerRadius = 8
        emptyAction.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        emptyAction.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        
        [emptyIcon, emptyTitle, emptySubtitle, emptyAction].forEach(emptyStack.addArrangedSubview)
        
        view.addSubview(emptyStack)
        emptyStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(24)
            make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(24)
        }
        
        emptyStack.isHidden = true
    }
    
    // MARK: - Networking
    private func fetchCategoriesAndNotes() {
        let url = "https://dayday.azurewebsites.net/api/categories"
        AF.request(url)
            .validate()
            .responseDecodable(of: Categories.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let categories):
                    let names = categories.dailyCategories.map { $0.name }
                    let descs = categories.dailyCategories.map { $0.description }
                    DispatchQueue.main.async {
                        self.strings = names
                        self.subtitles = descs
                    }
                    self.fetchAllNotes(for: categories.dailyCategories)
                case .failure(let error):
                    print("Failed to fetch categories: \(error)")
                    DispatchQueue.main.async {
                        self.allNotes = []
                        self.refreshControl.endRefreshing()
                        self.stopLoading()
                    }
                }
            }
    }
    
    private func fetchAllNotes(for categories: [Category]) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let group = DispatchGroup()
        var collected: [NoteWithMeta] = []
        
        for cat in categories {
            group.enter()
            let encoded = cat.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cat.name
            let url = "https://dayday.azurewebsites.net/api/notes/\(encoded)"
            AF.request(url)
                .validate()
                .responseDecodable(of: GetDailyNotesResponse.self, decoder: decoder) { response in
                    switch response.result {
                    case .success(let payload):
                        collected.append(contentsOf: payload.dailyNotes)
                    case .failure(let error):
                        print("Failed to fetch notes for \(cat.name): \(error)")
                    }
                    group.leave()
                }
        }
        
        group.notify(queue: .main) {
            let sorted = collected.sorted { $0.createdAt > $1.createdAt }
            self.allNotes = sorted
            self.refreshControl.endRefreshing()
            self.stopLoading()
        }
    }
    
    // MARK: - Grouping
    private func rebuildDaySections() {
        guard !allNotes.isEmpty else {
            daySections = []
            return
        }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        
        let grouped = Dictionary(grouping: allNotes) { (note: NoteWithMeta) -> Date in
            calendar.startOfDay(for: note.createdAt)
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        
        var sections: [DaySection] = grouped.map { (day, notes) in
            let title: String
            if day == todayStart {
                title = "Сегодня"
            } else if day == yesterdayStart {
                title = "Вчера"
            } else {
                title = formatter.string(from: day)
            }
            let sorted = notes.sorted { $0.createdAt > $1.createdAt }
            return DaySection(date: day, title: title, items: sorted)
        }
        
        sections.sort { $0.date > $1.date }
        daySections = sections
    }
    
    // MARK: - Private methods
    private func addSubViews() {
        // Контент
        view.addSubview(collectionView)
        // Оверлей и индикатор поверх всего
        view.addSubview(overlayView)
        overlayView.addSubview(activityIndicator)
    }
    
    private func configureContraints() {
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func startLoading() {
        // Показать только индикатор на белом фоне
        overlayView.isHidden = false
        activityIndicator.startAnimating()
        
        // Скрыть весь UI
        collectionView.isHidden = true
        emptyStack.isHidden = true
        headerContainer.isHidden = true
        
        // Отключить взаимодействие
        view.isUserInteractionEnabled = false
    }
    
    private func stopLoading() {
        // Вернуть взаимодействие
        view.isUserInteractionEnabled = true
        
        // Спрятать оверлей и индикатор
        activityIndicator.stopAnimating()
        overlayView.isHidden = true
        
        // Показать UI
        collectionView.isHidden = false
        headerContainer.isHidden = false
        
        // Актуализировать пустое состояние
        updateEmptyState()
    }
    
    private func updateEmptyState() {
        let dataCount = isSearching ? filteredNames.count : strings.count
        let isEmpty = dataCount == 0
        emptyStack.isHidden = !isEmpty
        // Если показываем пустое состояние категорий — можно скрыть коллекцию
        collectionView.isHidden = isEmpty ? true : collectionView.isHidden
    }
    
    private func applyFilterAndReload() {
        if isSearching {
            let query = (searchController.searchBar.text ?? "").lowercased()
            var newNames: [String] = []
            var newSubtitles: [String] = []
            for (idx, name) in strings.enumerated() {
                let sub = subtitles.indices.contains(idx) ? subtitles[idx] : ""
                if name.lowercased().contains(query) || sub.lowercased().contains(query) {
                    newNames.append(name)
                    newSubtitles.append(sub)
                }
            }
            filteredNames = newNames
            filteredSubtitles = newSubtitles
        } else {
            filteredNames = strings
            filteredSubtitles = subtitles
        }
        collectionView.reloadData()
    }
    
    private func makeLayout() -> UICollectionViewLayout {
        // Секции: 0 — Header, 1 — Категории, 2... — группы заметок по дням
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self else { return nil }
            if sectionIndex == 0 {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(140))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                let groupSize = itemSize
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 4, trailing: 0)
                return section
            } else if sectionIndex == 1 {
                let isCompact = environment.traitCollection.horizontalSizeClass == .compact
                let isLandscape = environment.container.effectiveContentSize.width > environment.container.effectiveContentSize.height
                let columns: Int = isCompact ? (isLandscape ? 3 : 2) : 4
                
                let spacing: CGFloat = 12
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(120))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(140))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4)
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(36)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                return section
            } else {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(110))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(110))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 16, trailing: 0)
                
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(36)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                return section
            }
        }
        return layout
    }
    
    private func updateTodayProgress() {
        todayCurrent = min(strings.count, todayGoal)
        let progressValue = todayGoal == 0 ? 0 : Float(todayCurrent) / Float(todayGoal)
        progress.setProgress(progressValue, animated: true)
        headerSubtitle.text = "Заметок сегодня: \(todayCurrent) из \(todayGoal)"
    }
    
    @objc private func addTapped() {
        viewModel.didTapAddNote()
    }
    
    @objc private func openAnalyticsFromHeader() {
        switchToAnalyticsTab()
    }
    
    @objc private func refreshPulled() {
        // Для pull-to-refresh тоже скрываем весь UI, как вы просили
        startLoading()
        fetchCategoriesAndNotes()
    }
    
    private func switchToAnalyticsTab() {
        if let tab = self.tabBarController, let items = tab.viewControllers, items.count > 1 {
            tab.selectedIndex = 1
        }
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // 0: Header, 1: Категории, 2...: секции заметок по дням
        let base = 2
        let notesSections = daySections.count
        let dataCount = isSearching ? filteredNames.count : strings.count
        if dataCount == 0 { return 0 }
        return base + notesSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        else if section == 1 { return isSearching ? filteredNames.count : strings.count }
        else {
            let idx = section - 2
            guard daySections.indices.contains(idx) else { return 0 }
            return daySections[idx].items.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderCell", for: indexPath)
            if headerContainer.superview !== cell.contentView {
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }
                cell.contentView.addSubview(headerContainer)
                headerContainer.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    headerContainer.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                    headerContainer.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                    headerContainer.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                    headerContainer.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
                ])
            }
            return cell
        } else if indexPath.section == 1 {
            let names = isSearching ? filteredNames : strings
            let subs = isSearching ? filteredSubtitles : subtitles
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCollectionViewCell.identifier, for: indexPath) as! CategoryCollectionViewCell
            let name = names[indexPath.row]
            let sub = subs.indices.contains(indexPath.row) ? subs[indexPath.row] : ""
            cell.configure(title: name, subTitle: sub)
            return cell
        } else {
            let idx = indexPath.section - 2
            let note = daySections[idx].items[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoteCollectionViewCell.identifier, for: indexPath) as! NoteCollectionViewCell
            cell.configure(with: note)
            return cell
        }
    }
    
    // Заголовки секций
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.reuseID, for: indexPath) as! SectionHeaderView
        if indexPath.section == 1 {
            view.titleLabel.text = "Категории"
        } else if indexPath.section >= 2 {
            let idx = indexPath.section - 2
            if daySections.indices.contains(idx) {
                view.titleLabel.text = daySections[idx].title
            } else {
                view.titleLabel.text = ""
            }
        }
        return view
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let names = isSearching ? filteredNames : strings
            let categoryName = names[indexPath.row]
            viewModel.didSelectCategory(name: categoryName)
        }
    }
}

// MARK: - UISearchResultsUpdating
extension HomeViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilterAndReload()
        updateTodayProgress()
        updateEmptyState()
    }
}

// MARK: - Models
struct Categories {
    var dailyCategories: [Category]
}

struct Category: Sendable {
    let id: Int
    let name: String
    let description: String
}

nonisolated extension Categories: Decodable { }
nonisolated extension Category: Decodable { }

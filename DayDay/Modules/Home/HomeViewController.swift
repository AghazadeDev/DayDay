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
    
    // Refactor
    private var strings: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private var subtitles: [String] = []
    
    //MARK: - Views
    private lazy var addButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemPurple.withAlphaComponent(0.3)
        button.layer.cornerRadius = 30
        button.clipsToBounds = true
        let plusImage = UIImage(systemName: "plus")
        button.setImage(plusImage, for: .normal)
        button.tintColor = .white
        button.configuration = .glass()
        button.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        
        return button
    }()
    
    // Loading indicator
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = .secondaryLabel
        return indicator
    }()
    
    // TODO: - Make UICollectionViewCompositionalLayout
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.itemSize = .init(width: UIScreen.main.bounds.width / 2 - 20 , height: 100)
        layout.sectionInset = .init(top: 10, left: 10, bottom: 10, right: 10)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        return collectionView
    }()
    
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
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CategoryCollectionViewCell.self, forCellWithReuseIdentifier: CategoryCollectionViewCell.identifier)
        addSubViews()
        configureContraints()
        
        // Start loading
        startLoading()
        
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
                        self.stopLoading()
                    }
                case .failure(let error):
                    print("Failed to fetch categories: \(error)")
                    DispatchQueue.main.async {
                        self.stopLoading()
                    }
                }
            }
    }
    
    // MARK: - Private methods
    private func addSubViews() {
        view.addSubview(collectionView)
        view.addSubview(addButton)
        view.addSubview(activityIndicator)
    }
    
    private func configureContraints() {
        addButton.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.size.equalTo(60)
        }
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func startLoading() {
        activityIndicator.startAnimating()
        collectionView.isUserInteractionEnabled = false
        view.isUserInteractionEnabled = true
    }
    
    private func stopLoading() {
        activityIndicator.stopAnimating()
        collectionView.isUserInteractionEnabled = true
    }
    
    @objc private func addTapped() {
        viewModel.didTapAddNote()
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        strings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCollectionViewCell.identifier, for: indexPath) as! CategoryCollectionViewCell
        cell.configure(title: strings[indexPath.row], subTitle: subtitles[indexPath.row])
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let categoryName = strings[indexPath.row]
        viewModel.didSelectCategory(name: categoryName)
    }
}

// MARK: - Models
// Keep the model types at the top level and make their Decodable conformances nonisolated.

struct Categories {
    var dailyCategories: [Category]
}

struct Category: Sendable {
    let id: Int
    let name: String
    let description: String
}

// Provide nonisolated Decodable conformances via extensions to avoid inheriting any actor isolation.
nonisolated extension Categories: Decodable { }
nonisolated extension Category: Decodable { }


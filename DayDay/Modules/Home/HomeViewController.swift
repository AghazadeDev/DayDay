//
//  HomeViewController.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 29.09.25.
//

import UIKit
import SnapKit

final class HomeViewController: UIViewController {
    // MARK: - ViewModel
    private let viewModel: HomeViewModel
    
    private let strings: [String] = [
        "Finance",
        "Health",
        "Love",
        "Work",
        "Personal",
        "Other",
    ]
    
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
    }
    
    // MARK: - Private methods
    private func addSubViews() {
        view.addSubview(collectionView)
        view.addSubview(addButton)

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
        cell.configure(title: strings[indexPath.row])
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("")
    }
}

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
        addSubViews()
        configureContraints()
    }
    
    // MARK: - Private methods
    private func addSubViews() {
        view.addSubview(addButton)
    }
    
    private func configureContraints() {
        addButton.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.size.equalTo(60)
        }
    }
    
    @objc private func addTapped() {
        viewModel.didTapAddNote()
    }
}

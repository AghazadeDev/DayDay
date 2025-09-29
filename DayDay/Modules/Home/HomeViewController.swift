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
    private let addNoteView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        view.layer.cornerRadius = 30
        
        return view
    }()

    private let addNoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.init(systemName: "plus"), for: .normal)
        button.tintColor = .systemGreen
        button.addTarget(self, action: #selector(didTapAddNote), for: .touchUpInside)
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
    
    private func addSubViews() {
        view.addSubview(addNoteView)
        addNoteView.addSubview(addNoteButton)
    }
    
    private func configureContraints() {
        addNoteView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.size.equalTo(60)
        }
        
        addNoteButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }
    }
    
    @objc private func didTapAddNote() {
        viewModel.didTapAddNote()
    }
}

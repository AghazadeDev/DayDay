//
//  HomeCoordinator.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 29.09.25.
//

import UIKit

class HomeCoordinator: BaseCoordinator {
    override func start() {
        let viewModel = HomeViewModel(coordinator: self)
        let viewController = HomeViewController(viewModel: viewModel)
        navigationController?.viewControllers = [viewController]
    }
    
    func showAddNote() {
        let detailsVM = AddNoteViewModel()
        let detailsVC = AddNoteViewController(viewModel: detailsVM)
        navigationController?.pushViewController(detailsVC, animated: true)
    }
}

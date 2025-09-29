//
//  HomeCoordinator.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 29.09.25.
//

import UIKit

class HomeCoordinator: BaseCoordinator {
    override func start() {
        let viewModel = HomeViewModel()
        let viewController = HomeViewController(viewModel: viewModel)
        navigationController?.viewControllers = [viewController]
    }
}

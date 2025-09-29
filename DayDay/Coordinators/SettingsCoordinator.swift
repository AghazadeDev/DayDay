//
//  SettingsCoordinator.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 29.09.25.
//

import UIKit

final class SettingsCoordinator: BaseCoordinator {
    override func start() {
        let viewModel = SettingsViewModel()
        let viewController = SettingsViewController(viewModel: viewModel)
        navigationController?.viewControllers = [viewController]
    }
}

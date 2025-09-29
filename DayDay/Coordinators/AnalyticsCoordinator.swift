//
//  AnalyticsCoordinator.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 29.09.25.
//

import UIKit

class AnalyticsCoordinator: BaseCoordinator {
    override func start() {
        let viewModel = AnalyticsViewModel()
        let viewController = AnalyticsViewController(viewModel: viewModel)
        navigationController?.viewControllers = [viewController]
    }
}

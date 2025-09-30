//
//  TabBarCoordinator.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 29.09.25.
//

import UIKit

final class TabBarCoordinator {
    let tabBarController: UITabBarController

    private var homeCoordinator: HomeCoordinator?
    private var analyticsCoordinator: AnalyticsCoordinator?
    private var settingsCoordinator: SettingsCoordinator?

    init() {
        self.tabBarController = UITabBarController()
    }
    
    func start() {
        let homeNav = UINavigationController()
        let analyticsNav = UINavigationController()
        let settingsNav = UINavigationController()
        
        let homeCoordinator = HomeCoordinator(navigationController: homeNav)
        let analyticsCoordinator = AnalyticsCoordinator(navigationController: analyticsNav)
        let settingsCoordinator = SettingsCoordinator(navigationController: settingsNav)
        
        homeCoordinator.start()
        analyticsCoordinator.start()
        settingsCoordinator.start()

        self.homeCoordinator = homeCoordinator
        self.analyticsCoordinator = analyticsCoordinator
        self.settingsCoordinator = settingsCoordinator
        
        tabBarController.viewControllers = [homeNav, analyticsNav, settingsNav]
        
        tabBarController.tabBar.items?[0].title = "Home"
        tabBarController.tabBar.items?[0].image = UIImage(systemName: "house")
        tabBarController.tabBar.items?[1].title = "Analytics"
        tabBarController.tabBar.items?[1].image = UIImage(systemName: "chart.bar.xaxis")
        tabBarController.tabBar.items?[2].title = "Settings"
        tabBarController.tabBar.items?[2].image = UIImage(systemName: "gear")
        
        tabBarController.tabBar.tintColor = .systemPurple
        tabBarController.tabBarMinimizeBehavior = .onScrollDown
    }
}

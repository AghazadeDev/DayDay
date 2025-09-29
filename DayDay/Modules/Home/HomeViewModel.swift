//
//  HomeViewModel.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 29.09.25.
//

import Foundation

final class HomeViewModel {
    weak var coordinator: HomeCoordinator?
    
    init(coordinator: HomeCoordinator?) {
        self.coordinator = coordinator
    }
    
    var title: String { "Home" }
    
    func didTapAddNote() {
        coordinator?.showAddNote()
    }
}

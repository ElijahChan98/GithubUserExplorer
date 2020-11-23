//
//  MainCoordinator.swift
//  CoordinatorApp
//
//  Created by Elijah Tristan Huey Chan on 11/19/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit

class MainCoordinator: NSObject, Coordinator, UINavigationControllerDelegate {
    var childCoordinators: [Coordinator] = [Coordinator]()
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = UsersListViewController.instantiate()
        vc.coordinator = self
        navigationController.delegate = self
        self.navigationController.pushViewController(vc, animated: false)
    }
    
    func viewProfile(from user: GithubUser) {
        let vc = GithubUserProfileViewController()
        vc.coordinator = self
        let viewModel = GithubUserProfileViewModel(user: user, delegate: vc)
        vc.viewModel = viewModel
        vc.title = user.username
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    func childDidFinish(_ child: Coordinator?) {
        for (index, coordinator) in childCoordinators.enumerated() {
            if coordinator === child {
                childCoordinators.remove(at: index)
                break
            }
        }
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard let fromViewController = navigationController.transitionCoordinator?.viewController(forKey: .from) else {
            return
        }
        if navigationController.viewControllers.contains(fromViewController) {
            return
        }
        
        if let profileViewController = fromViewController as? GithubUserProfileViewController {
            childDidFinish(profileViewController.coordinator)
        }
    }
}

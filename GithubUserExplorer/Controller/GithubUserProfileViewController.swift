//
//  GithubUserProfileViewController.swift
//  GithubUserExplorer
//
//  Created by Elijah Tristan Huey Chan on 11/22/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit

class GithubUserProfileViewController: UIViewController, GithubUserProfileViewModelDelegate {
    
    weak var coordinator: MainCoordinator?
    
    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var blogLabel: UILabel!
    @IBOutlet weak var notesTextField: UITextField!
    @IBOutlet weak var noInternetBanner: UILabel!
    
    var viewModel: GithubUserProfileViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(showNoInternetBanner), name: .NetworkConnectivityDidChange, object: nil)
        hideNoInternetBanner()
        self.hideKeyboardWhenTappedAround()
        viewModel?.viewControllerDidLoad()
    }
    
    func hideNoInternetBanner() {
        let transform = CGAffineTransform(translationX: 0, y: -noInternetBanner.frame.height)
        noInternetBanner.alpha = 0
        noInternetBanner.transform = transform
    }
    
    @objc func showNoInternetBanner(_ notification: NSNotification) {
        guard let isConnected = notification.userInfo?["isConnected"] as? (Bool), isConnected == false else {
            hideNoInternetBanner()
            return
        }
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: .curveLinear, animations: {
            self.noInternetBanner.alpha = 0.5
            self.noInternetBanner.transform = .identity
        }, completion: nil)
    }

    @IBAction func onSaveButtonClick(_ sender: Any) {
        if let note = notesTextField.text {
            viewModel?.saveNote(note)
        }
    }
    
    func updateUIElementsWithUser(_ user: GithubUser) {
        userProfileImageView.image = user.image
        followersLabel.text = "Followers: \(user.followers ?? 0)"
        followingLabel.text = "Following: \(user.following ?? 0)"
        nameLabel.text = "Name: \(user.name ?? "No name")"
        companyLabel.text = "Company: \(user.company ?? "No Company")"
        blogLabel.text = "Blog: \(user.blog ?? "No Blog")"
        notesTextField.text = user.note
    }
}

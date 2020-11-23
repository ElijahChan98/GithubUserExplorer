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
    
    var viewModel: GithubUserProfileViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        viewModel?.viewControllerDidLoad()
    }

    @IBAction func onSaveButtonClick(_ sender: Any) {
        if let note = notesTextField.text {
            viewModel?.saveNote(note)
        }
    }
    
    func updateUIElementsWithUser(_ user: GithubUser) {
        userProfileImageView.image = user.image
        followersLabel.text = "Followers: \(user.followers!)"
        followingLabel.text = "Following: \(user.following!)"
        nameLabel.text = "Name: \(user.name ?? "No name")"
        companyLabel.text = "Company: \(user.company ?? "No Company")"
        blogLabel.text = "Blog: \(user.blog ?? "No Blog")"
        notesTextField.text = user.note
    }
}

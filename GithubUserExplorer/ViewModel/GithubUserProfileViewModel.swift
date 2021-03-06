//
//  GithubUserProfileViewModel.swift
//  GithubUserExplorer
//
//  Created by Elijah Tristan Huey Chan on 11/22/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit
import CoreData

class GithubUserProfileViewModel {
    var user = GithubUser()
    var delegate: GithubUserProfileViewModelDelegate?
    
    convenience init(user: GithubUser, delegate: GithubUserProfileViewModelDelegate?) {
        self.init()
        self.user = user
        self.delegate = delegate
    }
    
    func viewControllerDidLoad(){
        fetchUserProfile()
    }
    
    func saveNote(_ note: String) {
        user.note = note
        let userToSave = user
        GithubUserPersistence.shared.update(user: userToSave)
    }
    
    func fetchUserProfile() {
        RequestManager.shared.fetchGithubUserProfile(username: self.user.username!) { (success, response) in
            if let payload = response {
                if let fetchedUser = GithubUser().createUserProfileFromPayload(payload) {
                    self.user.id = fetchedUser.id
                    self.user.followers = fetchedUser.followers
                    self.user.following = fetchedUser.following
                    self.user.name = fetchedUser.name
                    self.user.blog = fetchedUser.blog
                    self.user.company = fetchedUser.company
                    self.user.seen = true
                    GithubUserPersistence.shared.update(user: fetchedUser)
                }
            }
            DispatchQueue.main.async {
                self.delegate?.updateUIElementsWithUser(self.user)
            }
        }
    }
}

protocol GithubUserProfileViewModelDelegate {
    func updateUIElementsWithUser(_ user: GithubUser)
}

//
//  CellItems.swift
//  GithubUserExplorer
//
//  Created by Elijah Tristan Huey Chan on 11/26/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit

enum UserViewModelItemType {
    case Normal
    case Inverted
    case Noted
    case NotedInverted
}

protocol UserViewModelItem {
    var type: UserViewModelItemType { get set }
    var user: GithubUser { get set }
}

class NormalUserViewModelItem: UserViewModelItem {
    var user: GithubUser
    var type: UserViewModelItemType
    
    init(user: GithubUser) {
        self.user = user
        self.type = .Normal
    }
}

class InvertedUserViewModelItem: UserViewModelItem {
    var user: GithubUser
    var type: UserViewModelItemType
    
    init(user: GithubUser) {
        self.user = user
        self.type = .Inverted
    }
}

class NotedUserViewModelItem: UserViewModelItem {
    var note: String
    var user: GithubUser
    var type: UserViewModelItemType
    
    init(note: String, user: GithubUser) {
        self.user = user
        self.note = note
        self.type = .Noted
    }
}

class NotedInvertedUserViewModelItem: UserViewModelItem {
    var note: String
    var user: GithubUser
    var type: UserViewModelItemType
    
    init(note: String, user: GithubUser) {
        self.user = user
        self.note = note
        self.type = .NotedInverted
    }
}

//
//  CellItems.swift
//  GithubUserExplorer
//
//  Created by Elijah Tristan Huey Chan on 11/26/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit

protocol GenericUserItem {
    var user: GithubUser { get set }
    
    var showNote: Bool { get }
    var invertImage: Bool { get set }
}

class NormalUserItem: GenericUserItem {
    var showNote: Bool {
        return user.note != nil
    }
    var invertImage: Bool
    var user: GithubUser
    
    init(user: GithubUser, invertImage: Bool) {
        self.user = user
        self.invertImage = invertImage
    }
}

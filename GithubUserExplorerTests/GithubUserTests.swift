//
//  GithubUserTests.swift
//  GithubUserExplorerTests
//
//  Created by Elijah Tristan Huey Chan on 11/23/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import XCTest

class GithubUserTests: XCTestCase {
    let samplePayload: [String: Any] = [
        "url": "https://api.github.com/users/elijah",
        "avatar_url": "www.avatarurl.com",
        "type": "user",
        "id": 1,
        "name": "Elijah",
        "company": "Tawk",
        "blog": "www.blog.com",
        "followers": 101,
        "following": 105,
        
    ]
    
    var user = GithubUser()
    var persistence = GithubUserPersistence.shared
    var viewModel = UsersListViewModel()
    
    func testAll() {
        self.testCreateUserFromPayload()
        self.testUserPersistenceSaveAndFetch()
        self.testUserPersistenceUpdate()
        self.testFetchUsersFromCache()
    }
    
    func testCreateUserFromPayload() {
        if let user = GithubUser().createUserFromPayload(samplePayload) {
            self.user = user
            XCTAssertTrue(user.userUrl == "https://api.github.com/users/elijah")
            XCTAssertTrue(user.avatarStringUrl == "www.avatarurl.com")
            XCTAssertTrue(user.details == "user")
            XCTAssertTrue(user.username == "elijah")
            XCTAssertTrue(user.id == 1)
            XCTAssertTrue(user.name == "Elijah")
            XCTAssertTrue(user.company == "Tawk")
            XCTAssertTrue(user.blog == "www.blog.com")
            XCTAssertTrue(user.followers == 101)
            XCTAssertTrue(user.following == 105)
        }
        else {
            XCTFail("user not created")
        }
    }

    func testUserPersistenceSaveAndFetch() {
        persistence.save(user: self.user)
        sleep(2)
        persistence.retrieveUsersFromCache { (success, users) in
            if success {
                guard let user = users.first else {
                    XCTFail("no user fetched")
                    return
                }
                
                XCTAssertTrue(user.userUrl == "https://api.github.com/users/elijah")
                XCTAssertTrue(user.avatarStringUrl == "www.avatarurl.com")
                XCTAssertTrue(user.details == "user")
                XCTAssertTrue(user.username == "elijah")
                XCTAssertTrue(user.id == 1)
                XCTAssertTrue(user.name == "Elijah")
                XCTAssertTrue(user.company == "tawk")
                XCTAssertTrue(user.blog == "www.blog.com")
                XCTAssertTrue(user.followers == 101)
                XCTAssertTrue(user.following == 105)
            }
            else {
                XCTFail("fetching failed")
            }
        }
    }
    
    func testUserPersistenceUpdate() {
        self.user.state = .filtered
        self.user.note = "test note"
        persistence.update(user: self.user)
        
        persistence.retrieveUsersFromCache { (success, users) in
            if success {
                guard let user = users.first else {
                    XCTFail("no user fetched")
                    return
                }
                
                XCTAssertTrue(user.state.rawValue == "filtered")
                XCTAssertTrue(user.note == "test note")
            }
            else {
                XCTFail("fetching failed")
            }
        }
    }
    
    func testFetchUsersFromCache() {
        viewModel.fetchUsersFromCache()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertTrue(self.viewModel.users.count > 0)
            XCTAssertTrue(self.viewModel.totalCount == self.viewModel.users.count)
        }
    }

}

//
//  GithubUsers.swift
//  CoordinatorApp
//
//  Created by Elijah Tristan Huey Chan on 11/20/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import CoreData
import UIKit

enum PhotoRecordState: String {
    case new = "new"
    case downloaded = "downloaded"
    case failed = "failed"
}

class GithubUser: Codable {
    enum CodingKeys: String, CodingKey {
        case userUrl = "url"
        case avatarStringUrl = "avatar_url"
        case details = "type"
        case id = "id"

        //profile details
        case name = "name"
        case company = "company"
        case blog = "blog"
        case followers = "followers"
        case following = "following"
    }
    
    var userUrl: String?
    var avatarStringUrl: String?
    var details: String?
    var id: Int?
    var username: String?
    var name: String?
    var company: String?
    var blog: String?
    var followers: Int?
    var following: Int?
    
    var note: String?
    var seen: Bool?
    
    var state = PhotoRecordState.new
    var image = UIImage(named: "none")
    
    func createUserFromPayload(_ payload: [String: Any]) -> GithubUser? {
        let decoder = JSONDecoder()
        do{
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            do {
                let user = try decoder.decode(GithubUser.self, from: jsonData)
                user.username = user.userUrl?.replacingOccurrences(of: "\(Constants.GITHUB_BASE_URL)\(Constants.GITHUB_USERS)/", with: "")
                GithubUserPersistence.shared.save(user: user)
                return user
            } catch {
                print(error.localizedDescription)
            }
        }
        catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func createUserProfileFromPayload(_ payload: [String: Any]) -> GithubUser? {
        let decoder = JSONDecoder()
        do{
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            do {
                let user = try decoder.decode(GithubUser.self, from: jsonData)
                return user
            } catch {
                print(error.localizedDescription)
            }
        }
        catch {
            print(error.localizedDescription)
        }
        return nil
    }
}

class ImageDownloader: Operation {
    let user: GithubUser
    var completion: (()->Void)
  
    init(_ user: GithubUser) {
        self.user = user
        self.completion = {}
    }
  
    override func main() {
        if isCancelled {
            self.completion()
            return
        }

        guard let stringUrl = user.avatarStringUrl, let avatarUrl = URL(string: stringUrl), let id = user.id else {
            return
        }
        
        if isCancelled {
            self.completion()
            return
        }
        
        if let cachedImage = GithubUserPersistence.shared.loadImageFromCache(key: "\(id)") {
            self.user.image = cachedImage
            self.user.state = .downloaded
            self.completion()
        }
        else {
            let task = URLSession.shared.dataTask(with: avatarUrl) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    self.user.image = image
                    self.user.state = .downloaded
                    GithubUserPersistence.shared.saveImageToCache(key: "\(id)", image: image)
                    self.completion()
                }
                else {
                    self.user.state = .failed
                    self.user.image = UIImage(named: "placeholder")
                    self.completion()
                }
            }
            task.resume()
        }
        
    }
}

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
    case filtered = "filtered"
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
    var image = UIImage(named: "Placeholder")
    
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
  
    init(_ user: GithubUser) {
        self.user = user
    }
  
    override func main() {
        if isCancelled {
            return
        }

        guard let stringUrl = user.avatarStringUrl, let avatarUrl = URL(string: stringUrl), let imageData = try? Data(contentsOf: avatarUrl) else {
            return
        }
    
        if isCancelled {
            return
        }
    
        if !imageData.isEmpty {
            user.image = UIImage(data:imageData)
            user.state = .downloaded
            GithubUserPersistence.shared.update(user: user, imageData: imageData)
        } else {
            user.state = .failed
            user.image = UIImage(named: "Failed")
        }
    }
}

class ImageFiltration: Operation {
    let user: GithubUser

    init(_ user: GithubUser) {
        self.user = user
    }

    override func main () {
        if isCancelled {
            return
        }

        guard self.user.state == .downloaded else {
            return
        }

        if let image = user.image,
            let filteredImage = applyInvertedColorsFilter(image) {
            user.image = filteredImage
            user.state = .filtered
        }
    }

    func applyInvertedColorsFilter(_ image: UIImage) -> UIImage? {
        guard let data = image.pngData() else { return nil }
        let inputImage = CIImage(data: data)

        if isCancelled {
            return nil
        }

        let context = CIContext(options: nil)

        guard let filter = CIFilter(name: "CIColorInvert") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)

        if isCancelled {
            return nil
        }

        guard
            let outputImage = filter.outputImage,
            let outImage = context.createCGImage(outputImage, from: outputImage.extent)
            else {
                return nil
        }

        return UIImage(cgImage: outImage)
    }
}

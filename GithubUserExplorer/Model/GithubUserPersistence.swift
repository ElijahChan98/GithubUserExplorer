//
//  GithubUserPersistence.swift
//  GithubUserExplorer
//
//  Created by Elijah Tristan Huey Chan on 11/22/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit
import CoreData

class GithubUserPersistence {
    static let shared = GithubUserPersistence()
    
    func save(user: GithubUser) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "GithubUserAvatar", in: managedContext)!
            let avatar = NSManagedObject(entity: entity, insertInto: managedContext)
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GithubUserAvatar")
            let predicate = NSPredicate(format: "id = %ld", user.id!)
            fetchRequest.predicate = predicate
            
            do {
                let object = try managedContext.fetch(fetchRequest)
                if object.count == 0 {
                    avatar.setValue(user.userUrl, forKey: "userUrl")
                    avatar.setValue(user.avatarStringUrl, forKey: "avatarStringUrl")
                    avatar.setValue(user.details, forKey: "details")
                    avatar.setValue(user.id, forKey: "id")
                    avatar.setValue(user.state.rawValue, forKey: "photoRecordState")
                    avatar.setValue(user.username, forKey: "username")
                    avatar.setValue(user.seen, forKey: "seen")

                    do {
                        try managedContext.save()
                    } catch let error as NSError {
                        print("Could not save. \(error), \(error.userInfo)")
                    }
                }
                else {
                    return
                }
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func update(user: GithubUser, imageData: Data) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GithubUserAvatar")
            let predicate = NSPredicate(format: "avatarStringUrl = %@", user.avatarStringUrl!)
            fetchRequest.predicate = predicate
            
            do {
                let object = try managedContext.fetch(fetchRequest)
                if object.count == 1
                {
                    let objectUpdate = object.first as! NSManagedObject
                    objectUpdate.setValue(imageData, forKey: "imageData")
                    objectUpdate.setValue(user.state.rawValue, forKey: "photoRecordState")
                    do{
                        try managedContext.save()
                    }
                    catch
                    {
                        print(error)
                    }
                }
            }
            catch
            {
                print(error)
            }
        }
    }
    
    func update(user: GithubUser) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GithubUserAvatar")
            let predicate = NSPredicate(format: "id = %ld", user.id!)
            fetchRequest.predicate = predicate
            
            do {
                let object = try managedContext.fetch(fetchRequest)
                if object.count == 1
                {
                    let objectUpdate = object.first as! NSManagedObject
                    objectUpdate.setValue(user.id, forKey: "id")
                    objectUpdate.setValue(user.userUrl, forKey: "userUrl")
                    objectUpdate.setValue(user.avatarStringUrl, forKey: "avatarStringUrl")
                    objectUpdate.setValue(user.details, forKey: "details")
                    objectUpdate.setValue(user.state.rawValue, forKey: "photoRecordState")
                    objectUpdate.setValue(user.username, forKey: "username")
                    objectUpdate.setValue(user.image?.pngData(), forKey: "imageData")
                    objectUpdate.setValue(user.note, forKey: "note")
                    objectUpdate.setValue(user.seen, forKey: "seen")
                    
                    objectUpdate.setValue(user.name, forKey: "name")
                    objectUpdate.setValue(user.company, forKey: "company")
                    objectUpdate.setValue(user.blog, forKey: "blog")
                    objectUpdate.setValue(user.followers, forKey: "followers")
                    objectUpdate.setValue(user.following, forKey: "following")
                    
                    do{
                        try managedContext.save()
                    }
                    catch
                    {
                        print(error)
                    }
                }
            }
            catch
            {
                print(error)
            }
        }
    }
    
    func deleteAllData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GithubUserAvatar")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer

        do {
            try persistentContainer.viewContext.execute(deleteRequest)
        } catch let error as NSError {
            print(error)
        }
    }
    
    func retrieveUsersFromCache(completion: @escaping (_ success: Bool, _ users: [GithubUser]) -> ()) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "GithubUserAvatar")
        do {
            let managedUsers = try managedContext.fetch(fetchRequest)
            var users: [GithubUser] = []
            for managedUser in managedUsers {
                let user = GithubUser()
                user.id = managedUser.value(forKeyPath: "id") as? Int
                user.userUrl = managedUser.value(forKeyPath: "userUrl") as? String
                user.username = managedUser.value(forKeyPath: "username") as? String
                user.avatarStringUrl = managedUser.value(forKeyPath: "avatarStringUrl") as? String
                user.details = managedUser.value(forKeyPath: "details") as? String
                
                user.followers = managedUser.value(forKeyPath: "followers") as? Int
                user.following = managedUser.value(forKeyPath: "following") as? Int
                user.blog = managedUser.value(forKeyPath: "blog") as? String
                user.name = managedUser.value(forKeyPath: "name") as? String
                user.company = managedUser.value(forKeyPath: "company") as? String
                user.note = managedUser.value(forKeyPath: "note") as? String
                user.seen = managedUser.value(forKeyPath: "seen") as? Bool ?? false
                
                if let imageData = managedUser.value(forKeyPath: "imageData") as? Data {
                    user.image = UIImage(data: imageData)
                }
                if let stateStringValue = managedUser.value(forKeyPath: "photoRecordState") as? String {
                    user.state = PhotoRecordState(rawValue: stateStringValue)!
                }
                if user.id != -1 {
                    users.append(user)
                }
            }
            completion(true, users)
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
}

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
    let imageCache = NSCache<NSString, UIImage>()
    
    func loadImageFromCache(key: String) -> UIImage? {
        if let filePath = self.filePath(forKey: key), let fileData = FileManager.default.contents(atPath: filePath.path), let image = UIImage(data: fileData) {
            return image
        }
        return nil
    }
    
    func saveImageToCache(key: String, image: UIImage) {
        guard let imageData = image.pngData() else {
            return
        }
        if let filePath = filePath(forKey: key) {
            do  {
                try imageData.write(to: filePath, options: .atomic)
            } catch let err {
                print("Saving file resulted in error: ", err)
            }
        }
    }
    
    private func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        
        guard let documentURL = fileManager.urls(for: .documentDirectory,
                                                 in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        
        return documentURL.appendingPathComponent(key + ".png")
    }
    
    func save(user: GithubUser) {
        let managedContext = CoreDataContainer.shared.persistentContainer.viewContext
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
    
    func update(user: GithubUser) {
        let managedContext = CoreDataContainer.shared.persistentContainer.viewContext
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
                //objectUpdate.setValue(user.state.rawValue, forKey: "photoRecordState")
                objectUpdate.setValue(user.username, forKey: "username")
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
    
    func deleteAllData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GithubUserAvatar")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        let persistentContainer = CoreDataContainer.shared.persistentContainer

        do {
            try persistentContainer.viewContext.execute(deleteRequest)
        } catch let error as NSError {
            print(error)
        }
    }
    
    func retrieveUsersFromCache(completion: @escaping (_ success: Bool, _ users: [GithubUser]) -> ()) {
        let managedContext = CoreDataContainer.shared.persistentContainer.viewContext
        
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
                
                if let cachedImage = self.loadImageFromCache(key: "\(user.id ?? -1)") {
                    user.image = cachedImage
                    user.state = .downloaded
                }
                else {
                    user.state = .new
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

class CoreDataContainer {
    public static let shared = CoreDataContainer()
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "GithubUserExplorer")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

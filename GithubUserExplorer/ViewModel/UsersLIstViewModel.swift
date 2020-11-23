//
//  GithubProfileViewModel.swift
//  CoordinatorApp
//
//  Created by Elijah Tristan Huey Chan on 11/20/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit
import CoreData

class UsersListViewModel {
    var users: [GithubUser] = []
    var filteredUsers: [GithubUser] = []
    private let pendingOperations = PendingOperations()
    var delegate: UsersListViewModelDelegate?
    
    private var since: Int = 0
    private var total = 0
    private var isFetchInProgress = false
    
    var currentCount: Int {
        return users.count
    }
    
    var totalCount: Int {
        return total
    }
    
    func fetchUsersFromCache() {
        self.users = []
        GithubUserPersistence.shared.retrieveUsersFromCache { (success, users) in
            if success {
                DispatchQueue.main.async {
                    self.users = users
                    self.total = users.count
                    self.since = users.last?.id ?? 0
                    self.delegate?.onFetchUsersSuccess(with: .none)
                }
            }
            else {
                DispatchQueue.main.async {
                    self.delegate?.onFetchUsersFail(with: "failed")
                }
            }
        }
    }
    
    func fetchGithubUsers() {
        guard !isFetchInProgress else {
            return
        }
        
        self.isFetchInProgress = true
        
        RequestManager.shared.fetchGithubUsers(since: since) { (success, response) in
            if success {
                let sinceCounter = self.since
                var newUsers: [GithubUser] = []
                if let payloads = response?["payloads"] as? [[String: Any]] {
                    for payload in payloads {
                        if let user = GithubUser().createUserFromPayload(payload) {
                            let exists = self.users.contains { (userInUsers) -> Bool in
                                return user.id == userInUsers.id
                            }
                            if !exists {
                                self.users.append(user)
                                newUsers.append(user)
                                self.since = user.id!
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.isFetchInProgress = false
                        self.total = self.total + newUsers.count
                        
                        if sinceCounter > 0 {
                            let indexPathsToReload = self.calculateIndexPathsToReload(from: newUsers)
                            self.delegate?.onFetchUsersSuccess(with: indexPathsToReload)
                        }
                        else {
                            self.delegate?.onFetchUsersSuccess(with: .none)
                        }
                    }
                }
            }
            else {
                DispatchQueue.main.async {
                    self.isFetchInProgress = false
                    self.delegate?.onFetchUsersFail(with: "failed")
                }
            }
        }
    }
    
    private func calculateIndexPathsToReload(from newUsers: [GithubUser]) -> [IndexPath] {
        let startIndex = users.count - newUsers.count
        let endIndex = startIndex + newUsers.count
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
    }
    
    
    func startOperations(for user: GithubUser, at indexPath: IndexPath) {
        switch (user.state) {
        case .new:
            startDownload(for: user, at: indexPath)
        case .downloaded:
            guard ((indexPath.row + 1) % 4 == 0) else {
            return
        }
        startFiltration(for: user, at: indexPath)
        default:
            print("do nothing")
        }
    }
    
    func startDownload(for user: GithubUser, at indexPath: IndexPath) {
        guard Reachability.isConnectedToNetwork() else {
            return
        }
        
        guard pendingOperations.downloadsInProgress[indexPath] == nil else {
            return
        }
        let downloader = ImageDownloader(user)
      
        downloader.completionBlock = {
            if downloader.isCancelled {
                return
            }
            DispatchQueue.main.async {
                self.pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
                self.delegate?.reloadTableviewRowsAt(at: [indexPath], with: .fade)
            }
        }
      
        pendingOperations.downloadsInProgress[indexPath] = downloader
        pendingOperations.downloadQueue.addOperation(downloader)
    }
        
    func startFiltration(for user: GithubUser, at indexPath: IndexPath) {
        guard pendingOperations.filtrationsInProgress[indexPath] == nil else {
            return
        }

        let filterer = ImageFiltration(user)
        filterer.completionBlock = {
            if filterer.isCancelled {
                return
            }

            DispatchQueue.main.async {
                self.pendingOperations.filtrationsInProgress.removeValue(forKey: indexPath)
                self.delegate?.reloadTableviewRowsAt(at: [indexPath], with: .fade)
            }
        }

        pendingOperations.filtrationsInProgress[indexPath] = filterer
        pendingOperations.filtrationQueue.addOperation(filterer)
    }
    

    func suspendAllOperations() {
        pendingOperations.downloadQueue.isSuspended = true
        pendingOperations.filtrationQueue.isSuspended = true
    }

    func resumeAllOperations() {
        pendingOperations.downloadQueue.isSuspended = false
        pendingOperations.filtrationQueue.isSuspended = false
    }

    func loadImagesForOnscreenCells() {
        if let pathsArray = self.delegate?.getIndexPathForVisibleRows?() {
        var allPendingOperations = Set(pendingOperations.downloadsInProgress.keys)
        allPendingOperations.formUnion(pendingOperations.filtrationsInProgress.keys)

        var toBeCancelled = allPendingOperations
        let visiblePaths = Set(pathsArray)
        toBeCancelled.subtract(visiblePaths)
          
        var toBeStarted = visiblePaths
        toBeStarted.subtract(allPendingOperations)
          
        for indexPath in toBeCancelled {
            if let pendingDownload = pendingOperations.downloadsInProgress[indexPath] {
                pendingDownload.cancel()
            }
            pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
            if let pendingFiltration = pendingOperations.filtrationsInProgress[indexPath] {
                pendingFiltration.cancel()
            }
            pendingOperations.filtrationsInProgress.removeValue(forKey: indexPath)
        }
            
        for indexPath in toBeStarted {
            let recordToProcess = users[indexPath.row]
            startOperations(for: recordToProcess, at: indexPath)
        }
      }
    }
}

extension UsersListViewModel {
    func filterContentForSearchText(_ searchText: String) {
        filteredUsers = users.filter({ (user) -> Bool in
            let usernameSearch = (user.username?.lowercased().contains(searchText.lowercased()) ?? false)
            let noteSearch = (user.note?.lowercased().contains(searchText.lowercased()) ?? false)
            return usernameSearch || noteSearch
        })
        delegate?.reloadTableView()
    }
}

@objc protocol UsersListViewModelDelegate {
    func onFetchUsersSuccess(with newIndexPathsToReload: [IndexPath]?)
    func onFetchUsersFail(with reason: String)
    
    //functions for image queue download
    func reloadTableviewRowsAt(at: [IndexPath], with: UITableView.RowAnimation)
    func reloadTableView()
    
    @objc optional func getIndexPathForVisibleRows() -> [IndexPath]?
}

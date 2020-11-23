//
//  GithubProfileViewController.swift
//  CoordinatorApp
//
//  Created by Elijah Tristan Huey Chan on 11/19/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit

class UsersListViewController: UIViewController, Storyboarded, UsersListViewModelDelegate {
    
    @IBOutlet weak var tableview: UITableView!
    weak var coordinator: MainCoordinator?
    var viewModel: UsersListViewModel!
    @IBOutlet weak var noInternetBanner: UILabel!
    
    var searchController = UISearchController(searchResultsController: nil)
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    var isFiltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(showNoInternetBanner), name: .NetworkConnectivityDidChange, object: nil)
        hideNoInternetBanner()
        setupSearchController()
        
        viewModel = UsersListViewModel()
        viewModel.delegate = self
        
        self.tableview.delegate = self
        self.tableview.dataSource = self
        self.tableview.register(UINib.init(nibName: "NormalUserCell", bundle: nil), forCellReuseIdentifier: "NormalUserCell")
        self.tableview.register(UINib.init(nibName: "NotedUserCell", bundle: nil), forCellReuseIdentifier: "NotedUserCell")
        
        viewModel.fetchUsersFromCache()
        viewModel.fetchGithubUsers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableview.reloadData()
    }
    
    func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Users"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    func hideNoInternetBanner() {
        let transform = CGAffineTransform(translationX: 0, y: -noInternetBanner.frame.height)
        noInternetBanner.alpha = 0
        noInternetBanner.transform = transform
    }
    
    @objc func showNoInternetBanner(_ notification: NSNotification) {
        guard let isConnected = notification.userInfo?["isConnected"] as? (Bool), isConnected == false else {
            hideNoInternetBanner()
            return
        }
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: .curveLinear, animations: {
            self.noInternetBanner.alpha = 0.5
            self.noInternetBanner.transform = .identity
        }, completion: nil)
    }
    
    func onFetchUsersSuccess(with newIndexPathsToReload: [IndexPath]?) {
        guard let newIndexPathsToReload = newIndexPathsToReload else {
            tableview.reloadData()
            return
        }
        
        tableview.insertRows(at: newIndexPathsToReload, with: .automatic)
        let indexPathsToReload = visibleIndexPathsToReload(intersecting: newIndexPathsToReload)
        tableview.reloadRows(at: indexPathsToReload, with: .automatic)
    }
    
    func onFetchUsersFail(with reason: String) {
        print(reason)
    }
}

extension UsersListViewController: UITableViewDelegate, UITableViewDataSource {
    func reloadTableviewRowsAt(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.tableview.reloadRows(at: indexPaths, with: animation)
    }
    
    func reloadTableView() {
        self.tableview.reloadData()
    }
    
    func getIndexPathForVisibleRows() -> [IndexPath]? {
        return tableview.indexPathsForVisibleRows
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return viewModel.filteredUsers.count
        }
        return viewModel.totalCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user: GithubUser
        if isFiltering {
            user = viewModel.filteredUsers[indexPath.row]
        }
        else {
            user = viewModel.users[indexPath.row]
        }
        
        if let _ = user.note {
            let cell = self.tableview.dequeueReusableCell(withIdentifier: "NotedUserCell") as! NotedUserCell
            cell.backgroundColor = nil
            
            cell.userLabel?.text = user.username
            cell.detailLabel?.text = user.details
            cell.avatarImage?.image = user.image
            
            if user.seen == true {
                cell.backgroundColor = .lightGray
            }
            
            switch (user.state) {
            case .filtered:
                cell.activityIndicator.stopAnimating()
            case .failed:
                cell.activityIndicator.stopAnimating()
                cell.textLabel?.text = "Failed to load"
            case .new:
                cell.activityIndicator.startAnimating()
                if !tableView.isDragging && !tableView.isDecelerating {
                    viewModel.startOperations(for: user, at: indexPath)
                }
            case .downloaded:
                cell.activityIndicator.stopAnimating()
                if !tableView.isDragging && !tableView.isDecelerating {
                    viewModel.startOperations(for: user, at: indexPath)
                }
            }
            return cell
        }
        else {
            let cell = self.tableview.dequeueReusableCell(withIdentifier: "NormalUserCell") as! NormalUserCell
            cell.backgroundColor = nil
            
            cell.userLabel?.text = user.username
            cell.detailLabel?.text = user.details
            cell.avatarImage?.image = user.image
            
            if user.seen == true {
                cell.backgroundColor = .lightGray
            }
            
            switch (user.state) {
            case .filtered:
                cell.activityIndicator.stopAnimating()
            case .failed:
                cell.activityIndicator.stopAnimating()
                cell.textLabel?.text = "Failed to load"
            case .new:
                cell.activityIndicator.startAnimating()
                if !tableView.isDragging && !tableView.isDecelerating {
                    viewModel.startOperations(for: user, at: indexPath)
                }
            case .downloaded:
                cell.activityIndicator.stopAnimating()
                if !tableView.isDragging && !tableView.isDecelerating {
                    viewModel.startOperations(for: user, at: indexPath)
                }
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user: GithubUser
        if isFiltering {
            user = viewModel.filteredUsers[indexPath.row]
        }
        else {
            user = viewModel.users[indexPath.row]
        }
        self.coordinator?.viewProfile(from: user)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: isLoadingCell) {
            viewModel.fetchGithubUsers()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !isFiltering else {
            return
        }
        if indexPath.row + 1 == viewModel.totalCount {
            viewModel.fetchGithubUsers()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewModel.suspendAllOperations()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            viewModel.loadImagesForOnscreenCells()
            viewModel.resumeAllOperations()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        viewModel.loadImagesForOnscreenCells()
        viewModel.resumeAllOperations()
    }
}

private extension UsersListViewController {
    func isLoadingCell(for indexPath: IndexPath) -> Bool {
        return indexPath.row >= viewModel.currentCount
    }

    func visibleIndexPathsToReload(intersecting indexPaths: [IndexPath]) -> [IndexPath] {
        let indexPathsForVisibleRows = tableview.indexPathsForVisibleRows ?? []
        let indexPathsIntersection = Set(indexPathsForVisibleRows).intersection(indexPaths)
        return Array(indexPathsIntersection)
    }
}

extension UsersListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        viewModel.filterContentForSearchText(searchBar.text!)
        viewModel.loadImagesForOnscreenCells()
    }
}

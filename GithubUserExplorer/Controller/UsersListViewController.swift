//
//  GithubProfileViewController.swift
//  CoordinatorApp
//
//  Created by Elijah Tristan Huey Chan on 11/19/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit
import Network

class UsersListViewController: UIViewController, Storyboarded, UsersListViewModelDelegate {
    
    @IBOutlet weak var tableview: UITableView!
    weak var coordinator: MainCoordinator?
    var viewModel: UsersListViewModel!
    @IBOutlet weak var noInternetBanner: UILabel!
    
    private var firstLoad = true
    
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
        ConnectionMonitor.shared.monitorNetworkChanges()
        setupSearchController()
        
        viewModel = UsersListViewModel()
        viewModel.delegate = self
        
        self.tableview.delegate = self
        self.tableview.dataSource = self
        self.tableview.register(UINib.init(nibName: "NormalUserCell", bundle: nil), forCellReuseIdentifier: "NormalUserCell")
        self.tableview.register(UINib.init(nibName: "NotedUserCell", bundle: nil), forCellReuseIdentifier: "NotedUserCell")
        self.tableview.register(UINib.init(nibName: "InvertedUserCell", bundle: nil), forCellReuseIdentifier: "InvertedUserCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if firstLoad {
            viewModel.fetchUsersFromCache()
            viewModel.fetchGithubUsers()
            firstLoad = false
        }
        else {
            viewModel.fetchUsersFromCache()
        }
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
        DispatchQueue.main.async {
            let transform = CGAffineTransform(translationX: 0, y: -self.noInternetBanner.frame.height)
            self.noInternetBanner.alpha = 0
            self.noInternetBanner.transform = transform
        }
    }
    
    @objc func showNoInternetBanner(_ notification: NSNotification) {
        guard let isConnected = notification.userInfo?["isConnected"] as? (Bool), isConnected == false else {
            hideNoInternetBanner()
            return
        }
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: .curveLinear, animations: {
                self.noInternetBanner.alpha = 0.5
                self.noInternetBanner.transform = .identity
            }, completion: nil)
        }
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
            return viewModel.filteredUserItems.count
        }
        return viewModel.totalCount
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var item: UserViewModelItem
        if !isFiltering {
            item = viewModel.userItems[indexPath.row]
        }
        else {
            item = viewModel.filteredUserItems[indexPath.row]
        }
        switch item.type {
        case .Normal:
            let cell = self.tableview.dequeueReusableCell(withIdentifier: "NormalUserCell") as! NormalUserCell
            cell.item = item
            switch (item.user.state) {
            case .failed, .downloaded:
                cell.activityIndicator.stopAnimating()
            case .new:
                cell.activityIndicator.startAnimating()
                if !tableView.isDragging && !tableView.isDecelerating {
                    viewModel.startOperations(for: item.user, at: indexPath)
                }
            }
            return cell
        case .Noted:
            let cell = self.tableview.dequeueReusableCell(withIdentifier: "NotedUserCell") as! NotedUserCell
            cell.item = item
            switch (item.user.state) {
            case .failed, .downloaded:
                cell.activityIndicator.stopAnimating()
            case .new:
                cell.activityIndicator.startAnimating()
                if !tableView.isDragging && !tableView.isDecelerating {
                    viewModel.startOperations(for: item.user, at: indexPath)
                }
            }
            return cell
        case .Inverted:
            let cell = self.tableview.dequeueReusableCell(withIdentifier: "InvertedUserCell") as! InvertedUserCell
            cell.item = item
            switch (item.user.state) {
            case .failed, .downloaded:
                cell.activityIndicator.stopAnimating()
            case .new:
                cell.activityIndicator.startAnimating()
                if !tableView.isDragging && !tableView.isDecelerating {
                    viewModel.startOperations(for: item.user, at: indexPath)
                }
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user: GithubUser
        if isFiltering {
            user = viewModel.filteredUserItems[indexPath.row].user
        }
        else {
            user = viewModel.userItems[indexPath.row].user
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
        viewModel.suspendAllOperations()
        viewModel.filterContentForSearchText(searchBar.text!)
        viewModel.loadImagesForOnscreenCells()
    }
}

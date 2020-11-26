//
//  OperationsManager.swift
//  GithubUserExplorer
//
//  Created by Elijah Tristan Huey Chan on 11/21/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit

class PendingOperations {
    lazy var downloadsInProgress: [IndexPath: Operation] = [:]
    lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
}

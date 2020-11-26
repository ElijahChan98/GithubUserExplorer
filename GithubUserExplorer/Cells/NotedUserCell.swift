//
//  NotedUserCell.swift
//  GithubUserExplorer
//
//  Created by Elijah Tristan Huey Chan on 11/21/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit

class NotedUserCell: UITableViewCell {
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noteImageView: UIImageView!
    
    var item: UserViewModelItem? {
        didSet {
            guard let item = item as? NotedUserViewModelItem else {
                return
            }
            
            userLabel.text = item.user.username
            detailLabel.text = item.user.details
            avatarImage.image = item.user.image
            if item.user.seen == true {
                self.backgroundColor = .lightGray
            }
            else {
                self.backgroundColor = nil
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

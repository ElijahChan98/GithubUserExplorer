//
//  UserCell.swift
//  GithubUserExplorer
//
//  Created by Elijah Tristan Huey Chan on 11/26/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noteImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func applyInvertedColorsFilter(_ image: UIImage) -> UIImage? {
        guard let data = image.pngData() else { return nil }
        let inputImage = CIImage(data: data)

        let context = CIContext(options: nil)

        guard let filter = CIFilter(name: "CIColorInvert") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage, let outImage = context.createCGImage(outputImage, from: outputImage.extent)
            else {
                return nil
        }

        return UIImage(cgImage: outImage)
    }
}

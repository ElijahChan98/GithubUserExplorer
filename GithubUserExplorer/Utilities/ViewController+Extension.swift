//
//  ViewController+Extension.swift
//  GithubUserExplorer
//
//  Created by Elijah Tristan Huey Chan on 11/22/20.
//  Copyright © 2020 Elijah Tristan Huey Chan. All rights reserved.
//

import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func checkForDarkMode() -> UIUserInterfaceStyle {
        return self.traitCollection.userInterfaceStyle
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

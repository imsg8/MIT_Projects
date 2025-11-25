//
//  UIViewController+KeyboardDismiss.swift
//  MyCal360
//
//  Created by Shivang Gulati on 07/11/25.
//

import UIKit

extension UIViewController {

    /// Enables dismissing keyboard when tapping anywhere outside input fields
    func enableKeyboardDismissOnTap() {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboardGlobally)
        )
        tapGesture.cancelsTouchesInView = false // allows buttons to still work
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboardGlobally() {
        view.endEditing(true)
    }
}


//
//  UIViewController+Extensions.swift
//  Youtube Loader
//
//  Created by isEmpty on 22.01.2021.
//

import UIKit

extension UIViewController {
    func showAlert(alertText : String?, alertMessage : String? = nil) {
        let alert = UIAlertController(title: alertText, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

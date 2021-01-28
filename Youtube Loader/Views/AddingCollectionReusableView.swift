//
//  AddingCollectionReusableView.swift
//  Youtube Loader
//
//  Created by isEmpty on 24.01.2021.
//

import UIKit

final class AddingCollectionReusableView: UICollectionReusableView {
    
    //MARK: - Properties
    public static let reuseIdentifier = "AddingCollectionReusableView"
    public var button: AddingButton!

    //MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureButton()
    }
    
    //MARK: - Supporting Methods
    private func configureButton() {
        button = AddingButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            button.heightAnchor.constraint(equalTo: button.widthAnchor)
        ])
    }
}

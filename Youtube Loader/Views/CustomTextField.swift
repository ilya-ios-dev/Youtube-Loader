//
//  CustomTextField.swift
//  Youtube Loader
//
//  Created by isEmpty on 26.01.2021.
//

import UIKit

@IBDesignable
final class CustomTextField: UIView {
    
    //MARK: - Properties
    private var usernameLabelYAnchorConstraint: NSLayoutConstraint!
    private var usernameLabelLeadingAnchor: NSLayoutConstraint!
    
    public lazy var bottomLine: CALayer = {
        let bottomLine = CALayer()
        usernameTextField.layer.addSublayer(bottomLine)
        return bottomLine
    }()
    
    public var placeholder: String = "Username" {
        didSet {
            usernameLBL.text = placeholder
        }
    }
    
    public var bottomLineColor: UIColor = UIColor.darkGray {
        didSet {
            bottomLine.backgroundColor = bottomLineColor.cgColor
        }
    }
    public lazy var usernameLBL: UILabel! = {
        let label = UILabel()
        label.text = "Username"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alpha = 0.5
        return label
    }()
    
    public lazy var usernameTextField: UITextField! = {
        let textLabel = UITextField()
        textLabel.borderStyle = .none
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        return textLabel
    }()
    
    //MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(usernameTextField)
        addSubview(usernameLBL)
        usernameTextField.delegate = self
        
        configureViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubview(usernameTextField)
        addSubview(usernameLBL)
        usernameTextField.delegate = self
        
        configureViews()

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let amountOrigin = CGPoint(x: 0, y: usernameTextField.bounds.height)
        bottomLine.frame = CGRect(origin: amountOrigin, size: CGSize(width: usernameTextField.bounds.width, height: 1))
    }
    
    private func configureViews() {
        usernameLabelYAnchorConstraint = usernameLBL.centerYAnchor.constraint(equalTo: usernameTextField.centerYAnchor, constant: 0)
        usernameLabelLeadingAnchor = usernameLBL.leadingAnchor.constraint(equalTo: usernameTextField.leadingAnchor, constant: 0)
        
        usernameTextField.fillSuperview()
        NSLayoutConstraint.activate([
            usernameLabelYAnchorConstraint,
            usernameLabelLeadingAnchor,
        ])
        bottomLine.backgroundColor = bottomLineColor.cgColor
    }
}

//MARK: - UITextFieldDelegate
extension CustomTextField: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // When the object shrinks, it shifts to the center,
        // i.e. a decrease in 0.8 times means that on each side the object will move by 0.1 + 0.1
        let leadingConstant = usernameLBL.frame.width * 0.1
        usernameLabelYAnchorConstraint.constant = -25
        usernameLabelLeadingAnchor.constant = -leadingConstant
        performAnimation(transform: CGAffineTransform(scaleX: 0.8, y: 0.8))
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text, text.isEmpty {
            usernameLabelYAnchorConstraint.constant = 0
            usernameLabelLeadingAnchor.constant = 5
            performAnimation(transform: CGAffineTransform(scaleX: 1, y: 1))
        }
    }
    
    private func performAnimation(transform: CGAffineTransform) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.usernameLBL.transform = transform
            self.layoutIfNeeded()
        }, completion: nil)
    }
}

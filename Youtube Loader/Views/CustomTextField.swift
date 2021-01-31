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
    private var labelYAnchorConstraint: NSLayoutConstraint!
    private var labelLeadingAnchorConstraint: NSLayoutConstraint!
    
    public lazy var bottomLine: CALayer = {
        let bottomLine = CALayer()
        textField.layer.addSublayer(bottomLine)
        return bottomLine
    }()
    
    public var placeholder: String = "Username" {
        didSet {
            label.text = placeholder
        }
    }
    
    public var bottomLineColor: UIColor = UIColor.darkGray {
        didSet {
            bottomLine.backgroundColor = bottomLineColor.cgColor
        }
    }
    
    public var text: String? {
        get {
            return textField.text
        } set {
            textField.text = newValue
            let leadingConstant = label.frame.width * 0.1
            labelYAnchorConstraint.constant = -25
            labelLeadingAnchorConstraint.constant = -leadingConstant
            performAnimation(transform: CGAffineTransform(scaleX: 0.8, y: 0.8))
        }
    }
    
    public lazy var label: UILabel! = {
        let label = UILabel()
        label.text = "Label"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alpha = 0.5
        return label
    }()
    
    public lazy var textField: UITextField! = {
        let textLabel = UITextField()
        textLabel.borderStyle = .none
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        return textLabel
    }()
    
    //MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textField)
        addSubview(label)
        textField.delegate = self
        
        configureViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubview(textField)
        addSubview(label)
        textField.delegate = self
        
        configureViews()

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let amountOrigin = CGPoint(x: 0, y: textField.bounds.height)
        bottomLine.frame = CGRect(origin: amountOrigin, size: CGSize(width: textField.bounds.width, height: 1))
    }
    
    private func configureViews() {
        labelYAnchorConstraint = label.centerYAnchor.constraint(equalTo: textField.centerYAnchor, constant: 0)
        labelLeadingAnchorConstraint = label.leadingAnchor.constraint(equalTo: textField.leadingAnchor, constant: 0)
        
        textField.fillSuperview()
        NSLayoutConstraint.activate([
            labelYAnchorConstraint,
            labelLeadingAnchorConstraint,
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
        let leadingConstant = label.frame.width * 0.1
        labelYAnchorConstraint.constant = -25
        labelLeadingAnchorConstraint.constant = -leadingConstant
        performAnimation(transform: CGAffineTransform(scaleX: 0.8, y: 0.8))
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text, text.isEmpty {
            labelYAnchorConstraint.constant = 0
            labelLeadingAnchorConstraint.constant = 5
            performAnimation(transform: CGAffineTransform(scaleX: 1, y: 1))
        }
    }
    
    private func performAnimation(transform: CGAffineTransform) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.label.transform = transform
            self.layoutIfNeeded()
        }, completion: nil)
    }
}

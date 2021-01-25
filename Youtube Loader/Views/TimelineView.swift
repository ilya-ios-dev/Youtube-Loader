//
//  TimelineView.swift
//  Youtube Loader
//
//  Created by isEmpty on 11.01.2021.
//

import UIKit

final class TimelineView: UIView {
    
    //MARK: - Properties
    private var bottomStackView: UIStackView!

    public var startLabel: UILabel!
    public var endLabel: UILabel!
    public var slider: UISlider!
    
    //MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    public func changeAccentColor(to color: UIColor) {
        startLabel.textColor = color
        slider.setThumbImage(makeCircleWith(size: CGSize(width: 10, height: 10), backgroundColor: color), for: .normal)
        slider.setThumbImage(makeCircleWith(size: CGSize(width: 17, height: 17), backgroundColor: color), for: .highlighted)
        slider.minimumTrackTintColor = color
        slider.maximumTrackTintColor = #colorLiteral(red: 0.7098039216, green: 0.831372549, blue: 0.8823529412, alpha: 1)

    }
}

private extension TimelineView {
    private func setupViews() {
        setupStartLabel()
        setupEndLabel()
        setupSlider()
        setupStackView()
        bottomStackView.addArrangedSubview(slider)
        
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.axis = .horizontal
        stackView.addArrangedSubview(startLabel)
        stackView.addArrangedSubview(endLabel)
        
        bottomStackView.addArrangedSubview(stackView)
        addSubview(bottomStackView)
        bottomStackView.fillSuperview()
    }
    
    private func setupStartLabel() {
        startLabel = UILabel()
        startLabel.text = "00:00"
        startLabel.textColor = #colorLiteral(red: 0.2941176471, green: 0.3333333333, blue: 0.3529411765, alpha: 1)
        startLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
    }
    
    private func setupEndLabel() {
        endLabel = UILabel()
        endLabel.text = "00:00"
        endLabel.textColor = #colorLiteral(red: 0.2941176471, green: 0.3333333333, blue: 0.3529411765, alpha: 1)
        endLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
    }
    
    private func setupSlider() {
        slider = UISlider()
        //Resize thumb.
        slider.setThumbImage(makeCircleWith(size: CGSize(width: 10, height: 10), backgroundColor: #colorLiteral(red: 0.2352941176, green: 0.2588235294, blue: 0.3568627451, alpha: 1)), for: .normal)
        slider.setThumbImage(makeCircleWith(size: CGSize(width: 17, height: 17), backgroundColor: #colorLiteral(red: 0.2352941176, green: 0.2588235294, blue: 0.3568627451, alpha: 1)), for: .highlighted)
        slider.minimumTrackTintColor = #colorLiteral(red: 0.2352941176, green: 0.2588235294, blue: 0.3568627451, alpha: 1)
        slider.maximumTrackTintColor = .white
    }
    
    private func makeCircleWith(size: CGSize, backgroundColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(backgroundColor.cgColor)
        context?.setStrokeColor(UIColor.clear.cgColor)
        let bounds = CGRect(origin: .zero, size: size)
        context?.addEllipse(in: bounds)
        context?.drawPath(using: .fill)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func setupStackView() {
        bottomStackView = UIStackView()
        bottomStackView.alignment = .fill
        bottomStackView.axis = .vertical
        bottomStackView.distribution = .fill
    }
}

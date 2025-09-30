//
//  CategoryCollectionViewCell.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 01.10.25.
//

import UIKit
import SnapKit

final class CategoryCollectionViewCell: UICollectionViewCell {
    static let identifier = "CategoryCollectionViewCell"
    
    private let effectView = UIVisualEffectView()
    private let glassEffect = UIGlassEffect()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        glassEffect.isInteractive = true
        effectView.effect = glassEffect
        effectView.cornerConfiguration = .corners(radius: .fixed(12))
        glassEffect.tintColor = .systemBlue

        addSubviews()
        configureContraints()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviews() {
        addSubview(effectView)
        effectView.contentView.addSubview(titleLabel)
    }
    
    private func configureContraints() {
        effectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}


extension CategoryCollectionViewCell {
    func configure(title: String) {
        titleLabel.text = title
    }
}

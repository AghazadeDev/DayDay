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
        label.numberOfLines = .zero
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .light)
        label.textColor = .secondaryLabel
        label.numberOfLines = .zero
        return label
    }()
    
    private let titlesStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 4
        
        return sv
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
        effectView.contentView.addSubview(titlesStackView)
        [
            titleLabel,
            subtitleLabel
        ].forEach(titlesStackView.addArrangedSubview)
    }
    
    private func configureContraints() {
        effectView.snp.makeConstraints { make in
            make.horizontalEdges.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
        }
        titlesStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
}


extension CategoryCollectionViewCell {
    func configure(title: String, subTitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subTitle
    }
}

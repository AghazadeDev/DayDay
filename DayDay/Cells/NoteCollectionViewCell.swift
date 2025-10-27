//
//  NoteCollectionViewCell.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 27.10.25.
//

import UIKit
import SnapKit

final class NoteCollectionViewCell: UICollectionViewCell {
    static let identifier = "NoteCollectionViewCell"
    
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let dateLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 14
        cardView.layer.masksToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        
        contentLabel.font = .systemFont(ofSize: 14)
        contentLabel.textColor = .secondaryLabel
        contentLabel.numberOfLines = 4
        
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = .tertiaryLabel
        dateLabel.textAlignment = .right
        
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
        }
        
        cardView.addSubview(titleLabel)
        cardView.addSubview(contentLabel)
        cardView.addSubview(dateLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(14)
        }
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(14)
        }
        dateLabel.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(contentLabel.snp.bottom).offset(8)
            make.trailing.bottom.equalToSuperview().inset(14)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with note: NoteWithMeta) {
        titleLabel.text = note.title
        contentLabel.text = note.content
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        dateLabel.text = df.string(from: note.createdAt)
    }
}

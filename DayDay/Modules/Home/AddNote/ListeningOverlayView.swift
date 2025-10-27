//
//  ListeningOverlayView.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 27.10.25.
//

import UIKit
import SnapKit

final class ListeningOverlayView: UIView {
    var onStop: (() -> Void)?
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        return v
    }()
    
    private let container = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stopButton = UIButton(type: .system)
    private let pulseView: PulsingMicView = {
        let v = PulsingMicView()
        v.pulseColor = UIColor.systemPurple.withAlphaComponent(0.28)
        v.coreColor = UIColor.systemPurple
        v.pulseCount = 3
        v.pulseDuration = 1.8
        v.pulseMaxScale = 2.6
        v.alpha = 1
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = true
        setup()
    }
    
    private func setup() {
        addSubview(blurView)
        addSubview(dimView)
        addSubview(container)
        container.addSubview(pulseView)
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(stopButton)
        
        blurView.snp.makeConstraints { $0.edges.equalToSuperview() }
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        container.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(safeAreaLayoutGuide).offset(24)
            make.trailing.lessThanOrEqualTo(safeAreaLayoutGuide).inset(24)
        }
        
        pulseView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(220)
        }
        
        titleLabel.text = "Слушаю…"
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        
        subtitleLabel.text = "Говорите свободно. Анимация реагирует на голос."
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        stopButton.setTitle("Стоп", for: .normal)
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.backgroundColor = .systemPurple
        stopButton.layer.cornerRadius = 12
        stopButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(pulseView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        stopButton.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    func present(in host: UIView) {
        host.addSubview(self)
        self.alpha = 0
        self.snp.makeConstraints { make in
            make.edges.equalTo(host)
        }
        pulseView.start()
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
        }
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.pulseView.stop()
            self.removeFromSuperview()
        })
    }
    
    @objc private func stopTapped() {
        onStop?()
    }
    
    // Публичное обновление уровня (0...1)
    func update(level: CGFloat) {
        pulseView.updateLevel(level)
    }
}


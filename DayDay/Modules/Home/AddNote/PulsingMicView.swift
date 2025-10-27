//
//  PulsingMicView.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 27.10.25.
//

import UIKit

final class PulsingMicView: UIView {
    // Базовые настройки
    var pulseColor: UIColor = UIColor.systemPurple.withAlphaComponent(0.26) { didSet { pulseLayers.forEach { $0.fillColor = pulseColor.cgColor } } }
    var coreColor: UIColor = UIColor.systemPurple { didSet { coreView.backgroundColor = coreColor } }
    var pulseCount: Int = 3 { didSet { createPulseLayers() } }
    var pulseDuration: CFTimeInterval = 1.8
    var pulseMaxScale: CGFloat = 2.4
    var pulseLineWidth: CGFloat = 0
    
    private let coreView = UIView()
    private var pulseLayers: [CAShapeLayer] = []
    private var isAnimating = false
    
    // Реактивный коэффициент (0...1), от громкости
    private var level: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
        setup()
    }
    
    private func setup() {
        coreView.backgroundColor = coreColor
        addSubview(coreView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        coreView.frame = bounds.insetBy(dx: bounds.width * 0.35, dy: bounds.height * 0.35)
        coreView.layer.cornerRadius = min(coreView.bounds.width, coreView.bounds.height) / 2
        if pulseLayers.isEmpty {
            createPulseLayers()
        } else {
            updatePulsePaths()
        }
    }
    
    private func createPulseLayers() {
        pulseLayers.forEach { $0.removeFromSuperlayer() }
        pulseLayers.removeAll()
        
        for _ in 0..<pulseCount {
            let layer = CAShapeLayer()
            layer.fillColor = pulseColor.cgColor
            layer.strokeColor = pulseLineWidth > 0 ? pulseColor.cgColor : nil
            layer.lineWidth = pulseLineWidth
            self.layer.insertSublayer(layer, below: coreView.layer)
            pulseLayers.append(layer)
        }
        updatePulsePaths()
    }
    
    private func updatePulsePaths() {
        let path = UIBezierPath(ovalIn: bounds.insetBy(dx: bounds.width * 0.15, dy: bounds.height * 0.15))
        pulseLayers.forEach { $0.path = path.cgPath }
    }
    
    func start() {
        guard !isAnimating else { return }
        isAnimating = true
        alpha = 1
        
        let step = pulseDuration / Double(max(1, pulseCount))
        for (index, layer) in pulseLayers.enumerated() {
            layer.removeAllAnimations()
            let group = CAAnimationGroup()
            group.duration = pulseDuration
            group.beginTime = CACurrentMediaTime() + (Double(index) * step)
            group.repeatCount = .infinity
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 0.8
            scale.toValue = pulseMaxScale
            
            let opacity = CAKeyframeAnimation(keyPath: "opacity")
            opacity.values = [0.55, 0.35, 0.0]
            opacity.keyTimes = [0, 0.7, 1]
            
            group.animations = [scale, opacity]
            layer.add(group, forKey: "pulse")
        }
        
        // Лёгкая пульсация ядра
        coreView.layer.removeAllAnimations()
        let core = CABasicAnimation(keyPath: "transform.scale")
        core.fromValue = 1.0
        core.toValue = 1.08
        core.duration = 0.6
        core.autoreverses = true
        core.repeatCount = .infinity
        core.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        coreView.layer.add(core, forKey: "corePulse")
    }
    
    func stop() {
        guard isAnimating else { return }
        isAnimating = false
        UIView.animate(withDuration: 0.22) {
            self.alpha = 0
        } completion: { _ in
            self.pulseLayers.forEach { $0.removeAllAnimations() }
            self.coreView.layer.removeAllAnimations()
        }
    }
    
    // Реакция на уровень громкости (0...1)
    func updateLevel(_ value: CGFloat) {
        // Сгладим и ограничим
        let clamped = max(0, min(1, value))
        // Лёгкая интерполяция
        level = level * 0.7 + clamped * 0.3
        
        // Меняем визуально: чуть увеличим базовый размер и альфу заливки
        // Чем выше уровень — тем сильнее масштаб “ядра” и видимость пульсов.
        let coreScale: CGFloat = 1.0 + level * 0.12
        coreView.transform = CGAffineTransform(scaleX: coreScale, y: coreScale)
        
        let fillAlphaBase: CGFloat = 0.26
        let fillAlpha = fillAlphaBase + level * 0.24 // до ~0.5
        let color = pulseColor.withAlphaComponent(fillAlpha)
        pulseLayers.forEach { $0.fillColor = color.cgColor }
    }
}


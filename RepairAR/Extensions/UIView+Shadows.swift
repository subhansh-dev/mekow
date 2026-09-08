import UIKit

// MARK: - UIView Shadow & Border Helpers

extension UIView {

    /// Apply a standard card shadow.
    func applyCardShadow(
        color: UIColor = .black,
        opacity: Float = 0.3,
        radius: CGFloat = 8,
        offset: CGSize = CGSize(width: 0, height: 2)
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = offset
        layer.masksToBounds = false
    }

    /// Apply a soft glow shadow (for accent-colored elements).
    func applyGlowShadow(
        color: UIColor = UIColor(hex: "#00D4FF"),
        radius: CGFloat = 12,
        opacity: Float = 0.4
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = .zero
        layer.masksToBounds = false
    }

    /// Add a border with specified color and width.
    func addBorder(color: UIColor, width: CGFloat = 1.0) {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
    }

    /// Round corners with a specific radius.
    func roundCorners(_ radius: CGFloat) {
        layer.cornerRadius = radius
        clipsToBounds = true
    }

    /// Apply a frosted glass effect (blur + tint).
    func applyFrostedGlass(
        style: UIBlurEffect.Style = .systemUltraThinMaterialDark,
        tint: UIColor = UIColor.black.withAlphaComponent(0.3)
    ) {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurView, at: 0)

        let tintView = UIView()
        tintView.backgroundColor = tint
        tintView.frame = bounds
        tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.contentView.addSubview(tintView)
    }

    /// Animate a subtle bounce.
    func bounceAnimation(scale: CGFloat = 1.05, duration: TimeInterval = 0.2) {
        UIView.animate(
            withDuration: duration / 2,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                self.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        ) { _ in
            UIView.animate(
                withDuration: duration / 2,
                delay: 0,
                options: [.curveEaseIn],
                animations: {
                    self.transform = .identity
                }
            )
        }
    }

    /// Animate fade in.
    func fadeIn(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        alpha = 0
        isHidden = false
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1
        }) { _ in
            completion?()
        }
    }

    /// Animate fade out.
    func fadeOut(duration: TimeInterval = 0.3, hideOnComplete: Bool = true, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0
        }) { _ in
            if hideOnComplete {
                self.isHidden = true
            }
            completion?()
        }
    }
}

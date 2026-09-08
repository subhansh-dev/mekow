import UIKit

// MARK: - Step Card View
// Floating card UI that shows the current repair step at the bottom of the AR view.

final class StepCardView: UIView {

    // MARK: - Properties

    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    private let borderView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        view.isUserInteractionEnabled = false
        return view
    }()

    private let stepBadge: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#00D4FF")
        view.layer.cornerRadius = 14
        return view
    }()

    private let stepNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = UIColor(hex: "#0A0A0F")
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 1
        return label
    }()

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.numberOfLines = 3
        return label
    }()

    private let warningIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        iv.tintColor = UIColor(hex: "#FF6B6B")
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private let tipIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "lightbulb.fill"))
        iv.tintColor = UIColor(hex: "#FFD700")
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private let chevronView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.up"))
        iv.tintColor = UIColor.white.withAlphaComponent(0.3)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        addSubview(blurView)
        addSubview(borderView)
        addSubview(stepBadge)
        stepBadge.addSubview(stepNumberLabel)
        addSubview(titleLabel)
        addSubview(instructionLabel)
        addSubview(warningIcon)
        addSubview(tipIcon)
        addSubview(chevronView)

        blurView.translatesAutoresizingMaskIntoConstraints = false
        borderView.translatesAutoresizingMaskIntoConstraints = false
        stepBadge.translatesAutoresizingMaskIntoConstraints = false
        stepNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        warningIcon.translatesAutoresizingMaskIntoConstraints = false
        tipIcon.translatesAutoresizingMaskIntoConstraints = false
        chevronView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            borderView.topAnchor.constraint(equalTo: topAnchor),
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stepBadge.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stepBadge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stepBadge.widthAnchor.constraint(equalToConstant: 28),
            stepBadge.heightAnchor.constraint(equalToConstant: 28),

            stepNumberLabel.centerXAnchor.constraint(equalTo: stepBadge.centerXAnchor),
            stepNumberLabel.centerYAnchor.constraint(equalTo: stepBadge.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: stepBadge.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -8),

            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            instructionLabel.leadingAnchor.constraint(equalTo: stepBadge.trailingAnchor, constant: 12),
            instructionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            warningIcon.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 10),
            warningIcon.leadingAnchor.constraint(equalTo: stepBadge.trailingAnchor, constant: 12),
            warningIcon.widthAnchor.constraint(equalToConstant: 16),
            warningIcon.heightAnchor.constraint(equalToConstant: 16),

            tipIcon.centerYAnchor.constraint(equalTo: warningIcon.centerYAnchor),
            tipIcon.leadingAnchor.constraint(equalTo: warningIcon.trailingAnchor, constant: 12),
            tipIcon.widthAnchor.constraint(equalToConstant: 16),
            tipIcon.heightAnchor.constraint(equalToConstant: 16),

            chevronView.centerYAnchor.constraint(equalTo: stepBadge.centerYAnchor),
            chevronView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chevronView.widthAnchor.constraint(equalToConstant: 16),
            chevronView.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    // MARK: - Configuration

    func configure(stepNumber: Int, title: String, instruction: String, warnings: [String], tips: [String]) {
        stepNumberLabel.text = "\(stepNumber)"
        titleLabel.text = title
        instructionLabel.text = instruction

        warningIcon.isHidden = warnings.isEmpty
        tipIcon.isHidden = tips.isEmpty

        // Animate content change
        let transition = CATransition()
        transition.type = .fade
        transition.duration = 0.2
        layer.add(transition, forKey: nil)
    }
}

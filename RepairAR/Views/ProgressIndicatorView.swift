import UIKit

// MARK: - Progress Indicator View
// Shows step progress as a series of dots with the current step highlighted.

final class ProgressIndicatorView: UIView {

    // MARK: - Properties

    private let totalSteps: Int
    private var currentStep: Int = 0
    private var dots: [UIView] = []
    private var labels: [UILabel] = []
    private let dotSize: CGFloat = 10
    private let activeDotSize: CGFloat = 14
    private let spacing: CGFloat = 6

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.distribution = .equalSpacing
        return sv
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.textAlignment = .right
        return label
    }()

    // MARK: - Init

    init(totalSteps: Int) {
        self.totalSteps = totalSteps
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(stackView)
        addSubview(progressLabel)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = spacing
        progressLabel.setContentHuggingPriority(.required, for: .horizontal)
        progressLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Create dots
        for i in 0..<totalSteps {
            let dot = UIView()
            dot.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            dot.layer.cornerRadius = dotSize / 2
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: dotSize),
                dot.heightAnchor.constraint(equalToConstant: dotSize),
            ])
            dots.append(dot)
            stackView.addArrangedSubview(dot)
        }

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: progressLabel.leadingAnchor, constant: -8),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),

            progressLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 32),
        ])

        setCurrentStep(0)
    }

    // MARK: - Update

    func setCurrentStep(_ step: Int) {
        currentStep = step
        progressLabel.text = "\(step + 1)/\(totalSteps)"

        for (index, dot) in dots.enumerated() {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                if index < step {
                    // Completed
                    dot.backgroundColor = UIColor(hex: "#00D4FF").withAlphaComponent(0.4)
                    dot.layer.cornerRadius = self.dotSize / 2
                    dot.transform = .identity
                } else if index == step {
                    // Current
                    dot.backgroundColor = UIColor(hex: "#00D4FF")
                    dot.layer.cornerRadius = self.activeDotSize / 2
                    dot.transform = CGAffineTransform(scaleX: self.activeDotSize / self.dotSize, y: self.activeDotSize / self.dotSize)
                } else {
                    // Not reached
                    dot.backgroundColor = UIColor.white.withAlphaComponent(0.2)
                    dot.layer.cornerRadius = self.dotSize / 2
                    dot.transform = .identity
                }
            }
        }

        // Haptic for completion
        if step > 0 {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    func markComplete() {
        for dot in dots {
            UIView.animate(withDuration: 0.3) {
                dot.backgroundColor = UIColor(hex: "#4CAF50")
            }
        }
        progressLabel.text = "✓ Done"
    }
}

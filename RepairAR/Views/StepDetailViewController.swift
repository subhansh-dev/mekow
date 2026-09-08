import UIKit

// MARK: - Step Detail View Controller
// Full-screen view for a single repair step with AR integration.
// Used when user wants to focus on a specific step without the AR camera.

final class StepDetailViewController: UIViewController {

    // MARK: - Properties

    private let step: RepairStep
    private let guide: RepairGuide
    private let device: Device
    private let stepIndex: Int

    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var stepNumberLabel: UILabel!
    private var titleLabel: UILabel!
    private var instructionLabel: UILabel!
    private var warningsStack: UIStackView!
    private var tipsStack: UIStackView!
    private var toolsStack: UIStackView!
    private var imageView: UIImageView?
    private var durationLabel: UILabel!

    private let padding: CGFloat = 20

    // MARK: - Init

    init(step: RepairStep, stepIndex: Int, guide: RepairGuide, device: Device) {
        self.step = step
        self.stepIndex = stepIndex
        self.guide = guide
        self.device = device
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#0A0A0F")
        setupUI()
        configureContent()
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Navigation
        title = "Step \(step.stepNumber)"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arkit"),
            style: .plain,
            target: self,
            action: #selector(openAR)
        )
        navigationItem.rightBarButtonItem?.tintColor = UIColor(hex: "#00D4FF")

        // Scroll view
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        // Step number
        stepNumberLabel = UILabel()
        stepNumberLabel.font = .systemFont(ofSize: 60, weight: .bold)
        stepNumberLabel.textColor = UIColor(hex: "#00D4FF").withAlphaComponent(0.2)
        stepNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stepNumberLabel)

        // Duration
        durationLabel = UILabel()
        durationLabel.font = .systemFont(ofSize: 12, weight: .medium)
        durationLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(durationLabel)

        // Title
        titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // Instruction
        instructionLabel = UILabel()
        instructionLabel.font = .systemFont(ofSize: 16, weight: .regular)
        instructionLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(instructionLabel)

        // Warnings stack
        warningsStack = createSectionStack(icon: "exclamationmark.triangle.fill", iconColor: UIColor(hex: "#FF6B6B"))
        warningsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(warningsStack)

        // Tips stack
        tipsStack = createSectionStack(icon: "lightbulb.fill", iconColor: UIColor(hex: "#FFD700"))
        tipsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tipsStack)

        // Tools stack
        toolsStack = createSectionStack(icon: "wrench.fill", iconColor: UIColor(hex: "#00D4FF"))
        toolsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(toolsStack)

        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            stepNumberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stepNumberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            durationLabel.centerYAnchor.constraint(equalTo: stepNumberLabel.centerYAnchor, constant: -10),
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            titleLabel.topAnchor.constraint(equalTo: stepNumberLabel.bottomAnchor, constant: -8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            instructionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            warningsStack.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 20),
            warningsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            warningsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            tipsStack.topAnchor.constraint(equalTo: warningsStack.bottomAnchor, constant: 16),
            tipsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            tipsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            toolsStack.topAnchor.constraint(equalTo: tipsStack.bottomAnchor, constant: 16),
            toolsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            toolsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            toolsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
        ])
    }

    // MARK: - Content Configuration

    private func configureContent() {
        stepNumberLabel.text = String(format: "%02d", step.stepNumber)
        titleLabel.text = step.title
        instructionLabel.text = step.instruction

        if let duration = step.durationFormatted {
            durationLabel.text = "⏱ \(duration)"
            durationLabel.isHidden = false
        } else {
            durationLabel.isHidden = true
        }

        // Warnings
        if step.hasWarnings {
            warningsStack.isHidden = false
            for warning in step.warnings {
                let label = UILabel()
                label.text = warning
                label.font = .systemFont(ofSize: 14, weight: .regular)
                label.textColor = UIColor(hex: "#FF6B6B")
                label.numberOfLines = 0
                warningsStack.addArrangedSubview(label)
            }
        } else {
            warningsStack.isHidden = true
        }

        // Tips
        if step.hasTips {
            tipsStack.isHidden = false
            for tip in step.tips {
                let label = UILabel()
                label.text = tip
                label.font = .systemFont(ofSize: 14, weight: .regular)
                label.textColor = UIColor(hex: "#FFD700")
                label.numberOfLines = 0
                tipsStack.addArrangedSubview(label)
            }
        } else {
            tipsStack.isHidden = true
        }

        // Tools
        if !step.toolsNeeded.isEmpty {
            toolsStack.isHidden = false
            for tool in step.toolsNeeded {
                let label = UILabel()
                label.text = "• \(tool)"
                label.font = .systemFont(ofSize: 14, weight: .regular)
                label.textColor = UIColor(hex: "#00D4FF")
                toolsStack.addArrangedSubview(label)
            }
        } else {
            toolsStack.isHidden = true
        }
    }

    // MARK: - Helpers

    private func createSectionStack(icon: String, iconColor: UIColor) -> UIStackView {
        let iconImageView = UIImageView(image: UIImage(systemName: icon))
        iconImageView.tintColor = iconColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 18),
            iconImageView.heightAnchor.constraint(equalToConstant: 18),
        ])

        let headerStack = UIStackView(arrangedSubviews: [iconImageView, UIView()])
        headerStack.axis = .horizontal
        headerStack.spacing = 8

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.addArrangedSubview(headerStack)
        return stack
    }

    // MARK: - Actions

    @objc private func openAR() {
        let arVC = ARViewController(device: device, guide: guide)
        present(arVC, animated: true)
    }
}

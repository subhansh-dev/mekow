import UIKit

// MARK: - Component Info View
// Popup showing details about a tapped component in the AR view.

final class ComponentInfoView: UIView {

    // MARK: - Properties

    var onDismiss: (() -> Void)?

    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()

    private let borderView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(hex: "#00D4FF").withAlphaComponent(0.3).cgColor
        view.isUserInteractionEnabled = false
        return view
    }()

    private let iconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#00D4FF").withAlphaComponent(0.15)
        view.layer.cornerRadius = 20
        return view
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = UIColor(hex: "#00D4FF")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private let typeBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = UIColor(hex: "#00D4FF")
        label.backgroundColor = UIColor(hex: "#00D4FF").withAlphaComponent(0.15)
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.numberOfLines = 4
        return label
    }()

    private let toolsHeader: UILabel = {
        let label = UILabel()
        label.text = "🔧 Tools Required"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        return label
    }()

    private let toolsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.numberOfLines = 0
        return label
    }()

    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.4)
        return button
    }()

    // MARK: - Init

    init(component: Component) {
        super.init(frame: .zero)
        setupLayout()
        configure(with: component)
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        addSubview(blurView)
        addSubview(borderView)
        addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        addSubview(nameLabel)
        addSubview(typeBadge)
        addSubview(descriptionLabel)
        addSubview(toolsHeader)
        addSubview(toolsLabel)
        addSubview(dismissButton)

        blurView.translatesAutoresizingMaskIntoConstraints = false
        borderView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        typeBadge.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        toolsHeader.translatesAutoresizingMaskIntoConstraints = false
        toolsLabel.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            borderView.topAnchor.constraint(equalTo: topAnchor),
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor),

            dismissButton.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            dismissButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            dismissButton.widthAnchor.constraint(equalToConstant: 24),
            dismissButton.heightAnchor.constraint(equalToConstant: 24),

            iconContainer.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            iconContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconContainer.widthAnchor.constraint(equalToConstant: 40),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: dismissButton.leadingAnchor, constant: -8),

            typeBadge.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            typeBadge.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            typeBadge.heightAnchor.constraint(equalToConstant: 20),
            typeBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            descriptionLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            toolsHeader.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            toolsHeader.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            toolsHeader.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            toolsLabel.topAnchor.constraint(equalTo: toolsHeader.bottomAnchor, constant: 4),
            toolsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            toolsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            toolsLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }

    // MARK: - Configuration

    private func configure(with component: Component) {
        nameLabel.text = component.name
        descriptionLabel.text = component.description
        typeBadge.text = "  \(component.type.rawValue.uppercased())  "

        // Icon based on type
        let icon: String
        switch component.type {
        case .screw: icon = "circle.fill"
        case .component: icon = "cpu"
        case .cable: icon = "cable.connector"
        case .connector: icon = "point.3.connected.trianglepath.dotted"
        case .adhesive: icon = "drop.fill"
        case .battery: icon = "battery.100.bolt"
        case .display: icon = "display"
        case .storage: icon = "internaldrive"
        case .memory: icon = "memorychip"
        case .fan: icon = "fan.fill"
        case .board: icon = "cpu"
        }
        iconView.image = UIImage(systemName: icon)

        if component.toolsRequired.isEmpty {
            toolsHeader.isHidden = true
            toolsLabel.isHidden = true
        } else {
            toolsHeader.isHidden = false
            toolsLabel.isHidden = false
            toolsLabel.text = component.toolsRequired.joined(separator: " • ")
        }
    }

    // MARK: - Actions

    @objc private func dismissTapped() {
        onDismiss?()
    }
}

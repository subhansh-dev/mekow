import UIKit

// MARK: - Difficulty Badge View
// Small badge showing repair difficulty with color coding.

final class DifficultyBadgeView: UIView {

    // MARK: - Properties

    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textAlignment = .center
        return label
    }()

    private let dotView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 3
        return view
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupLayout() {
        layer.cornerRadius = 10
        clipsToBounds = true

        addSubview(dotView)
        addSubview(label)

        dotView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: dotView.leadingAnchor, constant: -8),
            centerYAnchor.constraint(equalTo: dotView.centerYAnchor),
            dotView.widthAnchor.constraint(equalToConstant: 6),
            dotView.heightAnchor.constraint(equalToConstant: 6),
            dotView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            dotView.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: 4),
            trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            topAnchor.constraint(equalTo: label.topAnchor, constant: -4),
            bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
        ])
    }

    // MARK: - Configuration

    func setDifficulty(_ difficulty: RepairGuide.Difficulty) {
        label.text = difficulty.displayName
        let color = UIColor(hex: difficulty.colorHex)
        label.textColor = color
        dotView.backgroundColor = color
        backgroundColor = color.withAlphaComponent(0.15)
    }
}

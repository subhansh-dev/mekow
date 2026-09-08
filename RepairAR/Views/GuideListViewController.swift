import UIKit

// MARK: - Guide List View Controller
// Displays available repair guides for a selected device.

final class GuideListViewController: UIViewController {

    // MARK: - Properties

    private let device: Device
    private var guides: [RepairGuide] = []
    private var tableView: UITableView!
    private var headerView: UIView!
    private var emptyLabel: UILabel!

    private let cellIdentifier = "GuideCell"
    private let padding: CGFloat = 16

    // MARK: - Init

    init(device: Device) {
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
        title = device.displayName
        loadData()
        setupUI()
    }

    // MARK: - Data

    private func loadData() {
        guides = DataManager.shared.getGuides(for: device.id)
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Device header
        headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        let deviceIcon = UIImageView(image: UIImage(systemName: "laptopcomputer"))
        deviceIcon.tintColor = UIColor(hex: "#00D4FF")
        deviceIcon.contentMode = .scaleAspectFit
        deviceIcon.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(deviceIcon)

        let deviceName = UILabel()
        deviceName.text = device.displayName
        deviceName.font = .systemFont(ofSize: 22, weight: .bold)
        deviceName.textColor = .white
        deviceName.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(deviceName)

        let infoLabel = UILabel()
        infoLabel.text = "\(device.componentCount) components • \(device.manufacturer)"
        infoLabel.font = .systemFont(ofSize: 13, weight: .regular)
        infoLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(infoLabel)

        let guidesTitle = UILabel()
        guidesTitle.text = "Repair Guides"
        guidesTitle.font = .systemFont(ofSize: 18, weight: .semibold)
        guidesTitle.textColor = .white
        guidesTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guidesTitle)

        // Table view
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(GuideCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Empty state
        emptyLabel = UILabel()
        emptyLabel.text = "No repair guides available for this device.\nCheck iFixit for online guides."
        emptyLabel.font = .systemFont(ofSize: 15, weight: .regular)
        emptyLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.isHidden = !guides.isEmpty
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            headerView.heightAnchor.constraint(equalToConstant: 80),

            deviceIcon.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            deviceIcon.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            deviceIcon.widthAnchor.constraint(equalToConstant: 48),
            deviceIcon.heightAnchor.constraint(equalToConstant: 48),

            deviceName.leadingAnchor.constraint(equalTo: deviceIcon.trailingAnchor, constant: 16),
            deviceName.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            deviceName.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),

            infoLabel.leadingAnchor.constraint(equalTo: deviceName.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            infoLabel.topAnchor.constraint(equalTo: deviceName.bottomAnchor, constant: 4),

            guidesTitle.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            guidesTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            tableView.topAnchor.constraint(equalTo: guidesTitle.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
        ])
    }

    // MARK: - Navigation

    private func startGuide(_ guide: RepairGuide) {
        let arVC = ARViewController(device: device, guide: guide)
        present(arVC, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension GuideListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guides.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! GuideCell
        let guide = guides[indexPath.row]
        cell.configure(with: guide)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension GuideListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let guide = guides[indexPath.row]
        startGuide(guide)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        140
    }
}

// MARK: - Guide Cell

private final class GuideCell: UITableViewCell {

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private let difficultyBadge = DifficultyBadgeView()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        return label
    }()

    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        return label
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(hex: "#FFD700")
        return label
    }()

    private let chevronView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = UIColor.white.withAlphaComponent(0.3)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(difficultyBadge)
        cardView.addSubview(timeLabel)
        cardView.addSubview(stepsLabel)
        cardView.addSubview(ratingLabel)
        cardView.addSubview(chevronView)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        difficultyBadge.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        chevronView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -8),

            difficultyBadge.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            difficultyBadge.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),

            timeLabel.centerYAnchor.constraint(equalTo: difficultyBadge.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: difficultyBadge.trailingAnchor, constant: 12),

            stepsLabel.centerYAnchor.constraint(equalTo: difficultyBadge.centerYAnchor),
            stepsLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 12),

            ratingLabel.centerYAnchor.constraint(equalTo: difficultyBadge.centerYAnchor),
            ratingLabel.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -12),

            chevronView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevronView.widthAnchor.constraint(equalToConstant: 12),
        ])
    }

    func configure(with guide: RepairGuide) {
        titleLabel.text = guide.title
        difficultyBadge.setDifficulty(guide.difficulty)
        timeLabel.text = "⏱ \(guide.timeEstimateFormatted)"
        stepsLabel.text = "📋 \(guide.totalSteps) steps"
        if guide.rating > 0 {
            ratingLabel.text = "⭐ \(String(format: "%.1f", guide.rating))"
            ratingLabel.isHidden = false
        } else {
            ratingLabel.isHidden = true
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.15) {
            self.cardView.transform = highlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
        }
    }
}

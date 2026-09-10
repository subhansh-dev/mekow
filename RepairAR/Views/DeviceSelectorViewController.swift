import UIKit

// MARK: - Device Selector View Controller
// Grid layout for browsing and searching available devices.

final class DeviceSelectorViewController: UIViewController {

    // MARK: - Properties

    private var collectionView: UICollectionView!
    private var searchController: UISearchController!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!

    private var allDevices: [Device] = []
    private var filteredDevices: [Device] = []
    private var isSearching: Bool = false

    private let cellIdentifier = "DeviceCell"
    private let padding: CGFloat = 16
    private let cellSpacing: CGFloat = 12

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "Background") ?? UIColor(hex: "#0A0A0F")
        loadData()
        setupUI()
        setupSearchController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Data

    private func loadData() {
        allDevices = DataManager.shared.getAllDevices()
        filteredDevices = allDevices
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Title header
        titleLabel = UILabel()
        titleLabel.text = "RepairAR"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .white

        subtitleLabel = UILabel()
        subtitleLabel.text = "Select a device to begin repair"
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerStack)

        // Collection view layout
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = cellSpacing
        layout.minimumLineSpacing = cellSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: padding, bottom: padding, right: padding)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(DeviceCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsVerticalScrollIndicator = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            collectionView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search devices..."
        searchController.searchBar.tintColor = UIColor(hex: "#00D4FF")
        searchController.searchBar.searchTextField.textColor = .white
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    // MARK: - Navigation

    private func showGuides(for device: Device) {
        let guideVC = GuideListViewController(device: device)
        navigationController?.pushViewController(guideVC, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension DeviceSelectorViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let devices = isSearching ? filteredDevices : allDevices
        return devices.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? DeviceCell else {
            return UICollectionViewCell()
        }
        let devices = isSearching ? filteredDevices : allDevices
        let device = devices[indexPath.item]
        cell.configure(with: device)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension DeviceSelectorViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let devices = isSearching ? filteredDevices : allDevices
        let device = devices[indexPath.item]
        showGuides(for: device)

        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension DeviceSelectorViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = collectionView.bounds.width - padding * 2 - cellSpacing
        let itemWidth = totalWidth / 2
        return CGSize(width: itemWidth, height: itemWidth * 1.1)
    }
}

// MARK: - UISearchResultsUpdating

extension DeviceSelectorViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, !query.isEmpty else {
            isSearching = false
            filteredDevices = allDevices
            collectionView.reloadData()
            return
        }

        isSearching = true
        filteredDevices = allDevices.filter {
            $0.name.lowercased().contains(query.lowercased()) ||
            $0.manufacturer.lowercased().contains(query.lowercased())
        }
        collectionView.reloadData()
    }
}

// MARK: - Device Cell

private final class DeviceCell: UICollectionViewCell {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        return view
    }()

    private let iconView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#00D4FF").withAlphaComponent(0.15)
        view.layer.cornerRadius = 28
        return view
    }()

    private let deviceIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(hex: "#00D4FF")
        iv.image = UIImage(systemName: "laptopcomputer")
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()

    private let manufacturerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.textAlignment = .center
        return label
    }()

    private let componentCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = UIColor(hex: "#00D4FF")
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconView)
        iconView.addSubview(deviceIcon)
        containerView.addSubview(nameLabel)
        containerView.addSubview(manufacturerLabel)
        containerView.addSubview(componentCountLabel)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        deviceIcon.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        manufacturerLabel.translatesAutoresizingMaskIntoConstraints = false
        componentCountLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            iconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            iconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),

            deviceIcon.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            deviceIcon.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            deviceIcon.widthAnchor.constraint(equalToConstant: 28),
            deviceIcon.heightAnchor.constraint(equalToConstant: 28),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),

            manufacturerLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            manufacturerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            manufacturerLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),

            componentCountLabel.topAnchor.constraint(equalTo: manufacturerLabel.bottomAnchor, constant: 6),
            componentCountLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        ])
    }

    func configure(with device: Device) {
        nameLabel.text = device.displayName
        manufacturerLabel.text = device.manufacturer
        componentCountLabel.text = "\(device.componentCount) components"

        // Set icon based on category
        let icon: String
        switch device.category.lowercased() {
        case "laptop": icon = "laptopcomputer"
        case "phone": icon = "smartphone"
        case "tablet": icon = "tablet"
        case "desktop": icon = "desktopcomputer"
        default: icon = "laptopcomputer"
        }
        deviceIcon.image = UIImage(systemName: icon)
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.containerView.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            }
        }
    }
}

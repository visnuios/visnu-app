import UIKit

final class ProfileViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum MenuItem: String, CaseIterable {
        case myOrders = "My Orders"
        case myAddresses = "My Addresses"
        case favorites = "Favorites"
        case notifications = "Notifications"
        case coupons = "Coupons"
        case help = "Help & Support"
        case terms = "Terms & Conditions"
        case privacy = "Privacy Policy"
        case logout = "Logout"

        var symbolName: String {
            switch self {
            case .myOrders: return "list.bullet.rectangle"
            case .myAddresses: return "mappin.and.ellipse"
            case .favorites: return "heart"
            case .notifications: return "bell"
            case .coupons: return "ticket"
            case .help: return "questionmark.circle"
            case .terms: return "doc.text"
            case .privacy: return "lock.shield"
            case .logout: return "arrow.right.square"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        view.backgroundColor = .systemGroupedBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SubtitleCell.self, forCellReuseIdentifier: SubtitleCell.reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func openMenuItem(_ item: MenuItem) {
        switch item {
        case .myOrders:
            tabBarController?.selectedIndex = 2
        case .myAddresses:
            navigationController?.pushViewController(MyAddressesViewController(), animated: true)
        case .favorites:
            navigationController?.pushViewController(FavoritesViewController(), animated: true)
        case .notifications:
            NotificationsStore.shared.markAllRead()
            navigationController?.pushViewController(NotificationsViewController(), animated: true)
        case .coupons:
            navigationController?.pushViewController(CouponsViewController(), animated: true)
        case .help:
            navigationController?.pushViewController(StaticPageViewController(title: "Help & Support", content: "For support, email support@rvfood.example or call 1800-000-000."), animated: true)
        case .terms:
            navigationController?.pushViewController(StaticPageViewController(title: "Terms & Conditions", content: "These demo terms govern your use of the rvfood app."), animated: true)
        case .privacy:
            navigationController?.pushViewController(StaticPageViewController(title: "Privacy Policy", content: "We respect your privacy. Location data is used only to find nearby shops and calculate delivery."), animated: true)
        case .logout:
            confirmLogout()
        }
    }

    private func confirmLogout() {
        let alert = UIAlertController(title: "Logout?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            Task {
                await DemoAuthService().logout()
                SceneRouter.showAuth()
            }
        })
        present(alert, animated: true)
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : MenuItem.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ProfileCell")
            let profile = SessionStore.shared.profile
            cell.textLabel?.text = profile?.name ?? "Guest"
            cell.textLabel?.font = .boldSystemFont(ofSize: 17)
            cell.detailTextLabel?.text = profile?.email ?? ""
            cell.imageView?.image = UIImage(systemName: "person.crop.circle.fill")
            cell.imageView?.tintColor = .systemOrange
            cell.selectionStyle = .none
            return cell
        }
        let item = MenuItem.allCases[indexPath.row]
        var config = UIListContentConfiguration.cell()
        config.text = item.rawValue
        config.image = UIImage(systemName: item.symbolName)
        config.imageProperties.tintColor = item == .logout ? .systemRed : .systemOrange
        config.textProperties.color = item == .logout ? .systemRed : .label
        let cell = tableView.dequeueReusableCell(withIdentifier: SubtitleCell.reuseID, for: indexPath)
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1 else { return }
        openMenuItem(MenuItem.allCases[indexPath.row])
    }
}

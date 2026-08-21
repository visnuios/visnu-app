import UIKit

final class NotificationsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications"
        view.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
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
}

extension NotificationsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let items = NotificationsStore.shared.notifications
        if items.isEmpty {
            tableView.backgroundView = makeEmptyLabel("No notifications yet.")
        } else {
            tableView.backgroundView = nil
        }
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let notification = NotificationsStore.shared.notifications[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SubtitleCell.reuseID, for: indexPath)
        let icon = notification.kind == .order ? "🧾" : "🎉"
        cell.textLabel?.text = "\(icon) \(notification.title)"
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        cell.detailTextLabel?.text = notification.message
        cell.detailTextLabel?.numberOfLines = 2
        return cell
    }

    private func makeEmptyLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.frame = CGRect(x: 0, y: 0, width: 280, height: 40)
        label.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        return label
    }
}

final class MyAddressesViewController: UIViewController {

    private var addresses: [Address] = []
    private let repository: AddressRepositoryProtocol
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(repository: AddressRepositoryProtocol = DemoAddressRepository()) {
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Addresses"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(addTapped)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AddressCell.self, forCellReuseIdentifier: AddressCell.reuseID)
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
        load()
    }

    private func load() {
        Task {
            addresses = (try? await repository.addresses()) ?? []
            tableView.reloadData()
        }
    }

    @objc private func addTapped() {
        navigationController?.pushViewController(AddEditAddressViewController(address: nil) { [weak self] in
            self?.load()
        }, animated: true)
    }
}

extension MyAddressesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if addresses.isEmpty {
            tableView.backgroundView = {
                let label = UILabel()
                label.text = "No saved addresses.\nTap + to add one."
                label.textAlignment = .center
                label.numberOfLines = 0
                label.textColor = .secondaryLabel
                label.frame = CGRect(x: 0, y: 0, width: 260, height: 60)
                return label
            }()
            return 0
        }
        tableView.backgroundView = nil
        return addresses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.reuseID, for: indexPath) as! AddressCell
        cell.configure(address: addresses[indexPath.row], isSelected: addresses[indexPath.row].isDefault)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        Task {
            try? await repository.setDefault(addressId: addresses[indexPath.row].id)
            load()
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let address = addresses[indexPath.row]
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            self?.navigationController?.pushViewController(
                AddEditAddressViewController(address: address) { [weak self] in self?.load() },
                animated: true
            )
            completion(true)
        }
        edit.backgroundColor = .systemBlue
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            Task {
                try? await self?.repository.delete(addressId: address.id)
                self?.load()
                completion(true)
            }
        }
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
}

final class FavoritesViewController: UIViewController {

    private var favoriteShops: [Shop] = []
    private var favoriteProducts: [(product: Product, shopName: String)] = []
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favorites"
        view.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProductRowCell.self, forCellReuseIdentifier: ProductRowCell.reuseID)
        tableView.register(ShopCardCell.self, forCellReuseIdentifier: ShopCardCell.reuseID)
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
        let favorites = FavoritesStore.shared
        favoriteShops = DemoCatalog.shops.filter { favorites.isFavoriteShop($0.id) }
        favoriteProducts = DemoCatalog.products
            .filter { favorites.isFavoriteProduct($0.id) }
            .map { ($0, $0.shopName ?? "") }
        tableView.reloadData()
    }
}

extension FavoritesViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? favoriteShops.count : favoriteProducts.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return favoriteShops.isEmpty ? nil : "Favorite Shops"
        default: return favoriteProducts.isEmpty ? nil : "Favorite Products"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: ShopCardCell.reuseID, for: indexPath) as! ShopCardCell
            cell.configure(shop: favoriteShops[indexPath.row], customerPoint: SelectedLocationStore.shared.current.point)
            return cell
        }
        let entry = favoriteProducts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductRowCell.reuseID, for: indexPath) as! ProductRowCell
        cell.configure(product: entry.product, quantityInCart: CartManager.shared.quantity(ofProductId: entry.product.id))
        cell.onAddTapped = { [weak self] in
            guard let self else { return }
            CartFlowHelper.add(product: entry.product, from: self)
            cell.renderQuantity(CartManager.shared.quantity(ofProductId: entry.product.id))
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            navigationController?.pushViewController(ShopDetailsViewController(shop: favoriteShops[indexPath.row]), animated: true)
        } else {
            navigationController?.pushViewController(ProductDetailsViewController(product: favoriteProducts[indexPath.row].product), animated: true)
        }
    }
}

final class CouponsViewController: UIViewController {

    private let coupons = DemoCatalog.availableCoupons
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Coupons"
        view.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension CouponsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        coupons.isEmpty ? 0 : coupons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let coupon = coupons[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "CouponCell")
        cell.textLabel?.text = "🎟️ \(coupon.code)"
        cell.textLabel?.font = .boldSystemFont(ofSize: 16)
        cell.textLabel?.textColor = .systemOrange
        cell.detailTextLabel?.text = coupon.title
        cell.detailTextLabel?.numberOfLines = 0
        return cell
    }
}

final class StaticPageViewController: UIViewController {

    private let pageTitle: String
    private let content: String

    init(title: String, content: String) {
        self.pageTitle = title
        self.content = content
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = pageTitle
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = content
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
}

import UIKit

final class HomeViewController: UIViewController {

    private let shopRepository: ShopRepositoryProtocol
    private let productRepository: ProductRepositoryProtocol

    private var nearbyShops: [Shop] = []
    private var popularShops: [Shop] = []
    private var recommendedProducts: [Product] = []
    private var selectedCategoryId: String?

    private var state: ViewState = .idle {
        didSet { overlay.render(state: state) }
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let overlay = StateOverlayView()
    private let locationButton = UIButton(type: .system)
    private let bellButton = UIButton(type: .system)
    private let searchButton = UIButton(type: .system)
    private var headerStack: UIStackView!

    init(
        shopRepository: ShopRepositoryProtocol = DemoShopRepository(),
        productRepository: ProductRepositoryProtocol = DemoProductRepository()
    ) {
        self.shopRepository = shopRepository
        self.productRepository = productRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "rvfood"
        navigationItem.largeTitleDisplayMode = .never

        setupHeader()
        setupTable()

        overlay.onRetry = { [weak self] in
            self?.loadContent()
        }

        NotificationCenter.default.addObserver(
            forName: .selectedLocationDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadContent()
        }
        NotificationCenter.default.addObserver(
            forName: .unreadNotificationsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshBellBadge()
        }

        loadContent()
    }

    private func setupHeader() {
        locationButton.setTitleColor(.label, for: .normal)
        locationButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        locationButton.tintColor = .systemOrange
        locationButton.addTarget(self, action: #selector(openLocationPicker), for: .touchUpInside)

        bellButton.setImage(UIImage(systemName: "bell"), for: .normal)
        bellButton.tintColor = .label
        bellButton.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)

        searchButton.setTitle("  Search food, grocery, products", for: .normal)
        searchButton.contentHorizontalAlignment = .left
        searchButton.setTitleColor(.secondaryLabel, for: .normal)
        searchButton.backgroundColor = .secondarySystemGroupedBackground
        searchButton.layer.cornerRadius = 10
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.tintColor = .secondaryLabel
        searchButton.addTarget(self, action: #selector(openSearch), for: .touchUpInside)

        let headerStack = UIStackView(arrangedSubviews: [
            makeRow([locationButton, UIView(), bellButton]),
            searchButton
        ])
        headerStack.axis = .vertical
        headerStack.spacing = 12
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerStack)
        self.headerStack = headerStack

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchButton.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    private func makeRow(_ subviews: [UIView]) -> UIStackView {
        let row = UIStackView(arrangedSubviews: subviews)
        row.axis = .horizontal
        return row
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.register(ShopCardCell.self, forCellReuseIdentifier: ShopCardCell.reuseID)
        tableView.register(CategoryRowCell.self, forCellReuseIdentifier: CategoryRowCell.reuseID)
        tableView.register(ProductCarouselCell.self, forCellReuseIdentifier: ProductCarouselCell.reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func refreshBellBadge() {
        let count = NotificationsStore.shared.unreadCount
        bellButton.subviews.compactMap { $0 as? UILabel }.forEach { $0.removeFromSuperview() }
        guard count > 0 else { return }
        let badge = UILabel()
        badge.text = count > 9 ? "9+" : "\(count)"
        badge.font = .systemFont(ofSize: 10, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = .systemRed
        badge.textAlignment = .center
        badge.layer.cornerRadius = 8
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        bellButton.addSubview(badge)
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: bellButton.topAnchor, constant: -4),
            badge.trailingAnchor.constraint(equalTo: bellButton.trailingAnchor, constant: 6),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),
            badge.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshLocationTitle()
        refreshBellBadge()
    }

    private func refreshLocationTitle() {
        let location = SelectedLocationStore.shared.current
        locationButton.setTitle("  \(location.title) ▼", for: .normal)
    }

    private func loadContent() {
        state = .loading
        Task {
            do {
                async let shopsTask = shopRepository.nearbyShops(categoryId: selectedCategoryId)
                async let recommendedTask = productRepository.recommendedProducts(shopId: nil)
                let shopsResult = try await shopsTask
                let recommendedResult = try await recommendedTask

                nearbyShops = shopsResult
                popularShops = Array(shopsResult.sorted { $0.rating > $1.rating }.prefix(5))
                recommendedProducts = recommendedResult
                refreshLocationTitle()

                if shopsResult.isEmpty {
                    state = .empty("No nearby shops found. Try changing your location.")
                } else {
                    state = .idle
                }
                tableView.reloadData()
            } catch {
                state = .error("Unable to load shops. Please check your connection and try again.")
            }
        }
    }

    @objc private func openLocationPicker() {
        navigationController?.pushViewController(LocationPickerViewController(), animated: true)
    }

    @objc private func openSearch() {
        navigationController?.pushViewController(SearchViewController(), animated: true)
    }

    @objc private func openNotifications() {
        NotificationsStore.shared.markAllRead()
        navigationController?.pushViewController(NotificationsViewController(), animated: true)
    }

    private func openShop(_ shop: Shop) {
        navigationController?.pushViewController(ShopDetailsViewController(shop: shop), animated: true)
    }

    private func addToCart(_ product: Product) {
        CartFlowHelper.add(product: product, from: self)
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        state == .idle ? 4 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return nearbyShops.count
        case 2: return popularShops.count
        case 3: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard state == .idle else { return nil }
        switch section {
        case 0: return "Categories"
        case 1: return "Nearby Shops"
        case 2: return "Popular Shops"
        case 3: return "Recommended Products"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: CategoryRowCell.reuseID, for: indexPath) as! CategoryRowCell
            cell.configure(selectedCategoryId: selectedCategoryId) { [weak self] categoryId in
                self?.selectedCategoryId = (self?.selectedCategoryId == categoryId) ? nil : categoryId
                self?.loadContent()
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: ShopCardCell.reuseID, for: indexPath) as! ShopCardCell
            cell.configure(shop: nearbyShops[indexPath.row], customerPoint: SelectedLocationStore.shared.current.point)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: ShopCardCell.reuseID, for: indexPath) as! ShopCardCell
            cell.configure(shop: popularShops[indexPath.row], customerPoint: SelectedLocationStore.shared.current.point)
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: ProductCarouselCell.reuseID, for: indexPath) as! ProductCarouselCell
            cell.configure(products: recommendedProducts) { [weak self] product in
                self?.addToCart(product)
            }
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            openShop(nearbyShops[indexPath.row])
        } else if indexPath.section == 2 {
            openShop(popularShops[indexPath.row])
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 || indexPath.section == 3 ? 120 : UITableView.automaticDimension
    }
}

final class CartFlowHelper {

    static func add(product: Product, from viewController: UIViewController) {
        let cart = CartManager.shared
        do {
            switch try cart.addProduct(product) {
            case .conflict(let existing):
                presentReplaceCartAlert(product: product, existingShopName: existing.shopName ?? "another shop", from: viewController)
            default:
                break
            }
        } catch {
            viewController.presentErrorAlert(error)
        }
    }

    static func presentReplaceCartAlert(product: Product, existingShopName: String, from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Replace cart?",
            message: "You already have products from another shop (\(existingShopName)) in your cart. Do you want to replace your cart?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Replace Cart", style: .destructive) { _ in
            do {
                try CartManager.shared.replaceCart(with: product)
            } catch {
                viewController.presentErrorAlert(error)
            }
        })
        viewController.present(alert, animated: true)
    }
}

import UIKit

final class ShopDetailsViewController: UIViewController {

    private let shop: Shop
    private let productRepository: ProductRepositoryProtocol

    private var products: [Product] = []
    private var state: ViewState = .idle {
        didSet { overlay.render(state: state) }
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let overlay = StateOverlayView()

    init(shop: Shop, productRepository: ProductRepositoryProtocol = DemoProductRepository()) {
        self.shop = shop
        self.productRepository = productRepository
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = shop.name
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: nil,
            style: .plain,
            target: self,
            action: #selector(favoriteTapped)
        )
        refreshFavoriteButton()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProductRowCell.self, forCellReuseIdentifier: ProductRowCell.reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        overlay.onRetry = { [weak self] in
            self?.loadProducts()
        }
        loadProducts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !products.isEmpty {
            tableView.reloadData()
        }
    }

    private func refreshFavoriteButton() {
        let isFavorite = FavoritesStore.shared.isFavoriteShop(shop.id)
        navigationItem.rightBarButtonItem?.image = UIImage(systemName: isFavorite ? "heart.fill" : "heart")
        navigationItem.rightBarButtonItem?.tintColor = isFavorite ? .systemRed : .label
    }

    @objc private func favoriteTapped() {
        FavoritesStore.shared.toggleShop(shop.id)
        refreshFavoriteButton()
    }

    private var groupedSections: [(categoryName: String, items: [Product])] {
        let grouped = Dictionary(grouping: products) { product -> String in
            let raw = product.categoryId ?? "other"
            return raw.prefix(1).uppercased() + raw.dropFirst()
        }
        return grouped
            .map { (categoryName: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.categoryName < $1.categoryName }
    }

    private func loadProducts() {
        state = .loading
        Task {
            do {
                products = try await productRepository.products(shopId: shop.id)
                if products.isEmpty {
                    state = .empty("This shop has no products yet.")
                } else {
                    state = .idle
                }
                tableView.reloadData()
            } catch {
                state = .error("Unable to load products. Please try again.")
            }
        }
    }
}

extension ShopDetailsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        1 + groupedSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : groupedSections[section - 1].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? nil : groupedSections[section - 1].categoryName
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ShopInfoCell")
            cell.selectionStyle = .none
            cell.textLabel?.text = shop.isOpenNow ? "🟢 OPEN · \(shop.deliveryTimeMinutes) min delivery" : "🔴 CLOSED"
            cell.textLabel?.font = .boldSystemFont(ofSize: 14)
            let distanceKm = shop.distanceKm(from: SelectedLocationStore.shared.current.point)
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = [
                "★ \(String(format: "%.1f", shop.rating)) (\(shop.ratingCount))",
                "\(GeoMath.formattedDistance(distanceKm)) away",
                "Min order ₹\(Int(truncating: NSDecimalNumber(decimal: shop.minOrderAmount)))",
                "Open \(shop.opensAtHour):00 – \(shop.closesAtHour):00",
                shop.descriptionText ?? "No description available"
            ].joined(separator: "\n")
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: ProductRowCell.reuseID, for: indexPath) as! ProductRowCell
        let product = groupedSections[indexPath.section - 1].items[indexPath.row]
        cell.configure(product: product, quantityInCart: CartManager.shared.quantity(ofProductId: product.id))
        cell.onAddTapped = { [weak self] in
            guard let self else { return }
            CartFlowHelper.add(product: product, from: self)
            cell.renderQuantity(CartManager.shared.quantity(ofProductId: product.id))
        }
        cell.onQuantityChanged = { [weak self] newValue in
            self?.updateQuantity(newValue, for: product)
            cell.renderQuantity(CartManager.shared.quantity(ofProductId: product.id))
        }
        return cell
    }

    private func updateQuantity(_ newValue: Int, for product: Product) {
        let cart = CartManager.shared
        let current = cart.quantity(ofProductId: product.id)
        if newValue > current {
            CartFlowHelper.add(product: product, from: self)
        } else if newValue < current {
            cart.decreaseQuantity(productId: product.id)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section > 0 else { return }
        let product = groupedSections[indexPath.section - 1].items[indexPath.row]
        navigationController?.pushViewController(ProductDetailsViewController(product: product), animated: true)
    }
}

import UIKit

final class SearchViewController: UIViewController {

    private var results: [(product: Product, shopName: String, distanceKm: Double)] = []
    private var shopResults: [Shop] = []
    private var state: ViewState = .idle {
        didSet { overlay.render(state: state) }
    }

    private let productRepository: ProductRepositoryProtocol
    private let shopRepository: ShopRepositoryProtocol

    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let overlay = StateOverlayView()
    private var searchTask: Task<Void, Never>?

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
        title = "Search"
        view.backgroundColor = .systemGroupedBackground

        searchBar.placeholder = "Search products or shops"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProductRowCell.self, forCellReuseIdentifier: ProductRowCell.reuseID)
        tableView.register(ShopCardCell.self, forCellReuseIdentifier: ShopCardCell.reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        overlay.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        overlay.onRetry = { [weak self] in
            if let query = self?.searchBar.text {
                self?.search(query: query)
            }
        }
    }

    private func search(query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            shopResults = []
            state = .idle
            tableView.reloadData()
            return
        }
        state = .loading
        searchTask = Task {
            do {
                async let productsTask = productRepository.searchProducts(query: query)
                async let shopsTask = shopRepository.searchShops(query: query)
                let (productsResult, shopsResult) = try await (productsTask, shopsTask)
                if Task.isCancelled { return }
                results = productsResult
                shopResults = shopsResult
                if results.isEmpty && shopResults.isEmpty {
                    state = .empty("No results for \"\(query)\"")
                } else {
                    state = .idle
                }
                tableView.reloadData()
            } catch {
                if Task.isCancelled { return }
                state = .error("Search failed. Please try again.")
            }
        }
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard state == .idle else { return 0 }
        return section == 0 ? shopResults.count : results.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return shopResults.isEmpty ? nil : "Shops"
        default: return results.isEmpty ? nil : "Products"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: ShopCardCell.reuseID, for: indexPath) as! ShopCardCell
            cell.configure(shop: shopResults[indexPath.row], customerPoint: SelectedLocationStore.shared.current.point)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductRowCell.reuseID, for: indexPath) as! ProductRowCell
        let result = results[indexPath.row]
        cell.configure(product: result.product, quantityInCart: CartManager.shared.quantity(ofProductId: result.product.id))
        cell.onAddTapped = { [weak self] in
            guard let self else { return }
            CartFlowHelper.add(product: result.product, from: self)
            cell.renderQuantity(CartManager.shared.quantity(ofProductId: result.product.id))
        }
        cell.onQuantityChanged = { [weak self] newValue in
            guard let self else { return }
            let current = CartManager.shared.quantity(ofProductId: result.product.id)
            if newValue < current {
                CartManager.shared.decreaseQuantity(productId: result.product.id)
            } else {
                CartFlowHelper.add(product: result.product, from: self)
            }
            cell.renderQuantity(CartManager.shared.quantity(ofProductId: result.product.id))
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            navigationController?.pushViewController(ShopDetailsViewController(shop: shopResults[indexPath.row]), animated: true)
        } else {
            let result = results[indexPath.row]
            navigationController?.pushViewController(ProductDetailsViewController(product: result.product), animated: true)
        }
    }
}

extension SearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(runSearch), object: nil)
        perform(#selector(runSearch), with: nil, afterDelay: 0.35)
    }

    @objc private func runSearch() {
        search(query: searchBar.text ?? "")
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        search(query: searchBar.text ?? "")
    }
}

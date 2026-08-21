import UIKit

final class OrdersViewController: UIViewController {

    enum Tab: Int, CaseIterable {
        case active, completed, cancelled
    }

    private var allOrders: [Order] = []
    private var selectedTab: Tab = .active
    private var state: ViewState = .idle {
        didSet { overlay.render(state: state) }
    }

    private let repository: OrderRepositoryProtocol
    private let segmented = UISegmentedControl(items: ["Active", "Completed", "Cancelled"])
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let overlay = StateOverlayView()
    private var observer: NSObjectProtocol?

    init(repository: OrderRepositoryProtocol = LocalOrderRepository()) {
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Orders"
        view.backgroundColor = .systemGroupedBackground

        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(tabChanged), for: .valueChanged)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(OrderCardCell.self, forCellReuseIdentifier: OrderCardCell.reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        overlay.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(segmented)
        view.addSubview(tableView)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        overlay.onRetry = { [weak self] in
            self?.loadOrders()
        }
        observer = NotificationCenter.default.addObserver(
            forName: .ordersDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadOrders()
        }
        loadOrders()
    }

    @objc private func tabChanged() {
        selectedTab = Tab(rawValue: segmented.selectedSegmentIndex) ?? .active
        renderOrders()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadOrders()
    }

    private func loadOrders() {
        Task {
            do {
                allOrders = try await repository.orders()
                renderOrders()
            } catch {
                state = .error("Unable to load orders. Please try again.")
                tableView.reloadData()
            }
        }
    }

    private func filteredOrders() -> [Order] {
        switch selectedTab {
        case .active:
            return allOrders.filter { $0.status.isActive }
        case .completed:
            return allOrders.filter { $0.status == .delivered }
        case .cancelled:
            return allOrders.filter { $0.status == .cancelled || $0.status == .rejected }
        }
    }

    private func renderOrders() {
        let orders = filteredOrders()
        if orders.isEmpty {
            state = .empty("No \(selectedTab == .active ? "active" : selectedTab == .completed ? "completed" : "cancelled") orders yet.")
        } else {
            state = .idle
        }
        tableView.reloadData()
    }
}

extension OrdersViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state == .idle ? filteredOrders().count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OrderCardCell.reuseID, for: indexPath) as! OrderCardCell
        cell.configure(order: filteredOrders()[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let order = filteredOrders()[indexPath.row]
        navigationController?.pushViewController(OrderDetailsViewController(order: order), animated: true)
    }
}

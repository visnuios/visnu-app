import UIKit

final class AddressSelectionViewController: UIViewController {

    private var draft: CheckoutDraft
    private var addresses: [Address] = []
    private var selectedAddressId: String?
    private var state: ViewState = .idle {
        didSet { overlay.render(state: state) }
    }

    private let repository: AddressRepositoryProtocol
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let overlay = StateOverlayView()
    private let continueButton = PrimaryButton(title: "Continue")

    init(draft: CheckoutDraft, repository: AddressRepositoryProtocol = DemoAddressRepository()) {
        self.draft = draft
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Address"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(addAddressTapped)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AddressCell.self, forCellReuseIdentifier: AddressCell.reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        overlay.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(overlay)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -12),
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: continueButton.topAnchor),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])

        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        continueButton.isEnabled = false
        overlay.onRetry = { [weak self] in
            self?.loadAddresses()
        }
        loadAddresses()
    }

    private func loadAddresses() {
        state = .loading
        Task {
            do {
                addresses = try await repository.addresses()
                if addresses.isEmpty {
                    state = .empty("No saved addresses. Tap + to add one.")
                } else {
                    state = .idle
                }
                if selectedAddressId == nil {
                    selectedAddressId = CheckoutSession.shared.selectedAddress?.id
                        ?? addresses.first(where: { $0.isDefault })?.id
                        ?? addresses.first?.id
                }
                refreshSelection()
            } catch {
                state = .error("Unable to load addresses. Please try again.")
            }
        }
    }

    private func refreshSelection() {
        continueButton.isEnabled = selectedAddressId != nil && !addresses.isEmpty
        tableView.reloadData()
    }

    @objc private func addAddressTapped() {
        let editor = AddEditAddressViewController(address: nil) { [weak self] in
            self?.selectedAddressId = nil
            self?.loadAddresses()
        }
        navigationController?.pushViewController(editor, animated: true)
    }

    private func editAddress(_ address: Address) {
        let editor = AddEditAddressViewController(address: address) { [weak self] in
            self?.loadAddresses()
        }
        navigationController?.pushViewController(editor, animated: true)
    }

    @objc private func continueTapped() {
        guard let selectedId = selectedAddressId,
              let address = addresses.first(where: { $0.id == selectedId }) else { return }

        CheckoutSession.shared.select(address: address)

        draft.addressId = address.id
        draft.refresh(from: CartManager.shared.totals)

        navigationController?.pushViewController(OrderSummaryViewController(draft: draft), animated: true)
    }
}

extension AddressSelectionViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state == .idle ? addresses.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.reuseID, for: indexPath) as! AddressCell
        let address = addresses[indexPath.row]
        cell.configure(address: address, isSelected: address.id == selectedAddressId)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedAddressId = addresses[indexPath.row].id
        refreshSelection()
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let address = addresses[indexPath.row]
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            self?.editAddress(address)
            completion(true)
        }
        edit.backgroundColor = .systemBlue
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            Task {
                try? await self?.repository.delete(addressId: address.id)
                if self?.selectedAddressId == address.id {
                    self?.selectedAddressId = nil
                }
                self?.loadAddresses()
                completion(true)
            }
        }
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
}

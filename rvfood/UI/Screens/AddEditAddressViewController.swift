import UIKit

final class AddEditAddressViewController: UIViewController {

    private let existingAddress: Address?
    private let onSaved: () -> Void
    private let repository: AddressRepositoryProtocol

    private let scrollView = UIScrollView()
    private var nameField: UITextField!
    private var phoneField: UITextField!
    private var houseField: UITextField!
    private var streetField: UITextField!
    private var areaField: UITextField!
    private var cityField: UITextField!
    private var stateField: UITextField!
    private var pincodeField: UITextField!
    private let typeSegmented = UISegmentedControl(items: AddressType.allCases.map(\.rawValue))
    private let defaultSwitch = UISwitch()
    private let saveButton = PrimaryButton(title: "Save Address")

    init(
        address: Address?,
        repository: AddressRepositoryProtocol = LocalAddressRepository(),
        onSaved: @escaping () -> Void
    ) {
        self.existingAddress = address
        self.repository = repository
        self.onSaved = onSaved
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = existingAddress == nil ? "Add Address" : "Edit Address"
        view.backgroundColor = .systemBackground
        setupForm()
        populateIfNeeded()
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    private func makeField(_ placeholder: String, keyboard: UIKeyboardType = .default) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.keyboardType = keyboard
        field.autocapitalizationType = .words
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return field
    }

    private func setupForm() {
        nameField = makeField("Full name")
        phoneField = makeField("Phone number", keyboard: .phonePad)
        houseField = makeField("House / Building / Flat")
        streetField = makeField("Street")
        areaField = makeField("Area / Locality")
        cityField = makeField("City")
        stateField = makeField("State")
        pincodeField = makeField("Postal code", keyboard: .numberPad)

        typeSegmented.selectedSegmentIndex = 0

        let defaultRow = UIStackView(arrangedSubviews: [
            makeLabel("Set as default address"), UIView(), defaultSwitch
        ])
        defaultRow.axis = .horizontal

        let locationNote = UILabel()
        locationNote.text = "📍 Location will be set from your selected app location (\(SelectedLocationStore.shared.current.title))"
        locationNote.font = .systemFont(ofSize: 12)
        locationNote.textColor = .secondaryLabel
        locationNote.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [
            nameField, phoneField, houseField, streetField, areaField,
            cityField, stateField, pincodeField, typeSegmented, defaultRow, locationNote, saveButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }

    private func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15)
        return label
    }

    private func populateIfNeeded() {
        guard let address = existingAddress else { return }
        nameField.text = address.name
        phoneField.text = address.phone
        houseField.text = address.houseDetail
        streetField.text = address.street
        areaField.text = address.area
        cityField.text = address.city
        stateField.text = address.state
        pincodeField.text = address.postalCode
        typeSegmented.selectedSegmentIndex = AddressType.allCases.firstIndex(of: address.type) ?? 0
        defaultSwitch.isOn = address.isDefault
    }

    @objc private func saveTapped() {
        func value(_ field: UITextField) -> String {
            field.text?.trimmingCharacters(in: .whitespaces) ?? ""
        }
        guard !value(nameField).isEmpty else {
            presentErrorAlert(APIError.businessRule("Please enter a name."), title: "Missing details")
            return
        }
        guard value(phoneField).count >= 10 else {
            presentErrorAlert(APIError.businessRule("Please enter a valid phone number."), title: "Missing details")
            return
        }
        guard !value(houseField).isEmpty || !value(streetField).isEmpty else {
            presentErrorAlert(APIError.businessRule("Please enter your house or street details."), title: "Missing details")
            return
        }

        let address = Address(
            id: existingAddress?.id ?? "",
            name: value(nameField),
            phone: value(phoneField),
            houseDetail: value(houseField),
            street: value(streetField),
            area: value(areaField),
            city: value(cityField).isEmpty ? "Coimbatore" : value(cityField),
            state: value(stateField).isEmpty ? "Tamil Nadu" : value(stateField),
            postalCode: value(pincodeField),
            point: SelectedLocationStore.shared.current.point,
            type: AddressType.allCases[typeSegmented.selectedSegmentIndex],
            isDefault: defaultSwitch.isOn
        )

        saveButton.isEnabled = false
        Task {
            do {
                _ = try await repository.save(address)
                if CheckoutSession.shared.selectedAddress?.id == address.id {
                    CheckoutSession.shared.select(address: address)
                }
                onSaved()
                navigationController?.popViewController(animated: true)
            } catch {
                saveButton.isEnabled = true
                presentErrorAlert(error)
                print(error)
            }
        }
    }
}

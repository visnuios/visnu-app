import UIKit

final class ProductDetailsViewController: UIViewController {

    private let baseProduct: Product
    private var variations: [ProductVariationOption]
    private var selectedOptionIds: Set<String> = []
    private var quantity: Int = 1

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let heroImage = PlaceholderImageView(emoji: "🛒")
    private let nameLabel = UILabel()
    private let unitLabel = UILabel()
    private let priceLabel = UILabel()
    private let originalPriceLabel = UILabel()
    private let discountBadge = UILabel()
    private let stockLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let variationStack = UIStackView()
    private let quantityControl = QuantityControl()
    private let addToCartButton = PrimaryButton(title: "Add to Cart")

    init(product: Product, variations: [ProductVariationOption] = []) {
        self.baseProduct = product
        self.variations = variations
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    convenience init(product: Product) {
        self.init(product: product, variations: [])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Product Details"
        view.backgroundColor = .systemBackground
        setupLayout()
        renderContent()
        loadVariationsIfNeeded()
    }

    private func loadVariationsIfNeeded() {
        guard variations.isEmpty else { return }
        Task { [weak self] in
            guard let self,
                  let details = try? await DemoProductRepository().productDetails(productId: self.baseProduct.id),
                  !details.variations.isEmpty else { return }
            self.variations = details.variations
            self.renderContent()
        }
    }

    private func setupLayout() {
        heroImage.heightAnchor.constraint(equalToConstant: 220).isActive = true
        heroImage.layer.cornerRadius = 16
        heroImage.clipsToBounds = true

        nameLabel.font = .boldSystemFont(ofSize: 22)
        unitLabel.font = .systemFont(ofSize: 14)
        unitLabel.textColor = .secondaryLabel
        priceLabel.font = .boldSystemFont(ofSize: 24)
        originalPriceLabel.font = .systemFont(ofSize: 16)
        originalPriceLabel.textColor = .secondaryLabel
        discountBadge.font = .boldSystemFont(ofSize: 13)
        discountBadge.textColor = .systemGreen
        stockLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.font = .systemFont(ofSize: 15)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0

        variationStack.axis = .vertical
        variationStack.spacing = 12

        quantityControl.onChange = { [weak self] newValue in
            guard let self else { return }
            self.quantity = max(newValue, 1)
            self.quantityControl.render(value: self.quantity)
            self.refreshAddButtonTitle()
        }

        addToCartButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        let priceRow = UIStackView(arrangedSubviews: [priceLabel, originalPriceLabel, discountBadge])
        priceRow.axis = .horizontal
        priceRow.spacing = 8
        priceRow.alignment = .firstBaseline

        contentStack.axis = .vertical
        contentStack.spacing = 14
        [heroImage, nameLabel, unitLabel, priceRow, stockLabel, descriptionLabel, variationStack, makeQuantityRow()].forEach {
            contentStack.addArrangedSubview($0)
        }
        contentStack.setCustomSpacing(20, after: variationStack)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        addToCartButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(addToCartButton)
        view.addSubview(buttonContainer)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            buttonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            buttonContainer.heightAnchor.constraint(equalToConstant: 76),

            addToCartButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: 16),
            addToCartButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -16),
            addToCartButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor)
        ])
    }

    private func makeQuantityRow() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "Quantity"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        let row = UIStackView(arrangedSubviews: [titleLabel, UIView(), quantityControl])
        row.axis = .horizontal
        return row
    }

    private var effectiveProduct: Product {
        guard !selectedOptionIds.isEmpty else { return baseProduct }
        let selectedOptions = variations.filter { selectedOptionIds.contains($0.id) }
        let delta = selectedOptions.reduce(Decimal(0)) { $0 + $1.priceDelta }
        let suffix = selectedOptions.map(\.title).joined(separator: ", ")
        let adjustedPrice = max(baseProduct.effectiveUnitPrice + delta, 0)
        return Product(
            id: "\(baseProduct.id)__\(selectedOptionIds.sorted().joined(separator: "_"))",
            name: suffix.isEmpty ? baseProduct.name : "\(baseProduct.name) (\(suffix))",
            shopId: baseProduct.shopId,
            shopName: baseProduct.shopName,
            categoryId: baseProduct.categoryId,
            unit: baseProduct.unit,
            productDescription: baseProduct.productDescription,
            price: adjustedPrice,
            discountPrice: nil,
            stock: baseProduct.stock,
            imageURL: baseProduct.imageURL
        )
    }

    private func renderContent() {
        nameLabel.text = baseProduct.name
        unitLabel.text = baseProduct.unit ?? ""
        priceLabel.text = CurrencyFormatter.string(from: effectiveUnitPrice())
        if baseProduct.hasDiscount {
            let attributed = NSMutableAttributedString(
                string: CurrencyFormatter.string(from: baseProduct.price),
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
            originalPriceLabel.attributedText = attributed
            discountBadge.text = "\(baseProduct.discountPercent ?? 0)% OFF"
        } else {
            originalPriceLabel.attributedText = nil
            discountBadge.text = nil
        }
        if baseProduct.isOutOfStock {
            stockLabel.text = "Out of stock"
            stockLabel.textColor = .systemRed
            addToCartButton.isEnabled = false
        } else if baseProduct.stock <= 5 {
            stockLabel.text = "Only \(baseProduct.stock) left in stock"
            stockLabel.textColor = .systemOrange
        } else {
            stockLabel.text = "In stock · \(baseProduct.stock) available"
            stockLabel.textColor = .systemGreen
        }
        descriptionLabel.text = baseProduct.productDescription ?? "No description available"
        buildVariationControls()
        refreshAddButtonTitle()
    }

    private func effectiveUnitPrice() -> Decimal {
        let selectedOptions = variations.filter { selectedOptionIds.contains($0.id) }
        let delta = selectedOptions.reduce(Decimal(0)) { $0 + $1.priceDelta }
        return max(baseProduct.effectiveUnitPrice + delta, 0)
    }

    private func buildVariationControls() {
        variationStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !variations.isEmpty else { return }

        let groups = Dictionary(grouping: variations, by: \.groupName)
        for (groupName, options) in groups.sorted(by: { $0.key < $1.key }) {
            let titleLabel = UILabel()
            titleLabel.text = groupName
            titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

            let chipsRow = UIStackView(arrangedSubviews: [])
            chipsRow.axis = .horizontal
            chipsRow.spacing = 8

            let isSingleSelect = groupName.lowercased().contains("size") || groups.count == 1 && options.allSatisfy { $0.groupName == groupName }

            for option in options {
                let chip = UIButton(type: .system)
                var title = option.title
                if option.priceDelta != 0 {
                    let sign = option.priceDelta > 0 ? "+" : "−"
                    let amount = Int(truncating: NSDecimalNumber(decimal: abs(option.priceDelta)))
                    title += " (\(sign)₹\(amount))"
                }
                chip.setTitle(title, for: .normal)
                chip.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
                chip.layer.cornerRadius = 14
                chip.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
                chip.addAction(UIAction { [weak self] _ in
                    guard let self else { return }
                    if isSingleSelect {
                        let groupIds = Set(options.map(\.id))
                        self.selectedOptionIds.subtract(groupIds)
                    }
                    if self.selectedOptionIds.contains(option.id) {
                        self.selectedOptionIds.remove(option.id)
                    } else {
                        self.selectedOptionIds.insert(option.id)
                    }
                    self.buildVariationControls()
                    self.renderContent()
                }, for: .touchUpInside)
                styleChip(chip, selected: selectedOptionIds.contains(option.id))
                chipsRow.addArrangedSubview(chip)
            }

            let section = UIStackView(arrangedSubviews: [titleLabel, chipsRow])
            section.axis = .vertical
            section.spacing = 8
            variationStack.addArrangedSubview(section)
        }
    }

    private func styleChip(_ chip: UIButton, selected: Bool) {
        chip.backgroundColor = selected ? .systemOrange : .secondarySystemFill
        chip.setTitleColor(selected ? .white : .label, for: .normal)
    }

    private func refreshAddButtonTitle() {
        let total = effectiveUnitPrice() * Decimal(quantity)
        addToCartButton.setTitle("Add to Cart · \(CurrencyFormatter.string(from: total))", for: .normal)
    }

    @objc private func addTapped() {
        CartFlowHelper.add(product: effectiveProduct, from: self)
        navigationController?.popViewController(animated: true)
    }
}

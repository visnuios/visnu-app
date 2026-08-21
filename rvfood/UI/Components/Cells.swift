import UIKit

final class ShopCardCell: UITableViewCell {

    static let reuseID = "ShopCardCell"

    private let logoView = PlaceholderImageView(emoji: "🏪")
    private let nameLabel = UILabel()
    private let categoryLabel = UILabel()
    private let ratingLabel = UILabel()
    private let distanceLabel = UILabel()
    private let metaLabel = UILabel()
    private let statusLabel = UILabel()
    private let offerLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        backgroundColor = .clear
        contentView.backgroundColor = .secondarySystemGroupedBackground

        nameLabel.font = .boldSystemFont(ofSize: 16)
        categoryLabel.font = .systemFont(ofSize: 13)
        categoryLabel.textColor = .secondaryLabel
        ratingLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        ratingLabel.textColor = .systemGreen
        distanceLabel.font = .systemFont(ofSize: 13)
        distanceLabel.textColor = .secondaryLabel
        metaLabel.font = .systemFont(ofSize: 13)
        metaLabel.textColor = .secondaryLabel
        statusLabel.font = .boldSystemFont(ofSize: 12)
        offerLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        offerLabel.textColor = .systemOrange

        let nameRow = UIStackView(arrangedSubviews: [nameLabel, UIView(), statusLabel])
        nameRow.axis = .horizontal
        nameRow.spacing = 8

        let infoRow = UIStackView(arrangedSubviews: [ratingLabel, distanceLabel, UIView()])
        infoRow.axis = .horizontal
        infoRow.spacing = 10

        let textStack = UIStackView(arrangedSubviews: [nameRow, categoryLabel, infoRow, metaLabel, offerLabel])
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 4

        logoView.widthAnchor.constraint(equalToConstant: 64).isActive = true
        logoView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        logoView.layer.cornerRadius = 10
        logoView.clipsToBounds = true

        let cardStack = UIStackView(arrangedSubviews: [logoView, textStack])
        cardStack.axis = .horizontal
        cardStack.alignment = .top
        cardStack.spacing = 12
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            cardStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(shop: Shop, customerPoint: GeoPoint) {
        nameLabel.text = shop.name
        categoryLabel.text = shop.categoryName
        ratingLabel.text = "★ \(String(format: "%.1f", shop.rating)) (\(shop.ratingCount))"
        distanceLabel.text = "· \(GeoMath.formattedDistance(shop.distanceKm(from: customerPoint))) away"
        metaLabel.text = "\(shop.deliveryTimeMinutes) min delivery · Min order ₹\(Int(truncating: NSDecimalNumber(decimal: shop.minOrderAmount)))"
        if shop.isOpenNow {
            statusLabel.text = "OPEN"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "CLOSED"
            statusLabel.textColor = .systemRed
        }
        offerLabel.text = shop.offerText
        offerLabel.isHidden = shop.offerText == nil
    }
}

final class ProductRowCell: UITableViewCell {

    static let reuseID = "ProductRowCell"

    private let thumbView = PlaceholderImageView(emoji: "🥫")
    private let nameLabel = UILabel()
    private let unitLabel = UILabel()
    private let priceLabel = UILabel()
    private let originalPriceLabel = UILabel()
    private let discountLabel = UILabel()
    private let stockLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let quantityControl = QuantityControl()

    var onAddTapped: (() -> Void)?
    var onQuantityChanged: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        unitLabel.font = .systemFont(ofSize: 13)
        unitLabel.textColor = .secondaryLabel
        priceLabel.font = .boldSystemFont(ofSize: 15)
        originalPriceLabel.font = .systemFont(ofSize: 13)
        originalPriceLabel.textColor = .secondaryLabel
        discountLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        discountLabel.textColor = .systemGreen
        stockLabel.font = .systemFont(ofSize: 11)
        stockLabel.textColor = .systemRed

        addButton.setTitle("Add", for: .normal)
        addButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        addButton.setTitleColor(.white, for: .normal)
        addButton.backgroundColor = .systemGreen
        addButton.layer.cornerRadius = 8
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        quantityControl.onChange = { [weak self] newValue in
            self?.onQuantityChanged?(newValue)
        }

        let priceRow = UIStackView(arrangedSubviews: [priceLabel, originalPriceLabel, discountLabel])
        priceRow.axis = .horizontal
        priceRow.spacing = 6

        let textStack = UIStackView(arrangedSubviews: [nameLabel, unitLabel, priceRow, stockLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2

        thumbView.widthAnchor.constraint(equalToConstant: 56).isActive = true
        thumbView.heightAnchor.constraint(equalToConstant: 56).isActive = true
        thumbView.layer.cornerRadius = 8
        thumbView.clipsToBounds = true

        addButton.widthAnchor.constraint(equalToConstant: 72).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let rightStack = UIStackView(arrangedSubviews: [addButton, quantityControl])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing

        let cardStack = UIStackView(arrangedSubviews: [thumbView, textStack, UIView(), rightStack])
        cardStack.axis = .horizontal
        cardStack.alignment = .center
        cardStack.spacing = 12
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            cardStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func addTapped() {
        onAddTapped?()
    }

    func configure(product: Product, quantityInCart: Int) {
        nameLabel.text = product.name
        unitLabel.text = product.unit ?? ""
        priceLabel.text = CurrencyFormatter.string(from: product.effectiveUnitPrice)

        if product.hasDiscount {
            let attributed = NSMutableAttributedString(
                string: CurrencyFormatter.string(from: product.price),
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
            originalPriceLabel.attributedText = attributed
            discountLabel.text = "\(product.discountPercent ?? 0)% OFF"
        } else {
            originalPriceLabel.attributedText = nil
            discountLabel.text = nil
        }

        if product.isOutOfStock {
            stockLabel.text = "Out of stock"
            isUserInteractionEnabled = true
            addButton.isEnabled = false
            addButton.alpha = 0.4
        } else if product.stock <= 5 {
            stockLabel.text = "Only \(product.stock) left"
            addButton.isEnabled = true
            addButton.alpha = 1
        } else {
            stockLabel.text = nil
            addButton.isEnabled = true
            addButton.alpha = 1
        }

        renderQuantity(quantityInCart)
    }

    func renderQuantity(_ quantity: Int) {
        quantityControl.render(value: quantity)
        addButton.isHidden = quantity > 0
    }
}

final class CategoryChipCell: UICollectionViewCell {

    static let reuseID = "CategoryChipCell"

    private let iconLabel = UILabel()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 12

        iconLabel.font = .systemFont(ofSize: 22)
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [iconLabel, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(category: ShopCategory, isSelected: Bool) {
        iconLabel.text = isSelected ? category.symbolName : category.symbolName
        titleLabel.text = category.name
        contentView.backgroundColor = isSelected ? .systemOrange.withAlphaComponent(0.15) : .secondarySystemGroupedBackground
        layer.borderWidth = isSelected ? 1.5 : 0
        layer.borderColor = isSelected ? UIColor.systemOrange.cgColor : nil
        layer.cornerRadius = 12
    }
}

final class MiniProductCardCell: UICollectionViewCell {

    static let reuseID = "MiniProductCardCell"

    private let thumbView = PlaceholderImageView(emoji: "🎁")
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let originalPriceLabel = UILabel()
    private let addButton = UIButton(type: .system)

    var onAddTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.numberOfLines = 1
        priceLabel.font = .boldSystemFont(ofSize: 14)
        originalPriceLabel.font = .systemFont(ofSize: 12)
        originalPriceLabel.textColor = .secondaryLabel

        addButton.setTitle("Add", for: .normal)
        addButton.titleLabel?.font = .boldSystemFont(ofSize: 13)
        addButton.setTitleColor(.white, for: .normal)
        addButton.backgroundColor = .systemGreen
        addButton.layer.cornerRadius = 6
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        thumbView.heightAnchor.constraint(equalToConstant: 70).isActive = true

        let priceRow = UIStackView(arrangedSubviews: [priceLabel, originalPriceLabel])
        priceRow.axis = .horizontal
        priceRow.spacing = 4

        let stack = UIStackView(arrangedSubviews: [thumbView, nameLabel, priceRow, addButton])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            addButton.heightAnchor.constraint(equalToConstant: 28),
            addButton.widthAnchor.constraint(equalToConstant: 60)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func addTapped() {
        onAddTapped?()
    }

    func configure(product: Product) {
        nameLabel.text = product.name
        priceLabel.text = CurrencyFormatter.string(from: product.effectiveUnitPrice)
        if product.hasDiscount {
            let attributed = NSMutableAttributedString(
                string: CurrencyFormatter.string(from: product.price),
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
            originalPriceLabel.attributedText = attributed
        } else {
            originalPriceLabel.attributedText = nil
        }
    }
}

final class AddressCell: UITableViewCell {

    static let reuseID = "AddressCell"

    private let radioLabel = UILabel()
    private let typeLabel = UILabel()
    private let detailLabel = UILabel()
    private let defaultBadge = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        radioLabel.font = .systemFont(ofSize: 22)
        typeLabel.font = .boldSystemFont(ofSize: 15)
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 2
        defaultBadge.font = .systemFont(ofSize: 11, weight: .semibold)
        defaultBadge.textColor = .systemGreen
        defaultBadge.text = "DEFAULT"

        let titleRow = UIStackView(arrangedSubviews: [typeLabel, defaultBadge, UIView()])
        titleRow.axis = .horizontal
        titleRow.spacing = 8

        let stack = UIStackView(arrangedSubviews: [titleRow, detailLabel])
        stack.axis = .vertical
        stack.spacing = 3

        radioLabel.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(radioLabel)
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            radioLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            radioLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: radioLabel.trailingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(address: Address, isSelected: Bool) {
        radioLabel.text = isSelected ? "⦿" : "○"
        typeLabel.text = address.type.rawValue + " · " + address.name
        detailLabel.text = address.singleLine
        defaultBadge.isHidden = !address.isDefault
    }
}

final class OrderCardCell: UITableViewCell {

    static let reuseID = "OrderCardCell"

    private let orderIdLabel = UILabel()
    private let shopLabel = UILabel()
    private let dateLabel = UILabel()
    private let itemsLabel = UILabel()
    private let totalLabel = UILabel()
    private let statusLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator

        orderIdLabel.font = .boldSystemFont(ofSize: 15)
        shopLabel.font = .systemFont(ofSize: 14)
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = .secondaryLabel
        itemsLabel.font = .systemFont(ofSize: 13)
        itemsLabel.textColor = .secondaryLabel
        totalLabel.font = .boldSystemFont(ofSize: 15)
        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)

        let topRow = UIStackView(arrangedSubviews: [orderIdLabel, UIView(), totalLabel])
        topRow.axis = .horizontal
        let midRow = UIStackView(arrangedSubviews: [shopLabel, UIView(), statusLabel])
        midRow.axis = .horizontal

        let stack = UIStackView(arrangedSubviews: [topRow, midRow, itemsLabel, dateLabel])
        stack.axis = .vertical
        stack.spacing = 3
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(order: Order) {
        orderIdLabel.text = "#\(order.id)"
        shopLabel.text = order.shopName
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: order.createdAt)
        itemsLabel.text = "\(order.itemCount) item(s)"
        totalLabel.text = CurrencyFormatter.string(from: order.totals.grandTotal)
        statusLabel.text = order.status.displayTitle
        switch order.status {
        case .delivered:
            statusLabel.textColor = .systemGreen
        case .cancelled, .rejected:
            statusLabel.textColor = .systemRed
        default:
            statusLabel.textColor = .systemOrange
        }
    }
}

final class SubtitleCell: UITableViewCell {

    static let reuseID = "SubtitleCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

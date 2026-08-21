import UIKit

final class CategoryRowCell: UITableViewCell {

    static let reuseID = "CategoryRowCell"

    private var categories = DefaultShopCategories.all
    private var selectedCategoryId: String?
    private var onSelect: ((String) -> Void)?

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        contentView.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(selectedCategoryId: String?, onSelect: @escaping (String) -> Void) {
        self.selectedCategoryId = selectedCategoryId
        self.onSelect = onSelect
        rebuildButtons()
    }

    private func rebuildButtons() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for category in categories {
            let isSelected = category.id == selectedCategoryId
            let button = UIButton(type: .system)
            button.setTitle("\(category.name)", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            button.setTitleColor(isSelected ? .white : .label, for: .normal)
            button.backgroundColor = isSelected ? .systemOrange : .secondarySystemGroupedBackground
            button.layer.cornerRadius = 14
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
            button.addAction(UIAction { [weak self] _ in
                self?.onSelect?(category.id)
            }, for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
    }
}

final class ProductCarouselCell: UITableViewCell {

    static let reuseID = "ProductCarouselCell"

    private var products: [Product] = []
    private var onAdd: ((Product) -> Void)?

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        contentView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(products: [Product], onAdd: @escaping (Product) -> Void) {
        self.products = products
        self.onAdd = onAdd
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for product in products {
            let card = MiniProductCardCell(frame: CGRect(x: 0, y: 0, width: 130, height: 150))
            card.configure(product: product)
            card.onAddTapped = { [weak self] in
                self?.onAdd?(product)
            }
            card.widthAnchor.constraint(equalToConstant: 130).isActive = true
            stackView.addArrangedSubview(card)
        }
    }
}

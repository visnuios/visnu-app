import Foundation

enum DemoCatalog {

    static let shops: [Shop] = [
        Shop(
            id: "shop_freshmart",
            name: "Fresh Mart Grocery",
            categoryName: "Grocery",
            descriptionText: "Your neighbourhood grocery store with fresh daily supplies.",
            rating: 4.5,
            ratingCount: 1240,
            point: GeoPoint(latitude: 11.0200, longitude: 76.9600),
            deliveryRadiusKm: 6,
            minOrderAmount: 99,
            deliveryTimeMinutes: 25,
            opensAtHour: 7,
            closesAtHour: 22,
            isClosedPermanently: false,
            offerText: "FREE delivery above ₹499",
            imageURL: nil
        ),
        Shop(
            id: "shop_veggy",
            name: "Anna Vegetable Stall",
            categoryName: "Vegetables",
            descriptionText: "Farm fresh vegetables and fruits every morning.",
            rating: 4.2,
            ratingCount: 860,
            point: GeoPoint(latitude: 11.0240, longitude: 76.9580),
            deliveryRadiusKm: 5,
            minOrderAmount: 49,
            deliveryTimeMinutes: 20,
            opensAtHour: 6,
            closesAtHour: 21,
            isClosedPermanently: false,
            offerText: "Up to 30% OFF",
            imageURL: nil
        ),
        Shop(
            id: "shop_bakery",
            name: "Oven Fresh Bakery",
            categoryName: "Bakery",
            descriptionText: "Breads, cakes and snacks baked fresh all day.",
            rating: 4.7,
            ratingCount: 2100,
            point: GeoPoint(latitude: 11.0100, longitude: 76.9520),
            deliveryRadiusKm: 4,
            minOrderAmount: 79,
            deliveryTimeMinutes: 30,
            opensAtHour: 8,
            closesAtHour: 23,
            isClosedPermanently: false,
            offerText: nil,
            imageURL: nil
        ),
        Shop(
            id: "shop_pizzacorner",
            name: "Pizza Corner",
            categoryName: "Restaurant",
            descriptionText: "Hot wood-fired pizzas, garlic bread and more.",
            rating: 4.4,
            ratingCount: 3320,
            point: GeoPoint(latitude: 11.0310, longitude: 76.9700),
            deliveryRadiusKm: 7,
            minOrderAmount: 149,
            deliveryTimeMinutes: 35,
            opensAtHour: 11,
            closesAtHour: 23,
            isClosedPermanently: false,
            offerText: "Buy 1 Get 1 on Garlic Bread",
            imageURL: nil
        ),
        Shop(
            id: "shop_dairy",
            name: "Sri Dairy & Farms",
            categoryName: "Dairy",
            descriptionText: "Milk, curd, paneer, ghee and farm products.",
            rating: 4.6,
            ratingCount: 980,
            point: GeoPoint(latitude: 11.0090, longitude: 76.9630),
            deliveryRadiusKm: 8,
            minOrderAmount: 59,
            deliveryTimeMinutes: 28,
            opensAtHour: 6,
            closesAtHour: 22,
            isClosedPermanently: false,
            offerText: nil,
            imageURL: nil
        ),
        Shop(
            id: "shop_supermart",
            name: "XYZ Supermarket",
            categoryName: "Grocery",
            descriptionText: "Everything for your home under one roof.",
            rating: 4.1,
            ratingCount: 1560,
            point: GeoPoint(latitude: 11.0480, longitude: 76.9820),
            deliveryRadiusKm: 4,
            minOrderAmount: 199,
            deliveryTimeMinutes: 40,
            opensAtHour: 9,
            closesAtHour: 21,
            isClosedPermanently: false,
            offerText: "10% OFF above ₹500",
            imageURL: nil
        ),
        Shop(
            id: "shop_faraway",
            name: "Distant Meat House",
            categoryName: "Meat",
            descriptionText: "Fresh cuts delivered chilled.",
            rating: 4.0,
            ratingCount: 420,
            point: GeoPoint(latitude: 11.0900, longitude: 77.0500),
            deliveryRadiusKm: 2,
            minOrderAmount: 249,
            deliveryTimeMinutes: 45,
            opensAtHour: 8,
            closesAtHour: 20,
            isClosedPermanently: false,
            offerText: nil,
            imageURL: nil
        )
    ]

    static let products: [Product] = [
        Product(id: "tomato", name: "Tomato", shopId: "shop_veggy", shopName: "Anna Vegetable Stall", categoryId: "vegetables", unit: "1 kg", productDescription: "Locally grown ripe tomatoes.", price: 60, discountPrice: 45, stock: 40, imageURL: nil),
        Product(id: "onion", name: "Onion", shopId: "shop_veggy", shopName: "Anna Vegetable Stall", categoryId: "vegetables", unit: "1 kg", productDescription: nil, price: 42, discountPrice: nil, stock: 55, imageURL: nil),
        Product(id: "carrot", name: "Carrot", shopId: "shop_veggy", shopName: "Anna Vegetable Stall", categoryId: "vegetables", unit: "500 g", productDescription: "Crunchy Ooty carrots.", price: 38, discountPrice: 32, stock: 30, imageURL: nil),
        Product(id: "apple", name: "Apple", shopId: "shop_veggy", shopName: "Anna Vegetable Stall", categoryId: "fruits", unit: "1 kg", productDescription: "Kashmiri apples.", price: 180, discountPrice: 150, stock: 25, imageURL: nil),
        Product(id: "banana", name: "Banana", shopId: "shop_veggy", shopName: "Anna Vegetable Stall", categoryId: "fruits", unit: "1 dozen", productDescription: nil, price: 48, discountPrice: nil, stock: 60, imageURL: nil),

        Product(id: "rice", name: "Ponni Rice", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "5 kg", productDescription: "Premium ponni boiled rice.", price: 380, discountPrice: 340, stock: 35, imageURL: nil),
        Product(id: "atta", name: "Whole Wheat Atta", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "5 kg", productDescription: nil, price: 260, discountPrice: nil, stock: 28, imageURL: nil),
        Product(id: "sunflower_oil", name: "Sunflower Oil", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "1 L", productDescription: "Refined sunflower oil.", price: 165, discountPrice: 145, stock: 44, imageURL: nil),
        Product(id: "sugar", name: "Sugar", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "1 kg", productDescription: nil, price: 46, discountPrice: nil, stock: 70, imageURL: nil),
        Product(id: "biscuits", name: "Good Day Biscuits", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "snacks", unit: "600 g", productDescription: "Cashew and butter cookies.", price: 90, discountPrice: 78, stock: 48, imageURL: nil),
        Product(id: "chips", name: "Potato Chips", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "snacks", unit: "150 g", productDescription: nil, price: 35, discountPrice: nil, stock: 90, imageURL: nil),

        Product(id: "milk", name: "Aavin Milk", shopId: "shop_dairy", shopName: "Sri Dairy & Farms", categoryId: "dairy", unit: "500 ml", productDescription: "Toned milk pouch.", price: 26, discountPrice: nil, stock: 100, imageURL: nil),
        Product(id: "curd", name: "Curd", shopId: "shop_dairy", shopName: "Sri Dairy & Farms", categoryId: "dairy", unit: "400 g", productDescription: "Thick set curd.", price: 34, discountPrice: 30, stock: 65, imageURL: nil),
        Product(id: "paneer", name: "Paneer", shopId: "shop_dairy", shopName: "Sri Dairy & Farms", categoryId: "dairy", unit: "200 g", productDescription: nil, price: 95, discountPrice: nil, stock: 18, imageURL: nil),
        Product(id: "ghee", name: "Pure Ghee", shopId: "shop_dairy", shopName: "Sri Dairy & Farms", categoryId: "dairy", unit: "500 ml", productDescription: "Traditional hand-churned ghee.", price: 320, discountPrice: 285, stock: 12, imageURL: nil),

        Product(id: "bread", name: "Milk Bread", shopId: "shop_bakery", shopName: "Oven Fresh Bakery", categoryId: "bakery", unit: "400 g", productDescription: "Soft white bread.", price: 40, discountPrice: nil, stock: 30, imageURL: nil),
        Product(id: "croissant", name: "Butter Croissant", shopId: "shop_bakery", shopName: "Oven Fresh Bakery", categoryId: "bakery", unit: "1 pc", productDescription: nil, price: 55, discountPrice: 45, stock: 20, imageURL: nil),
        Product(id: "chocolate_cake", name: "Chocolate Cake", shopId: "shop_bakery", shopName: "Oven Fresh Bakery", categoryId: "bakery", unit: "500 g", productDescription: "Rich truffle cake.", price: 340, discountPrice: 299, stock: 8, imageURL: nil),
        Product(id: "honey", name: "Wild Forest Honey", shopId: "shop_bakery", shopName: "Oven Fresh Bakery", categoryId: "grocery", unit: "350 g", productDescription: "Raw unprocessed honey.", price: 240, discountPrice: 199, stock: 15, imageURL: nil),

        Product(id: "pizza_margherita", name: "Margherita Pizza", shopId: "shop_pizzacorner", shopName: "Pizza Corner", categoryId: "restaurant", unit: nil, productDescription: "Classic cheese and tomato pizza.", price: 250, discountPrice: 199, stock: 14, imageURL: nil),
        Product(id: "garlic_bread", name: "Garlic Bread", shopId: "shop_pizzacorner", shopName: "Pizza Corner", categoryId: "restaurant", unit: "4 pcs", productDescription: "Cheesy garlic bread sticks.", price: 120, discountPrice: 99, stock: 16, imageURL: nil),
        Product(id: "dry_fruits", name: "Mixed Dry Fruits", shopId: "shop_pizzacorner", shopName: "Pizza Corner", categoryId: "snacks", unit: "250 g", productDescription: "Almonds, cashews and raisins.", price: 310, discountPrice: 275, stock: 10, imageURL: nil)
    ]

    static let pizzaVariations: [ProductVariationOption] = [
        ProductVariationOption(id: "size_s", groupName: "Size", title: "Small", priceDelta: -50),
        ProductVariationOption(id: "size_m", groupName: "Size", title: "Medium", priceDelta: 0),
        ProductVariationOption(id: "size_l", groupName: "Size", title: "Large", priceDelta: 120),
        ProductVariationOption(id: "extra_cheese", groupName: "Extras", title: "Extra Cheese", priceDelta: 40),
        ProductVariationOption(id: "extra_chicken", groupName: "Extras", title: "Chicken Topping", priceDelta: 60),
        ProductVariationOption(id: "extra_mushroom", groupName: "Extras", title: "Mushroom", priceDelta: 35)
    ]

    static func coupon(forCode code: String) -> Coupon? {
        switch code.trimmingCharacters(in: .whitespaces).uppercased() {
        case "SAVE10":
            return Coupon(
                id: "coupon_save10",
                code: "SAVE10",
                title: "10% off up to ₹40 · Min order ₹300",
                discountType: .percentage,
                value: 10,
                minOrderAmount: 300,
                maxDiscountAmount: 40,
                shopId: nil,
                expiresAt: Date.now.addingTimeInterval(30 * 86400)
            )
        case "FLAT50":
            return Coupon(
                id: "coupon_flat50",
                code: "FLAT50",
                title: "₹50 off on any order",
                discountType: .fixed,
                value: 50,
                minOrderAmount: 200,
                maxDiscountAmount: nil,
                shopId: nil,
                expiresAt: Date.now.addingTimeInterval(15 * 86400)
            )
        default:
            return nil
        }
    }

    static var availableCoupons: [Coupon] {
        [coupon(forCode: "SAVE10"), coupon(forCode: "FLAT50")].compactMap { $0 }
    }
}

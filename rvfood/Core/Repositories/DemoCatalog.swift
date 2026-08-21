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
        ),
        Shop(
            id: "shop_biriyani",
            name: "Anjappar Biriyani House",
            categoryName: "Restaurant",
            descriptionText: "Authentic Seeraga Samba biriyani and Chettinad sides.",
            rating: 4.6,
            ratingCount: 5410,
            point: GeoPoint(latitude: 11.0135, longitude: 76.9602),
            deliveryRadiusKm: 8,
            minOrderAmount: 179,
            deliveryTimeMinutes: 40,
            opensAtHour: 11,
            closesAtHour: 23,
            isClosedPermanently: false,
            offerText: "₹50 OFF above ₹500",
            imageURL: nil
        ),
        Shop(
            id: "shop_fruitbox",
            name: "Fruit Box Coimbatore",
            categoryName: "Fruits",
            descriptionText: "Hand-picked seasonal fruits and fresh cut boxes.",
            rating: 4.3,
            ratingCount: 640,
            point: GeoPoint(latitude: 11.0220, longitude: 76.9480),
            deliveryRadiusKm: 6,
            minOrderAmount: 99,
            deliveryTimeMinutes: 30,
            opensAtHour: 7,
            closesAtHour: 21,
            isClosedPermanently: false,
            offerText: "Seasonal combos live now",
            imageURL: nil
        ),
        Shop(
            id: "shop_meatmaster",
            name: "Meat Master",
            categoryName: "Meat",
            descriptionText: "Antibiotic-free chicken, mutton and seafood.",
            rating: 4.4,
            ratingCount: 1890,
            point: GeoPoint(latitude: 11.0330, longitude: 76.9860),
            deliveryRadiusKm: 7,
            minOrderAmount: 199,
            deliveryTimeMinutes: 38,
            opensAtHour: 7,
            closesAtHour: 21,
            isClosedPermanently: false,
            offerText: nil,
            imageURL: nil
        ),
        Shop(
            id: "shop_sweets",
            name: "Sri Krishna Sweets",
            categoryName: "Snacks",
            descriptionText: "Classic Tamil sweets, savouries and gift boxes.",
            rating: 4.8,
            ratingCount: 4300,
            point: GeoPoint(latitude: 11.0160, longitude: 76.9720),
            deliveryRadiusKm: 6,
            minOrderAmount: 149,
            deliveryTimeMinutes: 32,
            opensAtHour: 9,
            closesAtHour: 22,
            isClosedPermanently: false,
            offerText: "Festival hampers available",
            imageURL: nil
        ),
        Shop(
            id: "shop_organics",
            name: "Green Leaf Organics",
            categoryName: "Vegetables",
            descriptionText: "Certified organic produce straight from farms.",
            rating: 4.5,
            ratingCount: 720,
            point: GeoPoint(latitude: 11.0410, longitude: 76.9510),
            deliveryRadiusKm: 9,
            minOrderAmount: 149,
            deliveryTimeMinutes: 42,
            opensAtHour: 8,
            closesAtHour: 20,
            isClosedPermanently: false,
            offerText: "Organic week · 15% OFF",
            imageURL: nil
        )
    ]

    static let products: [Product] = [
        Product(id: "tomato", name: "Tomato", shopId: "shop_veggy", shopName: "Anna Vegetable Stall", categoryId: "vegetables", unit: "1 kg", productDescription: "Locally grown ripe tomatoes.", price: 60, discountPrice: 45, stock: 40, imageURL: nil),
        Product(id: "onion", name: "Onion", shopId: "shop_veggy", shopName: "Anna Vegetable Stall", categoryId: "vegetables", unit: "1 kg", productDescription: nil, price: 42, discountPrice: nil, stock: 55, imageURL: nil),
        Product(id: "carrot", name: "Carrot", shopId: "shop_veggy", shopName: "Anna Vegetable Stall", categoryId: "vegetables", unit: "500 g", productDescription: "Crunchy Ooty carrots.", price: 38, discountPrice: 32, stock: 30, imageURL: nil),
        Product(id: "potato", name: "Potato", shopId: "shop_veggy", shopName: "Anna Vegetable Stall", categoryId: "vegetables", unit: "1 kg", productDescription: nil, price: 36, discountPrice: nil, stock: 65, imageURL: nil),
        Product(id: "capsicum", name: "Capsicum", shopId: "shop_veggy", shopName: "Anna Vegetable Stall", categoryId: "vegetables", unit: "500 g", productDescription: "Crisp green capsicum.", price: 44, discountPrice: 36, stock: 22, imageURL: nil),
        Product(id: "apple", name: "Apple", shopId: "shop_veggy", shopName: "Anna Vegetable Stall", categoryId: "fruits", unit: "1 kg", productDescription: "Kashmiri apples.", price: 180, discountPrice: 150, stock: 25, imageURL: nil),
        Product(id: "banana", name: "Banana", shopId: "shop_veggy", shopName: "Anna Vegetable Stall", categoryId: "fruits", unit: "1 dozen", productDescription: nil, price: 48, discountPrice: nil, stock: 60, imageURL: nil),

        Product(id: "rice", name: "Ponni Rice", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "5 kg", productDescription: "Premium ponni boiled rice.", price: 380, discountPrice: 340, stock: 35, imageURL: nil),
        Product(id: "atta", name: "Whole Wheat Atta", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "5 kg", productDescription: nil, price: 260, discountPrice: nil, stock: 28, imageURL: nil),
        Product(id: "sunflower_oil", name: "Sunflower Oil", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "1 L", productDescription: "Refined sunflower oil.", price: 165, discountPrice: 145, stock: 44, imageURL: nil),
        Product(id: "sugar", name: "Sugar", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "1 kg", productDescription: nil, price: 46, discountPrice: nil, stock: 70, imageURL: nil),
        Product(id: "salt", name: "Iodised Salt", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "1 kg", productDescription: nil, price: 28, discountPrice: nil, stock: 80, imageURL: nil),
        Product(id: "toor_dal", name: "Toor Dal", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "1 kg", productDescription: "Unpolished toor dal.", price: 155, discountPrice: 138, stock: 40, imageURL: nil),
        Product(id: "tea_powder", name: "Tea Powder", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "500 g", productDescription: "Strong Nilgiri leaf blend.", price: 210, discountPrice: 185, stock: 26, imageURL: nil),
        Product(id: "biscuits", name: "Good Day Biscuits", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "snacks", unit: "600 g", productDescription: "Cashew and butter cookies.", price: 90, discountPrice: 78, stock: 48, imageURL: nil),
        Product(id: "chips", name: "Potato Chips", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "snacks", unit: "150 g", productDescription: nil, price: 35, discountPrice: nil, stock: 90, imageURL: nil),
        Product(id: "detergent", name: "Detergent Powder", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "2 kg", productDescription: nil, price: 320, discountPrice: 289, stock: 18, imageURL: nil),
        Product(id: "dishwash_bar", name: "Dishwash Bar", shopId: "shop_freshmart", shopName: "Fresh Mart Grocery", categoryId: "grocery", unit: "3 x 200 g", productDescription: nil, price: 60, discountPrice: nil, stock: 52, imageURL: nil),

        Product(id: "milk", name: "Aavin Milk", shopId: "shop_dairy", shopName: "Sri Dairy & Farms", categoryId: "dairy", unit: "500 ml", productDescription: "Toned milk pouch.", price: 26, discountPrice: nil, stock: 100, imageURL: nil),
        Product(id: "curd", name: "Curd", shopId: "shop_dairy", shopName: "Sri Dairy & Farms", categoryId: "dairy", unit: "400 g", productDescription: "Thick set curd.", price: 34, discountPrice: 30, stock: 65, imageURL: nil),
        Product(id: "paneer", name: "Paneer", shopId: "shop_dairy", shopName: "Sri Dairy & Farms", categoryId: "dairy", unit: "200 g", productDescription: nil, price: 95, discountPrice: nil, stock: 18, imageURL: nil),
        Product(id: "ghee", name: "Pure Ghee", shopId: "shop_dairy", shopName: "Sri Dairy & Farms", categoryId: "dairy", unit: "500 ml", productDescription: "Traditional hand-churned ghee.", price: 320, discountPrice: 285, stock: 12, imageURL: nil),
        Product(id: "butter", name: "Farm Butter", shopId: "shop_dairy", shopName: "Sri Dairy & Farms", categoryId: "dairy", unit: "100 g", productDescription: nil, price: 58, discountPrice: nil, stock: 34, imageURL: nil),
        Product(id: "buttermilk", name: "Spiced Buttermilk", shopId: "shop_dairy", shopName: "Sri Dairy & Farms", categoryId: "dairy", unit: "300 ml", productDescription: "Chilled neer mor with curry leaf.", price: 20, discountPrice: 15, stock: 75, imageURL: nil),
        Product(id: "cheese_slices", name: "Cheese Slices", shopId: "shop_dairy", shopName: "Sri Dairy & Farms", categoryId: "dairy", unit: "10 slices", productDescription: nil, price: 135, discountPrice: 119, stock: 20, imageURL: nil),

        Product(id: "bread", name: "Milk Bread", shopId: "shop_bakery", shopName: "Oven Fresh Bakery", categoryId: "bakery", unit: "400 g", productDescription: "Soft white bread.", price: 40, discountPrice: nil, stock: 30, imageURL: nil),
        Product(id: "croissant", name: "Butter Croissant", shopId: "shop_bakery", shopName: "Oven Fresh Bakery", categoryId: "bakery", unit: "1 pc", productDescription: nil, price: 55, discountPrice: 45, stock: 20, imageURL: nil),
        Product(id: "chocolate_cake", name: "Chocolate Cake", shopId: "shop_bakery", shopName: "Oven Fresh Bakery", categoryId: "bakery", unit: "500 g", productDescription: "Rich truffle cake.", price: 340, discountPrice: 299, stock: 8, imageURL: nil),
        Product(id: "honey", name: "Wild Forest Honey", shopId: "shop_bakery", shopName: "Oven Fresh Bakery", categoryId: "grocery", unit: "350 g", productDescription: "Raw unprocessed honey.", price: 240, discountPrice: 199, stock: 15, imageURL: nil),
        Product(id: "veg_puff", name: "Veg Puff", shopId: "shop_bakery", shopName: "Oven Fresh Bakery", categoryId: "snacks", unit: "1 pc", productDescription: "Flaky pastry with spiced veggies.", price: 25, discountPrice: nil, stock: 40, imageURL: nil),
        Product(id: "chicken_puff", name: "Chicken Puff", shopId: "shop_bakery", shopName: "Oven Fresh Bakery", categoryId: "snacks", unit: "1 pc", productDescription: nil, price: 35, discountPrice: 30, stock: 32, imageURL: nil),
        Product(id: "donut", name: "Glazed Donut", shopId: "shop_bakery", shopName: "Oven Fresh Bakery", categoryId: "bakery", unit: "1 pc", productDescription: nil, price: 65, discountPrice: 55, stock: 14, imageURL: nil),

        Product(id: "pizza_margherita", name: "Margherita Pizza", shopId: "shop_pizzacorner", shopName: "Pizza Corner", categoryId: "restaurant", unit: nil, productDescription: "Classic cheese and tomato pizza.", price: 250, discountPrice: 199, stock: 14, imageURL: nil),
        Product(id: "pizza_farmhouse", name: "Farmhouse Pizza", shopId: "shop_pizzacorner", shopName: "Pizza Corner", categoryId: "restaurant", unit: nil, productDescription: "Loaded with garden veggies.", price: 320, discountPrice: 279, stock: 10, imageURL: nil),
        Product(id: "garlic_bread", name: "Garlic Bread", shopId: "shop_pizzacorner", shopName: "Pizza Corner", categoryId: "restaurant", unit: "4 pcs", productDescription: "Cheesy garlic bread sticks.", price: 120, discountPrice: 99, stock: 16, imageURL: nil),
        Product(id: "pasta_alfredo", name: "Alfredo Pasta", shopId: "shop_pizzacorner", shopName: "Pizza Corner", categoryId: "restaurant", unit: nil, productDescription: "Creamy white sauce pasta.", price: 220, discountPrice: nil, stock: 12, imageURL: nil),
        Product(id: "cold_coffee", name: "Cold Coffee", shopId: "shop_pizzacorner", shopName: "Pizza Corner", categoryId: "restaurant", unit: "300 ml", productDescription: nil, price: 110, discountPrice: 89, stock: 25, imageURL: nil),
        Product(id: "dry_fruits", name: "Mixed Dry Fruits", shopId: "shop_pizzacorner", shopName: "Pizza Corner", categoryId: "snacks", unit: "250 g", productDescription: "Almonds, cashews and raisins.", price: 310, discountPrice: 275, stock: 10, imageURL: nil),

        Product(id: "chicken_biriyani", name: "Chicken Biriyani", shopId: "shop_biriyani", shopName: "Anjappar Biriyani House", categoryId: "restaurant", unit: "750 g pack", productDescription: "Seeraga samba rice, slow cooked.", price: 280, discountPrice: 249, stock: 30, imageURL: nil),
        Product(id: "mutton_biriyani", name: "Mutton Biriyani", shopId: "shop_biriyani", shopName: "Anjappar Biriyani House", categoryId: "restaurant", unit: "750 g pack", productDescription: nil, price: 380, discountPrice: 349, stock: 18, imageURL: nil),
        Product(id: "veg_meals", name: "South Indian Veg Meals", shopId: "shop_biriyani", shopName: "Anjappar Biriyani House", categoryId: "restaurant", unit: nil, productDescription: "Unlimited rice meals with sides.", price: 180, discountPrice: nil, stock: 24, imageURL: nil),
        Product(id: "pepper_chicken", name: "Chettinad Pepper Chicken", shopId: "shop_biriyani", shopName: "Anjappar Biriyani House", categoryId: "restaurant", unit: "350 g", productDescription: "Fiery dry pepper chicken.", price: 260, discountPrice: 235, stock: 15, imageURL: nil),
        Product(id: "rasmalai", name: "Rasmalai", shopId: "shop_biriyani", shopName: "Anjappar Biriyani House", categoryId: "snacks", unit: "2 pcs", productDescription: nil, price: 90, discountPrice: nil, stock: 20, imageURL: nil),

        Product(id: "watermelon", name: "Watermelon", shopId: "shop_fruitbox", shopName: "Fruit Box Coimbatore", categoryId: "fruits", unit: "1 pc (~3 kg)", productDescription: "Sweet and juicy.", price: 90, discountPrice: 69, stock: 20, imageURL: nil),
        Product(id: "pomegranate", name: "Pomegranate", shopId: "shop_fruitbox", shopName: "Fruit Box Coimbatore", categoryId: "fruits", unit: "500 g", productDescription: nil, price: 120, discountPrice: 99, stock: 26, imageURL: nil),
        Product(id: "papaya", name: "Papaya", shopId: "shop_fruitbox", shopName: "Fruit Box Coimbatore", categoryId: "fruits", unit: "1 kg", productDescription: nil, price: 55, discountPrice: nil, stock: 30, imageURL: nil),
        Product(id: "grapes", name: "Black Grapes", shopId: "shop_fruitbox", shopName: "Fruit Box Coimbatore", categoryId: "fruits", unit: "500 g", productDescription: "Seedless black grapes.", price: 85, discountPrice: 74, stock: 24, imageURL: nil),
        Product(id: "fruit_box_small", name: "Mixed Fruit Box (Small)", shopId: "shop_fruitbox", shopName: "Fruit Box Coimbatore", categoryId: "fruits", unit: "6 varieties", productDescription: "Ready-to-eat cut fruit box for 2.", price: 150, discountPrice: 129, stock: 12, imageURL: nil),

        Product(id: "chicken_curry_cut", name: "Chicken Curry Cut", shopId: "shop_meatmaster", shopName: "Meat Master", categoryId: "meat", unit: "500 g", productDescription: "Skinless, curry cut pieces.", price: 185, discountPrice: 165, stock: 28, imageURL: nil),
        Product(id: "chicken_boneless", name: "Chicken Boneless", shopId: "shop_meatmaster", shopName: "Meat Master", categoryId: "meat", unit: "450 g", productDescription: nil, price: 245, discountPrice: nil, stock: 20, imageURL: nil),
        Product(id: "mutton_curry_cut", name: "Mutton Curry Cut", shopId: "shop_meatmaster", shopName: "Meat Master", categoryId: "meat", unit: "500 g", productDescription: "Tender goat meat.", price: 520, discountPrice: 489, stock: 10, imageURL: nil),
        Product(id: "fish_seer", name: "Seer Fish Steaks", shopId: "shop_meatmaster", shopName: "Meat Master", categoryId: "meat", unit: "500 g", productDescription: "Cleaned seer fish steaks.", price: 480, discountPrice: 449, stock: 8, imageURL: nil),
        Product(id: "prawns", name: "Prawns (Cleaned)", shopId: "shop_meatmaster", shopName: "Meat Master", categoryId: "meat", unit: "400 g", productDescription: nil, price: 320, discountPrice: nil, stock: 12, imageURL: nil),
        Product(id: "eggs", name: "Farm Eggs", shopId: "shop_meatmaster", shopName: "Meat Master", categoryId: "meat", unit: "6 pcs", productDescription: nil, price: 48, discountPrice: 42, stock: 60, imageURL: nil),

        Product(id: "mysore_pak", name: "Ghee Mysore Pak", shopId: "shop_sweets", shopName: "Sri Krishna Sweets", categoryId: "snacks", unit: "250 g", productDescription: "Melts in the mouth.", price: 200, discountPrice: 179, stock: 22, imageURL: nil),
        Product(id: "laddu", name: "Boondi Laddu", shopId: "shop_sweets", shopName: "Sri Krishna Sweets", categoryId: "snacks", unit: "250 g", productDescription: nil, price: 160, discountPrice: nil, stock: 30, imageURL: nil),
        Product(id: "mixture", name: "South Indian Mixture", shopId: "shop_sweets", shopName: "Sri Krishna Sweets", categoryId: "snacks", unit: "200 g", productDescription: "Crunchy tea-time mixture.", price: 75, discountPrice: 65, stock: 45, imageURL: nil),
        Product(id: "murukku", name: "Butter Murukku", shopId: "shop_sweets", shopName: "Sri Krishna Sweets", categoryId: "snacks", unit: "200 g", productDescription: nil, price: 85, discountPrice: nil, stock: 38, imageURL: nil),
        Product(id: "halwa", name: "Wheat Halwa", shopId: "shop_sweets", shopName: "Sri Krishna Sweets", categoryId: "snacks", unit: "250 g", productDescription: "Slow-cooked Tirunelveli style.", price: 190, discountPrice: 169, stock: 16, imageURL: nil),

        Product(id: "org_spinach", name: "Organic Spinach", shopId: "shop_organics", shopName: "Green Leaf Organics", categoryId: "vegetables", unit: "250 g", productDescription: "Pesticide-free palak.", price: 35, discountPrice: 29, stock: 26, imageURL: nil),
        Product(id: "org_tomato", name: "Organic Tomato", shopId: "shop_organics", shopName: "Green Leaf Organics", categoryId: "vegetables", unit: "500 g", productDescription: nil, price: 45, discountPrice: 39, stock: 30, imageURL: nil),
        Product(id: "org_carrot", name: "Organic Carrot", shopId: "shop_organics", shopName: "Green Leaf Organics", categoryId: "vegetables", unit: "500 g", productDescription: "Ooty hill carrots.", price: 55, discountPrice: nil, stock: 24, imageURL: nil),
        Product(id: "org_avocado", name: "Organic Avocado", shopId: "shop_organics", shopName: "Green Leaf Organics", categoryId: "fruits", unit: "2 pcs", productDescription: "Creamy hass avocados.", price: 240, discountPrice: 209, stock: 10, imageURL: nil),
        Product(id: "org_millet_mix", name: "Millet Health Mix", shopId: "shop_organics", shopName: "Green Leaf Organics", categoryId: "grocery", unit: "500 g", productDescription: "Nine millet breakfast mix.", price: 175, discountPrice: 155, stock: 20, imageURL: nil)
    ]

    static let pizzaVariations: [ProductVariationOption] = [
        ProductVariationOption(id: "size_s", groupName: "Size", title: "Small", priceDelta: -50),
        ProductVariationOption(id: "size_m", groupName: "Size", title: "Medium", priceDelta: 0),
        ProductVariationOption(id: "size_l", groupName: "Size", title: "Large", priceDelta: 120),
        ProductVariationOption(id: "extra_cheese", groupName: "Extras", title: "Extra Cheese", priceDelta: 40),
        ProductVariationOption(id: "extra_chicken", groupName: "Extras", title: "Chicken Topping", priceDelta: 60),
        ProductVariationOption(id: "extra_mushroom", groupName: "Extras", title: "Mushroom", priceDelta: 35)
    ]

    static let cakeVariations: [ProductVariationOption] = [
        ProductVariationOption(id: "cake_500", groupName: "Weight", title: "500 g", priceDelta: 0),
        ProductVariationOption(id: "cake_1kg", groupName: "Weight", title: "1 kg", priceDelta: 290),
        ProductVariationOption(id: "cake_message", groupName: "Add-ons", title: "Message on Cake", priceDelta: 30),
        ProductVariationOption(id: "cake_candles", groupName: "Add-ons", title: "Candles & Knife", priceDelta: 20)
    ]

    static let biriyaniVariations: [ProductVariationOption] = [
        ProductVariationOption(id: "spicy_mild", groupName: "Spice Level", title: "Mild", priceDelta: 0),
        ProductVariationOption(id: "spicy_hot", groupName: "Spice Level", title: "Extra Spicy", priceDelta: 0),
        ProductVariationOption(id: "extra_raita", groupName: "Add-ons", title: "Extra Raita", priceDelta: 25),
        ProductVariationOption(id: "extra_salna", groupName: "Add-ons", title: "Extra Salna", priceDelta: 25)
    ]

    static func variations(forProductId productId: String) -> [ProductVariationOption] {
        switch productId {
        case "pizza_margherita", "pizza_farmhouse":
            return pizzaVariations
        case "chocolate_cake":
            return cakeVariations
        case "chicken_biriyani", "mutton_biriyani":
            return biriyaniVariations
        default:
            return []
        }
    }

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
                title: "₹50 off on orders above ₹200",
                discountType: .fixed,
                value: 50,
                minOrderAmount: 200,
                maxDiscountAmount: nil,
                shopId: nil,
                expiresAt: Date.now.addingTimeInterval(15 * 86400)
            )
        case "WELCOME20":
            return Coupon(
                id: "coupon_welcome20",
                code: "WELCOME20",
                title: "₹20 off on your first order above ₹99",
                discountType: .fixed,
                value: 20,
                minOrderAmount: 99,
                maxDiscountAmount: nil,
                shopId: nil,
                expiresAt: Date.now.addingTimeInterval(60 * 86400)
            )
        case "BIRYANI15":
            return Coupon(
                id: "coupon_biryani15",
                code: "BIRYANI15",
                title: "15% off up to ₹75 at Anjappar Biriyani House",
                discountType: .percentage,
                value: 15,
                minOrderAmount: 250,
                maxDiscountAmount: 75,
                shopId: "shop_biriyani",
                expiresAt: Date.now.addingTimeInterval(20 * 86400)
            )
        case "SWEET10":
            return Coupon(
                id: "coupon_sweet10",
                code: "SWEET10",
                title: "10% off up to ₹50 at Sri Krishna Sweets",
                discountType: .percentage,
                value: 10,
                minOrderAmount: 200,
                maxDiscountAmount: 50,
                shopId: "shop_sweets",
                expiresAt: Date.now.addingTimeInterval(25 * 86400)
            )
        default:
            return nil
        }
    }

    static var availableCoupons: [Coupon] {
        ["SAVE10", "FLAT50", "WELCOME20", "BIRYANI15", "SWEET10"].compactMap { coupon(forCode: $0) }
    }
}

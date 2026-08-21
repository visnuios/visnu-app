import UIKit

final class MainTabBarController: UITabBarController {

    private let cart = CartManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let home = UINavigationController(rootViewController: HomeViewController())
        let search = UINavigationController(rootViewController: SearchViewController())
        let orders = UINavigationController(rootViewController: OrdersViewController())
        let cartNav = UINavigationController(rootViewController: CartViewController())
        let profile = UINavigationController(rootViewController: ProfileViewController())

        home.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        search.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), selectedImage: UIImage(systemName: "magnifyingglass.circle.fill"))
        orders.tabBarItem = UITabBarItem(title: "Orders", image: UIImage(systemName: "list.bullet.rectangle"), selectedImage: UIImage(systemName: "list.bullet.rectangle.fill"))
        cartNav.tabBarItem = UITabBarItem(title: "Cart", image: UIImage(systemName: "cart"), selectedImage: UIImage(systemName: "cart.fill"))
        profile.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.circle"), selectedImage: UIImage(systemName: "person.circle.fill"))

        viewControllers = [home, search, orders, cartNav, profile]
        tabBar.tintColor = .systemOrange

        refreshCartBadge()
        NotificationCenter.default.addObserver(
            forName: .cartDidChange,
            object: cart,
            queue: .main
        ) { [weak self] _ in
            self?.refreshCartBadge()
        }
    }

    private func refreshCartBadge() {
        let count = cart.itemCount
        viewControllers?[3].tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
    }
}

import UIKit

enum SceneRouter {

    static func showMainApp() {
        setRoot(MainTabBarController())
    }

    static func showAuth() {
        CartManager.shared.clearCart()
        CheckoutSession.shared.reset()
        setRoot(UINavigationController(rootViewController: AuthViewController()))
    }

    private static func setRoot(_ viewController: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let window = scene.keyWindow else { return }
        window.rootViewController = viewController
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
}

final class AuthViewController: UIViewController {

    enum Mode {
        case login, register, forgot
    }

    private var mode: Mode = .login

    private let titleLabel = UILabel()
    private let nameField = UITextField()
    private let emailField = UITextField()
    private let phoneField = UITextField()
    private let passwordField = UITextField()
    private let primaryButton = PrimaryButton(title: "Login")
    private let switchModeButton = UIButton(type: .system)

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = DemoAuthService()) {
        self.authService = authService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        applyMode()
    }

    private func setupUI() {
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .center

        nameField.placeholder = "Full name"
        emailField.placeholder = "Email"
        phoneField.placeholder = "Phone number"
        passwordField.placeholder = "Password"
        [emailField, passwordField].forEach { $0.keyboardType = .emailAddress }
        phoneField.keyboardType = .phonePad
        passwordField.isSecureTextEntry = true
        [nameField, emailField, phoneField, passwordField].forEach {
            $0.borderStyle = .roundedRect
            $0.heightAnchor.constraint(equalToConstant: 46).isActive = true
        }

        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
        switchModeButton.addTarget(self, action: #selector(switchModeTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel, nameField, emailField, phoneField, passwordField, primaryButton, switchModeButton
        ])
        stack.axis = .vertical
        stack.spacing = 14
        stack.setCustomSpacing(24, after: titleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }

    private func applyMode() {
        nameField.isHidden = mode != .register
        phoneField.isHidden = mode != .register
        switch mode {
        case .login:
            titleLabel.text = "Welcome to rvfood 👋"
            primaryButton.setTitle("Login", for: .normal)
            switchModeButton.setTitle("New here? Create an account   ·   Forgot password?", for: .normal)
        case .register:
            titleLabel.text = "Create your account"
            primaryButton.setTitle("Register", for: .normal)
            switchModeButton.setTitle("Already have an account? Login", for: .normal)
        case .forgot:
            titleLabel.text = "Reset password"
            primaryButton.setTitle("Send Reset Link", for: .normal)
            switchModeButton.setTitle("Back to Login", for: .normal)
        }
    }

    @objc private func switchModeTapped() {
        switch mode {
        case .login:
            showActionSheetForAuthSwitch()
        case .register:
            mode = .login
        case .forgot:
            mode = .login
        }
        applyMode()
    }

    private func showActionSheetForAuthSwitch() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Create an account", style: .default) { [weak self] _ in
            self?.mode = .register
            self?.applyMode()
        })
        sheet.addAction(UIAlertAction(title: "Forgot password", style: .default) { [weak self] _ in
            self?.mode = .forgot
            self?.applyMode()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    @objc private func primaryTapped() {
        func value(_ field: UITextField) -> String {
            field.text?.trimmingCharacters(in: .whitespaces) ?? ""
        }
        primaryButton.isEnabled = false

        Task {
            do {
                switch mode {
                case .login:
                    _ = try await authService.login(email: value(emailField), password: value(passwordField))
                    SceneRouter.showMainApp()
                case .register:
                    _ = try await authService.register(
                        name: value(nameField),
                        email: value(emailField),
                        phone: value(phoneField),
                        password: value(passwordField)
                    )
                    SceneRouter.showMainApp()
                case .forgot:
                    let message = try await authService.forgotPassword(email: value(emailField))
                    let alert = UIAlertController(title: "Check your email", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                        self?.mode = .login
                        self?.applyMode()
                    })
                    present(alert, animated: true)
                }
            } catch {
                presentErrorAlert(error)
            }
            primaryButton.isEnabled = true
        }
    }
}

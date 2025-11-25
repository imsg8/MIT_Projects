//
//  LogoutViewController.swift
//  MyCal360
//
//  Created by Shivang Gulati on 23/11/25.
//

import UIKit
import CommonCrypto

extension String {
    /// SHA-256 hash of the string
    func sha256() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

class LogoutViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Auth Model + API
    struct LoginPayload: Encodable {
        let email: String
        let password: String
    }
    
    struct SignupPayload: Encodable {
        let email: String
        let password: String
        let full_name: String
    }

    enum AuthAPI {
        static let baseURL = "https://zjswnutnpopqqawyxujb.supabase.co"
        static let publishableKey = "sb_publishable_Tg8SFkKZ6zX_HIiHSC4LOA_TaUcq177"

        // MARK: - LOGIN
        static func login(email: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
            
            let safeEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
            let hashedPassword = password.sha256()
            let safeHashedPassword = hashedPassword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? hashedPassword
            
            let urlString =
            baseURL +
            "/rest/v1/users_sb?email=eq.\(safeEmail)&password=eq.\(safeHashedPassword)&is_active=eq.true&select=id,email,full_name"
            
            guard let url = URL(string: urlString) else {
                completion(.failure(URLError(.badURL)))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(publishableKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard
                    let http = response as? HTTPURLResponse,
                    (200...299).contains(http.statusCode)
                else {
                    let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
                    let err = NSError(
                        domain: "AuthAPI",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Login failed: \(body)"]
                    )
                    completion(.failure(err))
                    return
                }
                
                do {
                    let users = try JSONDecoder().decode([AuthResponse].self, from: data ?? Data())
                    
                    guard let user = users.first else {
                        let err = NSError(
                            domain: "AuthAPI",
                            code: 401,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid email or password"]
                        )
                        completion(.failure(err))
                        return
                    }
                    
                    // Update last_login
                    updateLastLogin(userId: user.user_id ?? "")
                    
                    // Save session in memory
                    AuthSession.shared.currentUser = user
                    
                    completion(.success(user))
                    
                } catch {
                    completion(.failure(error))
                }
                
            }.resume()
        }

        // MARK: - UPDATE LAST LOGIN
        static func updateLastLogin(userId: String) {
            guard let url = URL(string: baseURL + "/rest/v1/users_sb?id=eq.\(userId)") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue(publishableKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = [
                "last_login": ISO8601DateFormatter().string(from: Date())
            ]

            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request).resume()
        }

        // MARK: - SIGNUP
        static func signup(_ payload: SignupPayload, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let url = URL(string: baseURL + "/rest/v1/users_sb") else {
                completion(.failure(URLError(.badURL)))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(publishableKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
            
            // Hash the password before sending
            let hashedPassword = payload.password.sha256()
            let hashedPayload: [String: String] = [
                "email": payload.email,
                "password": hashedPassword,  // Store hashed password
                "full_name": payload.full_name
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: hashedPayload)
            } catch {
                completion(.failure(error))
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let http = response as? HTTPURLResponse else {
                    completion(.failure(URLError(.badServerResponse)))
                    return
                }
                
                guard http.statusCode == 201 else {
                    let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
                    let err = NSError(
                        domain: "AuthAPI",
                        code: http.statusCode,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Signup failed: \(body)"
                        ]
                    )
                    completion(.failure(err))
                    return
                }
                
                completion(.success(()))
            }
            .resume()
        }
    }


    // MARK: - UI Properties
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    private let logoImageView = UIImageView()
    private let welcomeLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Login fields
    private let loginEmailField = UITextField()
    private let loginPasswordField = UITextField()
    private var loginFieldsContainer: UIStackView!
    
    // Signup fields
    private let signupNameField = UITextField()
    private let signupEmailField = UITextField()
    private let signupPasswordField = UITextField()
    private let signupConfirmPasswordField = UITextField()
    private var signupFieldsContainer: UIStackView!
    
    private let actionButton = UIButton(type: .system)
    private let toggleModeButton = UIButton(type: .system)
    
    private var isLoginMode = true
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if SessionManager.shared.isSessionValid(),
               let userId = SessionManager.shared.getUserId() {
                
                print("✅ Already logged in, navigating to main app")
                
                FamilyStore.shared.configureForUser(id: userId, migrateLegacyIfPresent: false) { [weak self] result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            self?.navigateToMainApp()
                        case .failure(let error):
                            print("⚠️ FamilyStore config failed: \(error.localizedDescription)")
                        }
                    }
                }
                return
            }
        
        enableKeyboardDismissOnTap()
        setupKeyboardHandling(scrollView: scrollView)
        view.backgroundColor = .systemGroupedBackground
        setupScrollView()
        setupLogo()
        setupWelcomeText()
        setupFormFields()
        setupButtons()
        updateUIForMode()
    }

    // MARK: - Layout
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -40)
        ])
    }
    
    private func setupLogo() {
        logoImageView.image = UIImage(named: "logo_wb")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        
        stackView.addArrangedSubview(logoImageView)
        stackView.setCustomSpacing(24, after: logoImageView)
    }
    
    private func setupWelcomeText() {
        welcomeLabel.text = "Welcome Back"
        welcomeLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        welcomeLabel.textAlignment = .center
        
        subtitleLabel.text = "Sign in to continue tracking your calories"
        subtitleLabel.font = UIFont.systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        let textStack = UIStackView(arrangedSubviews: [welcomeLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 8
        
        stackView.addArrangedSubview(textStack)
        stackView.setCustomSpacing(32, after: textStack)
    }

    private func setupFormFields() {
        // LOGIN FIELDS CONTAINER
        loginFieldsContainer = UIStackView()
        loginFieldsContainer.axis = .vertical
        loginFieldsContainer.spacing = 16
        
        loginFieldsContainer.addArrangedSubview(makeLabeledField(
            label: "Email",
            placeholder: "you@example.com",
            textField: loginEmailField,
            type: .emailAddress,
            isSecure: false
        ))
        
        loginFieldsContainer.addArrangedSubview(makeLabeledField(
            label: "Password",
            placeholder: "Enter your password",
            textField: loginPasswordField,
            type: .password,
            isSecure: true
        ))
        
        // SIGNUP FIELDS CONTAINER
        signupFieldsContainer = UIStackView()
        signupFieldsContainer.axis = .vertical
        signupFieldsContainer.spacing = 16
        signupFieldsContainer.isHidden = true
        
        signupFieldsContainer.addArrangedSubview(makeLabeledField(
            label: "Full Name",
            placeholder: "Enter your full name",
            textField: signupNameField,
            type: .name,
            isSecure: false
        ))
        
        signupFieldsContainer.addArrangedSubview(makeLabeledField(
            label: "Email",
            placeholder: "you@example.com",
            textField: signupEmailField,
            type: .emailAddress,
            isSecure: false
        ))
        
        signupFieldsContainer.addArrangedSubview(makeLabeledField(
            label: "Password",
            placeholder: "Min 8 chars, alphanumeric",
            textField: signupPasswordField,
            type: .newPassword,
            isSecure: true
        ))
        
        signupFieldsContainer.addArrangedSubview(makeLabeledField(
            label: "Confirm Password",
            placeholder: "Re-enter your password",
            textField: signupConfirmPasswordField,
            type: .newPassword,
            isSecure: true
        ))
        
        stackView.addArrangedSubview(loginFieldsContainer)
        stackView.addArrangedSubview(signupFieldsContainer)
    }

    private func setupButtons() {
        // Action Button
        actionButton.setTitle("Sign In", for: .normal)
        actionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        actionButton.backgroundColor = .systemBlue
        actionButton.tintColor = .white
        actionButton.layer.cornerRadius = 12
        actionButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        actionButton.addTarget(self, action: #selector(handleAuthAction), for: .touchUpInside)
        
        stackView.addArrangedSubview(actionButton)
        stackView.setCustomSpacing(16, after: actionButton)
        
        // Divider
        let divider = makeDivider()
        stackView.addArrangedSubview(divider)
        stackView.setCustomSpacing(16, after: divider)
        
        // Toggle Mode Button
        toggleModeButton.setTitle("Don't have an account? Sign Up", for: .normal)
        toggleModeButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        toggleModeButton.setTitleColor(.systemBlue, for: .normal)
        toggleModeButton.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)
        
        stackView.addArrangedSubview(toggleModeButton)
    }

    // MARK: - Actions
    @objc private func handleAuthAction() {
        view.endEditing(true)
        
        if isLoginMode {
            handleLogin()
        } else {
            handleSignup()
        }
    }
    
    private func handleLogin() {
        let email = loginEmailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = loginPasswordField.text ?? ""
        
        guard !email.isEmpty, !password.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }
        
        guard isValidEmail(email) else {
            showAlert(title: "Error", message: "Please enter a valid email address.")
            return
        }
        
        performLogin(email: email, password: password)
    }
    
    private func handleSignup() {
        let name = signupNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = signupEmailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = signupPasswordField.text ?? ""
        let confirmPassword = signupConfirmPasswordField.text ?? ""
        
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }
        
        guard isValidEmail(email) else {
            showAlert(title: "Error", message: "Please enter a valid email address.")
            return
        }
        
        guard isValidPassword(password) else {
            showAlert(title: "Error", message: "Password must be at least 8 characters and contain both letters and numbers.")
            return
        }
        
        guard password == confirmPassword else {
            showAlert(title: "Error", message: "Passwords do not match.")
            return
        }
        
        performSignup(email: email, password: password, name: name)
    }

    private func performLogin(email: String, password: String) {
        actionButton.isEnabled = false
        actionButton.setTitle("Signing In...", for: .normal)
        
        AuthAPI.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                
                switch result {
                case .success(let response):
                    // Save user session
                    if let userId = response.user_id {
                        UserDefaults.standard.set(userId, forKey: "user_id")
                        UserDefaults.standard.set(email, forKey: "user_email")
                        UserDefaults.standard.set(response.full_name, forKey: "user_name")
                        UserDefaults.standard.set(Date(), forKey: "last_login_date")
                        
                        let fullName = response.full_name ?? "User"
                        
                        SessionManager.shared.saveSession(userId: userId)
                        AuthSession.shared.saveUser(response)
                        
                        // CRITICAL: Wait for FamilyStore configuration before navigating
                        FamilyStore.shared.configureForUser(
                            id: userId,
                            migrateLegacyIfPresent: true
                        ) { configResult in
                            DispatchQueue.main.async {
                                switch configResult {
                                case .success:
                                    print("✅ FamilyStore configured for user: \(userId)")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        self.actionButton.isEnabled = true
                                        self.actionButton.setTitle("Sign In", for: .normal)
                                        if FamilyStore.shared.members.isEmpty {
                                            self.presentGetStarted(fullName: fullName)
                                        } else {
                                            self.navigateToMainApp()
                                        }
                                    }
                                    
                                case .failure(let error):
                                    print("⚠️ FamilyStore configuration failed: \(error.localizedDescription)")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                                        self.actionButton.isEnabled = true
                                        self.actionButton.setTitle("Sign In", for: .normal)
                                        
                                        self.showAlert(
                                            title: "Warning",
                                            message: "Logged in, but some features may not work correctly."
                                        ) {
                                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                            if FamilyStore.shared.members.isEmpty {
                                                self.presentGetStarted(fullName: fullName)
                                            } else {
                                                self.navigateToMainApp()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        self.actionButton.isEnabled = true
                        self.actionButton.setTitle("Sign In", for: .normal)
                        self.showAlert(title: "Error", message: "Invalid user data received")
                    }
                    
                case .failure(let error):
                    self.actionButton.isEnabled = true
                    self.actionButton.setTitle("Sign In", for: .normal)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    self.showAlert(title: "Login Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func presentGetStarted(fullName: String) {
        let vc = GetStartedViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.prefilledName = fullName
        present(vc, animated: true)

        NotificationCenter.default.addObserver(
            forName: .init("GetStartedCompleted"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.navigateToMainApp()
        }
    }
    
    private func performSignup(email: String, password: String, name: String) {
        actionButton.isEnabled = false
        actionButton.setTitle("Creating Account...", for: .normal)
        
        let payload = SignupPayload(email: email, password: password, full_name: name)
        
        AuthAPI.signup(payload) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                
                self.actionButton.isEnabled = true
                self.actionButton.setTitle("Sign Up", for: .normal)
                
                switch result {
                case .success:
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    self.showAlert(title: "Success!", message: "Account created successfully. Please sign in.") {
                        self.isLoginMode = true
                        self.updateUIForMode()
                        self.loginEmailField.text = email
                        self.loginPasswordField.text = password
                    }
                    
                case .failure(let error):
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    self.showAlert(title: "Signup Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func toggleMode() {
        isLoginMode.toggle()
        updateUIForMode()
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateUIForMode() {
        if isLoginMode {
            welcomeLabel.text = "Welcome Back"
            subtitleLabel.text = "Sign in to continue tracking your calories"
            actionButton.setTitle("Sign In", for: .normal)
            toggleModeButton.setTitle("Don't have an account? Sign Up", for: .normal)
            loginFieldsContainer.isHidden = false
            signupFieldsContainer.isHidden = true
        } else {
            welcomeLabel.text = "Create Account"
            subtitleLabel.text = "Join MyCal360 and start your fitness journey"
            actionButton.setTitle("Sign Up", for: .normal)
            toggleModeButton.setTitle("Already have an account? Sign In", for: .normal)
            loginFieldsContainer.isHidden = true
            signupFieldsContainer.isHidden = false
        }
    }
    
    private func navigateToMainApp() {
        DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                self?.performSegue(withIdentifier: "HomeSegue", sender: self)
            }
    }

    // MARK: - UI Builders
    private func makeLabeledField(label: String, placeholder: String, textField: UITextField, type: UITextContentType, isSecure: Bool) -> UIView {
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.autocapitalizationType = .none
        textField.textContentType = type
        textField.isSecureTextEntry = isSecure
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.delegate = self
        
        if type == .name {
            textField.autocapitalizationType = .words
        }
        
        // Custom text field styling
        let fieldContainer = UIView()
        fieldContainer.backgroundColor = .secondarySystemGroupedBackground
        fieldContainer.layer.cornerRadius = 12
        fieldContainer.layer.borderWidth = 1
        fieldContainer.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        fieldContainer.addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: fieldContainer.topAnchor, constant: 14),
            textField.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -16),
            textField.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor, constant: -14),
            fieldContainer.heightAnchor.constraint(equalToConstant: 52)
        ])

        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        labelView.textColor = .label

        let stack = UIStackView(arrangedSubviews: [labelView, fieldContainer])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }
    
    private func makeDivider() -> UIView {
        let container = UIView()
        container.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        let leftLine = UIView()
        leftLine.backgroundColor = .separator
        leftLine.translatesAutoresizingMaskIntoConstraints = false
        
        let rightLine = UIView()
        rightLine.backgroundColor = .separator
        rightLine.translatesAutoresizingMaskIntoConstraints = false
        
        let orLabel = UILabel()
        orLabel.text = "OR"
        orLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        orLabel.textColor = .secondaryLabel
        orLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(leftLine)
        container.addSubview(orLabel)
        container.addSubview(rightLine)
        
        NSLayoutConstraint.activate([
            orLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            orLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            leftLine.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            leftLine.trailingAnchor.constraint(equalTo: orLabel.leadingAnchor, constant: -12),
            leftLine.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftLine.heightAnchor.constraint(equalToConstant: 1),
            
            rightLine.leadingAnchor.constraint(equalTo: orLabel.trailingAnchor, constant: 12),
            rightLine.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rightLine.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rightLine.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        return container
    }

    // MARK: - Validation Helpers
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters, contains letters and numbers
        guard password.count >= 8 else { return false }
        
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        
        return hasLetter && hasNumber
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(ac, animated: true)
    }
}


//
//  GetSupportView.swift
//  MyCal360
//
//  Created by Shivang Gulati on 07/11/25.
//

import UIKit

// MARK: - SupportPayload + API

struct SupportPayload: Encodable {
    let name: String
    let title: String
    let message: String
    let email: String
}

enum SupportAPI {
    static let baseURL = "https://zjswnutnpopqqawyxujb.supabase.co"
    static let publishableKey = "sb_publishable_Tg8SFkKZ6zX_HIiHSC4LOA_TaUcq177"

    static func submit(_ payload: SupportPayload, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/rest/v1/get_support") else {
            completion(.failure(URLError(.badURL)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse, http.statusCode == 201 else {
                let body = String(data: data ?? Data(), encoding: .utf8) ?? "No response"
                let err = NSError(domain: "SupportAPI", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed (\((response as? HTTPURLResponse)?.statusCode ?? 0)) \(body)"
                ])
                completion(.failure(err))
                return
            }

            completion(.success(()))
        }.resume()
    }
}

class GetSupportView: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var nameField = UITextField()
    private var emailField = UITextField()
    private var titleField = UITextField()
    private let messageTextView = UITextView()
    private let charLabel = UILabel()
    private let submitButton = UIButton(type: .system)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        setupKeyboardHandling(scrollView: scrollView)
        
        title = "Get Support"
        view.backgroundColor = .systemGroupedBackground

        setupScrollView()
        setupForm()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle"),
            style: .plain,
            target: self,
            action: #selector(closeView)
        )
        navigationItem.leftBarButtonItem?.tintColor = .systemBlue
    }

    // MARK: - Dismissal
    @objc private func closeView() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Scroll View Setup
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - Form Setup
    private func setupForm() {
        // Header text
        let header = UILabel()
        header.text = "Tell us what you need help with. We'll reply to the email you enter below (typically within 24–72 working hours)."
        header.font = UIFont.systemFont(ofSize: 14)
        header.textColor = .secondaryLabel
        header.numberOfLines = 0
        header.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(header)

        // Form card
        let formCard = makeFormCard()
        contentView.addSubview(formCard)
        formCard.translatesAutoresizingMaskIntoConstraints = false

        // Submit button
        submitButton.setTitle("Submit Request", for: .normal)
        submitButton.backgroundColor = .systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 10
        submitButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(submitButton)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            formCard.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 20),
            formCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            formCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            submitButton.topAnchor.constraint(equalTo: formCard.bottomAnchor, constant: 16),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            submitButton.heightAnchor.constraint(equalToConstant: 48),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    // MARK: - Form Card
    private func makeFormCard() -> UIView {
        let card = UICard()

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 26
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        // Name Field
        let nameInput = LabeledTextField(
            labelText: "Full Name *",
            placeholder: "Your name",
            keyboard: .default,
            borderColor: UIColor.label.withAlphaComponent(0.1),
            filled: true
        )
        self.nameField = nameInput.textField
        nameField.delegate = self
        nameField.textContentType = .name
        stack.addArrangedSubview(nameInput)

        // Email Field
        let emailInput = LabeledTextField(
            labelText: "Email *",
            placeholder: "you@example.com",
            keyboard: .emailAddress,
            borderColor: UIColor.label.withAlphaComponent(0.1),
            filled: true
        )
        self.emailField = emailInput.textField
        emailField.delegate = self
        emailField.textContentType = .emailAddress
        emailField.autocapitalizationType = .none
        stack.addArrangedSubview(emailInput)

        // Title Field
        let titleInput = LabeledTextField(
            labelText: "Title *",
            placeholder: "Short subject (e.g., Can't export PDF)",
            keyboard: .default,
            borderColor: UIColor.label.withAlphaComponent(0.1),
            filled: true
        )
        self.titleField = titleInput.textField
        titleField.delegate = self
        titleField.textContentType = .nickname
        titleField.autocapitalizationType = .sentences
        stack.addArrangedSubview(titleInput)

        // Message Field
        let messageLabel = makeSectionHeader("Message *")

        messageTextView.delegate = self
        messageTextView.font = UIFont.systemFont(ofSize: 15)
        messageTextView.backgroundColor = .clear
        messageTextView.layer.borderWidth = 1
        messageTextView.layer.cornerRadius = 10
        messageTextView.layer.borderColor = UIColor.label.withAlphaComponent(0.1).cgColor
        messageTextView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        messageTextView.heightAnchor.constraint(equalToConstant: 140).isActive = true

        charLabel.text = "Minimum 10 characters."
        charLabel.font = UIFont.systemFont(ofSize: 12)
        charLabel.textColor = .secondaryLabel

        let msgStack = UIStackView(arrangedSubviews: [messageLabel, messageTextView, charLabel])
        msgStack.axis = .vertical
        msgStack.spacing = 6
        stack.addArrangedSubview(msgStack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.layoutMarginsGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.layoutMarginsGuide.bottomAnchor)
        ])

        return card
    }

    // MARK: - Submission
    @objc private func handleSubmit() {
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let message = messageTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              name.count >= 2, title.count >= 3, message.count >= 10, isValidEmail(email)
        else {
            showAlert(title: "Error", message: "Please fill all required fields correctly.")
            return
        }

        submitButton.isEnabled = false
        submitButton.setTitle("Submitting…", for: .normal)

        // Compose message with context info
        let device = UIDevice.current.model
        let ios = UIDevice.current.systemVersion
        let appV = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let composedMessage = """
        Device: \(device), iOS \(ios)
        App: \(appV) (\(build))
        ---
        \(message)
        """

        let payload = SupportPayload(name: name, title: title, message: composedMessage, email: email)

        SupportAPI.submit(payload) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.submitButton.isEnabled = true
                self.submitButton.setTitle("Submit Request", for: .normal)

                switch result {
                case .success:
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    self.showAlert(title: "Request Submitted ✅",
                                   message: "We'll reply to you at your email.")
                    self.resetForm()
                case .failure(let error):
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    self.showAlert(title: "Failed to Submit", message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - UI Builders
    private func makeSectionHeader(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private func resetForm() {
        nameField.text = ""
        emailField.text = ""
        titleField.text = ""
        messageTextView.text = ""
    }

    private func isValidEmail(_ s: String) -> Bool {
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: s)
    }
}

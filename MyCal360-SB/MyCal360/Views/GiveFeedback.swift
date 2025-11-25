//
//  giveFeedback.swift
//  MyCal360
//
//  Created by Shivang Gulati on 07/11/25.
//

import UIKit

class GiveFeedback: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    // MARK: - Feedback Model + API
    struct FeedbackPayload: Encodable {
        let message: String
        let type: String
        let contact_email: String?
        let contact_phone: String?
        let name: String?
    }

    enum FeedbackAPI {
        static let baseURL = "https://zjswnutnpopqqawyxujb.supabase.co"
        static let publishableKey = "sb_publishable_Tg8SFkKZ6zX_HIiHSC4LOA_TaUcq177"

        static func submit(_ payload: FeedbackPayload, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let url = URL(string: baseURL + "/rest/v1/give_feedback") else {
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
                    let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
                    let err = NSError(domain: "FeedbackAPI", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Server error: \(body)"
                    ])
                    completion(.failure(err))
                    return
                }

                completion(.success(()))
            }.resume()
        }
    }

    // MARK: - UI Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let generalFeedbackButton = UIButton(type: .system)
    private let requestFeatureButton = UIButton(type: .system)
    private let reportBugButton = UIButton(type: .system)

    private var nameField = UITextField()
    private var emailField = UITextField()
    private var phoneCodeField = UITextField()
    private var phoneField = UITextField()
    private let messageTextView = UITextView()

    private let charLimitLabel = UILabel()
    private let submitButton = UIButton(type: .system)

    private var selectedCategory: String = "GeneralFeedback"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        setupKeyboardHandling(scrollView: scrollView)
        title = "Give Feedback"
        view.backgroundColor = .systemGroupedBackground

        setupScrollView()
        setupFormFields()
        
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
    private func setupFormFields() {
        // Intro text
        let intro = makeIntro(
            title: "We'd love your feedback",
            text: "Tell us what's working, what's confusing, or what you'd like next. Your message helps us make MyCal360 better."
        )
        contentView.addSubview(intro)
        intro.translatesAutoresizingMaskIntoConstraints = false

        // Category selection card
        let categoryCard = makeCategoryCard()
        contentView.addSubview(categoryCard)
        categoryCard.translatesAutoresizingMaskIntoConstraints = false

        // Form card with all inputs
        let formCard = makeFormCard()
        contentView.addSubview(formCard)
        formCard.translatesAutoresizingMaskIntoConstraints = false

        // Submit button
        submitButton.setTitle("Submit Feedback", for: .normal)
        submitButton.backgroundColor = .systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 10
        submitButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(submitButton)

        NSLayoutConstraint.activate([
            intro.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            intro.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            intro.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            categoryCard.topAnchor.constraint(equalTo: intro.bottomAnchor, constant: 20),
            categoryCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            categoryCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            formCard.topAnchor.constraint(equalTo: categoryCard.bottomAnchor, constant: 16),
            formCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            formCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            submitButton.topAnchor.constraint(equalTo: formCard.bottomAnchor, constant: 16),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            submitButton.heightAnchor.constraint(equalToConstant: 48),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }

    // MARK: - Category Card
    private func makeCategoryCard() -> UIView {
        let card = UICard()

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        let categoryLabel = makeSectionHeader("Category")
        stack.addArrangedSubview(categoryLabel)

        stack.addArrangedSubview(makeSpacer(height: 6))

        // Configure buttons
        configureSelectionButton(generalFeedbackButton,
                                title: "General Feedback",
                                subtitle: "Share your thoughts or suggestions",
                                isFirst: true,
                                isLast: false)
        configureSelectionButton(requestFeatureButton,
                                title: "Request Feature",
                                subtitle: "Tell us what you'd like to see",
                                isFirst: false,
                                isLast: false)
        configureSelectionButton(reportBugButton,
                                title: "Report a Bug",
                                subtitle: "Help us fix issues you've found",
                                isFirst: false,
                                isLast: true)

        generalFeedbackButton.addTarget(self, action: #selector(selectGeneralFeedback), for: .touchUpInside)
        requestFeatureButton.addTarget(self, action: #selector(selectRequestFeature), for: .touchUpInside)
        reportBugButton.addTarget(self, action: #selector(selectReportBug), for: .touchUpInside)

        let buttonContainer = UIStackView(arrangedSubviews: [
            generalFeedbackButton,
            makeDivider(),
            requestFeatureButton,
            makeDivider(),
            reportBugButton
        ])
        buttonContainer.axis = .vertical
        buttonContainer.spacing = 0
        buttonContainer.backgroundColor = .secondarySystemBackground
        buttonContainer.layer.cornerRadius = 10
        buttonContainer.clipsToBounds = true

        stack.addArrangedSubview(buttonContainer)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.layoutMarginsGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.layoutMarginsGuide.bottomAnchor)
        ])

        // Select first option by default
        updateSelectionState()

        return card
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
            labelText: "Full Name (optional)",
            placeholder: "Your full name",
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
            labelText: "Email (optional)",
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

        // Phone Fields
        let phoneLabel = makeSectionHeader("Phone (optional)")
        
        let phoneStack = UIStackView()
        phoneStack.axis = .horizontal
        phoneStack.spacing = 8

        phoneCodeField.placeholder = "+91"
        phoneCodeField.text = "+91"
        phoneCodeField.keyboardType = .numberPad
        phoneCodeField.borderStyle = .roundedRect
        phoneCodeField.layer.cornerRadius = 10
        phoneCodeField.widthAnchor.constraint(equalToConstant: 70).isActive = true

        phoneField.placeholder = "Phone number"
        phoneField.keyboardType = .numberPad
        phoneField.borderStyle = .roundedRect
        phoneField.layer.cornerRadius = 10

        phoneStack.addArrangedSubview(phoneCodeField)
        phoneStack.addArrangedSubview(phoneField)

        let phoneContainer = UIStackView(arrangedSubviews: [phoneLabel, phoneStack])
        phoneContainer.axis = .vertical
        phoneContainer.spacing = 6

        stack.addArrangedSubview(phoneContainer)

        // Message Field
        let messageLabel = makeSectionHeader("Message")

        messageTextView.delegate = self
        messageTextView.font = UIFont.systemFont(ofSize: 15)
        messageTextView.layer.cornerRadius = 10
        messageTextView.layer.borderWidth = 1
        messageTextView.layer.borderColor = UIColor.label.withAlphaComponent(0.1).cgColor
        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        messageTextView.heightAnchor.constraint(equalToConstant: 140).isActive = true

        charLimitLabel.text = "Minimum 10 characters"
        charLimitLabel.font = UIFont.systemFont(ofSize: 12)
        charLimitLabel.textColor = .secondaryLabel

        let msgStack = UIStackView(arrangedSubviews: [messageLabel, messageTextView, charLimitLabel])
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

    // MARK: - Button Configuration
    private func configureSelectionButton(_ button: UIButton, title: String, subtitle: String, isFirst: Bool, isLast: Bool) {
        button.contentHorizontalAlignment = .leading
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        let radioView = UIView()
        radioView.translatesAutoresizingMaskIntoConstraints = false
        radioView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        radioView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        radioView.layer.cornerRadius = 10
        radioView.layer.borderWidth = 2
        radioView.layer.borderColor = UIColor.systemGray3.cgColor
        radioView.backgroundColor = .clear
        radioView.tag = 999 // Tag to find it later

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        stack.addArrangedSubview(radioView)
        stack.addArrangedSubview(textStack)

        button.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12)
        ])
    }

    // MARK: - Selection Handlers
    @objc private func selectGeneralFeedback() {
        selectedCategory = "GeneralFeedback"
        updateSelectionState()
    }

    @objc private func selectRequestFeature() {
        selectedCategory = "RequestAFeature"
        updateSelectionState()
    }

    @objc private func selectReportBug() {
        selectedCategory = "ReportABug"
        updateSelectionState()
    }

    private func updateSelectionState() {
        updateButtonSelection(generalFeedbackButton, isSelected: selectedCategory == "GeneralFeedback")
        updateButtonSelection(requestFeatureButton, isSelected: selectedCategory == "RequestAFeature")
        updateButtonSelection(reportBugButton, isSelected: selectedCategory == "ReportABug")
    }

    private func updateButtonSelection(_ button: UIButton, isSelected: Bool) {
        if let radioView = button.viewWithTag(999) {
            if isSelected {
                radioView.layer.borderColor = UIColor.systemBlue.cgColor
                radioView.layer.borderWidth = 6
                radioView.backgroundColor = .white
            } else {
                radioView.layer.borderColor = UIColor.systemGray3.cgColor
                radioView.layer.borderWidth = 2
                radioView.backgroundColor = .clear
            }
        }
    }

    // MARK: - Submit Handler
    @objc private func handleSubmit() {
        let message = messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard message.count >= 10 else {
            showAlert(title: "Error", message: "Message must be at least 10 characters long.")
            return
        }

        submitButton.isEnabled = false
        submitButton.setTitle("Submitting...", for: .normal)

        let payload = FeedbackPayload(
            message: message,
            type: selectedCategory,
            contact_email: emailField.text?.isEmpty == true ? nil : emailField.text,
            contact_phone: phoneField.text?.isEmpty == true ? nil : phoneField.text,
            name: nameField.text?.isEmpty == true ? nil : nameField.text
        )

        FeedbackAPI.submit(payload) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                self.submitButton.isEnabled = true
                self.submitButton.setTitle("Submit Feedback", for: .normal)

                switch result {
                case .success:
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    self.showAlert(title: "Thank You!", message: "Your feedback was submitted successfully.")
                    self.resetForm()
                case .failure(let error):
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    self.showAlert(title: "Error", message: "Failed to submit feedback.\n\(error.localizedDescription)")
                }
            }
        }
    }

    private func resetForm() {
        nameField.text = ""
        emailField.text = ""
        phoneField.text = ""
        messageTextView.text = ""
        submitButton.isEnabled = true
        submitButton.setTitle("Submit Feedback", for: .normal)
    }

    // MARK: - UI Builders
    private func makeIntro(title: String, text: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)

        let bodyLabel = UILabel()
        bodyLabel.text = text
        bodyLabel.numberOfLines = 0
        bodyLabel.font = UIFont.systemFont(ofSize: 15)
        bodyLabel.textColor = .secondaryLabel

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(bodyLabel)
        return stack
    }

    private func makeSectionHeader(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return divider
    }

    private func makeSpacer(height: CGFloat) -> UIView {
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        return spacer
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

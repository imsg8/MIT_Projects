//
//  LLMViewController.swift
//  MyCal360
//
//  Created by Shivang Gulati on 25/11/25.
//

import UIKit

// MARK: - LLM Client (holds key & endpoint)
struct LLMClient {
    static var apiKey: String = "AIzaSyDH_ojFcsez22pXWlcCyObEe8U6KPErBjc"
    static var endpoint: String =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(LLMClient.apiKey)"
}

// MARK: - Message Model
fileprivate enum MessageRole: String {
    case user, assistant, system
}

fileprivate struct ChatMessage {
    let id: UUID
    let role: MessageRole
    let text: String?
    let image: UIImage?
    let createdAt: Date
    // convenience
    init(role: MessageRole, text: String? = nil, image: UIImage? = nil) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.image = image
        self.createdAt = Date()
    }
}

// MARK: - Message Cell
fileprivate class MessageCell: UITableViewCell {
    static let reuseId = "MessageCell2"

        private let bubble = ChatBubbleView()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            backgroundColor = .clear
            selectionStyle = .none

            contentView.addSubview(bubble)
            bubble.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                bubble.topAnchor.constraint(equalTo: contentView.topAnchor),
                bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
                bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            ])
        }

        required init?(coder: NSCoder) { fatalError() }

        func configure(with msg: ChatMessage) {
            bubble.configure(role: msg.role, text: msg.text, image: msg.image)
        }
}

// MARK: - LLMViewController
final class LLMViewController: UIViewController {

    // Close snippet when presented modally
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "MyCal360-AI"

        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(closeTapped)
            )
        }
        enableKeyboardDismissOnTap()
        setupViews()
        configureActions()
        configureKeyboardHandling()
    }

    @objc private func closeTapped() {
        messages.removeAll()
        navigationController?.popViewController(animated: true)
    }

    // UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputContainer = UIView()
    private let attachButton = UIButton(type: .system)
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var inputBottomConstraint: NSLayoutConstraint?

    // chat history (in-memory only)
    private var messages: [ChatMessage] = []

    // Picker
    private var imagePicker: UIImagePickerController?

    // Activity
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Setup
    private func setupViews() {
        // Table
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.reuseId)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .interactive
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        view.addSubview(tableView)

        // Input container
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)
        inputContainer.backgroundColor = UIColor.systemGroupedBackground
        inputContainer.layer.borderColor = UIColor.label.withAlphaComponent(0.06).cgColor
        inputContainer.layer.borderWidth = 0.5

        attachButton.setImage(UIImage(systemName: "paperclip"), for: .normal)
        attachButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(attachButton)

        textField.placeholder = "Type a message..."
        textField.layer.cornerRadius = 12
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.backgroundColor = UIColor.secondarySystemGroupedBackground
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.returnKeyType = .send
        inputContainer.addSubview(textField)

        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(sendButton)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(activityIndicator)

        // Constraints
        inputBottomConstraint = inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottomConstraint!,

            attachButton.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            attachButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            attachButton.widthAnchor.constraint(equalToConstant: 36),
            attachButton.heightAnchor.constraint(equalToConstant: 36),

            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 64),

            textField.leadingAnchor.constraint(equalTo: attachButton.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            textField.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -8),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            activityIndicator.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            activityIndicator.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
        textField.delegate = self

        // Initially empty placeholder system message
        messages = []
    }

    private func configureActions() {
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)
    }

    private func configureKeyboardHandling() {
        // Use your helper to manage keyboard and automatic scrolling
        setupKeyboardHandling(scrollView: tableView)
        // Also observe keyboard notifications here to adjust input bottom anchor
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }

    @objc private func keyboardWillChangeFrame(_ n: Notification) {
        guard let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = n.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let kbTop = frame.origin.y
        let safeAreaBottom = view.safeAreaInsets.bottom
        let bottomInset = max(0, view.bounds.height - kbTop - safeAreaBottom)

        inputBottomConstraint?.constant = -bottomInset

        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: UIView.AnimationOptions(rawValue: curve << 16)) {
            self.view.layoutIfNeeded()
            self.scrollToBottom(animated: false)
        }
    }

    // MARK: - Actions
    @objc private func attachTapped() {
        let alert = UIAlertController(title: "Attach", message: "Choose image source", preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                self.showImagePicker(.camera)
            })
        }
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.showImagePicker(.photoLibrary)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    private func showImagePicker(_ source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        imagePicker = picker
        present(picker, animated: true)
    }

    @objc private func sendTapped() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }

        // Append user message locally
        let userMessage = ChatMessage(role: .user, text: text, image: nil)
        appendMessageAndReload(userMessage)
        textField.text = ""
        scrollToBottom(animated: true)

        // send to API
        sendToAPI(messages: [userMessage], attachments: [])
    }

    // For image-only send (when user selects image and optionally has text)
    private func sendImageMessage(image: UIImage, withText text: String? = nil) {
        // Append local user message with image
        let msg = ChatMessage(role: .user, text: text, image: image)
        appendMessageAndReload(msg)
        scrollToBottom(animated: true)

        // send to API with both text and image
        sendToAPI(messages: [msg], attachments: [image])
    }

    private func appendMessageAndReload(_ message: ChatMessage) {
        messages.append(message)
        tableView.reloadData()
    }

    private func scrollToBottom(animated: Bool) {
        guard messages.count > 0 else { return }
        let last = messages.count - 1
        let idx = IndexPath(row: last, section: 0)
        tableView.scrollToRow(at: idx, at: .bottom, animated: animated)
    }

    // MARK: - Networking / API
    private func sendToAPI(messages: [ChatMessage], attachments: [UIImage]) {
        guard let url = URL(string: LLMClient.endpoint) else { return }

        activityIndicator.startAnimating()
        sendButton.isEnabled = false

        // Build Gemini "contents"
        var parts: [[String: Any]] = []

        // Include message text
        for m in messages {
            if let t = m.text, !t.isEmpty {
                parts.append([
                    "text": t
                ])
            }
        }

        // Include images
        for img in attachments {
            if let jpg = img.jpegData(compressionQuality: 0.85) {
                parts.append([
                    "inline_data": [
                        "mime_type": "image/jpeg",
                        "data": jpg.base64EncodedString()
                    ]
                ])
            }
        }

        let payload: [String: Any] = [
            "system_instruction": [
                "parts": [
                    [
                        "text": """
        You are MyCal360 LLM Assistant.

        STRICT RULES:
        **YOU NEED TO REPLY TO EVERY TEXTS NO MATTER WHAT, SAY SOMETHING, ANYTHING AT ALL TIMES, NO BLANK RESPONSE**
        1. NEVER use *, **, bold, italics, bullet points, markdown, emojis, or symbols.
        2. ALWAYS reply in plain text only.
        3. NEVER output formatted lists. If needed, separate points with new lines only.
        4. Do NOT answer anything outside fitness, nutrition, exercise, training, health calculations, TDEE, BMR, macros, calories, diet plan and everything related to well being health and fitness.
        5. If the user asks anything unrelated, respond exactly with:
        MyCal360-AI can only answer questions about fitness, health, nutrition and exercise.
        """
                    ]
                ]
            ],

            "contents": [
                [
                    "role": "user",
                    "parts": parts
                ]
            ]
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            finishSendingWithError(error)
            return
        }

        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.sendButton.isEnabled = true
            }

            if let err { self.finishSendingWithError(err); return }
            guard let data = data else { self.finishSendingWithError(NSError(domain: "", code: -1)); return }

            // Parse Gemini response
            let replyText = self.parseGeminiResponse(data)
            let reply = ChatMessage(role: .assistant, text: replyText, image: nil)

            DispatchQueue.main.async {
                self.appendMessageAndReload(reply)
                self.scrollToBottom(animated: true)
            }
        }.resume()
    }
    
    private func parseGeminiResponse(_ data: Data) -> String {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]]
        else {
            return "No valid response."
        }

        // Look for first text part
        for p in parts {
            if let t = p["text"] as? String {
                return t.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // fallback if nothing found
        return "No valid text in response."
    }


    private func finishSendingWithError(_ error: Error) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.sendButton.isEnabled = true
            let errMsg = ChatMessage(role: .assistant, text: "Error: \(error.localizedDescription)", image: nil)
            self.appendMessageAndReload(errMsg)
            self.scrollToBottom(animated: true)
        }
    }

    // MARK: - Clean up (clear history when view disappears)
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITableView DataSource / Delegate
extension LLMViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let m = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.reuseId, for: indexPath) as! MessageCell
        cell.configure(with: m)
        return cell
    }
}

// MARK: - UITextField Delegate (send on Return)
extension LLMViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }
}

// MARK: - UIImagePickerController Delegate
extension LLMViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        imagePicker = nil
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        imagePicker = nil

        // Prefer edited image, then original
        var chosen: UIImage?
        if let ed = info[.editedImage] as? UIImage { chosen = ed }
        else if let orig = info[.originalImage] as? UIImage { chosen = orig }

        guard let img = chosen else { return }

        // Ask user for optional caption before sending
        let captionAlert = UIAlertController(title: "Attach image", message: "Add optional message to send with the image", preferredStyle: .alert)
        captionAlert.addTextField { tf in
            tf.placeholder = "Say something about the image..."
        }
        captionAlert.addAction(UIAlertAction(title: "Send", style: .default) { _ in
            let text = captionAlert.textFields?.first?.text
            self.sendImageMessage(image: img, withText: text)
        })
        captionAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(captionAlert, animated: true)
    }
}

final class ChatBubbleView: UIView {

    private let bubble = UIView()
    private let messageLabel = UILabel()
    private let imageView = UIImageView()

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var imageHeight: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        bubble.layer.cornerRadius = 16
        bubble.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bubble)
        bubble.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.72).isActive = true

        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(messageLabel)

        imageView.layer.cornerRadius = 12
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(imageView)

        // === Important: store height constraint for dynamic collapse ===
        imageHeight = imageView.heightAnchor.constraint(equalToConstant: 0)
        imageHeight.isActive = true

        leadingConstraint = bubble.leadingAnchor.constraint(equalTo: leadingAnchor)
        trailingConstraint = bubble.trailingAnchor.constraint(equalTo: trailingAnchor)

        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,

            bubble.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            bubble.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            messageLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),

            imageView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: bubble.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: bubble.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    fileprivate func configure(role: MessageRole, text: String?, image: UIImage?) {

        if role == .user {
            trailingConstraint.isActive = true
            leadingConstraint.isActive = false
            bubble.backgroundColor = UIColor(hex: "f27040")
            messageLabel.textColor = .white
        } else {
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
            bubble.backgroundColor = UIColor.secondarySystemBackground
            messageLabel.textColor = .label
        }

        // Text
        messageLabel.text = text

        // Image handling (MAIN FIX)
        if let img = image {
            imageView.image = img
            imageView.isHidden = false
            imageHeight.constant = 160   // show image
        } else {
            imageView.isHidden = true
            imageHeight.constant = 0     // collapse
        }
    }
}


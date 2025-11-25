//
//  UIKitEquivalentHelpers.swift
//  MyCal360
//
//  Created by Shivang Gulati on 10/11/25.
//

import UIKit
import Foundation

struct AuthResponse: Codable {
    let user_id: String?
    let email: String?
    let full_name: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case user_id = "id"
        case email = "email"
        case full_name = "full_name"
        case message = "message"
    }
}

final class AuthSession {
    static let shared = AuthSession()
    var currentUser: AuthResponse?
    private init() {}

    private let userKey = "auth_user"

    func saveUser(_ user: AuthResponse) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
        currentUser = user
    }

    func loadUser() {
        guard let data = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(AuthResponse.self, from: data)
        else { return }

        currentUser = user
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: userKey)
        currentUser = nil
    }
}


// MARK: - Hide Keyboard
extension UIViewController {
    func hideKeyboard() {
        view.endEditing(true)
    }
}

extension Notification.Name {
    static let familyStoreDidLoad = Notification.Name("familyStoreDidLoad")
    static let familyStoreDidChange = Notification.Name("familyStoreDidChange") // for CRUD changes
}

// Associated object keys for storing scrollView reference
private struct AssociatedKeys {
    static var scrollView = "scrollView"
}

extension UIViewController {
    
    /// Call this in viewDidLoad() to enable automatic scrolling when keyboard appears
    func setupKeyboardHandling(scrollView: UIScrollView) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        // Store the scrollView reference for later use
        objc_setAssociatedObject(self, &AssociatedKeys.scrollView, scrollView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let scrollView = objc_getAssociatedObject(self, &AssociatedKeys.scrollView) as? UIScrollView,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        
        let keyboardHeight = keyboardFrame.height
        
        // Adjust content inset to make room for keyboard
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        
        // Find the active text field or text view
        var activeField: UIView?
        
        if let textField = findFirstResponder(in: view) as? UITextField {
            activeField = textField
        } else if let textView = findFirstResponder(in: view) as? UITextView {
            activeField = textView
        }
        
        // Scroll to make the active field visible above the keyboard
        if let field = activeField {
            // Convert field's frame to scrollView's coordinate system
            let fieldFrame = field.convert(field.bounds, to: scrollView)
            
            // Calculate the visible area (scrollView height minus keyboard height)
            let visibleHeight = scrollView.frame.height - keyboardHeight
            
            // Position field just above keyboard with a small margin (20-30 points)
            let marginAboveKeyboard: CGFloat = 40
            let fieldBottom = fieldFrame.origin.y + fieldFrame.height
            let targetY = fieldBottom - visibleHeight + marginAboveKeyboard
            
            // Make sure we don't scroll past the content or go negative
            let maxOffset = max(0, scrollView.contentSize.height + keyboardHeight - scrollView.frame.height)
            let scrollOffset = min(max(0, targetY), maxOffset)
            
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16)) {
                scrollView.setContentOffset(CGPoint(x: 0, y: scrollOffset), animated: false)
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        guard let scrollView = objc_getAssociatedObject(self, &AssociatedKeys.scrollView) as? UIScrollView,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16)) {
            scrollView.contentInset = .zero
            scrollView.scrollIndicatorInsets = .zero
        }
    }
    
    // Helper to find the first responder (active text field/view)
    private func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder {
            return view
        }
        
        for subview in view.subviews {
            if let firstResponder = findFirstResponder(in: subview) {
                return firstResponder
            }
        }
        
        return nil
    }
    
    // Remove observers when view controller is deallocated
    func removeKeyboardHandling() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

// MARK: - UIColor(hex:)
extension UIColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let a, r, g, b: UInt64

        switch hexString.count {
        case 3:
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255,0,0,0)
        }

        self.init(red: CGFloat(r)/255,
                  green: CGFloat(g)/255,
                  blue: CGFloat(b)/255,
                  alpha: CGFloat(a)/255)
    }
}


// MARK: - Base Card (Matches SwiftUI Card)
class UICard: UIView {
    init(padding: CGFloat = 14) {
        super.init(frame: .zero)
        backgroundColor = UIColor.secondarySystemGroupedBackground
        layer.cornerRadius = 14
        layer.borderWidth = 0.8
        layer.borderColor = UIColor.label.withAlphaComponent(0.12).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 2)
        translatesAutoresizingMaskIntoConstraints = false
        layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }

    required init?(coder: NSCoder) { fatalError() }
}


// MARK: - MenuCard (UIKit)
class UIMenuCard: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.secondarySystemGroupedBackground
        layer.cornerRadius = 14
        layer.borderWidth = 0.8
        layer.borderColor = UIColor.label.withAlphaComponent(0.12).cgColor
        translatesAutoresizingMaskIntoConstraints = false
    }
    required init?(coder: NSCoder) { fatalError() }
}


// MARK: - Gradient Card (UIKit version of SwiftUI CardView)
class GradientCardView: UIView {

    let iconView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let arrowView = UIImageView()

    init(title: String, subtitle: String, systemImage: String, colors: [UIColor]) {
        super.init(frame: .zero)

        // Gradient
        let gradient = CAGradientLayer()
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = 20
        layer.insertSublayer(gradient, at: 0)

        layer.shadowOpacity = 0.18
        layer.shadowRadius = 6
        layer.shadowOffset = .init(width: 0, height: 3)

        // Icon
        iconView.image = UIImage(systemName: systemImage)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        iconView.layer.cornerRadius = 15
        iconView.clipsToBounds = true

        // Labels
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 18)

        subtitleLabel.text = subtitle
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.numberOfLines = 2

        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = UIColor.white.withAlphaComponent(0.8)

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 3

        let hstack = UIStackView(arrangedSubviews: [iconView, stack, arrowView])
        hstack.alignment = .center
        hstack.spacing = 16

        addSubview(hstack)
        hstack.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hstack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hstack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            hstack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            hstack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.heightAnchor.constraint(equalToConstant: 60),
        ])

        // Resize gradient when bounds change
        func layoutSubviews() {
            super.layoutSubviews()
            gradient.frame = bounds
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}


// MARK: - FancyNumberField (UIKit)
class FancyNumberField: UIView, UITextFieldDelegate {

    enum Allowance { case integer, decimal }

    let titleLabel = UILabel()
    let iconView = UIImageView()
    let textField = UITextField()
    let unitLabel = UILabel()

    var allowed: Allowance = .decimal

    init(title: String, icon: String, unit: String, allowed: Allowance = .decimal) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        self.allowed = allowed

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = .black

        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 18).isActive = true

        textField.keyboardType = allowed == .integer ? .numberPad : .decimalPad
        textField.placeholder = placeholder(for: title)
        textField.delegate = self

        // Capsule unit
        unitLabel.text = unit
        unitLabel.font = .systemFont(ofSize: 11)
        unitLabel.textColor = .secondaryLabel
        unitLabel.backgroundColor = .clear
        unitLabel.layer.cornerRadius = 0
        unitLabel.clipsToBounds = false
        unitLabel.setContentHuggingPriority(.required, for: .horizontal)
        unitLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let hstack = UIStackView(arrangedSubviews: [iconView, textField, unitLabel])
        hstack.spacing = 10
        hstack.alignment = .center

        let container = UIView()
        container.backgroundColor = UIColor.secondarySystemGroupedBackground
        container.layer.cornerRadius = 14
        container.layer.borderWidth = 1.5
        container.layer.borderColor = UIColor.label.withAlphaComponent(0.12).cgColor

        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        addSubview(container)
        container.addSubview(hstack)

        hstack.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            container.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            hstack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            hstack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            hstack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            hstack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Filtering logic
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let allowedSet = "0123456789"
        if allowed == .integer {
            return string.rangeOfCharacter(from: CharacterSet(charactersIn: allowedSet).inverted) == nil
        }

        if allowed == .decimal {
            let current = (textField.text ?? "") as NSString
            let newString = current.replacingCharacters(in: range, with: string)

            let regex = "^[0-9]*((\\.|,)[0-9]*)?$"
            return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: newString)
        }
        return true
    }

    private func placeholder(for title: String) -> String {
        switch title.lowercased() {
        case "age": return "e.g. 28"
        case "height": return "e.g. 172"
        case "weight": return "e.g. 68.5"
        case _ where title.lowercased().contains("body fat"): return "e.g. 18"
        default: return "Enter value"
        }
    }
}


// MARK: - LabeledTextField (UIKit)
class LabeledTextField: UIView {

    let label = UILabel()
    let textField = UITextField()

    init(labelText: String,
         placeholder: String,
         keyboard: UIKeyboardType = .default,
         borderColor: UIColor = UIColor.label.withAlphaComponent(0.1),
         filled: Bool = true) {

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        label.text = labelText
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabel

        textField.placeholder = placeholder
        textField.keyboardType = keyboard
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none

        let container = UIView()
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = borderColor.cgColor
        if filled {
            container.backgroundColor = UIColor.secondarySystemGroupedBackground
        }

        let inset = UIStackView(arrangedSubviews: [textField])
        inset.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        inset.isLayoutMarginsRelativeArrangement = true

        addSubview(label)
        addSubview(container)
        container.addSubview(inset)

        label.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        inset.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),

            container.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 6),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            inset.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            inset.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            inset.topAnchor.constraint(equalTo: container.topAnchor),
            inset.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

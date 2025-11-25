//
//  MenuView.swift
//  MyCal360
//
//  Created by Shivang Gulati on 07/11/25.
//

import UIKit

class MenuView: UIViewController {
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let greeting = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Menu"
        view.backgroundColor = .systemGroupedBackground
        setupNavigationBar()
        setupScrollView()
        setupMenuSections()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let fullName = AuthSession.shared.currentUser?.full_name ?? "User"
        let firstName = fullName.components(separatedBy: " ").first ?? fullName
        print(firstName)
        greeting.text = "Hi \(firstName)"
    }

    @objc private func closeMenu() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Setup Navigation
    private func setupNavigationBar() {
        navigationItem.title = "Menu"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle"),
            style: .plain,
            target: self,
            action: #selector(closeMenu)
        )
        navigationItem.leftBarButtonItem?.tintColor = .systemBlue
    }

    // MARK: - Setup ScrollView + Stack
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
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -40)
        ])
    }

    // MARK: - Create Menu Sections
    private func setupMenuSections() {
        
        // ---- Greeting header ----
        greeting.font = .systemFont(ofSize: 32, weight: .bold)
        greeting.textColor = .label
        greeting.textAlignment = .left
        stackView.addArrangedSubview(greeting)
        
        stackView.addArrangedSubview(makeSectionHeader("Helpful When Needed"))
        stackView.addArrangedSubview(makeOptionRow(title: "What is MyCal360?", icon: "questionmark.circle"))
        stackView.addArrangedSubview(makeOptionRow(title: "MyCal360 Tips", icon: "sparkles"))

        stackView.addArrangedSubview(makeSectionHeader("Manage Your Data"))
        stackView.addArrangedSubview(makeOptionRow(title: "Add Data", icon: "doc.badge.plus"))
        stackView.addArrangedSubview(makeOptionRow(title: "Manage Family", icon: "person.3"))
        stackView.addArrangedSubview(makeOptionRow(title: "Saved Metrics", icon: "chart.bar.doc.horizontal"))
        
        stackView.addArrangedSubview(makeOptionRow(title: "Progress", icon: "chart.line.uptrend.xyaxis"))
        
//        stackView.addArrangedSubview(makeOptionRow(title: "Import / Export Your Data", icon: "arrow.up.arrow.down.square", tint: .systemBlue))

        stackView.addArrangedSubview(makeSectionHeader("Get In Touch"))
        stackView.addArrangedSubview(makeOptionRow(title: "Give Feedback", icon: "bubble.left.and.bubble.right"))
        stackView.addArrangedSubview(makeOptionRow(title: "Get Support", icon: "lifepreserver"))

        stackView.addArrangedSubview(makeSectionHeader("About & Legal"))
        stackView.addArrangedSubview(makeOptionRow(title: "Privacy Policy", icon: "doc.text.magnifyingglass"))
        stackView.addArrangedSubview(makeOptionRow(title: "Note from the Developer", icon: "person.text.rectangle"))
        
        // Bottom signature section
        let footerLabel = UILabel()
        footerLabel.text = "© MyCal360 \(Calendar.current.component(.year, from: Date()))"
        footerLabel.textAlignment = .center
        footerLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        footerLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(footerLabel)
    }

    // MARK: - UI Builders
    private func makeSectionHeader(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }

    private func makeOptionRow(title: String, icon: String, tint: UIColor? = nil) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 0.5
        container.layer.borderColor = UIColor.separator.cgColor

        let imageView = UIImageView(image: UIImage(systemName: icon))
        imageView.tintColor = tint ?? .label
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = tint ?? .label
        label.translatesAutoresizingMaskIntoConstraints = false

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .tertiaryLabel
        arrow.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [imageView, label, UIView(), arrow])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            imageView.widthAnchor.constraint(equalToConstant: 20)
        ])

        // Add tap gesture for navigation
        let tap = UITapGestureRecognizer(target: self, action: #selector(menuItemTapped(_:)))
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
        container.accessibilityLabel = title

        return container
    }

    @objc private func menuItemTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view, let title = view.accessibilityLabel else { return }
        print("Tapped: \(title)")
        
        switch title {
            
        // MARK: - Helpful When Needed
        case "What is MyCal360?":
            performSegue(withIdentifier: "showWhatIsMyCal360", sender: self)
            
        case "MyCal360 Tips":
            performSegue(withIdentifier: "showTips", sender: self)
            
            
        // MARK: - Manage Your Data
        case "Add Data":
            performSegue(withIdentifier: "addData", sender: self)
            
        case "Manage Family":
            performSegue(withIdentifier: "showManageFamily", sender: self)
            
        case "Saved Metrics":
            performSegue(withIdentifier: "showSavedMetrics", sender: self)
            
        case "Progress":
            performSegue(withIdentifier: "showProgress", sender: self)
            
//        case "Import / Export Your Data":
//            performSegue(withIdentifier: "showImportExport", sender: self)
            
            
        // MARK: - Get In Touch
        case "Give Feedback":
            performSegue(withIdentifier: "showGiveFeedback", sender: self)
            
        case "Get Support":
            performSegue(withIdentifier: "showGetSupport", sender: self)
            
            
        // MARK: - About & Legal
        case "Privacy Policy":
            performSegue(withIdentifier: "showPrivacyPolicy", sender: self)
            
        case "Note from the Developer":
            performSegue(withIdentifier: "showDeveloperNote", sender: self)
            
        default:
            break
        }
    }

}

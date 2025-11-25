//
//  DeveloperNoteViewController.swift
//  MyCal360
//
//  Created by Shivang Gulati on 07/11/25.
//

import UIKit
import SafariServices

class DevNote: UIViewController {
    
    // MARK: - Scrollable Layout
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "A Note from the Developer"
        view.backgroundColor = .systemGroupedBackground
        setupScrollView()
        setupSections()
        
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
        
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32)
        ])
    }
    
    // MARK: - Content Setup
    private func setupSections() {
        // Section 1 — Introduction
        let introText = """
        MyCal360 is a project very close to my heart. I created this application to better understand my own health and nutritional needs. Over time, it became clear that this knowledge should be accessible to everyone — especially since it’s so easy to feel overwhelmed by “How many calories should I eat in a day?”

        My goal is to make MyCal360 a comprehensive and reliable resource for understanding body metrics and recommended intake, based on well-established formulas.

        I sincerely hope this app adds value to your life!

        P.S. — You can connect with me using the links at the bottom of this page.
        
        Regards,  
        Shivang Gulati
        """
        
        let introLabel = makeParagraph(title: "Why I Built MyCal360", body: introText)
        contentStack.addArrangedSubview(introLabel)
        
        // Section 2 — What’s Next
        addCard(
            icon: "sparkles",
            title: "What’s Next",
            text: """
            I’m currently focused on MyCal360 Flaunts — a simple way to turn your progress into clean, shareable visuals for socials or your camera roll. It needs polish, and I’d rather ship it right than rush it.

            I’ve also heard your requests for detailed nutrition breakdowns (calories, protein, carbs, fiber). I’m exploring this now. To do it properly, I need a reliable food database and a great UX — likely as a separate companion app rather than bloating the main app.

            — Timeline —
            • Flaunts: aiming before end of 2025  
            • Nutrition App: aiming before end of 2026
            """
        )
        
        // Section 3 — Contact / Links
        addCard(
            icon: "message",
            title: "Want to Talk? Let’s Talk!",
            text: "Prefer a quick chat or want to share ideas? I’m happy to connect.",
            links: [
                ("Start a conversation ↗", "mailto:mycalcount@gmail.com", "envelope"),
                ("Connect with me on LinkedIn ↗", "https://www.linkedin.com/in/shivanggulati810/", "link")
            ]
        )
    }
    
    // MARK: - Builders
    
    private func makeParagraph(title: String, body: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        
        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.numberOfLines = 0
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }

    private func addCard(icon: String, title: String, text: String, links: [(String, String, String)]? = nil) {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 0.5
        container.layer.borderColor = UIColor.separator.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemBlue
        iconView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        
        let headerStack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        
        let bodyLabel = UILabel()
        bodyLabel.numberOfLines = 0
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.text = text
        
        let vStack = UIStackView(arrangedSubviews: [headerStack, bodyLabel])
        vStack.axis = .vertical
        vStack.spacing = 10

        // Add optional links
        if let links = links {
            for (text, url, iconName) in links {
                let button = makeLinkButton(text: text, url: url, icon: iconName)
                vStack.addArrangedSubview(button)
            }
        }

        vStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            vStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            vStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            vStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        
        contentStack.addArrangedSubview(container)
    }
    
    private func makeLinkButton(text: String, url: String, icon: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.tintColor = .systemBlue
        button.contentHorizontalAlignment = .leading
        button.tag = url.hashValue // store hash for identification
        button.addAction(UIAction { [weak self] _ in
            self?.openLink(url)
        }, for: .touchUpInside)
        button.configuration = .plain()
        return button
    }

    // MARK: - Actions
    private func openLink(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        if urlString.hasPrefix("mailto:") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        } else {
            let safari = SFSafariViewController(url: url)
            present(safari, animated: true)
        }
    }
}


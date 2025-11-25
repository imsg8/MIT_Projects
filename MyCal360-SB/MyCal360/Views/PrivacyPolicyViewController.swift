//
//  PrivacyPolicyViewController.swift
//  MyCal360
//
//  Created by Shivang Gulati on 30/08/25.
//

import UIKit

class PrivacyPolicyViewController: UIViewController {
    
    // MARK: - Scrollable UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Privacy Policy"
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

    // MARK: - Build Sections
    private func setupSections() {
        contentStack.addArrangedSubview(makeHeader(title: "Privacy Policy", subtitle: """
        This Privacy Policy explains what we collect, why we collect it, how we use and share it, and your choices. By using MyCal360, you agree to these practices.
        """))
        
        addCard(
            icon: "lock.shield",
            title: "What We Collect",
            bullets: [
                "Body metrics you enter (e.g., age, height, weight, activity level).",
                "Feedback you submit (message and optional contact details).",
                "App diagnostics (non-identifying crash logs or performance info)."
            ]
        )

        addCard(
            icon: "gearshape.2",
            title: "How We Use It",
            bullets: [
                "To calculate calorie and macro results.",
                "To respond to feedback you submit.",
                "To improve app reliability and experience."
            ]
        )

        addCard(
            icon: "externaldrive.connected.to.line.below",
            title: "Data Storage & Processors",
            text: """
            We use secure, reputable services:
            • Supabase – stores feedback securely (RLS + API keys)
            • Vercel – hosts backend & PDF generator
            • Apple – optional analytics if enabled in iOS
            """
        )

        addCard(
            icon: "person.2.slash",
            title: "Sharing",
            text: """
            We do not sell your data. We only share with:
            • Service providers (as listed above)
            • Law enforcement if legally required
            """
        )

        addCard(
            icon: "clock.arrow.circlepath",
            title: "Retention & Deletion",
            text: """
            • Inputs remain on your device unless exported.
            • Feedback is retained for improvement.
            • You may request deletion by contacting us.
            """
        )

        addCard(
            icon: "shield.checkerboard",
            title: "Security",
            text: """
            We apply industry-standard safeguards: encryption in transit, restricted access keys, and RLS on feedback. No system is 100% secure, but risks are minimized.
            """
        )

        addCard(
            icon: "hand.tap",
            title: "Your Choices & Rights",
            bullets: [
                "Use the app without contact details.",
                "Request feedback deletion via email.",
                "Export or share PDF summaries freely.",
                "Disable analytics in iOS Settings."
            ]
        )

        addCard(
            icon: "exclamationmark.triangle",
            title: "Children & Sensitive Data",
            text: """
            MyCal360 is for general audiences. Avoid entering health diagnoses or sensitive info. Minors should use the app under adult or medical guidance.
            """
        )

        addCard(
            icon: "list.bullet.rectangle.fill",
            title: "Calculation References",
            text: """
            MyCal360 uses standard metabolic equations:
            • Mifflin–St Jeor (BMR)
            • Revised Harris–Benedict
            • Katch–McArdle (LBM-based)
            • TDEE (Total Daily Energy Expenditure)
            """
        )

        addCard(
            icon: "doc.richtext",
            title: "PDF Generation & Backend",
            text: """
            When you export a summary PDF, our Vercel backend generates it server-side securely. Only essential data is processed—never shared or used for ads.
            """
        )

        addCard(
            icon: "bell.badge",
            title: "Changes & Contact",
            text: """
            Policy updates will appear here. For questions or deletion requests, contact us at:
            mycalcount@gmail.com
            """
        )

        addCard(
            icon: "doc.text.magnifyingglass",
            title: "Legal Basis (Informational)",
            text: """
            We process data to provide requested services (contract), improve safety (legitimate interest), and comply with laws. You can object where rights apply.
            """
        )
    }

    // MARK: - Helpers
    
    private func makeHeader(title: String, subtitle: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        
        let vStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        vStack.axis = .vertical
        vStack.spacing = 6
        return vStack
    }

    private func addCard(icon: String, title: String, bullets: [String]? = nil, text: String? = nil) {
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
        bodyLabel.text = text ?? bullets?.map { "• \($0)" }.joined(separator: "\n")

        let stack = UIStackView(arrangedSubviews: [headerStack, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        contentStack.addArrangedSubview(container)
    }
}

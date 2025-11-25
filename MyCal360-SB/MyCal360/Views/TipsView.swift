//
//  TipsView.swift
//  MyCal360
//
//  Created by Shivang Gulati on 07/11/25.
//

import UIKit

class TipsView: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        
        title = "Tips"
        view.backgroundColor = .systemGroupedBackground
        
        setupScrollView()
    }
    
    private func setupScrollView() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30)
        ])
        
        // MARK: - Sections
        
        stackView.addArrangedSubview(makeSection(
            title: "Tips & How to Use MyCal360",
            text: """
            A visual, step-by-step guide to get the most out of MyCal360. Scroll to explore everything — from setting goals and using zigzag schedules to interpreting your daily targets and weekly summaries.
            """
        ))
        
        stackView.addArrangedSubview(makeCard(
            title: "Getting Started",
            bullets: [
                "Open the Calculator and enter your body details.",
                "Choose Lose, Maintain, or Gain — the app adjusts your daily target.",
                "Try Weekend Flex or Steady Week zigzag patterns for balance."
            ],
            symbol: "sparkles"
        ))
        
        stackView.addArrangedSubview(makeCard(
            title: "Body Inputs",
            bullets: [
                "Update weight periodically for better accuracy.",
                "Pick an activity level reflecting your average week.",
                "If you know body fat %, more precise BMR estimates are used."
            ],
            symbol: "person.crop.circle.badge.checkmark"
        ))
        
        stackView.addArrangedSubview(makeCard(
            title: "Interpreting Your Numbers",
            bullets: [
                "Your daily target is the suggested calorie level for your goal.",
                "Weekly total shows the sum of daily targets (important for zigzag).",
                "Focus on weekly trends — not daily swings."
            ],
            symbol: "gauge.with.dots.needle.bottom.50percent"
        ))
        
        stackView.addArrangedSubview(makeCard(
            title: "Logging Habits That Work",
            bullets: [
                "Log main meals first, snacks later for less friction.",
                "Use templates or favorites for common meals.",
                "If you miss a day, resume normally — no ‘repayment’ needed."
            ],
            symbol: "pencil.and.list.clipboard"
        ))
        
        stackView.addArrangedSubview(makeCard(
            title: "Hydration",
            bullets: [
                "Set a daily water goal and log adds through the day.",
                "Use flavored or zero-calorie drinks if needed.",
                "Hydration improves mood, training, and portion control."
            ],
            symbol: "drop.fill"
        ))
        
        stackView.addArrangedSubview(makeCard(
            title: "Meals & Planning",
            bullets: [
                "Include protein in every meal for satiety and recovery.",
                "Add fiber (veggies, fruits, grains) for fullness and gut health.",
                "Plan dinners early and keep flexibility for events."
            ],
            symbol: "fork.knife.circle.fill"
        ))
        
        stackView.addArrangedSubview(makeCard(
            title: "Weekly Recap",
            bullets: [
                "Review adherence % and weight changes weekly.",
                "If progress stalls for 2–3 weeks, adjust calories by ~5–10%.",
                "Focus on consistency, not perfection."
            ],
            symbol: "chart.bar.xaxis"
        ))
        
        stackView.addArrangedSubview(makeCard(
            title: "Troubleshooting",
            bullets: [
                "Recheck height, weight, and activity accuracy.",
                "Ensure stable network for syncing and PDF exports.",
                "If problems persist, send feedback via app settings."
            ],
            symbol: "wrench.and.screwdriver"
        ))
        
        stackView.addArrangedSubview(makeCard(
            title: "Safety & Medical Disclaimer",
            bullets: [
                "All numbers are estimates — consult professionals when in doubt.",
                "Avoid crash diets; aim for slow, sustainable progress.",
                "If you feel unwell, stop and seek medical advice."
            ],
            symbol: "exclamationmark.triangle.fill"
        ))
        
        stackView.addArrangedSubview(makeCard(
            title: "FAQ",
            bullets: [
                "Q: Why doesn’t my target match other apps?  \nA: Different equations and assumptions are used; MyCal360 keeps weekly totals consistent.",
                "Q: Do I need to log every calorie?  \nA: No — focus on general consistency and weekly averages.",
                "Q: How often to change goals?  \nA: Every 2–3 weeks, adjust by ~5–10% if progress feels off."
            ],
            symbol: "questionmark.circle"
        ))
    }
    
    // MARK: - Helpers
    
    private func makeSection(title: String, text: String) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        
        let bodyLabel = UILabel()
        bodyLabel.text = text
        bodyLabel.numberOfLines = 0
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.font = UIFont.preferredFont(forTextStyle: .body)
        
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(bodyLabel)
        
        return container
    }
    
    private func makeCard(title: String, bullets: [String], symbol: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 0.8
        card.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 6
        
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = .label
        icon.setContentHuggingPriority(.required, for: .horizontal)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        headerStack.addArrangedSubview(icon)
        headerStack.addArrangedSubview(titleLabel)
        
        stack.addArrangedSubview(headerStack)
        
        for bullet in bullets {
            let label = UILabel()
            label.text = "• " + bullet
            label.numberOfLines = 0
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .secondaryLabel
            stack.addArrangedSubview(label)
        }
        
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
        
        return card
    }
}


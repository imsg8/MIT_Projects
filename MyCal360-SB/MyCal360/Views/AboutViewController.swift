//
//  AboutViewController.swift
//  MyCal360
//
//  Created by Shivang Gulati on 07/11/25.
//

import UIKit

class AboutViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        
        title = "About MyCal360"
        view.backgroundColor = .systemGroupedBackground
        
        setupScrollContent()
    }
    
    private func setupScrollContent() {
        // Scroll View
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Content Container
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30)
        ])
        
        // Add all sections
        contentStack.addArrangedSubview(makeSection(
            title: "Overview",
            text: """
            MyCal360 estimates your daily calorie needs from your body details and activity level.
            
            Choose Lose or Gain to get a clear daily target. You’ll also see two optional weekly zigzag schedules that gently shift calories between days while keeping your total weekly calories the same. It’s a simple way to stay consistent while building in a little real-life flexibility.
            """
        ))
        
        contentStack.addArrangedSubview(makeCard(
            title: "Family Members & Tracking Everyone",
            body: """
            Add each person you care for (kids, partner, parents) so you can prefill age/height/sex, save their own weights, and keep data clean per person.

            • Open “Menu → Manage Family” to Add Member.
            • In the calculator, set Mode → Person, tap the person picker, and choose a member to prefill inputs.
            • Enter weight (and body-fat if you have it), then tap “Save Metrics to App” — entries are saved under that member.
            • View or edit entries in Saved Metrics; use the Person filter to see one member or All.
            • See progress and export cards in Flaunts after saving at least two weights.
            """
        ))
        
        contentStack.addArrangedSubview(makeCard(
            title: "How MyCal360 Calculates",
            body: """
            • BMR (basal metabolic rate) uses Mifflin–St Jeor by default.
            • If you provide body-fat %, we switch to Katch–McArdle (lean-mass based).
            • TDEE (daily needs) ≈ BMR × activity level.

            Targets:
            We convert your goal (Lose/Gain) into a daily calorie target from TDEE. Numbers are rounded for simplicity.
            """
        ))
        
        contentStack.addArrangedSubview(makeCard(
            title: "Activity Levels (Per Week)",
            body: """
            • Sedentary: little to no exercise
            • Light: ~1–2 light sessions
            • Moderate: ~3–4 moderate sessions
            • Active: ~5–6 sessions or active job
            • Very Active: 6+ hard sessions / manual labor
            """
        ))
        
        contentStack.addArrangedSubview(makeCard(
            title: "Goals & Suggested Weekly Rates",
            body: """
            • Maintain: stay around your TDEE
            • Mild: ~0.25 kg/week (gentle, sustainable)
            • Moderate: ~0.5 kg/week (common choice)
            • Extreme: ~1.0 kg/week (short-term only)

            Faster change is harder to sustain and may increase fatigue/hunger. Choose what fits your lifestyle.
            """
        ))
        
        contentStack.addArrangedSubview(makeCard(
            title: "Zigzag Option 1 – Weekend Flex",
            body: """
            Weekdays are slightly lower than your daily target so you can “bank” calories for the weekend. Weekend days are a bit higher while your total weekly calories remain balanced.

            Example:
            • Mon–Thu: −10% below daily target
            • Fri–Sat: +15–20% above daily target
            • Sun: at or slightly above target
            """
        ))
        
        contentStack.addArrangedSubview(makeCard(
            title: "Zigzag Option 2 – Steady Week",
            body: """
            Small ups and downs during the week keep things flexible but even — no big weekend bump.

            Example:
            • Mon/Wed/Fri: around target
            • Tue/Thu: −5–7% below target
            • Sat/Sun: +5–7% above target
            """
        ))
        
        contentStack.addArrangedSubview(makeCard(
            title: "Save & iCloud Sync",
            body: """
            • “Save Metrics to App” stores your data locally.
            • We also back them up to your private iCloud.
            • Press “Sync Now” to sync across devices.

            Privacy:
            We don’t track or sell data. Everything stays in your iCloud container.
            """
        ))
        
        contentStack.addArrangedSubview(makeCard(
            title: "Export & Share",
            body: """
            Generate a tidy PDF of your targets and insights, then share or save it for later.
            """
        ))
        
        contentStack.addArrangedSubview(makeCard(
            title: "Tips for Better Accuracy",
            body: """
            • Update weight and activity as they change.
            • Use weekly averages instead of single-day swings.
            • Add body-fat % if you have a reliable estimate.
            """
        ))
        
        contentStack.addArrangedSubview(makeCard(
            title: "Health & Safety",
            body: """
            MyCal360 provides estimates, not medical advice.
            Consult a professional if you have medical conditions, take medication, are pregnant, or are under 18. Avoid crash diets; aim for sustainable progress.
            """
        ))
    }
    
    // MARK: - Helper for Section Titles
    private func makeSection(title: String, text: String) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        
        let bodyLabel = UILabel()
        bodyLabel.text = text
        bodyLabel.font = UIFont.preferredFont(forTextStyle: .body)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(bodyLabel)
        return container
    }
    
    // MARK: - Helper for Card Sections
    private func makeCard(title: String, body: String) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = .secondarySystemGroupedBackground
        cardView.layer.cornerRadius = 12
        cardView.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        cardView.layer.borderWidth = 0.8
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = UIFont.systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(bodyLabel)
        
        cardView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
        
        return cardView
    }
}


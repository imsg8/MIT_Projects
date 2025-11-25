//
//  ViewController.swift
//  MyCal360
//
//  Created by Shivang Gulati on 07/11/25.
//

import UIKit
import Foundation

var isPreview: Bool {
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

final class ViewController: UIViewController {
    
    private let memberButton = UIButton(type: .system)
    private var selectedMember: FamilyMember?
    private var members: [FamilyMember] = []
    
    // MARK: - Stored Properties
    private var name: String = ""
    private var age: Int = 0
    private var height: Double = 0.0
    private var weight: Double = 0.0
    private var goalIndex: Int = 0
    private var genderIndex: Int = 0
    private var selectedActivity: ActivityLevel = .sedentary
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var nameField = UITextField()
    private var ageField = UITextField()
    private var heightField = UITextField()
    private var weightField = UITextField()
    private let goalSegment = UISegmentedControl(items: ["Lose", "Gain"])
    private let genderSegment = UISegmentedControl(items: ["Male", "Female"])
    private let activityButton = UIButton(type: .system)
    private let calculateButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    
    // MARK: - Enum
    enum ActivityLevel: String, CaseIterable {
        case sedentary       = "Sedentary (Little Exercise)"
        case light           = "Light (1–2 days/week)"
        case moderate        = "Moderate (3–4 days/week)"
        case active          = "Active (5–6 days/week)"
        case veryActive      = "Very Active (Daily Exercise)"
        case extremelyActive = "Extremely Active (2X Daily)"
        
        var multiplier: Double {
            switch self {
            case .sedentary:       return 1.2
            case .light:           return 1.375
            case .moderate:        return 1.465
            case .active:          return 1.55
            case .veryActive:      return 1.725
            case .extremelyActive: return 1.9
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
//        checkSessionValidity()
        if !isPreview {
            checkSessionValidity()
        }
        setupNavigationBar()
        setupScrollView()
        setupForm()
        configureActivityMenu()
        enableKeyboardDismissOnTap()
        setupKeyboardHandling(scrollView: scrollView)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onMembersUpdated),
            name: .familyMembersUpdated,
            object: nil
        )
    }
    
    @objc private func onMembersUpdated() {
        members = FamilyStore.shared.members
        configureMemberMenu()

        // Also reselect correct member if needed
        if let selected = selectedMember,
           let refreshed = members.first(where: { $0.id == selected.id }) {
            selectedMember = refreshed
            memberButton.setTitle(refreshed.name, for: .normal)
            prefillMemberData(refreshed)
        } else if let first = members.first {
            selectedMember = first
            memberButton.setTitle(first.name, for: .normal)
            prefillMemberData(first)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !isPreview {
            if SessionManager.shared.isSessionValid() {
                SessionManager.shared.extendSession()
            } else {
                handleSessionExpired()
                return
            }
        }

        FamilyStore.shared.refreshFromServer(silent: true) { _ in
        }
    }

    private func configureMemberMenu() {

        // Reload latest members
        members = FamilyStore.shared.members

        if members.isEmpty {
            memberButton.setTitle("No Members", for: .normal)
            memberButton.menu = nil
            memberButton.isEnabled = false
            memberButton.showsMenuAsPrimaryAction = false
            return
        }

        memberButton.isEnabled = true

        let actions = members.map { member in
            UIAction(title: member.name) { [weak self] _ in
                guard let self else { return }
                self.selectedMember = member
                self.memberButton.setTitle(member.name, for: .normal)
                self.prefillMemberData(member)
            }
        }

        memberButton.menu = UIMenu(title: "Choose Member", children: actions)
        memberButton.showsMenuAsPrimaryAction = true

        // Ensure a valid default is set
        if let selected = selectedMember {
            memberButton.setTitle(selected.name, for: .normal)
        } else if let first = members.first {
            selectedMember = first
            memberButton.setTitle(first.name, for: .normal)
            prefillMemberData(first)
        }
    }

    private func dimLockedFields() {
        ageField.alpha = 0.5
        heightField.alpha = 0.5
        genderSegment.alpha = 0.5
    }

    private func loadMembers() {
        members = FamilyStore.shared.members
        if let first = members.first {
            selectedMember = first
            prefillMemberData(first)
        }
    }
    
    private func prefillMemberData(_ member: FamilyMember) {
        name = member.name
        age = member.age
        height = member.height
        
        ageField.text = "\(member.age)"
        heightField.text = "\(member.height)"
        
        // Auto-fill gender
        genderIndex = member.gender == "Male" ? 0 : 1
        genderSegment.selectedSegmentIndex = genderIndex
        genderSegment.isEnabled = false

        // Lock fields
        ageField.isEnabled = false
        heightField.isEnabled = false
        
        dimLockedFields()
    }

    // MARK: - Navigation Bar
    private func setupNavigationBar() {
        // Left bar button (menu)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "line.3.horizontal"),
                style: .plain,
                target: self,
                action: #selector(openMenu)
            )

            // Right buttons — ORDER MATTERS (rightmost is last)
            let boltBtn = UIBarButtonItem(
                image: UIImage(systemName: "bolt"),
                style: .plain,
                target: self,
                action: #selector(openLLM)
            )

            let doorBtn = UIBarButtonItem(
                image: UIImage(systemName: "door.right.hand.open"),
                style: .plain,
                target: self,
                action: #selector(openRight)
            )

            navigationItem.rightBarButtonItems = [doorBtn, boltBtn]
        
        // Center logo in navigation bar
        let scaleFactor = 1.5
        let logoImageView = UIImageView(image: UIImage(named: "logo_wb"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let logoContainer = UIView()
        logoContainer.addSubview(logoImageView)
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 100 * scaleFactor),
            logoImageView.heightAnchor.constraint(equalToConstant: 32 * scaleFactor)
        ])
        
        navigationItem.titleView = logoContainer
    }
    
    @objc private func openMenu() {
        performSegue(withIdentifier: "showMenu", sender: self)
    }
    
    @objc private func openLLM() {
        let llmVC = LLMViewController()
        navigationController?.pushViewController(llmVC, animated: true)
    }
    
    @objc private func openRight() {
        let remainingTime = SessionManager.shared.getRemainingSessionTime()
        let alert = UIAlertController(
            title: "Logout",
            message: "Session expires in: \(remainingTime)\n\nAre you sure you want to logout?",
            preferredStyle: .alert
        )
        
        let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            self?.performLogout()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(cancelAction)
        alert.addAction(logoutAction)
        present(alert, animated: true, completion: nil)
    }

    private func performLogout() {
        SessionManager.shared.clearSession()
        performSegue(withIdentifier: "logoutSegue", sender: self)
    }
    
    // MARK: - Scroll View
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
    
    // MARK: - Form
    private func setupForm() {
        // Wrapper card
        let card = UICard()
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        // Stack inside card
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 26
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        // --- Member Selector ---
        let memberLabel = UILabel()
        memberLabel.text = "Member"
        memberLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        memberLabel.textColor = .secondaryLabel

        memberButton.setTitle("Select Member", for: .normal)
        memberButton.backgroundColor = .secondarySystemBackground
        memberButton.layer.cornerRadius = 10
        memberButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        memberButton.contentHorizontalAlignment = .leading
        memberButton.setTitleColor(.systemBlue, for: .normal)
        memberButton.titleLabel?.font = .systemFont(ofSize: 15)
        memberButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

        let memberStack = UIStackView(arrangedSubviews: [memberLabel, memberButton])
        memberStack.axis = .vertical
        memberStack.spacing = 6
        stack.addArrangedSubview(memberStack)

        // --- Gender (segmented) ---
        let genderLabel = UILabel()
        genderLabel.text = "Gender"
        genderLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        genderLabel.textColor = .secondaryLabel
        genderSegment.isEnabled = false
        
        let genderStack = UIStackView(arrangedSubviews: [genderLabel, genderSegment])
        genderStack.axis = .vertical
        genderStack.spacing = 6
        
        genderSegment.selectedSegmentIndex = 0
        genderSegment.selectedSegmentTintColor = .systemBlue
        genderSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)

        stack.addArrangedSubview(genderStack)

        // --- Age field ---
        let ageInput = FancyNumberField(
            title: "Age (yrs)",
            icon: "calendar",
            unit: "yrs",
            allowed: .integer
        )
        self.ageField = ageInput.textField
        stack.addArrangedSubview(ageInput)
        ageField.isEnabled = false

        // --- Height field ---
        let heightInput = FancyNumberField(
            title: "Height",
            icon: "ruler",
            unit: "cm",
            allowed: .decimal
        )
        self.heightField = heightInput.textField
        stack.addArrangedSubview(heightInput)
        self.heightField.isEnabled = false

        // --- Weight field ---
        let weightInput = FancyNumberField(
            title: "Weight",
            icon: "scalemass",
            unit: "kg",
            allowed: .decimal
        )
        self.weightField = weightInput.textField
        stack.addArrangedSubview(weightInput)

        // --- Goal segmented control ---
        let goalLabel = UILabel()
        goalLabel.text = "Goal"
        goalLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        goalLabel.textColor = .secondaryLabel

        let goalStack = UIStackView(arrangedSubviews: [goalLabel, goalSegment])
        goalStack.axis = .vertical
        goalStack.spacing = 6
        
        goalSegment.selectedSegmentIndex = 1
        goalSegment.selectedSegmentTintColor = .systemBlue
        goalSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)

        stack.addArrangedSubview(goalStack)

        // --- Activity Level Button ---
        let activityLabel = UILabel()
        activityLabel.text = "Activity Level"
        activityLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        activityLabel.textColor = .secondaryLabel

        activityButton.setTitle("Select Activity", for: .normal)
        activityButton.backgroundColor = .secondarySystemBackground
        activityButton.layer.cornerRadius = 10
        activityButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        activityButton.contentHorizontalAlignment = .leading
        activityButton.setTitleColor(.systemBlue, for: .normal)
        activityButton.titleLabel?.font = .systemFont(ofSize: 15)
        activityButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

        let actStack = UIStackView(arrangedSubviews: [activityLabel, activityButton])
        actStack.axis = .vertical
        actStack.spacing = 6
        stack.addArrangedSubview(actStack)
        
        // --- Buttons Stack ---
        let buttonStack = UIStackView(arrangedSubviews: [calculateButton, clearButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        calculateButton.setTitle("Calculate", for: .normal)
        calculateButton.backgroundColor = .systemBlue
        calculateButton.setTitleColor(.white, for: .normal)
        calculateButton.layer.cornerRadius = 10
        calculateButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        calculateButton.addTarget(self, action: #selector(calculateTapped), for: .touchUpInside)
        calculateButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)

        clearButton.setTitle("Clear", for: .normal)
        clearButton.backgroundColor = .systemRed
        clearButton.setTitleColor(.white, for: .normal)
        clearButton.layer.cornerRadius = 10
        clearButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        clearButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)

        // Add buttons stack to the main stack view inside card
        stack.addArrangedSubview(buttonStack)

        // Layout constraints
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

            stack.topAnchor.constraint(equalTo: card.layoutMarginsGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.layoutMarginsGuide.bottomAnchor)
        ])
    }

    
    // MARK: - UI Helpers
    private func makeSectionHeader(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }
    
    // MARK: - Activity Menu
    private func configureActivityMenu() {
        let actions = ActivityLevel.allCases.map { level in
            UIAction(title: level.rawValue) { [weak self] _ in
                self?.selectedActivity = level
                self?.activityButton.setTitle(level.rawValue, for: .normal)
            }
        }
        activityButton.menu = UIMenu(title: "Choose Activity Level", children: actions)
        activityButton.showsMenuAsPrimaryAction = true
    }
    
    // MARK: - Actions
    @objc private func calculateTapped() {
        guard let member = selectedMember else { return }
        name = member.name
        age = member.age
        height = member.height
        guard let weightValue = Double(weightField.text ?? "") else {
            showAlert(msg: "Please enter a valid weight.")
            return
        }
        if weightValue < 50 || weightValue > 150 {
            showAlert(msg: "Weight must be between 50 kg and 150 kg.")
            return
        }
        weight = weightValue
        genderIndex = member.gender == "Male" ? 0 : 1
        goalIndex = goalSegment.selectedSegmentIndex
        
        performSegue(withIdentifier: "showResults", sender: self)
    }
    
    @objc private func clearTapped() {
        weightField.text = ""
        goalSegment.selectedSegmentIndex = 1
        selectedActivity = .sedentary
        activityButton.setTitle("Select Activity", for: .normal)

        if let first = members.first {
            selectedMember = first
            memberButton.setTitle(first.name, for: .normal)
            prefillMemberData(first)
        }
    }
    
    // MARK: - Data Passing
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showResults" {
            let tdee = calculateMaintenanceCalories()
            if let nav = segue.destination as? UINavigationController,
               let resultsVC = nav.topViewController as? ResultsViewController {
                resultsVC.maintenanceCalories = tdee
                resultsVC.goalIndex = goalIndex
                resultsVC.selectedActivity = selectedActivity
                resultsVC.genderIndex = genderIndex
                resultsVC.age = age
                resultsVC.height = height
                resultsVC.weight = weight
                resultsVC.name = name
            } else if let resultsVC = segue.destination as? ResultsViewController {
                resultsVC.maintenanceCalories = tdee
                resultsVC.goalIndex = goalIndex
                resultsVC.selectedActivity = selectedActivity
                resultsVC.genderIndex = genderIndex
                resultsVC.age = age
                resultsVC.height = height
                resultsVC.weight = weight
                resultsVC.name = name
            }
        }
    }
    
    // MARK: - BMR & TDEE
    private func calculateMaintenanceCalories() -> Double {
        let baseBMR = 10.0 * weight + 6.25 * height - 5.0 * Double(age)
        let bmr = genderIndex == 0 ? baseBMR + 5.0 : baseBMR - 161.0
        return bmr * selectedActivity.multiplier
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func checkSessionValidity() {
        if !SessionManager.shared.isSessionValid() {
            // Session expired, logout immediately
            DispatchQueue.main.async {
                self.handleSessionExpired()
            }
        } else {
            // Valid session, extend it
            SessionManager.shared.extendSession()
        }
    }
    
    private func handleSessionExpired() {
        if isPreview { return }
        let alert = UIAlertController(
            title: "Session Expired",
            message: "Your session has expired after 3 days of inactivity. Please log in again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.performLogout()
        })
        present(alert, animated: true)
    }
    
    private func showAlert(msg: String) {
        let alert = UIAlertController(title: "Invalid Input", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}

#if DEBUG
import SwiftUI

struct ViewController_Preview: PreviewProvider {
    static var previews: some View {
        UINavigationController(rootViewController: ViewController())
            .toPreview()
    }
}

extension UIViewController {
    func toPreview() -> some View {
        UIViewControllerPreview(self)
    }
}

struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController

    init(_ vc: @autoclosure () -> ViewController) {
        self.viewController = vc()
    }

    func makeUIViewController(context: Context) -> ViewController {
        viewController
    }

    func updateUIViewController(_ vc: ViewController, context: Context) {}
}
#endif

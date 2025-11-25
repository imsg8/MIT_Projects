//
//  GetStartedViewController.swift
//  MyCal360
//

import UIKit

final class GetStartedViewController: UIViewController {
    
    var prefilledName: String?   // FROM SIGNUP
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let nameLabel = UILabel()
    private var ageField = UITextField()
    private var heightField = UITextField()
    private var weightField = UITextField()
    private let topImageView = UIImageView()

    private let genderSegment = UISegmentedControl(items: ["Male", "Female"])
    private let saveButton = UIButton(type: .system)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGroupedBackground
        setupScrollView()
        setupForm()
        enableKeyboardDismissOnTap()
        setupKeyboardHandling(scrollView: scrollView)
    }
    
    // MARK: - Scroll View Layout
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
    
    
    // MARK: - Form (Styled like Main VC)
    private func setupForm() {
        
        // ---- TOP IMAGE ----
        topImageView.image = UIImage(named: "mycallabs_wb")
        topImageView.contentMode = .scaleAspectFit
        topImageView.translatesAutoresizingMaskIntoConstraints = false
        topImageView.heightAnchor.constraint(equalToConstant: 120).isActive = true

        contentView.addSubview(topImageView)

        // Center horizontally
        NSLayoutConstraint.activate([
            topImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            topImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])

        
        let card = UICard()
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 26
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        // ----- TITLE -----
        let titleLabel = UILabel()
        titleLabel.text = "Let's Get Started"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        stack.addArrangedSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Add your first member and initial weight."
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        stack.addArrangedSubview(subtitleLabel)
        
        // ----- INFO / REQUIREMENT -----
        let infoLabel = UILabel()
        infoLabel.text =
        """
        To continue, we need to set up at least one member for your account.
        This helps us track your calories, metrics, and progress.
        """
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        stack.addArrangedSubview(infoLabel)
        
        // ----- PREFILLED NAME -----
        print(prefilledName)
        nameLabel.text = "Name: \(prefilledName ?? "Unknown")"
        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .label
        stack.addArrangedSubview(nameLabel)
        
        // ----- GENDER -----
        let genderLabel = UILabel()
        genderLabel.text = "Gender"
        genderLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        genderLabel.textColor = .secondaryLabel
        
        genderSegment.selectedSegmentIndex = 0
        genderSegment.selectedSegmentTintColor = .systemBlue
        genderSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        
        let genderStack = UIStackView(arrangedSubviews: [genderLabel, genderSegment])
        genderStack.axis = .vertical
        genderStack.spacing = 6
        stack.addArrangedSubview(genderStack)
        
        // ----- AGE -----
        let ageInput = FancyNumberField(
            title: "Age (yrs)",
            icon: "calendar",
            unit: "yrs",
            allowed: .integer
        )
        self.ageField = ageInput.textField
        stack.addArrangedSubview(ageInput)
        
        // ----- HEIGHT -----
        let heightInput = FancyNumberField(
            title: "Height",
            icon: "ruler",
            unit: "cm",
            allowed: .decimal
        )
        self.heightField = heightInput.textField
        stack.addArrangedSubview(heightInput)
        
        // ----- WEIGHT -----
        let weightInput = FancyNumberField(
            title: "Initial Weight",
            icon: "scalemass",
            unit: "kg",
            allowed: .decimal
        )
        self.weightField = weightInput.textField
        stack.addArrangedSubview(weightInput)
        
        // ----- SAVE BUTTON -----
        saveButton.setTitle("Save & Continue", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        stack.addArrangedSubview(saveButton)
        
        // Layout
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topImageView.bottomAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            stack.topAnchor.constraint(equalTo: card.layoutMarginsGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.layoutMarginsGuide.bottomAnchor)
        ])
        
        // Ensures scrollability on small devices
        contentView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: 40).isActive = true
    }

    
    
    // MARK: - Save Logic
    @objc private func saveTapped() {
        
        guard let name = prefilledName,
              let age = Int(ageField.text ?? ""),
              let height = Double(heightField.text ?? ""),
              let weight = Double(weightField.text ?? "") else {
            showAlert("Please fill in all fields correctly.")
            return
        }
        
        // Age validation
        if age < 10 || age > 100 {
            showAlert("Age must be between 10 and 100 years.")
            return
        }

        // Height validation
        if height < 90 || height > 220 {
            showAlert("Height must be between 90 cm and 220 cm.")
            return
        }

        // Weight validation
        if weight < 50 || weight > 150 {
            showAlert("Weight must be between 50 kg and 150 kg.")
            return
        }
        
        let gender = genderSegment.selectedSegmentIndex == 0 ? "Male" : "Female"
        var newMember = FamilyMember(name: name, age: age, height: height, gender: gender)
        
        saveButton.isEnabled = false
        saveButton.setTitle("Saving...", for: .normal)
        
        
        // ---- STEP 1: SAVE MEMBER ----
        FamilyStore.shared.addMember(newMember) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.saveInitialWeight(for: name, weight: weight)
                case .failure(let error):
                    self.saveButton.isEnabled = true
                    self.saveButton.setTitle("Save & Continue", for: .normal)
                    self.showAlert("Failed to save member: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    private func saveInitialWeight(for memberName: String, weight: Double) {
        
        guard let member = FamilyStore.shared.members.first(where: { $0.name == memberName }) else {
            showAlert("Unexpected error: Member not found after saving.")
            return
        }
        
        let entry = WeightEntry(id: nil, date: Date(), weight: weight)
        var updated = member
        updated.weights.append(entry)
        
        
        // ---- STEP 2: SAVE WEIGHT ----
        FamilyStore.shared.updateMember(updated) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.dismiss(animated: true) {
                        NotificationCenter.default.post(name: .init("GetStartedCompleted"), object: nil)
                    }
                    
                case .failure(let error):
                    self.showAlert("Failed to save weight: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    // MARK: - Alert
    private func showAlert(_ message: String) {
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

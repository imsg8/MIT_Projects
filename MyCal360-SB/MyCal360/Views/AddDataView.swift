//
//  AddDataView.swift
//  MyCal360
//
//  Created by Shivang Gulati on 08/11/25.
//

import UIKit

final class AddDataView: UIViewController {
    
    private let memberButton = UIButton(type: .system)
    private let datePicker = UIDatePicker()
    private let weightField = UITextField()
    private let saveButton = UIButton(type: .system)

    private var selectedMember: FamilyMember?
    private var members: [FamilyMember] { FamilyStore.shared.members }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Data"
        view.backgroundColor = .systemGroupedBackground
        
        // Check if FamilyStore is configured BEFORE setting up UI
        guard FamilyStore.shared.userId != nil else {
            showAlert(title: "Error", message: "Please log in first")
            return
        }
        
        FamilyStore.shared.load()
        setupUI()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle"),
            style: .plain,
            target: self,
            action: #selector(closeView)
        )
        navigationItem.leftBarButtonItem?.tintColor = .systemBlue
        
        checkMemberAvailability()
    }

    // MARK: - Dismissal
    @objc private func closeView() {
        dismiss(animated: true, completion: nil)
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        // ScrollView (same structure as ViewController)
        let scrollView = UIScrollView()
        let contentView = UIView()
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

        // ---- CARD ----
        let card = UICard()
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 26
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        // ---- Title ----
        let titleLabel = UILabel()
        titleLabel.text = "Add Weight Data"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        stack.addArrangedSubview(titleLabel)

        // ---- Member ----
        let memberLabel = UILabel()
        memberLabel.text = "Member"
        memberLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        memberLabel.textColor = .secondaryLabel

        let memberStack = UIStackView(arrangedSubviews: [memberLabel, memberButton])
        memberStack.axis = .vertical
        memberStack.spacing = 6

        memberButton.setTitle("Select Member", for: .normal)
        memberButton.backgroundColor = .secondarySystemBackground
        memberButton.layer.cornerRadius = 10
        memberButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        memberButton.contentHorizontalAlignment = .leading
        memberButton.setTitleColor(.systemBlue, for: .normal)
        memberButton.titleLabel?.font = .systemFont(ofSize: 15)
        memberButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

        stack.addArrangedSubview(memberStack)

        // ---- Date ----
        let dateLabel = UILabel()
        dateLabel.text = "Date"
        dateLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        dateLabel.textColor = .secondaryLabel

        let dateStack = UIStackView(arrangedSubviews: [dateLabel, datePicker])
        dateStack.axis = .vertical
        dateStack.spacing = 6
        dateStack.alignment = .leading

        datePicker.datePickerMode = .date
        datePicker.maximumDate = Date()
        datePicker.preferredDatePickerStyle = .compact
        datePicker.heightAnchor.constraint(equalToConstant: 40).isActive = true

        stack.addArrangedSubview(dateStack)

        // ---- Weight ----
        let weightLabel = UILabel()
        weightLabel.text = "Weight (kg)"
        weightLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        weightLabel.textColor = .secondaryLabel

        let weightStack = UIStackView(arrangedSubviews: [weightLabel, weightField])
        weightStack.axis = .vertical
        weightStack.spacing = 6

        weightField.borderStyle = .roundedRect
        weightField.keyboardType = .decimalPad
        weightField.heightAnchor.constraint(equalToConstant: 40).isActive = true

        stack.addArrangedSubview(weightStack)

        // ---- Save Button ----
        saveButton.setTitle("Save Entry", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.heightAnchor.constraint(equalToConstant: 48).isActive = true

        stack.addArrangedSubview(saveButton)

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        // ---- Layout for card and stack ----
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

        // same dropdown config
        configureMemberDropdown()

        // auto-select first
        if let first = members.first {
            selectedMember = first
            memberButton.setTitle(first.name, for: .normal)
        }
    }

    
    private func configureMemberDropdown() {
        if members.isEmpty {
            memberButton.isEnabled = false
            return
        }
        
        let actions = members.map { member in
            UIAction(title: member.name) { [weak self] _ in
                self?.selectedMember = member
                self?.memberButton.setTitle(member.name, for: .normal)
            }
        }
        
        memberButton.menu = UIMenu(title: "Select Member", children: actions)
        memberButton.showsMenuAsPrimaryAction = true
    }

    private func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }

    private func checkMemberAvailability() {
        if members.isEmpty {
            memberButton.isUserInteractionEnabled = false
            saveButton.isEnabled = false
            saveButton.alpha = 0.5
            showAlert(title: "No Members Found",
                      message: "Please register a family member first before adding weight data.")
        }
    }

    @objc private func saveTapped() {
        guard !members.isEmpty else {
            showAlert(title: "No Members", message: "Please add a member before saving data.")
            return
        }
        guard let member = selectedMember,
              let weightText = weightField.text, !weightText.isEmpty,
              let weight = Double(weightText) else {
            showAlert(title: "Missing Info", message: "Please select a member and enter a valid weight.")
            return
        }
        
        // Weight validation
        if weight < 50 || weight > 150 {
            showAlert(title: "Invalid Weight", message: "Weight must be between 50 kg and 150 kg.")
            return
        }

        // Disable button during save
        saveButton.isEnabled = false
        saveButton.alpha = 0.5
        saveButton.setTitle("Saving...", for: .normal)
        
        // Create new weight entry (without ID, will be assigned by server)
        let newEntry = WeightEntry(id: nil, date: datePicker.date, weight: weight)
        var updated = member
        updated.weights.append(newEntry)
        
        FamilyStore.shared.updateMember(updated) { result in
            DispatchQueue.main.async {
                self.saveButton.isEnabled = true
                self.saveButton.alpha = 1.0
                self.saveButton.setTitle("Save Entry", for: .normal)
                
                switch result {
                case .success:
                    self.weightField.text = ""
                    // Refresh to get the server-assigned weight ID
                    FamilyStore.shared.refreshFromServer(silent: true) { _ in
                        DispatchQueue.main.async {
                            self.showAlert(title: "Saved!", message: "Weight entry has been added successfully.")
                        }
                    }
                case .failure(let error):
                    // Revert local cache on failure - remove the unsaved entry
                    var revertedMember = member
                    revertedMember.weights = member.weights // Original weights without the new entry
                    FamilyStore.shared.updateMemberLocallyOnly(revertedMember)
                    
                    self.showAlert(title: "Error", message: "Failed to save: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Picker Delegates
extension AddDataView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        members.isEmpty ? 1 : members.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        members.isEmpty ? "No Members Available" : members[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard !members.isEmpty else {
            selectedMember = nil
            return
        }
        selectedMember = members[row]
    }
}

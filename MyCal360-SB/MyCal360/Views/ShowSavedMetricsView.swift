//
//  showSavedMetricsView.swift
//  MyCal360
//
//  Created by Shivang Gulati on 08/11/25.
//

import UIKit

// MARK: - Swipe to Delete Metric (REPLACEMENT)
extension ShowSavedMetricsView {
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            guard var member = self.selectedMember else { completion(false); return }

            // Work on a sorted copy (descending = newest first), which is what the UI displays
            var sortedWeights = member.weights.sorted { $0.date > $1.date }

            // defensive: ensure index exists
            guard indexPath.row >= 0, indexPath.row < sortedWeights.count else {
                completion(false); return
            }

            // Identify the entry to remove
            let entryToRemove = sortedWeights[indexPath.row]

            // If this entry exists on server (has id) call deleteWeight
            if let wId = entryToRemove.id {
                FamilyStore.shared.deleteWeight(memberId: member.id, weightId: wId) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            // update local model and UI
                            var updatedMember = member
                            updatedMember.weights.removeAll { $0.id == wId }
                            FamilyStore.shared.updateMemberLocallyOnly(updatedMember) // helper below
                            self.selectedMember = updatedMember
                            UIView.transition(with: tableView, duration: 0.18, options: .transitionCrossDissolve, animations: {
                                tableView.reloadData()
                            })
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            completion(true)
                        case .failure:
                            // fallback: remove locally and try to sync via updateMember
                            var updatedMember = member
                            updatedMember.weights.removeAll { $0.date == entryToRemove.date && $0.weight == entryToRemove.weight }
                            FamilyStore.shared.updateMember(updatedMember)
                            self.selectedMember = updatedMember
                            DispatchQueue.main.async { tableView.reloadData() }
                            completion(true)
                        }
                    }
                }
            } else {
                // Local-only entry — simply remove and sync via updateMember
                var updatedMember = member
                updatedMember.weights.removeAll { $0.date == entryToRemove.date && $0.weight == entryToRemove.weight }
                FamilyStore.shared.updateMember(updatedMember)
                self.selectedMember = updatedMember
                DispatchQueue.main.async { tableView.reloadData() }
                completion(true)
            }
        }

        deleteAction.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}


final class ShowSavedMetricsView: UIViewController {
    
    // MARK: - UI Components
    private let memberButton = UIButton(type: .system)
    private let infoContainer = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()
    
    // MARK: - Data
    private var members: [FamilyMember] { FamilyStore.shared.members }
    private var selectedMember: FamilyMember? {
        didSet { updateUIForSelectedMember() }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Saved Metrics"
        view.backgroundColor = .systemGroupedBackground
        FamilyStore.shared.load()
        setupUI()
        configureMemberMenu()

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

    private func configureMemberMenu() {
        let actions = members.map { member in
            UIAction(title: member.name) { [weak self] _ in
                self?.selectedMember = member
                self?.memberButton.setTitle(member.name, for: .normal)
            }
        }
        
        memberButton.menu = UIMenu(title: "Choose Member", children: actions)
        memberButton.showsMenuAsPrimaryAction = true
    }

    // MARK: - Setup
    private func setupUI() {
        // ---- CARD for member selector + info ----
        let card = UICard()
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        // Vertical stack inside card
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 22
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)

        // Header label
        let headerLabel = UILabel()
        headerLabel.text = "Select Member"
        headerLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        headerLabel.textColor = .secondaryLabel

        // Member selection button (same style as AddDataView)
        memberButton.setTitle("Select Member", for: .normal)
        memberButton.backgroundColor = .secondarySystemBackground
        memberButton.layer.cornerRadius = 10
        memberButton.contentHorizontalAlignment = .leading
        memberButton.setTitleColor(.systemBlue, for: .normal)
        memberButton.titleLabel?.font = .systemFont(ofSize: 15)
        memberButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        memberButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        cardStack.addArrangedSubview(headerLabel)
        cardStack.addArrangedSubview(memberButton)

        // ---- Member Info (same view, now inside card) ----
        infoContainer.axis = .vertical
        infoContainer.alignment = .leading
        infoContainer.spacing = 4
        infoContainer.translatesAutoresizingMaskIntoConstraints = false

        cardStack.addArrangedSubview(infoContainer)

        // ---- Layout for card ----
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            cardStack.topAnchor.constraint(equalTo: card.layoutMarginsGuide.topAnchor),
            cardStack.leadingAnchor.constraint(equalTo: card.layoutMarginsGuide.leadingAnchor),
            cardStack.trailingAnchor.constraint(equalTo: card.layoutMarginsGuide.trailingAnchor),
            cardStack.bottomAnchor.constraint(equalTo: card.layoutMarginsGuide.bottomAnchor),
        ])
        
        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MetricCell.self, forCellReuseIdentifier: "MetricCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        
        // Empty Label
        emptyLabel.text = "No weight records yet."
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.font = .systemFont(ofSize: 15)
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        
        // Layout
        NSLayoutConstraint.activate([
            // card already has top/leading/trailing set above; place table below card
            tableView.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Set default selection (preselect + set button title)
        if let first = members.first {
            selectedMember = first
            memberButton.setTitle(first.name, for: .normal)
        } else {
            emptyLabel.text = "No registered family members yet.\nPlease add a member first."
            emptyLabel.isHidden = false
            tableView.isHidden = true
            infoContainer.isHidden = true
            memberButton.isUserInteractionEnabled = false
        }
    }
    
    // MARK: - UI Update
    private func updateUIForSelectedMember() {
        infoContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard let member = selectedMember else {
            emptyLabel.isHidden = false
            emptyLabel.text = "No member selected."
            tableView.reloadData()
            return
        }
        
        let nameLabel = makeInfoLabel("person.fill  \(member.name)")
        let ageLabel = makeInfoLabel("calendar  Age: \(member.age)")
        let heightLabel = makeInfoLabel("ruler  Height: \(Int(member.height)) cm")
        let genderLabel = makeInfoLabel("figure.stand  Gender: \(member.gender)")
        
        [nameLabel, ageLabel, heightLabel, genderLabel].forEach { infoContainer.addArrangedSubview($0) }
        
        if member.weights.isEmpty {
            emptyLabel.text = "No saved weights for \(member.name)."
            emptyLabel.isHidden = false
        } else {
            emptyLabel.isHidden = true
        }
        
        tableView.reloadData()
    }
    
    private func makeInfoLabel(_ text: String) -> UILabel {
        let label = UILabel()
        let parts = text.split(separator: " ", maxSplits: 1)
        if parts.count == 2 {
            let symbol = UIImage(systemName: String(parts[0])) ?? UIImage()
            let attachment = NSTextAttachment()
            attachment.image = symbol
            attachment.bounds = CGRect(x: 0, y: -2, width: 16, height: 16)
            
            let attributed = NSMutableAttributedString(attachment: attachment)
            attributed.append(NSAttributedString(string: "  " + parts[1]))
            label.attributedText = attributed
        } else {
            label.text = text
        }
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        return label
    }
}

// MARK: - Picker
extension ShowSavedMetricsView: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        members.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        members[row].name
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedMember = members[row]
    }
}

// MARK: - TableView
extension ShowSavedMetricsView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedMember?.weights.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let member = selectedMember else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "MetricCell", for: indexPath) as! MetricCell
        let weightEntry = member.weights.sorted { $0.date > $1.date }[indexPath.row]
        cell.configure(with: weightEntry)
        return cell
    }
}

// MARK: - Metric Cell
final class MetricCell: UITableViewCell {
    
    private let dateLabel = UILabel()
    private let weightLabel = UILabel()
    private let container = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        
        dateLabel.font = .systemFont(ofSize: 15, weight: .medium)
        dateLabel.textColor = .label
        
        weightLabel.font = .systemFont(ofSize: 16, weight: .bold)
        weightLabel.textColor = .systemBlue
        
        let stack = UIStackView(arrangedSubviews: [dateLabel, weightLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14)
        ])
    }
    
    func configure(with entry: WeightEntry) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        dateLabel.text = formatter.string(from: entry.date)
        weightLabel.text = "\(entry.weight) kg"
    }
    
}


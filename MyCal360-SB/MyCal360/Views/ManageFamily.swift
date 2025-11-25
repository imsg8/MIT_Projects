//
//  ManageFamily.swift
//  MyCal360
//
//  Created by Shivang Gulati on 08/11/25.
//

import UIKit

final class ManageFamily: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Manage Family"
        view.backgroundColor = .systemGroupedBackground
        
        setupTable()
        setupNavBar()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle"),
            style: .plain,
            target: self,
            action: #selector(closeView)
        )
        navigationItem.leftBarButtonItem?.tintColor = .systemBlue
        
        // Check if FamilyStore is configured
        guard FamilyStore.shared.userId != nil else {
            showResultAlert(title: "Error", message: "Please log in first")
            return
        }
        
        // Load with completion
        FamilyStore.shared.load { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.tableView.reloadData()
                case .failure(let error):
                    print("⚠️ Failed to load family data: \(error.localizedDescription)")
                    self.tableView.reloadData()
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshFamily),
            name: .familyStoreDidLoad,
            object: nil
        )
    }
    
    @objc private func refreshFamily() {
        tableView.reloadData()
    }

    // MARK: - Dismissal
    @objc private func closeView() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Setup
    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addMember)
        )
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        FamilyStore.shared.members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let member = FamilyStore.shared.members[indexPath.row]
        cell.textLabel?.text = "\(member.name) (\(member.gender))"
        cell.accessoryType = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let member = FamilyStore.shared.members[indexPath.row]

            FamilyStore.shared.deleteMember(member) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    case .failure(let error):
                        self.showResultAlert(
                            title: "Error",
                            message: "Failed to delete from Supabase: \(error.localizedDescription)"
                        )
                        print("❌ Supabase delete failed:", error)
                    }
                }
            }
        }
    }
    
    // MARK: - Add/Edit Member
    @objc private func addMember() {
        showEditAlert(for: nil)
    }
    
    private func showEditAlert(for member: FamilyMember?) {
        let alert = UIAlertController(
            title: "Add Member",
            message: "\n\n\n", // <- adds space for the segmented control
            preferredStyle: .alert
        )
        
        // Text fields
        alert.addTextField { tf in
            tf.placeholder = "Name"
            tf.text = member?.name
        }
        
        alert.addTextField { tf in
            tf.placeholder = "Age"
            tf.keyboardType = .numberPad
            if let age = member?.age { tf.text = "\(age)" }
        }
        
        alert.addTextField { tf in
            tf.placeholder = "Height (cm)"
            tf.keyboardType = .decimalPad
            if let height = member?.height { tf.text = "\(height)" }
        }
//        
//        // Add the segmented control *after presentation* to avoid hierarchy issues
        let genderControl = UISegmentedControl(items: ["Male", "Female"])
        genderControl.selectedSegmentIndex = (member?.gender.lowercased() == "female") ? 1 : 0
        genderControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Buttons
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // LOCATION: ManageFamily.swift, inside showEditAlert(for:) method
        // FIND the alert.addAction line with "Add"/"Update" and REPLACE with:

        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let age = Int(alert.textFields?[1].text ?? ""),
                  let height = Double(alert.textFields?[2].text ?? "") else { return }

            if (age < 10 || age > 100) && (height < 90 || height > 220) {
                self.showResultAlert(title: "Invalid Age and Height", message: "Age must be between 10 and 100 while Height must be between 90 cm and 220 cm.")
                return
            }
            
            if age < 10 || age > 100 {
                self.showResultAlert(title: "Invalid Age", message: "Age must be between 10 and 100.")
                return
            }

            if height < 90 || height > 220 {
                self.showResultAlert(title: "Invalid Height", message: "Height must be between 90 cm and 220 cm.")
                return
            }

            
            // FIX: Corrected gender mapping (index 0 = Male, index 1 = Female)
            let gender = genderControl.selectedSegmentIndex == 0 ? "Male" : "Female"
            
            var updated = FamilyMember(name: name, age: age, height: height, gender: gender)
            
            // Show loading indicator
            let loadingAlert = UIAlertController(title: nil, message: "Saving...", preferredStyle: .alert)
            let indicator = UIActivityIndicatorView(style: .medium)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            loadingAlert.view.addSubview(indicator)
            NSLayoutConstraint.activate([
                indicator.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
                indicator.topAnchor.constraint(equalTo: loadingAlert.view.topAnchor, constant: 40)
            ])
            indicator.startAnimating()
            self.present(loadingAlert, animated: true)
            // ADD MODE: Use async add with completion
            FamilyStore.shared.addMember(updated) { result in
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        switch result {
                        case .success:
                            self.tableView.reloadData()
                            self.showResultAlert(title: "Success", message: "Member added successfully")
                        case .failure(let error):
                            self.showResultAlert(title: "Error", message: "Failed to add: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
        })
        present(alert, animated: true) {
            guard let container = alert.view.subviews.first?.subviews.first else { return }

            container.addSubview(genderControl)

            NSLayoutConstraint.activate([
                genderControl.topAnchor.constraint(equalTo: container.topAnchor, constant: 70),
                genderControl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                genderControl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                genderControl.heightAnchor.constraint(equalToConstant: 30)
            ])
        }
    }
    
    private func showResultAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}


//
//  ProgressView.swift
//  MyCal360
//
//  Weight progress visualization with member selection and insights
//

import UIKit

final class ProgressView: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let headerCard = UICard()
    private let selectorCard = UICard()
    private let chartCard = UICard()
    private let insightsCard = UICard()
    
    private let memberButton = UIButton(type: .system)
    private let chartContainerView = UIView()
    private let emptyStateView = UIView()
    private let insightsStack = UIStackView()
    
    private var selectedMember: FamilyMember?
    private var members: [FamilyMember] { FamilyStore.shared.members }
    
    private let maxPointsPerChart = 25
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Progress"
        view.backgroundColor = .systemGroupedBackground
        
        // Check if FamilyStore is configured
        guard FamilyStore.shared.userId != nil else {
            showAlert(title: "Error", message: "Please log in first")
            return
        }
        
        FamilyStore.shared.load { [weak self] _ in
            DispatchQueue.main.async {
                self?.setupUI()
                self?.autoSelectMember()
                self?.refreshChart()
            }
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle"),
            style: .plain,
            target: self,
            action: #selector(closeView)
        )
        navigationItem.leftBarButtonItem?.tintColor = .systemBlue
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataChange),
            name: .familyStoreDidChange,
            object: nil
        )
    }
    
    @objc private func closeView() {
        dismiss(animated: true)
    }
    
    @objc private func handleDataChange() {
        refreshChart()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // Scroll view setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48)
        ])
        
        setupSelectorCard()
        setupChartCard()
        setupInsightsCard()
        setupEmptyState()
    }
    
    private func setupSelectorCard() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16     // Increased to separate sections nicely
        stack.translatesAutoresizingMaskIntoConstraints = false

        // ------------------------------
        // 1. HEADER CONTENT (moved here)
        // ------------------------------
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.spacing = 6

        let headerTitle = UILabel()
        headerTitle.text = "Your progress, visualized!"
        headerTitle.font = .systemFont(ofSize: 17, weight: .semibold)

        let headerSubtitle = UILabel()
        headerSubtitle.text = "Track weight changes over time"
        headerSubtitle.font = .systemFont(ofSize: 13)
        headerSubtitle.textColor = .secondaryLabel
        headerSubtitle.numberOfLines = 0

        headerStack.addArrangedSubview(headerTitle)
        headerStack.addArrangedSubview(headerSubtitle)

        // ------------------------------
        // 2. SELECTOR SECTION
        // ------------------------------
        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.spacing = 8

        let icon = UIImageView(image: UIImage(systemName: "person.3"))
        icon.tintColor = .systemBlue
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 20).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = "Who do you want to chart?"
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        titleRow.addArrangedSubview(icon)
        titleRow.addArrangedSubview(titleLabel)
        titleRow.addArrangedSubview(UIView()) // Spacer

        let descLabel = UILabel()
        descLabel.text = "Choose a person to see their weight trend and insights."
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0

        memberButton.setTitle("Select Member", for: .normal)
        memberButton.backgroundColor = .secondarySystemBackground
        memberButton.layer.cornerRadius = 10
        memberButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        memberButton.contentHorizontalAlignment = .leading
        memberButton.setTitleColor(.systemBlue, for: .normal)
        memberButton.titleLabel?.font = .systemFont(ofSize: 15)
        memberButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)

        configureMemberDropdown()

        // ------------------------------
        // FINAL ORDER IN THE CARD
        // ------------------------------
        stack.addArrangedSubview(headerStack)     // Header first
        stack.addArrangedSubview(titleRow)        // Then selector title
        stack.addArrangedSubview(descLabel)       // Then description
        stack.addArrangedSubview(memberButton)    // Then selector button

        selectorCard.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: selectorCard.layoutMarginsGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: selectorCard.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: selectorCard.layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: selectorCard.layoutMarginsGuide.bottomAnchor)
        ])

        contentStack.addArrangedSubview(selectorCard)
    }

    
    private func setupChartCard() {
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.heightAnchor.constraint(equalToConstant: 280).isActive = true
        
        chartCard.addSubview(chartContainerView)
        NSLayoutConstraint.activate([
            chartContainerView.topAnchor.constraint(equalTo: chartCard.layoutMarginsGuide.topAnchor),
            chartContainerView.leadingAnchor.constraint(equalTo: chartCard.layoutMarginsGuide.leadingAnchor),
            chartContainerView.trailingAnchor.constraint(equalTo: chartCard.layoutMarginsGuide.trailingAnchor),
            chartContainerView.bottomAnchor.constraint(equalTo: chartCard.layoutMarginsGuide.bottomAnchor)
        ])
        
        contentStack.addArrangedSubview(chartCard)
    }
    
    private func setupInsightsCard() {
        insightsStack.axis = .vertical
        insightsStack.spacing = 12
        insightsStack.translatesAutoresizingMaskIntoConstraints = false
        
        insightsCard.addSubview(insightsStack)
        NSLayoutConstraint.activate([
            insightsStack.topAnchor.constraint(equalTo: insightsCard.layoutMarginsGuide.topAnchor),
            insightsStack.leadingAnchor.constraint(equalTo: insightsCard.layoutMarginsGuide.leadingAnchor),
            insightsStack.trailingAnchor.constraint(equalTo: insightsCard.layoutMarginsGuide.trailingAnchor),
            insightsStack.bottomAnchor.constraint(equalTo: insightsCard.layoutMarginsGuide.bottomAnchor)
        ])
        
        contentStack.addArrangedSubview(insightsCard)
        insightsCard.isHidden = true
    }
    
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: "chart.line.uptrend.xyaxis"))
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = "No data yet"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        
        let descLabel = UILabel()
        descLabel.text = "Add weight entries to see your progress chart here."
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(descLabel)
        
        emptyStateView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: emptyStateView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: emptyStateView.trailingAnchor, constant: -20)
        ])
        
        chartContainerView.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
        ])
    }
    
    // MARK: - Member Selection
    private func configureMemberDropdown() {
        if members.isEmpty {
            memberButton.isEnabled = false
            memberButton.setTitle("No members available", for: .normal)
            return
        }
        
        let sortedMembers = members.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        let actions = sortedMembers.map { member in
            UIAction(title: member.name) { [weak self] _ in
                self?.selectedMember = member
                self?.memberButton.setTitle(member.name, for: .normal)
                self?.refreshChart()
            }
        }
        
        memberButton.menu = UIMenu(title: "Select Member", children: actions)
        memberButton.showsMenuAsPrimaryAction = true
    }
    
    private func autoSelectMember() {
        if members.count == 1 {
            selectedMember = members.first
            memberButton.setTitle(selectedMember?.name, for: .normal)
        }
    }
    
    // MARK: - Chart & Insights
    private func refreshChart() {
        guard let member = selectedMember else {
            showEmptyState()
            return
        }
        
        let weights = member.weights.sorted { $0.date < $1.date }
        let recentWeights = Array(weights.suffix(maxPointsPerChart))
        
        if recentWeights.isEmpty {
            showEmptyState()
            return
        }
        
        // Clear previous chart
        chartContainerView.subviews.forEach { if $0 != emptyStateView { $0.removeFromSuperview() } }
        emptyStateView.isHidden = true
        
        // Create simple chart visualization
        createSimpleChart(with: recentWeights, for: member)
        
        // Update insights
        updateInsights(with: recentWeights, for: member)
    }
    
    private func showEmptyState() {
        chartContainerView.subviews.forEach { if $0 != emptyStateView { $0.removeFromSuperview() } }
        emptyStateView.isHidden = false
        insightsCard.isHidden = true
    }
    
    private func createSimpleChart(with weights: [WeightEntry], for member: FamilyMember) {
        let chartView = SimpleLineChartView(weights: weights, memberName: member.name)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        
        chartContainerView.addSubview(chartView)
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            chartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            chartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
        ])
    }
    
    private func updateInsights(with weights: [WeightEntry], for member: FamilyMember) {
        insightsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard weights.count >= 2,
              let earliest = weights.first,
              let latest = weights.last else {
            insightsCard.isHidden = true
            return
        }
        
        // Calculate insights
        let totalDelta = latest.weight - earliest.weight
        let days = latest.date.timeIntervalSince(earliest.date) / 86_400.0
        let weeks = max(days / 7.0, 0.001)
        let perWeek = totalDelta / weeks
        
        // Trend icon
        let (icon, color): (String, UIColor) = {
            if totalDelta < -0.05 { return ("arrow.down.right.circle.fill", .systemGreen) }
            if totalDelta > 0.05 { return ("arrow.up.right.circle.fill", .systemRed) }
            return ("arrow.left.and.right.circle.fill", .systemOrange)
        }()
        
        // Header
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        let headerLabel = UILabel()
        headerLabel.text = "Insights for \(member.name)"
        headerLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        
        headerStack.addArrangedSubview(iconView)
        headerStack.addArrangedSubview(headerLabel)
        headerStack.addArrangedSubview(UIView()) // Spacer
        
        insightsStack.addArrangedSubview(headerStack)
        
        // Insights rows
        addInsightRow(label: "Total change", value: formatChange(totalDelta))
        addInsightRow(label: "Avg change / week", value: formatChange(perWeek))
        addInsightRow(label: "Date range", value: formatDateRange(from: earliest.date, to: latest.date))
        addInsightRow(label: "Data points", value: "\(weights.count)")
        
        insightsCard.isHidden = false
    }
    
    private func addInsightRow(label: String, value: String) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 13)
        labelView.textColor = .secondaryLabel
        
        let valueView = UILabel()
        valueView.text = value
        valueView.font = .systemFont(ofSize: 13, weight: .semibold)
        valueView.textAlignment = .right
        
        row.addArrangedSubview(labelView)
        row.addArrangedSubview(valueView)
        
        insightsStack.addArrangedSubview(row)
    }
    
    // MARK: - Helpers
    private func formatChange(_ value: Double) -> String {
        let absText = String(format: "%.2f", abs(value))
        return (value >= 0 ? "+" : "–") + absText + " kg"
    }
    
    private func formatDateRange(from start: Date, to end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Simple Line Chart View
class SimpleLineChartView: UIView {
    private let weights: [WeightEntry]
    private let memberName: String
    
    init(weights: [WeightEntry], memberName: String) {
        self.weights = weights
        self.memberName = memberName
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func draw(_ rect: CGRect) {
//        guard let context = UIGraphicsGetCurrentContext(), weights.count >= 2 else {
//            drawPlaceholder(in: rect)
//            return
//        }
//        
//        let padding: CGFloat = 40
//        let chartRect = CGRect(x: padding, y: padding, width: rect.width - padding * 2, height: rect.height - padding * 2)
//        
//        // Get min/max values
//        let weightValues = weights.map { $0.weight }
//        let minWeight = weightValues.min()! - 2
//        let maxWeight = weightValues.max()! + 2
//        let weightRange = maxWeight - minWeight
//        
//        // Draw axes
//        context.setStrokeColor(UIColor.separator.cgColor)
//        context.setLineWidth(1)
//        context.move(to: CGPoint(x: chartRect.minX, y: chartRect.minY))
//        context.addLine(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
//        context.addLine(to: CGPoint(x: chartRect.maxX, y: chartRect.maxY))
//        context.strokePath()
//        
//        // Draw line
//        context.setStrokeColor(UIColor.systemBlue.cgColor)
//        context.setLineWidth(2)
//        
//        var points: [CGPoint] = []
//        for (index, weight) in weights.enumerated() {
//            let x = chartRect.minX + (CGFloat(index) / CGFloat(weights.count - 1)) * chartRect.width
//            let normalizedWeight = (weight.weight - minWeight) / weightRange
//            let y = chartRect.maxY - normalizedWeight * chartRect.height
//            points.append(CGPoint(x: x, y: y))
//        }
//        
//        for (index, point) in points.enumerated() {
//            if index == 0 {
//                context.move(to: point)
//            } else {
//                context.addLine(to: point)
//            }
//        }
//        context.strokePath()
//        
//        // Draw points
//        context.setFillColor(UIColor.systemBlue.cgColor)
//        for point in points {
//            context.fillEllipse(in: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6))
//        }
//        
//        // Draw labels
//        drawLabels(minWeight: minWeight, maxWeight: maxWeight, chartRect: chartRect)
//    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), weights.count >= 2 else {
            drawPlaceholder(in: rect)
            return
        }

        let padding: CGFloat = 40
        let chartRect = CGRect(x: padding, y: padding, width: rect.width - padding * 2, height: rect.height - padding * 2)

        // Get min/max values
        let weightValues = weights.map { $0.weight }
        let minWeight = weightValues.min()! - 2
        let maxWeight = weightValues.max()! + 2
        let weightRange = maxWeight - minWeight

        // Draw axes
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: chartRect.minX, y: chartRect.minY))
        context.addLine(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
        context.addLine(to: CGPoint(x: chartRect.maxX, y: chartRect.maxY))
        context.strokePath()

        // Draw line
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2)

        var points: [CGPoint] = []
        for (index, weight) in weights.enumerated() {
            let x = chartRect.minX + (CGFloat(index) / CGFloat(weights.count - 1)) * chartRect.width
            let normalizedWeight = (weight.weight - minWeight) / weightRange
            let y = chartRect.maxY - normalizedWeight * chartRect.height
            points.append(CGPoint(x: x, y: y))
        }

        for (index, point) in points.enumerated() {
            if index == 0 {
                context.move(to: point)
            } else {
                context.addLine(to: point)
            }
        }
        context.strokePath()

        // Draw points
        context.setFillColor(UIColor.systemBlue.cgColor)
        for point in points {
            context.fillEllipse(in: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6))
        }

        // Draw labels
        drawLabels(minWeight: minWeight, maxWeight: maxWeight, chartRect: chartRect)

        // -------------------------------
        // AXIS LABELS (NEW)
        // -------------------------------
        let axisFont: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ]

        // X-Axis label
        let xLabel = "Date" as NSString
        let xSize = xLabel.size(withAttributes: axisFont)
        xLabel.draw(
            at: CGPoint(
                x: chartRect.minX + (chartRect.width - xSize.width) / 2,
                y: chartRect.maxY + 8
            ),
            withAttributes: axisFont
        )

        // Y-Axis label (rotated)
        let yLabel = "Weight (kg)" as NSString
        let ySize = yLabel.size(withAttributes: axisFont)

        context.saveGState()

        // Move context to position where label should appear
        context.translateBy(
            x: chartRect.minX - 28,
            y: chartRect.minY + (chartRect.height + ySize.width) / 2
        )

        // Rotate -90 degrees
        context.rotate(by: -.pi / 2)

        // Draw label
        yLabel.draw(
            at: CGPoint(x: 0, y: 0),
            withAttributes: axisFont
        )

        context.restoreGState()
    }

    
    private func drawLabels(minWeight: Double, maxWeight: Double, chartRect: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        // Y-axis labels
        let minLabel = String(format: "%.1f", minWeight) as NSString
        let maxLabel = String(format: "%.1f", maxWeight) as NSString
        
        minLabel.draw(at: CGPoint(x: 5, y: chartRect.maxY - 10), withAttributes: attributes)
        maxLabel.draw(at: CGPoint(x: 5, y: chartRect.minY), withAttributes: attributes)
        
        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: UIColor.label
        ]
        let title = "Weight Trend - \(memberName)" as NSString
        let titleSize = title.size(withAttributes: titleAttrs)
        title.draw(at: CGPoint(x: (bounds.width - titleSize.width) / 2, y: 10), withAttributes: titleAttrs)
    }
    
    private func drawPlaceholder(in rect: CGRect) {
        let text = "Not enough data to draw chart" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(at: CGPoint(x: (rect.width - size.width) / 2, y: (rect.height - size.height) / 2), withAttributes: attributes)
    }
}

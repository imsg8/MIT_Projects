//
//  ResultsViewController.swift
//  MyCal360
//
//  Created by Shivang Gulati on 07/11/25.
//

import UIKit

class ResultsViewController: UIViewController {

    // MARK: - Data Passed from First ViewController
    var maintenanceCalories: Double = 0.0
    var goalIndex: Int = 0
    var genderIndex: Int = 0
    var selectedActivity: ViewController.ActivityLevel = .sedentary
    var age: Int = 0
    var height: Double = 0.0
    var weight: Double = 0.0
    var name: String = ""

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let maintenanceLabel = UILabel()
    private let mildLabel = UILabel()
    private let moderateLabel = UILabel()
    private let extremeLabel = UILabel()
    private let bmiLabel = UILabel()
    private let proteinLabel = UILabel()
    private let carbLabel = UILabel()
    
    // Chart
    private let chartScrollView = UIScrollView()
    private let chartContainer = UIView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Results for \(name)"
        view.backgroundColor = .systemGroupedBackground
        
        setupScrollView()
        setupSections()
        populateResults()
        setupBMIChart()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(closeView)
        )
    }
    
    @objc private func closeView() {
        dismiss(animated: true)
    }

    // MARK: - Scroll & Stack Layout
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
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -40)
        ])
    }

    // MARK: - Section Setup
    private func setupSections() {
        let header = makeHeader(title: "Daily Caloric & Macro Breakdown", systemImage: "chart.bar.doc.horizontal")
        contentStack.addArrangedSubview(header)
        
        let caloriesSection = makeSection(
            title: "Daily Calorie Goals",
            icon: "flame.fill",
            labels: [maintenanceLabel, mildLabel, moderateLabel, extremeLabel]
        )
        contentStack.addArrangedSubview(caloriesSection)
        
        let bmiSection = makeSection(
            title: "BMI & Body Metrics",
            icon: "figure.strengthtraining.traditional",
            labels: [bmiLabel]
        )
        contentStack.addArrangedSubview(bmiSection)
        
        contentStack.addArrangedSubview(makeChartCard())
        
        let macrosSection = makeSection(
            title: "Macronutrient Targets",
            icon: "fork.knife.circle.fill",
            labels: [proteinLabel, carbLabel]
        )
        contentStack.addArrangedSubview(macrosSection)
    }

    // MARK: - Populate Values (restored)
    private func populateResults() {
        guard height > 0, weight > 0 else {
            maintenanceLabel.text = "Enter valid data to calculate results."
            return
        }

        let base = maintenanceCalories
        var mild: Double = 0, moderate: Double = 0, extreme: Double = 0
        
        if goalIndex == 0 { // Weight Loss
            mild = base - 250
            moderate = base - 500
            extreme = base - 1000
        } else if goalIndex == 1 { // Weight Gain
            mild = base + 250
            moderate = base + 500
            extreme = base + 1000
        }
//        print("Mild value: \(mild), Moderate value: \(moderate), Extreme value: \(extreme), Base value: \(base) AHAHAHAHAH, Goal Index: \(goalIndex)")
        func attributedLabel(text: String, value: Int, lineColor: UIColor) -> NSAttributedString {
            let main = "\(text): \(value) kcal/day  (Graph line "
            let dash = "———"
            let close = ")"

            let full = NSMutableAttributedString(string: main + dash + close)

            // Color the dash to match graph line
            let range = (full.string as NSString).range(of: dash)
            full.addAttribute(.foregroundColor, value: lineColor, range: range)

            // Keep the rest standard
            full.addAttribute(.foregroundColor, value: UIColor.label, range: NSMakeRange(0, main.count))
            full.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: NSMakeRange(main.count + dash.count, close.count))

            return full
        }

        maintenanceLabel.text = "Maintenance: \(Int(base)) kcal/day"
        mildLabel.attributedText = attributedLabel(text: "Mild", value: Int(mild), lineColor: .systemGreen)
        moderateLabel.attributedText = attributedLabel(text: "Moderate", value: Int(moderate), lineColor: .systemOrange)
        extremeLabel.attributedText = attributedLabel(text: "Extreme", value: Int(extreme), lineColor: .systemRed)


        let heightM = height / 100.0
        let bmi = weight / (heightM * heightM)
        bmiLabel.text = String(format: "BMI: %.1f", bmi)

        let protein = proteinRange(for: selectedActivity, weightKg: weight)
        proteinLabel.text = "Protein: \(protein) g/day"

        let carbs = carbRange(for: base)
        carbLabel.text = "Carbs: \(carbs) g/day"
    }

    // MARK: - Chart UI Setup
    private func makeChartCard() -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 14
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.05
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        
        let titleLabel = UILabel()
        titleLabel.text = "Projected BMI Journey"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "This chart shows how many weeks it may take to reach your healthy BMI target."
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        chartScrollView.translatesAutoresizingMaskIntoConstraints = false
        chartScrollView.showsHorizontalScrollIndicator = true
        chartScrollView.alwaysBounceHorizontal = true
        chartScrollView.layer.cornerRadius = 12
        chartScrollView.backgroundColor = .tertiarySystemGroupedBackground
        chartContainer.translatesAutoresizingMaskIntoConstraints = false
        
        chartScrollView.addSubview(chartContainer)
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(chartScrollView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            
            chartScrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 10),
            chartScrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            chartScrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            chartScrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
            chartScrollView.heightAnchor.constraint(equalToConstant: 250),
            
            chartContainer.topAnchor.constraint(equalTo: chartScrollView.topAnchor),
            chartContainer.bottomAnchor.constraint(equalTo: chartScrollView.bottomAnchor),
            chartContainer.leadingAnchor.constraint(equalTo: chartScrollView.leadingAnchor),
            chartContainer.trailingAnchor.constraint(equalTo: chartScrollView.trailingAnchor),
            chartContainer.heightAnchor.constraint(equalTo: chartScrollView.heightAnchor),
            chartContainer.widthAnchor.constraint(equalToConstant: 800)
        ])
        
        return container
    }

    private func setupBMIChart() {
        guard height > 0, weight > 0 else { return }

        let heightM = height / 100.0
        let initialBMI = weight / (heightM * heightM)
        let weeks = Array(0...52)

        // Chart layout constants
        let chartWidth: CGFloat = 800
        let chartHeight: CGFloat = 200
        let horizontalPadding: CGFloat = 40
        let verticalPadding: CGFloat = 25

        // Compute BMI range
        let maxBMI = ceil(initialBMI)
        let minBMI = max(18.0, initialBMI - 5.0)
        let bmiStep = (maxBMI - minBMI) / 5

        // Paths for the three curves
        let mildPath = UIBezierPath()
        let moderatePath = UIBezierPath()
        let extremePath = UIBezierPath()

        func yForBMI(_ bmi: Double) -> CGFloat {
            let normalized = (bmi - minBMI) / (maxBMI - minBMI)
            return chartHeight + verticalPadding - CGFloat(normalized) * chartHeight
        }

        func xForWeek(_ week: Int) -> CGFloat {
            return horizontalPadding + CGFloat(week) * ((chartWidth - horizontalPadding * 2) / CGFloat(weeks.count - 1))
        }

        // Draw BMI paths
        for (i, week) in weeks.enumerated() {
            let mildLoss = Double(week) * 0.25
            let moderateLoss = Double(week) * 0.5
            let extremeLoss = Double(week) * 1.0

            let mildBMI = (weight - mildLoss) / (heightM * heightM)
            let moderateBMI = (weight - moderateLoss) / (heightM * heightM)
            let extremeBMI = (weight - extremeLoss) / (heightM * heightM)

            let x = xForWeek(week)

            if i == 0 {
                mildPath.move(to: CGPoint(x: x, y: yForBMI(mildBMI)))
                moderatePath.move(to: CGPoint(x: x, y: yForBMI(moderateBMI)))
                extremePath.move(to: CGPoint(x: x, y: yForBMI(extremeBMI)))
            } else {
                mildPath.addLine(to: CGPoint(x: x, y: yForBMI(mildBMI)))
                moderatePath.addLine(to: CGPoint(x: x, y: yForBMI(moderateBMI)))
                extremePath.addLine(to: CGPoint(x: x, y: yForBMI(extremeBMI)))
            }
        }

        // --- Draw Axes ---
        let axisPath = UIBezierPath()
        let leftX = horizontalPadding
        let rightX = chartWidth - horizontalPadding
        let bottomY = chartHeight + verticalPadding
        let topY = verticalPadding

        // Y-axis
        axisPath.move(to: CGPoint(x: leftX, y: bottomY))
        axisPath.addLine(to: CGPoint(x: leftX, y: topY))
        // X-axis
        axisPath.move(to: CGPoint(x: leftX, y: bottomY))
        axisPath.addLine(to: CGPoint(x: rightX, y: bottomY))

        let axisLayer = CAShapeLayer()
        axisLayer.path = axisPath.cgPath
        axisLayer.strokeColor = UIColor.systemGray3.cgColor
        axisLayer.lineWidth = 1.0
        chartContainer.layer.addSublayer(axisLayer)

        // --- Draw Tick Marks + Labels ---
        for i in 0..<weeks.count {
            let x = xForWeek(weeks[i])
            let tick = UIBezierPath()
            tick.move(to: CGPoint(x: x, y: bottomY))
            tick.addLine(to: CGPoint(x: x, y: bottomY + 5))
            let tickLayer = CAShapeLayer()
            tickLayer.path = tick.cgPath
            tickLayer.strokeColor = UIColor.systemGray3.cgColor
            tickLayer.lineWidth = 1
            chartContainer.layer.addSublayer(tickLayer)

            if i % 2 == 0 { // Label every 2 weeks
                let label = UILabel()
                label.text = "\(weeks[i])"
                label.font = UIFont.systemFont(ofSize: 10)
                label.textColor = .secondaryLabel
                label.sizeToFit()
                label.center = CGPoint(x: x, y: bottomY + 14)
                chartContainer.addSubview(label)
            }
        }

        for j in 0...5 {
            let bmiValue = minBMI + Double(j) * bmiStep
            let y = yForBMI(bmiValue)
            let line = UIBezierPath()
            line.move(to: CGPoint(x: leftX, y: y))
            line.addLine(to: CGPoint(x: rightX, y: y))

            let lineLayer = CAShapeLayer()
            lineLayer.path = line.cgPath
            lineLayer.strokeColor = UIColor.systemGray5.cgColor
            lineLayer.lineWidth = 0.5
            chartContainer.layer.addSublayer(lineLayer)

            let label = UILabel()
            label.text = String(format: "%.1f", bmiValue)
            label.font = UIFont.systemFont(ofSize: 10)
            label.textColor = .secondaryLabel
            label.sizeToFit()
            label.center = CGPoint(x: leftX - 18, y: y)
            chartContainer.addSubview(label)
        }

        // --- Draw BMI Lines ---
        func makeLine(path: UIBezierPath, color: UIColor) -> CAShapeLayer {
            let line = CAShapeLayer()
            line.path = path.cgPath
            line.strokeColor = color.cgColor
            line.fillColor = UIColor.clear.cgColor
            line.lineWidth = 2.5
            line.lineJoin = .round
            return line
        }

        chartContainer.layer.addSublayer(makeLine(path: mildPath, color: .systemGreen))
        chartContainer.layer.addSublayer(makeLine(path: moderatePath, color: .systemOrange))
        chartContainer.layer.addSublayer(makeLine(path: extremePath, color: .systemRed))

        // --- Legend ---
        let legend = UIStackView()
        legend.axis = .horizontal
        legend.spacing = 14
        legend.alignment = .center
        legend.translatesAutoresizingMaskIntoConstraints = false

        func makeLegendItem(color: UIColor, text: String) -> UIView {
            let dot = UIView()
            dot.backgroundColor = color
            dot.layer.cornerRadius = 5
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 10).isActive = true

            let label = UILabel()
            label.text = text
            label.font = UIFont.systemFont(ofSize: 13)

            let hStack = UIStackView(arrangedSubviews: [dot, label])
            hStack.axis = .horizontal
            hStack.spacing = 6
            return hStack
        }
        
        chartContainer.layoutIfNeeded()
        chartContainer.clipsToBounds = false
        
    }


    // MARK: - UI Helpers
    private func makeHeader(title: String, systemImage: String) -> UIView {
        let container = UIView()
        let icon = UIImageView(image: UIImage(systemName: systemImage))
        icon.tintColor = .systemBlue
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.numberOfLines = 2
        
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func makeSection(title: String, icon: String, labels: [UILabel]) -> UIView {
        let sectionStack = UIStackView()
        sectionStack.axis = .vertical
        sectionStack.spacing = 8
        
        let titleStack = UIStackView()
        titleStack.axis = .horizontal
        titleStack.alignment = .center
        titleStack.spacing = 8
        
        let symbol = UIImageView(image: UIImage(systemName: icon))
        symbol.tintColor = .systemTeal
        symbol.contentMode = .scaleAspectFit
        symbol.widthAnchor.constraint(equalToConstant: 22).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        titleStack.addArrangedSubview(symbol)
        titleStack.addArrangedSubview(titleLabel)
        
        let divider = UIView()
        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.4)
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        sectionStack.addArrangedSubview(titleStack)
        sectionStack.addArrangedSubview(divider)
        
        labels.forEach { label in
            label.font = UIFont.systemFont(ofSize: 16)
            label.numberOfLines = 2
            sectionStack.addArrangedSubview(label)
        }
        
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4
        
        card.addSubview(sectionStack)
        sectionStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sectionStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            sectionStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            sectionStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            sectionStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
        
        return card
    }

    // MARK: - Math Helpers
    private func proteinRange(for activity: ViewController.ActivityLevel, weightKg: Double) -> String {
        let map: [ViewController.ActivityLevel: (Double, Double)] = [
            .sedentary: (1.2, 1.6),
            .light: (1.4, 1.8),
            .moderate: (1.6, 2.2),
            .active: (1.8, 2.2),
            .veryActive: (1.8, 2.4),
            .extremelyActive: (2.0, 2.6)
        ]
        let range = map[activity] ?? (1.6, 2.2)
        let low = Int(round(weightKg * range.0))
        let high = Int(round(weightKg * range.1))
        return "\(low)–\(high)"
    }

    private func carbRange(for kcal: Double) -> String {
        let g1 = Int(round((kcal * 0.40) / 4.0))
        let g2 = Int(round((kcal * 0.55) / 4.0))
        return "\(g1)–\(g2)"
    }
}

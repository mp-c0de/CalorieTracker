// TutorialManager.swift - Manages tutorial tips with coach marks and arrows
// Made by mpcode

import SwiftUI
import TipKit

// MARK: - Tutorial Step Enum

enum TutorialStep: Int, CaseIterable {
    case settings = 0
    case calorieRing = 1
    case swipeVitamins = 2
    case addFoodTab = 3
    case aiQuickAdd = 4
    case scanBarcode = 5
    case productsTab = 6
    case manualTab = 7
    case aiLogsTab = 8
    case completed = 9

    var next: TutorialStep {
        TutorialStep(rawValue: rawValue + 1) ?? .completed
    }

    // Which tab this step belongs to (for auto-navigation)
    var tabIndex: Int? {
        switch self {
        case .settings, .calorieRing, .swipeVitamins:
            return 0 // Today tab
        case .addFoodTab, .aiQuickAdd, .scanBarcode:
            return 1 // Add Food tab
        case .productsTab:
            return 2 // Products tab
        case .manualTab:
            return 3 // Manual tab
        case .aiLogsTab:
            return 4 // AI Logs tab
        case .completed:
            return nil
        }
    }

    // Tooltip content for each step
    var title: String {
        switch self {
        case .settings: return "Settings & Profile"
        case .calorieRing: return "Your Daily Progress"
        case .swipeVitamins: return "Swipe for More"
        case .addFoodTab: return "Add Food Tab"
        case .aiQuickAdd: return "AI Quick Add"
        case .scanBarcode: return "Scan Barcodes"
        case .productsTab: return "Products Tab"
        case .manualTab: return "Manual Products"
        case .aiLogsTab: return "AI Logs Tab"
        case .completed: return ""
        }
    }

    var message: String {
        switch self {
        case .settings: return "Tap here to set your calorie goals, personal info, and AI preferences"
        case .calorieRing: return "Track your calories here - the ring fills as you log food"
        case .swipeVitamins: return "Swipe left to see vitamins, minerals, and calorie history"
        case .addFoodTab: return "Tap the Add Food tab below to log your meals and snacks"
        case .aiQuickAdd: return "Just type what you ate - AI estimates the calories automatically!"
        case .scanBarcode: return "Scan product barcodes to get instant nutrition info"
        case .productsTab: return "All your scanned products are saved here for quick access"
        case .manualTab: return "Products you've added manually without barcodes"
        case .aiLogsTab: return "View all AI estimations and responses here. That's the tour!"
        case .completed: return ""
        }
    }

    var icon: String {
        switch self {
        case .settings: return "gear"
        case .calorieRing: return "circle.dotted"
        case .swipeVitamins: return "hand.draw"
        case .addFoodTab: return "plus.circle.fill"
        case .aiQuickAdd: return "sparkles"
        case .scanBarcode: return "barcode.viewfinder"
        case .productsTab: return "archivebox"
        case .manualTab: return "square.and.pencil"
        case .aiLogsTab: return "doc.text.magnifyingglass"
        case .completed: return ""
        }
    }

    var buttonText: String {
        switch self {
        case .aiLogsTab: return "Finish Tour"
        default: return "Got it!"
        }
    }

    // Step counter (e.g., "1 of 9")
    var stepIndicator: String {
        guard self != .completed else { return "" }
        return "\(rawValue + 1) of 9"
    }
}

// MARK: - Tutorial Anchor Preference

struct TutorialAnchorPreference: Equatable {
    let step: TutorialStep
    let bounds: Anchor<CGRect>
}

struct TutorialAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [TutorialAnchorPreference] = []

    static func reduce(value: inout [TutorialAnchorPreference], nextValue: () -> [TutorialAnchorPreference]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - Tutorial Anchor Modifier

struct TutorialAnchorModifier: ViewModifier {
    let step: TutorialStep

    func body(content: Content) -> some View {
        content
            .anchorPreference(key: TutorialAnchorPreferenceKey.self, value: .bounds) { anchor in
                [TutorialAnchorPreference(step: step, bounds: anchor)]
            }
    }
}

extension View {
    /// Mark this view as the target for a tutorial step
    func tutorialAnchor(for step: TutorialStep) -> some View {
        modifier(TutorialAnchorModifier(step: step))
    }
}

// MARK: - Tutorial Manager

@Observable
class TutorialManager {
    static let shared = TutorialManager()

    // Current step in the tutorial sequence
    var currentStep: TutorialStep {
        didSet {
            UserDefaults.standard.set(currentStep.rawValue, forKey: "tutorialStep")
        }
    }

    // Check if user has completed onboarding
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    // Whether tutorial is actively showing
    var isShowingTutorial: Bool {
        currentStep != .completed
    }

    private init() {
        let rawValue = UserDefaults.standard.integer(forKey: "tutorialStep")
        self.currentStep = TutorialStep(rawValue: rawValue) ?? .settings
    }

    /// Configure TipKit - call this on app launch
    static func configureTips() {
        do {
            try Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        } catch {
            print("TipKit configuration failed: \(error)")
        }
    }

    /// Advance to the next tutorial step
    func advanceToNextStep() {
        currentStep = currentStep.next
    }

    /// Skip the entire tutorial
    func skipTutorial() {
        currentStep = .completed
    }

    /// Reset all tips to show tutorial again
    func resetAllTips() {
        currentStep = .settings
    }

    /// Alias for resetAllTips (used by SettingsView)
    func resetAllHints() {
        resetAllTips()
    }

    /// Mark a hint as seen (legacy stub for CoachMarkOverlay compatibility)
    func markHintSeen(_ id: String) {
        // No-op - we use step-based tracking now
    }

    /// Reset onboarding (for testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        resetAllTips()
    }
}

// GlobalTutorialOverlay has been moved to ContentView.swift as TutorialOverlayContent

// MARK: - Simple Tutorial Card (Always Centered)

struct TutorialCardSimple: View {
    let step: TutorialStep
    let onGotIt: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with step indicator and skip
            HStack {
                Text(step.stepIndicator)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Skip Tour") {
                    onSkip()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Icon and content
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: step.icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(step.title)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(step.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Got it button
            Button {
                onGotIt()
            } label: {
                Text(step.buttonText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
}

// MARK: - Spotlight Cutout (just the bright hole)

struct SpotlightCutout: View {
    let targetRect: CGRect

    var body: some View {
        Canvas { context, size in
            // Draw a "clear" rounded rect where the target is
            let padding: CGFloat = 8
            let spotlightRect = targetRect.insetBy(dx: -padding, dy: -padding)

            // Use destination out to punch a hole in the parent overlay
            context.blendMode = .destinationOut
            context.fill(
                Path(roundedRect: spotlightRect, cornerRadius: 12),
                with: .color(.white)
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Spotlight Overlay (Dark with cutout)

struct SpotlightOverlay: View {
    let targetRect: CGRect?

    var body: some View {
        Canvas { context, size in
            // Fill entire canvas with dark color
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.black.opacity(0.7))
            )

            // Cut out the spotlight area if we have a target
            if let rect = targetRect {
                // Expand the cutout a bit for padding
                let padding: CGFloat = 8
                let spotlightRect = rect.insetBy(dx: -padding, dy: -padding)

                context.blendMode = .destinationOut
                context.fill(
                    Path(roundedRect: spotlightRect, cornerRadius: 12),
                    with: .color(.white)
                )
            }
        }
        .allowsHitTesting(true)
    }
}

// MARK: - Coach Mark Tooltip with Arrow

struct CoachMarkTooltip: View {
    let step: TutorialStep
    let targetRect: CGRect?
    let screenSize: CGSize
    let onGotIt: () -> Void
    let onSkip: () -> Void

    // Calculate if tooltip should be above or below target
    private var tooltipPosition: TooltipPosition {
        guard let rect = targetRect else { return .center }

        let targetCenterY = rect.midY
        let screenMidY = screenSize.height / 2

        // If target is in upper half, show tooltip below
        // If target is in lower half, show tooltip above
        if targetCenterY < screenMidY {
            return .below(targetRect: rect)
        } else {
            return .above(targetRect: rect)
        }
    }

    enum TooltipPosition {
        case above(targetRect: CGRect)
        case below(targetRect: CGRect)
        case center

        var arrowDirection: ArrowDirection {
            switch self {
            case .above: return .down
            case .below: return .up
            case .center: return .none
            }
        }
    }

    enum ArrowDirection {
        case up, down, none
    }

    var body: some View {
        VStack(spacing: 0) {
            switch tooltipPosition {
            case .below(let rect):
                // Arrow pointing up
                ArrowShape(direction: .up)
                    .fill(Color(.systemBackground))
                    .frame(width: 20, height: 10)
                    .offset(x: calculateArrowOffset(targetRect: rect))

                tooltipCard
                    .padding(.horizontal, 20)

                Spacer()

            case .above(let rect):
                Spacer()

                tooltipCard
                    .padding(.horizontal, 20)

                ArrowShape(direction: .down)
                    .fill(Color(.systemBackground))
                    .frame(width: 20, height: 10)
                    .offset(x: calculateArrowOffset(targetRect: rect))

            case .center:
                Spacer()
                tooltipCard
                    .padding(.horizontal, 20)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: calculateVerticalOffset())
    }

    private func calculateArrowOffset(targetRect: CGRect) -> CGFloat {
        let arrowCenterX = targetRect.midX
        let screenCenterX = screenSize.width / 2
        return arrowCenterX - screenCenterX
    }

    private func calculateVerticalOffset() -> CGFloat {
        guard let rect = targetRect else { return 0 }

        switch tooltipPosition {
        case .below:
            // Position tooltip below the target
            return rect.maxY + 20 - (screenSize.height / 2) + 100
        case .above:
            // Position tooltip above the target
            return rect.minY - 20 - (screenSize.height / 2) - 100
        case .center:
            return 0
        }
    }

    private var tooltipCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with step indicator
            HStack {
                Text(step.stepIndicator)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    onSkip()
                } label: {
                    Text("Skip Tour")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Icon and content
            HStack(alignment: .top, spacing: 12) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: step.icon)
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(step.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Action button
            Button {
                onGotIt()
            } label: {
                Text(step.buttonText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background {
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .glassEffect(.regular.tint(.white.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
    }
}

// MARK: - Arrow Shape

struct ArrowShape: Shape {
    let direction: CoachMarkTooltip.ArrowDirection

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch direction {
        case .up:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        case .down:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()
        case .none:
            break
        }

        return path
    }
}

// MARK: - Legacy Tip Structs (for TipKit compatibility if needed)

struct SettingsTip: Tip {
    var title: Text { Text("Settings & Profile") }
    var message: Text? { Text("Tap here to set your calorie goals, personal info, and AI preferences") }
    var image: Image? { Image(systemName: "gear") }
    var actions: [Action] { Action(title: "Got it!") }
}

struct CalorieRingTip: Tip {
    var title: Text { Text("Your Daily Progress") }
    var message: Text? { Text("Track your calories here - the ring fills as you log food") }
    var image: Image? { Image(systemName: "circle.dotted") }
    var actions: [Action] { Action(title: "Got it!") }
}

struct SwipeVitaminsTip: Tip {
    var title: Text { Text("Swipe for More") }
    var message: Text? { Text("Swipe left to see vitamins, minerals, and calorie history") }
    var image: Image? { Image(systemName: "hand.draw") }
    var actions: [Action] { Action(title: "Got it!") }
}

struct AddFoodTabTip: Tip {
    var title: Text { Text("Add Food Tab") }
    var message: Text? { Text("Tap the Add Food tab below to log your meals and snacks") }
    var image: Image? { Image(systemName: "plus.circle.fill") }
    var actions: [Action] { Action(title: "Got it!") }
}

struct AIQuickAddTip: Tip {
    var title: Text { Text("AI Quick Add") }
    var message: Text? { Text("Just type what you ate - AI estimates the calories automatically!") }
    var image: Image? { Image(systemName: "sparkles") }
    var actions: [Action] { Action(title: "Got it!") }
}

struct ScanBarcodeTip: Tip {
    var title: Text { Text("Scan Barcodes") }
    var message: Text? { Text("Scan product barcodes to get instant nutrition info") }
    var image: Image? { Image(systemName: "barcode.viewfinder") }
    var actions: [Action] { Action(title: "Got it!") }
}

struct ProductsTabTip: Tip {
    var title: Text { Text("Products Tab") }
    var message: Text? { Text("All your scanned products are saved here for quick access") }
    var image: Image? { Image(systemName: "archivebox") }
    var actions: [Action] { Action(title: "Got it!") }
}

struct ManualTabTip: Tip {
    var title: Text { Text("Manual Products Tab") }
    var message: Text? { Text("Products you've added manually without barcodes") }
    var image: Image? { Image(systemName: "square.and.pencil") }
    var actions: [Action] { Action(title: "Got it!") }
}

struct AILogsTabTip: Tip {
    var title: Text { Text("AI Logs Tab") }
    var message: Text? { Text("View all AI estimations and responses here. That's the tour!") }
    var image: Image? { Image(systemName: "doc.text.magnifyingglass") }
    var actions: [Action] { Action(title: "Finish Tour") }
}

typealias TodayTabTip = SettingsTip

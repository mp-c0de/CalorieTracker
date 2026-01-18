// ContentView.swift - Main tab view
// Made by mpcode

import SwiftUI
import SwiftData
import TipKit

struct ContentView: View {
    @State private var selectedTab = 0

    // Observe tutorial state directly - this forces SwiftUI to re-render when it changes
    private var tutorialManager: TutorialManager { TutorialManager.shared }

    var body: some View {
        // Access tutorialManager properties to trigger observation tracking
        let currentStep = tutorialManager.currentStep
        let isShowingTutorial = tutorialManager.isShowingTutorial

        GeometryReader { geometry in
            ZStack {
                TabView(selection: $selectedTab) {
                    Tab("Today", systemImage: "flame.fill", value: 0) {
                        DashboardView()
                    }

                    Tab("Add Food", systemImage: "plus.circle.fill", value: 1) {
                        AddFoodView()
                    }

                    Tab("Products", systemImage: "barcode.viewfinder", value: 2) {
                        ProductListView()
                            .tutorialAnchor(for: .productsTab)
                    }

                    Tab("Manual", systemImage: "square.and.pencil", value: 3) {
                        ManualProductsView()
                            .tutorialAnchor(for: .manualTab)
                    }

                    Tab("AI Logs", systemImage: "doc.text.magnifyingglass", value: 4) {
                        AILogView()
                            .tutorialAnchor(for: .aiLogsTab)
                    }
                }

                // Tutorial overlay - directly in ZStack for proper observation
                if isShowingTutorial {
                    TutorialOverlayContent(
                        selectedTab: $selectedTab,
                        currentStep: currentStep,
                        geometry: geometry
                    )
                }
            }
        }
    }
}

// MARK: - Tutorial Overlay Content
struct TutorialOverlayContent: View {
    @Binding var selectedTab: Int
    let currentStep: TutorialStep
    let geometry: GeometryProxy

    var body: some View {
        ZStack {
            // Dark backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    // Block taps on backdrop
                }

            // Centered tooltip card
            VStack {
                Spacer()

                TutorialCardSimple(
                    step: currentStep,
                    onGotIt: {
                        withAnimation(.spring(duration: 0.3)) {
                            TutorialManager.shared.advanceToNextStep()
                            // Auto-switch tab if next step is on different tab
                            if let nextTab = TutorialManager.shared.currentStep.tabIndex,
                               nextTab != selectedTab {
                                selectedTab = nextTab
                            }
                        }
                    },
                    onSkip: {
                        withAnimation(.spring(duration: 0.3)) {
                            TutorialManager.shared.skipTutorial()
                        }
                    }
                )
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .animation(.spring(duration: 0.35), value: currentStep)
        .onChange(of: currentStep) { _, newStep in
            // Auto-switch tab when step changes
            if let targetTab = newStep.tabIndex, targetTab != selectedTab {
                withAnimation {
                    selectedTab = targetTab
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Product.self, FoodEntry.self, DailyLog.self, AIFoodTemplate.self, AILogEntry.self], inMemory: true)
        .task {
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
}

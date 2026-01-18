// CoachMarkOverlay.swift - Simple arrow tooltip component
// Made by mpcode

import SwiftUI

// MARK: - Simple Tooltip Arrow
struct TooltipArrow: View {
    let message: String
    let arrowDirection: ArrowDirection
    let onDismiss: () -> Void

    @State private var isAnimating = false

    enum ArrowDirection {
        case up, down, left, right
    }

    var body: some View {
        VStack(spacing: 0) {
            if arrowDirection == .down {
                arrowShape
                    .rotationEffect(.degrees(180))
            }

            HStack(spacing: 0) {
                if arrowDirection == .right {
                    arrowShape
                        .rotationEffect(.degrees(-90))
                }

                HStack(spacing: 6) {
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)

                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        onDismiss()
                    }
                }

                if arrowDirection == .left {
                    arrowShape
                        .rotationEffect(.degrees(90))
                }
            }

            if arrowDirection == .up {
                arrowShape
            }
        }
        // Wiggle animation
        .scaleEffect(isAnimating ? 1.03 : 1.0)
        .offset(y: isAnimating ? -2 : 2)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }

    private var arrowShape: some View {
        Triangle()
            .fill(.white)
            .frame(width: 16, height: 10)
            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Tooltip Modifier
struct TooltipModifier: ViewModifier {
    let id: String
    let message: String
    let arrowDirection: TooltipArrow.ArrowDirection
    @Binding var isVisible: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                if isVisible {
                    TooltipArrow(
                        message: message,
                        arrowDirection: arrowDirection,
                        onDismiss: {
                            isVisible = false
                            TutorialManager.shared.markHintSeen(id)
                        }
                    )
                    .offset(offset)
                    .transition(.scale.combined(with: .opacity))
                }
            }
    }

    private var alignment: Alignment {
        switch arrowDirection {
        case .up: return .bottom
        case .down: return .top
        case .left: return .trailing
        case .right: return .leading
        }
    }

    private var offset: CGSize {
        switch arrowDirection {
        case .up: return CGSize(width: 0, height: 8)
        case .down: return CGSize(width: 0, height: -8)
        case .left: return CGSize(width: 8, height: 0)
        case .right: return CGSize(width: -8, height: 0)
        }
    }
}

extension View {
    func tooltip(
        id: String,
        message: String,
        arrow: TooltipArrow.ArrowDirection = .up,
        isVisible: Binding<Bool>
    ) -> some View {
        modifier(TooltipModifier(
            id: id,
            message: message,
            arrowDirection: arrow,
            isVisible: isVisible
        ))
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        VStack(spacing: 80) {
            Button("Settings") { }
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .bottom) {
                    TooltipArrow(
                        message: "Tap to open settings",
                        arrowDirection: .up,
                        onDismiss: {}
                    )
                    .offset(y: 50)
                }

            Button("Add Food") { }
                .padding()
                .background(Color.orange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .top) {
                    TooltipArrow(
                        message: "Add your meals here",
                        arrowDirection: .down,
                        onDismiss: {}
                    )
                    .offset(y: -50)
                }
        }
        .padding()
    }
}

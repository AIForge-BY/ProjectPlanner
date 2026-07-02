import SwiftUI

struct PanelButtonStyle: ButtonStyle {
    let accent: Color
    var isProminent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(isProminent ? Color(red: 0.02, green: 0.06, blue: 0.08) : accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(background(configuration: configuration), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(accent.opacity(isProminent ? 0.0 : 0.32), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.74 : 1)
    }

    private func background(configuration: Configuration) -> Color {
        if isProminent {
            return accent.opacity(configuration.isPressed ? 0.76 : 0.92)
        }
        return accent.opacity(configuration.isPressed ? 0.18 : 0.11)
    }
}

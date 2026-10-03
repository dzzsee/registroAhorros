import SwiftUI

struct NFCScanButton: View {
    let isScanning: Bool
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 88, height: 88)
                    .shadow(color: .blue.opacity(0.4), radius: isScanning ? 20 : 10, x: 0, y: 4)

                Image(systemName: "nfc.symbol")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating, value: isScanning)
                    .scaleEffect(isScanning ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isScanning)

                if isScanning {
                    Circle()
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulse ? 1.5 : 1.0)
                        .opacity(pulse ? 0 : 0.5)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)
                        .onAppear { pulse = true }
                        .onDisappear { pulse = false }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isScanning)
    }
}
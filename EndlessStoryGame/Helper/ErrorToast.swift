

import SwiftUI

extension View {
    func errorToast(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(ErrorToastModifier(isPresented: isPresented, message: message))
    }
}

private struct ErrorToastModifier: ViewModifier {
    @State private var shouldShow: Bool = false
    @Binding var isPresented: Bool
    var message: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if shouldShow {
                VStack(spacing: 24) {
                    Text(message)
                    Button("OK") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .bold()
                    .padding(.bottom, -8)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 32)
                .background(Color(.secondarySystemBackground), in: .buttonBorder)
                .transition(.move(edge: .bottom).combined(with: .blurReplace))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .animation(.bouncy.speed(0.7), value: shouldShow)
        .onChange(of: isPresented, initial: true) { _, newValue in
            shouldShow = newValue
            guard isPresented else { return }
            Task {
                try? await Task.sleep(for: .seconds(5))
                isPresented = false
            }
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    VStack {
        Button("show/hide") {
            isPresented.toggle()
        }
    }
    .errorToast(isPresented: $isPresented, message: "發生錯誤，請稍後再試")
}

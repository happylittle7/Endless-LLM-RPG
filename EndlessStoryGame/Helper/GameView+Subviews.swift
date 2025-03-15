
import SwiftUI

// MARK: - subviews
extension GameView {
    @ViewBuilder
    var initialLoadingView: some View {
        if stories.isEmpty {
            VStack {
                if isLoading {
                    ProgressView()
                        .controlSize(.extraLarge)
                } else {
                    Button("開始遊戲", action: startStory)
                        .buttonStyle(.bordered)
                        .font(.title)                        
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    func optionButton(_ option: String) -> some View {
        Button {
            continueStory(with: option)
        } label: {
            Text(option)
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .padding(.vertical, 8)
    }
}

// MARK: - helpers
extension GameView {
    enum GameError: Error {
        case unableToProcessResponse
    }
}

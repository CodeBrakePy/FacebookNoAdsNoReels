import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var model = WebModel()

    var body: some View {
        VStack(spacing: 0) {
            FacebookWebView(model: model)
                .ignoresSafeArea(edges: .top)

            Divider()
            HStack {
                Button { model.webView.goBack() } label: { Image(systemName: "chevron.backward") }
                    .disabled(!model.canGoBack)
                Spacer()
                Button { model.webView.goForward() } label: { Image(systemName: "chevron.forward") }
                    .disabled(!model.canGoForward)
                Spacer()
                Button { model.goHome() } label: { Image(systemName: "house") }
                Spacer()
                Button { model.webView.reload() } label: { Image(systemName: "arrow.clockwise") }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }
}

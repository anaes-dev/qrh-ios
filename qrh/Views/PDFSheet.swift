//
//  PDFSheet.swift
//  qrh
//
//  The original guideline PDF from the Association of Anaesthetists website.
//

import SwiftUI
import WebKit

struct PDFSheet: View {
    let url: URL

    @Environment(\.dismiss) private var dismiss
    @State private var state = WebView.LoadState.loading

    var body: some View {
        NavigationStack {
            WebView(url: url, state: $state)
                .ignoresSafeArea(edges: .bottom)
                .overlay {
                    switch state {
                    case .loading:
                        ProgressView()
                    case .failed:
                        ContentUnavailableView("PDF Unavailable", systemImage: "wifi.slash",
                                               description: Text("The original PDF needs an internet connection."))
                    case .loaded:
                        EmptyView()
                    }
                }
                .navigationTitle("Original PDF")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { dismiss() }
                            .tint(.primary)
                    }
                }
        }
    }
}

//    "Done"-style close button, prominent on iOS 26 as UIKit's .done is

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button("Close", action: action)
                .buttonStyle(.glassProminent)
                .tint(Color(.link))
        } else {
            Button("Close", action: action)
                .fontWeight(.semibold)
        }
    }
}

struct WebView: UIViewRepresentable {
    enum LoadState { case loading, loaded, failed }

    let url: URL
    @Binding var state: LoadState

    func makeCoordinator() -> Coordinator { Coordinator(state: $state) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let state: Binding<LoadState>

        init(state: Binding<LoadState>) { self.state = state }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            state.wrappedValue = .loaded
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            state.wrappedValue = .failed
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            state.wrappedValue = .failed
        }
    }
}

#if DEBUG
#Preview("PDF") {
    PDFSheet(url: URL(string: "https://anaesthetists.org/Portals/0/PDFs/QRH/QRH_2-5_Hypertension_v1.pdf")!)
}
#endif

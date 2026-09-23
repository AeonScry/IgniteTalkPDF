import AppKit
import Combine
import IgniteTalkCore
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var session = PresentationSession()
    @State private var document: PDFDocument?
    @State private var selectedFileName: String?
    @State private var errorMessage: String?
    @State private var isPresenting = false

    private let lastPDFDirectoryKey = "LastPDFDirectory"

    var body: some View {
        Group {
            if isPresenting, let document {
                PresentationView(
                    document: document,
                    session: session,
                    onExit: exitPresentation
                )
            } else {
                setupView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var setupView: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "play.rectangle.on.rectangle.fill")
                .font(.system(size: 68, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.indigo)

            VStack(spacing: 10) {
                Text("IgniteTalkPDF")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("20 slides. 15 seconds each. Exactly 5 minutes.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                Button {
                    selectPDF()
                } label: {
                    Label(document == nil ? "Choose PDF" : "Choose Another PDF", systemImage: "doc.badge.plus")
                        .frame(minWidth: 180)
                }
                .controlSize(.large)

                if let selectedFileName {
                    Label(selectedFileName, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)
                }
            }

            Button {
                startPresentation()
            } label: {
                Label("Start Presentation", systemImage: "play.fill")
                    .font(.headline)
                    .frame(minWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(document == nil)

            Spacer()

            Text("PDF only • macOS 13+ • Press Escape during a presentation to exit fullscreen")
                .font(.footnote)
                .foregroundStyle(.tertiary)
            Text("Jack Teoh • DevOpsDays")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Created with GitHub Copilot")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 24)
        }
        .padding(40)
    }

    private func selectPDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a PDF containing exactly 20 pages."
        if let lastDirectory = UserDefaults.standard.string(forKey: lastPDFDirectoryKey) {
            panel.directoryURL = URL(fileURLWithPath: lastDirectory, isDirectory: true)
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }
        UserDefaults.standard.set(
            url.deletingLastPathComponent().path,
            forKey: lastPDFDirectoryKey
        )
        loadPDF(at: url)
    }

    private func startPresentation() {
        guard document != nil else { return }
        session.start()
        isPresenting = true
        DispatchQueue.main.async {
            NSApplication.shared.keyWindow?.toggleFullScreen(nil)
        }
    }

    private func exitPresentation() {
        session.pause()
        isPresenting = false
        if let window = NSApplication.shared.keyWindow, window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }

    private func loadPDF(at url: URL) {
        guard url.pathExtension.lowercased() == "pdf" else {
            document = nil
            selectedFileName = nil
            errorMessage = "The selected file must be a PDF."
            return
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            document = nil
            selectedFileName = nil
            errorMessage = "No PDF was found at \(url.path)."
            return
        }
        guard let candidate = PDFDocument(url: url) else {
            document = nil
            selectedFileName = nil
            errorMessage = "The selected file could not be opened as a PDF."
            return
        }
        guard candidate.pageCount == PresentationTimeline.pageCount else {
            document = nil
            selectedFileName = nil
            errorMessage = "This PDF has \(candidate.pageCount) pages. Ignite talks require exactly 20 pages."
            return
        }

        document = candidate
        selectedFileName = url.lastPathComponent
        errorMessage = nil
    }
}

private struct PresentationView: View {
    let document: PDFDocument
    @ObservedObject var session: PresentationSession
    let onExit: () -> Void

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            PDFPageView(document: document, pageIndex: session.currentPage)
                .ignoresSafeArea()

            completionOverlay

            controls
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
        .onReceive(timer) { _ in
            session.tick()
        }
        .onExitCommand(perform: onExit)
    }

    @ViewBuilder
    private var completionOverlay: some View {
        if session.phase == .finished {
            ZStack {
                Color.black
                Image("DODLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 620, maxHeight: 520)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .ignoresSafeArea()
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 18) {
                status

                Spacer()

                controlButton("Previous", systemImage: "backward.fill", action: session.previous)
                    .disabled(!session.timeline.canGoPrevious)

                controlButton(
                    session.phase == .paused ? "Resume" : "Pause",
                    systemImage: session.phase == .paused ? "play.fill" : "pause.fill",
                    action: session.togglePause
                )
                .disabled(session.phase != .running && session.phase != .paused)

                controlButton("Next", systemImage: "forward.fill", action: session.next)
                    .disabled(!session.timeline.canGoNext)

                controlButton("Restart", systemImage: "arrow.counterclockwise", action: session.restart)

                Spacer()

                Button("Exit", action: onExit)
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var status: some View {
        HStack(spacing: 14) {
            Text("\(session.timeline.pageNumber) / \(PresentationTimeline.pageCount)")
                .monospacedDigit()
            Text(statusTime)
                .monospacedDigit()
                .frame(width: 34, alignment: .trailing)
        }
        .font(.headline)
        .frame(minWidth: 120, alignment: .leading)
    }

    private var statusTime: String {
        return "\(Int(ceil(session.secondsRemaining)))s"
    }

    private func controlButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
    }
}

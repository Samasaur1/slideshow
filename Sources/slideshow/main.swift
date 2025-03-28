import ArgumentParser
import Foundation
import SwiftUI

struct CommonArgs: ParsableArguments {
    @Flag var verbose: Bool = false
    // TODO: I wish this was an option, but when I used the @Option type
    // and set a value for this flag, the app wouldn't launch.
    @Argument var delay: Double = 1
}

let verbose: Bool
let delay: Double
let filePaths: [String]

if isatty(STDIN_FILENO) == 1 {
    // This program's STDIN is attached to a terminal,
    // which means nothing was piped in.
    struct TtyArgs: ParsableArguments {
        @OptionGroup var common: CommonArgs
        @Argument var files: [String]
    }

    let args = TtyArgs.parseOrExit()

    verbose = args.common.verbose
    delay = args.common.delay
    filePaths = args.files
} else {
    // This program's STDIN is not attached to a terminal,
    // which means that something was piped into it.
    struct PipedArgs: ParsableArguments {
        @OptionGroup var common: CommonArgs
        // @Option var separator: String // TODO: support separators that aren't \0
    }

    let args = PipedArgs.parseOrExit()

    verbose = args.common.verbose
    delay = args.common.delay

    guard let input = try? FileHandle.standardInput.readToEnd() else {
        print("Cannot read input")
        exit(2)
    }

    filePaths = input.split(separator: 0).compactMap { String(data: $0, encoding: .utf8) }
}

let fileURLs = filePaths.compactMap { URL(filePath: $0) }

if verbose {
    print("Parsed arguments:")
    print("verbose:", verbose)
    print("delay:", delay)
}

import Quartz
struct QLImage: NSViewRepresentable {
    
    private let path: URL

    init(from url: URL) {
        self.path = url
    }
    
    func makeNSView(context: NSViewRepresentableContext<QLImage>) -> QLPreviewView {
        let preview = QLPreviewView(frame: .zero, style: .normal)
        preview?.autostarts = true
        preview?.previewItem = path as QLPreviewItem
        
        return preview ?? QLPreviewView()
    }
    
    func updateNSView(_ nsView: QLPreviewView, context: NSViewRepresentableContext<QLImage>) {
        nsView.previewItem = path as QLPreviewItem
    }
    
    typealias NSViewType = QLPreviewView
}

struct BetterImageView: View {
    let url: URL

    var body: some View {
        Group {
            let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
            let count = CGImageSourceGetCount(source)
            if count == 1 {
                let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)!
                Image(nsImage: NSImage(cgImage: cgImage, size: .zero))
                .resizable().scaledToFit()
            } else {
                QLImage(from: url)
            }
        }
    }
}

struct SlideshowView: View {
    @Environment(\.scenePhase) var scenePhase

    @State var index: Int = 0
    let files: [URL]
    @State var delay: Double {
        didSet {
            if verbose {
                print("delay: \(oldValue) -> \(delay)")
            }
            restartTimer()
        }
    }
    let verbose: Bool
    @State var paused: Bool = false {
        didSet {
            if verbose {
                print("paused: \(paused)")
            }
            restartTimer()
        }
    }
    @State private var timerTask: Task<Void, Error>? = nil

    func restartTimer() {
        self.timerTask?.cancel()

        guard !paused else { return }

        self.timerTask = Task {
            try await Task.sleep(for: .seconds(delay))
            self.rightAction()
            self.restartTimer()
        }
    }

    func upAction() {
        if self.delay <= 1 {
            delay /= 2
        } else {
            delay -= 1
        }
    }
    func leftAction() {
        index = index == 0 ? files.count - 1 : index - 1
        if verbose {
            print(files[index].relativePath)
        }
    }
    func pauseAction() {
        self.paused.toggle()
    }
    func rightAction() {
        index = (index + 1) % files.count
        if verbose {
            print(files[index].relativePath)
        }
    }
    func downAction() {
        if self.delay <= 1 {
            delay *= 2
        } else {
            delay += 1
        }
    }

    var body: some View {
        ZStack {
            Group {
                Button { upAction() } label: { Color.clear }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.upArrow, modifiers: [])
                Button { leftAction() } label: { Color.clear }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.leftArrow, modifiers: [])
                Button { pauseAction() } label: { Color.clear }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.space, modifiers: [])
                Button { rightAction() } label: { Color.clear }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.rightArrow, modifiers: [])
                Button { downAction() } label: { Color.clear }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.downArrow, modifiers: [])
            }
            BetterImageView(url: files[index])
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Color.clear.contentShape(Rectangle()).frame(height: geo.size.height * 0.2).onTapGesture{ upAction() }
                    HStack(spacing: 0) {
                        Color.clear.contentShape(Rectangle()).frame(width: geo.size.width * 0.2).onTapGesture { leftAction() }
                        Color.clear.contentShape(Rectangle()).onTapGesture { pauseAction() }
                        Color.clear.contentShape(Rectangle()).frame(width: geo.size.width * 0.2).onTapGesture { rightAction() }
                    }
                    Color.clear.contentShape(Rectangle()).frame(height: geo.size.height * 0.2).onTapGesture{ downAction() }
                }
            }
        }
        .navigationTitle(files[index].relativePath)
        .navigationDocument(files[index])
        .onAppear {
            self.restartTimer()
            if verbose {
                print(files[index].relativePath)
            }
        }
    }
}
struct MyScene: Scene {
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            SlideshowView(files: fileURLs, delay: delay, verbose: verbose)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
    }
}
struct MyApp: App {
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        MyScene()
    }
}

signal(SIGINT) { sig in
    print() // clear line
    exit(1)
}

NSApplication.shared.setActivationPolicy(.regular)
MyApp.main()

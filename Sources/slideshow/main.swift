#! /usr/bin/swift

//
// - This is just some AppKit boilerplate to launch a window.
//
import AppKit
@available(OSX 10.15, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    let window = NSWindow()
    let windowDelegate = WindowDelegate()
    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentSize = NSSize(width:800, height:600)
        window.setContentSize(contentSize)
        // window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.level = .floating
        window.delegate = windowDelegate
        window.title = "Slideshow"
        
        let graph = NSHostingView(rootView: DemoView())
        graph.frame = NSRect(origin: NSPoint(x:0, y:0), size: contentSize)
        graph.autoresizingMask = [.height, .width]
        window.contentView!.addSubview(graph)
        window.center()
        window.makeKeyAndOrderFront(window)
    }
    class WindowDelegate: NSObject, NSWindowDelegate {
        func windowWillClose(_ notification: Notification) {
            NSApplication.shared.terminate(0)
        }
    }
}

var fileURLs: [String] = []
var delay: Double
let verbose: Bool
if isatty(STDIN_FILENO) == 1 {
    print("isatty")
    guard CommandLine.argc > 1 else {
        print("If you don't pipe in files, you must put them on the command line!")
        exit(2)
    }
    fileURLs = Array(CommandLine.arguments.dropFirst())
    delay = 1
    verbose = false
} else {
    print("noisatty")
    let input = readLine()!
    let zero = UnicodeScalar(0)!
    let charzero = Character(zero)
    fileURLs = input.split(separator: charzero).map(String.init)

    delay = CommandLine.argc > 1 ? Double(CommandLine.arguments[1])! : 1
    print("delay=\(delay)")
    verbose = CommandLine.argc > 2
    print("verbose=\(verbose)")
}

if verbose {
    print(fileURLs[0])
}


//
// - This is the actual view.
//
import SwiftUI

extension Image {
    init?(from data: Data) {
        if let img = NSImage(data: data) {
            self.init(nsImage: img)
        } else {
            return nil
        }
    }

    init?(from url: URL) throws {
        let data = try Data(contentsOf: url)
        self.init(from: data)
    }

    init?(from path: String) throws {
        let url = URL(fileURLWithPath: path)
        try self.init(from: url)
    }
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

struct DemoView: View {
    @State private var idx: Int = 0
    var timer = Timer.publish(every: delay, on: .main, in: .common).autoconnect()
    let images = fileURLs
    @State var paused = false {
        didSet {
            print("paused: \(paused)")
        }
    }
    @State var interval: Double = delay
    
    func nextIdx() {
        idx += 1
        if idx == images.count { idx = 0 }
        if verbose {
            print(images[idx])
        }
    }
    func prevIdx() {
        idx -= 1
        if idx == -1 { idx = images.count - 1 }
        if verbose {
            print(images[idx])
        }
    }

    func timerTick() {
        guard !paused else {
            return
        }
        nextIdx()
    }

    func faster() {
        if self.interval <= 1 {
            interval /= 2
        } else {
            interval -= 1
        }
        // self.timer.invalidate()
        // self.timer = Timer.publish(every: interval, on: .main, in: .common).autoconnect() 
        if verbose {
            print("faster")
        }
    }
    func slower() {
        if self.interval <= 1 {
            interval *= 2
        } else {
            interval += 1
        }
        // self.timer.invalidate()
        // self.timer = Timer.publish(every: interval, on: .main, in: .common).autoconnect() 
        if verbose {
            print("slower")
        }
    }
    
    var body: some View {
        ZStack {
            //earlier means lower Z index
            Group {
            let path = URL(fileURLWithPath: images[idx])
            if path.pathExtension == "gif" {
                QLImage(from: path)
            } else {
                try! Image(from: path)?.resizable().scaledToFit()
            }
            }
            // try! Image(from: images[idx])?.resizable().scaledToFit()
            GeometryReader { geo in
                VStack(spacing: 0) {
                    /* Color.red.contentShape(Rectangle()).frame(height: geo.size.height * 0.2).onTapGesture{ self.faster() }
                    HStack(spacing: 0) {
                        Color.orange.contentShape(Rectangle()).frame(width: geo.size.width * 0.2).onTapGesture { self.prevIdx() }
                        Color.yellow.contentShape(Rectangle()).onTapGesture { self.paused.toggle() }
                        Color.green.contentShape(Rectangle()).frame(width: geo.size.width * 0.2).onTapGesture { self.nextIdx() }
                    }
                    Color.blue.contentShape(Rectangle()).frame(height: geo.size.height * 0.2).onTapGesture{ self.slower() } */
                    Color.clear.contentShape(Rectangle()).frame(height: geo.size.height * 0.2).onTapGesture{ self.faster() }
                    HStack(spacing: 0) {
                        Color.clear.contentShape(Rectangle()).frame(width: geo.size.width * 0.2).onTapGesture { self.prevIdx() }
                        Color.clear.contentShape(Rectangle()).onTapGesture { self.paused.toggle() }
                        Color.clear.contentShape(Rectangle()).frame(width: geo.size.width * 0.2).onTapGesture { self.nextIdx() }
                    }
                    Color.clear.contentShape(Rectangle()).frame(height: geo.size.height * 0.2).onTapGesture{ self.slower() }
                    /* Color.white.opacity(0.0001).frame(height: geo.size.height * 0.2).onTapGesture{ self.faster() }
                    HStack(spacing: 0) {
                        Color.white.opacity(0.0001).frame(width: geo.size.width * 0.2).onTapGesture { self.prevIdx() }
                        Color.white.opacity(0.0001).onTapGesture { self.paused.toggle() }
                        Color.white.opacity(0.0001).frame(width: geo.size.width * 0.2).onTapGesture { self.nextIdx() }
                    }
                    Color.white.opacity(0.0001).frame(height: geo.size.height * 0.2).onTapGesture{ self.slower() } */
                }
            }
            /* Button(action: { print(5) }) {
                Spacer()
            }
            .opacity(0) */
        }
        .onReceive(timer) { _ in self.timerTick() }
        // .onTapGesture {
        //     self.paused.toggle()
        // }
    }
}
//
// - More AppKit boilerplate.
//
let app = NSApplication.shared
let del = AppDelegate()
app.delegate = del
app.run()

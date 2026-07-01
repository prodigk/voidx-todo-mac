import AppKit
import SwiftUI

@main
struct VoidXTodoMacApp: App {
    @StateObject private var store = TodoStore()
    @StateObject private var pomodoro = PomodoroTimerStore()

    private let minimumWindowSize = CGSize(width: 1120, height: 720)
    private let defaultWindowSize = CGSize(width: 1280, height: 820)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(pomodoro)
                .frame(minWidth: minimumWindowSize.width, minHeight: minimumWindowSize.height)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: defaultWindowSize.width, height: defaultWindowSize.height)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandMenu("Pomodoro") {
                PomodoroMenuContent(timer: pomodoro, includesStatusHeader: true)
            }
        }

        MenuBarExtra {
            PomodoroMenuContent(timer: pomodoro, includesStatusHeader: true)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: pomodoro.isRunning ? "timer.circle.fill" : "timer")
                Text(pomodoro.menuBarTitle)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
            }
        }
        .menuBarExtraStyle(.menu)
    }
}

private enum PomodoroPhase {
    case focus
    case shortBreak

    var title: String {
        switch self {
        case .focus: "Focus"
        case .shortBreak: "Break"
        }
    }

    var nextTitle: String {
        switch self {
        case .focus: "Break"
        case .shortBreak: "Focus"
        }
    }

    var durationSeconds: Int {
        switch self {
        case .focus: 25 * 60
        case .shortBreak: 5 * 60
        }
    }
}

@MainActor
private final class PomodoroTimerStore: ObservableObject {
    @Published private(set) var phase: PomodoroPhase = .focus
    @Published private(set) var remainingSeconds = PomodoroPhase.focus.durationSeconds
    @Published private(set) var isRunning = false

    private var timer: Timer?

    var remainingText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var menuBarTitle: String {
        "\(phase.title) \(remainingText)"
    }

    var progressText: String {
        isRunning ? "Running" : "Paused"
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduleTimer()
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func reset() {
        pause()
        remainingSeconds = phase.durationSeconds
    }

    func switchPhase() {
        pause()
        phase = phase == .focus ? .shortBreak : .focus
        remainingSeconds = phase.durationSeconds
    }

    func skipToNextPhase() {
        completePhase()
    }

    private func scheduleTimer() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func tick() {
        guard isRunning else { return }

        if remainingSeconds > 1 {
            remainingSeconds -= 1
        } else {
            remainingSeconds = 0
            completePhase()
        }
    }

    private func completePhase() {
        pause()
        NSSound.beep()
        phase = phase == .focus ? .shortBreak : .focus
        remainingSeconds = phase.durationSeconds
    }
}

private struct PomodoroMenuContent: View {
    @ObservedObject var timer: PomodoroTimerStore
    let includesStatusHeader: Bool

    var body: some View {
        if includesStatusHeader {
            Text(timer.phase.title)
            Text(timer.remainingText)
            Text(timer.progressText)
            Divider()
        }

        Button(timer.isRunning ? "Pause Timer" : "Start Timer") {
            timer.toggle()
        }
        .keyboardShortcut("p", modifiers: [.command, .shift])

        Button("Reset \(timer.phase.title)") {
            timer.reset()
        }
        .keyboardShortcut("r", modifiers: [.command, .shift])

        Button("Switch to \(timer.phase.nextTitle)") {
            timer.switchPhase()
        }

        Button("Skip to \(timer.phase.nextTitle)") {
            timer.skipToNextPhase()
        }

        Divider()

        Text("25 min focus / 5 min break")
    }
}

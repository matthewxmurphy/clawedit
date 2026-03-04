import AppKit
import SwiftUI

private enum RetroArcadeAudio {
    static func play(_ name: String) {
        NSSound(named: NSSound.Name(name))?.play()
    }
}

private enum SnakeDirection {
    case up
    case down
    case left
    case right

    func isOpposite(of other: SnakeDirection) -> Bool {
        switch (self, other) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            return true
        default:
            return false
        }
    }
}

private struct SnakePoint: Equatable {
    var x: Int
    var y: Int
}

@MainActor
private final class SnakeGameModel: ObservableObject {
    @Published var snake: [SnakePoint] = []
    @Published var food = SnakePoint(x: 7, y: 7)
    @Published var score = 0
    @Published var isGameOver = false
    @Published var isRunning = true

    let boardSize = 18
    private var direction: SnakeDirection = .right
    private var pendingDirection: SnakeDirection = .right

    init() {
        reset()
    }

    func reset() {
        snake = [
            SnakePoint(x: 4, y: 9),
            SnakePoint(x: 3, y: 9),
            SnakePoint(x: 2, y: 9)
        ]
        direction = .right
        pendingDirection = .right
        score = 0
        isGameOver = false
        isRunning = true
        placeFood()
    }

    func togglePause() {
        guard !isGameOver else { return }
        isRunning.toggle()
    }

    func changeDirection(_ newDirection: SnakeDirection) {
        guard !newDirection.isOpposite(of: direction) else { return }
        pendingDirection = newDirection
    }

    func tick() {
        guard isRunning, !isGameOver else { return }
        direction = pendingDirection

        var head = snake[0]
        switch direction {
        case .up: head.y -= 1
        case .down: head.y += 1
        case .left: head.x -= 1
        case .right: head.x += 1
        }

        guard (0 ..< boardSize).contains(head.x), (0 ..< boardSize).contains(head.y), !snake.contains(head) else {
            isGameOver = true
            isRunning = false
            return
        }

        snake.insert(head, at: 0)
        if head == food {
            score += 1
            placeFood()
        } else {
            snake.removeLast()
        }
    }

    private func placeFood() {
        let openCells = (0 ..< boardSize).flatMap { x in
            (0 ..< boardSize).map { y in SnakePoint(x: x, y: y) }
        }.filter { !snake.contains($0) }

        food = openCells.randomElement() ?? SnakePoint(x: 7, y: 7)
    }
}

struct SnakeArcadeView: View {
    @StateObject private var model = SnakeGameModel()
    @State private var showingCredits = false
    private let ticker = Timer.publish(every: 0.14, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ClawEdit Snake")
                        .font(.custom("Monaco", size: 30))
                    Text("Arrow keys to move. Space to pause. R to restart.")
                        .font(.custom("Monaco", size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Score")
                        .font(.custom("Monaco", size: 12))
                        .foregroundStyle(.secondary)
                    Text("\(model.score)")
                        .font(.custom("Monaco", size: 24))
                }
            }

            SnakeBoard(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black)
                )
                .overlay(alignment: .center) {
                    if model.isGameOver {
                        VStack(spacing: 10) {
                            Text("Game Over")
                                .font(.custom("Monaco", size: 24))
                            Text("Press R to restart")
                                .font(.custom("Monaco", size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if showingCredits {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CLAWEDIT")
                            Text("by Matthew Murphy")
                            Text("www.matthewxmurphy.com")
                        }
                        .font(.custom("Monaco", size: 11))
                        .foregroundStyle(Color.green.opacity(0.9))
                        .padding(10)
                        .background(Color.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(14)
                    }
                }

            HStack {
                Button(model.isRunning ? "Pause" : "Resume") {
                    model.togglePause()
                }
                Button("Restart") {
                    model.reset()
                }
                Spacer()
                Text("Option + About  C = credits")
                    .font(.custom("Monaco", size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .focusable()
        .onAppear {
            model.reset()
            RetroArcadeAudio.play("Morse")
        }
        .onReceive(ticker) { _ in
            model.tick()
        }
        .onChange(of: model.score) { _, _ in
            RetroArcadeAudio.play("Pop")
        }
        .onChange(of: model.isGameOver) { _, isGameOver in
            if isGameOver {
                RetroArcadeAudio.play("Basso")
            }
        }
        .onMoveCommand { direction in
            switch direction {
            case .up:
                model.changeDirection(.up)
            case .down:
                model.changeDirection(.down)
            case .left:
                model.changeDirection(.left)
            case .right:
                model.changeDirection(.right)
            @unknown default:
                break
            }
        }
        .background(
            KeyEventHandlingView(
                onSpace: { model.togglePause() },
                onRestart: {
                    model.reset()
                    RetroArcadeAudio.play("Hero")
                },
                onToggleCredits: {
                    showingCredits.toggle()
                    RetroArcadeAudio.play(showingCredits ? "Tink" : "Glass")
                }
            )
        )
    }
}

private struct SnakeBoard: View {
    @ObservedObject var model: SnakeGameModel

    var body: some View {
        GeometryReader { geometry in
            let cellSize = min(geometry.size.width, geometry.size.height) / CGFloat(model.boardSize)

            Canvas { context, size in
                let boardRect = CGRect(origin: .zero, size: size)
                context.fill(Path(boardRect), with: .color(Color(red: 0.03, green: 0.06, blue: 0.03)))

                for x in 0 ..< model.boardSize {
                    for y in 0 ..< model.boardSize {
                        let rect = CGRect(
                            x: CGFloat(x) * cellSize,
                            y: CGFloat(y) * cellSize,
                            width: cellSize - 1,
                            height: cellSize - 1
                        )
                        context.fill(Path(rect), with: .color(Color.green.opacity(0.08)))
                    }
                }

                for segment in model.snake {
                    let rect = CGRect(
                        x: CGFloat(segment.x) * cellSize + 1,
                        y: CGFloat(segment.y) * cellSize + 1,
                        width: cellSize - 3,
                        height: cellSize - 3
                    )
                    context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(Color.green))
                }

                let foodRect = CGRect(
                    x: CGFloat(model.food.x) * cellSize + 2,
                    y: CGFloat(model.food.y) * cellSize + 2,
                    width: cellSize - 5,
                    height: cellSize - 5
                )
                context.fill(Path(ellipseIn: foodRect), with: .color(Color.red))

                for row in stride(from: 0.0, to: size.height, by: 6.0) {
                    let line = CGRect(x: 0, y: row, width: size.width, height: 1)
                    context.fill(Path(line), with: .color(Color.white.opacity(0.025)))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

private struct KeyEventHandlingView: NSViewRepresentable {
    let onSpace: () -> Void
    let onRestart: () -> Void
    let onToggleCredits: () -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onSpace = onSpace
        view.onRestart = onRestart
        view.onToggleCredits = onToggleCredits
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onSpace = onSpace
        nsView.onRestart = onRestart
        nsView.onToggleCredits = onToggleCredits
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

private final class KeyCaptureView: NSView {
    var onSpace: (() -> Void)?
    var onRestart: (() -> Void)?
    var onToggleCredits: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.charactersIgnoringModifiers?.lowercased() {
        case " ":
            onSpace?()
        case "r":
            onRestart?()
        case "c":
            onToggleCredits?()
        default:
            super.keyDown(with: event)
        }
    }
}

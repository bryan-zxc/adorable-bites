import SwiftUI
import SpriteKit

class SceneManager: ObservableObject {
    @Published var currentScene: SKScene?
    var sceneSize: CGSize = .zero

    func showLanding() {
        let progress = GameProgress.load()
        let scene = LandingScene(progress: progress)
        scene.size = sceneSize
        scene.scaleMode = .resizeFill
        scene.onLevelSelected = { [weak self] config in
            self?.showKitchen(config: config)
        }
        currentScene = scene
    }

    func showKitchen(config: LevelConfig) {
        let progress = GameProgress.load()
        let scene = KitchenScene(levelConfig: config, progress: progress)
        scene.size = sceneSize
        scene.scaleMode = .resizeFill
        scene.onGoHome = { [weak self] in
            self?.showLanding()
        }
        scene.onReplay = { [weak self] in
            self?.showKitchen(config: config)
        }
        scene.onNextLevel = { [weak self] nextConfig in
            self?.showKitchen(config: nextConfig)
        }
        currentScene = scene
    }
}

struct ContentView: View {
    @StateObject private var sceneManager = SceneManager()

    var body: some View {
        GeometryReader { geo in
            if let scene = sceneManager.currentScene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
                    .id(ObjectIdentifier(scene))
            } else {
                Color.clear.onAppear {
                    sceneManager.sceneSize = geo.size
                    sceneManager.showLanding()
                }
            }
        }
        .ignoresSafeArea()
    }
}

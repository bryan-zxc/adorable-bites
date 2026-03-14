import SwiftUI
import SpriteKit

struct ContentView: View {
    var body: some View {
        SpriteView(scene: makeScene())
            .ignoresSafeArea()
    }

    private func makeScene() -> KitchenScene {
        let scene = KitchenScene()
        scene.size = CGSize(width: 1133, height: 744)
        scene.scaleMode = .aspectFill
        return scene
    }
}

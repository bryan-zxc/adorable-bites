import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var scene: KitchenScene?

    var body: some View {
        GeometryReader { geo in
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            } else {
                Color.clear.onAppear {
                    let s = KitchenScene()
                    s.size = geo.size
                    s.scaleMode = .resizeFill
                    scene = s
                }
            }
        }
        .ignoresSafeArea()
    }
}

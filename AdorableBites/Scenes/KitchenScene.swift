import SpriteKit

class KitchenScene: SKScene {

    // MARK: - Game phase

    enum GamePhase {
        case addingIngredients
        case mixing
        case batterReady
        case cooking
        case readyToServe
        case burnt
        case servingCustomer
    }

    private var gamePhase: GamePhase = .addingIngredients

    // MARK: - Level config and callbacks

    private var levelConfig: LevelConfig?
    private var progress: GameProgress = GameProgress.load()
    var onGoHome: (() -> Void)?
    var onReplay: (() -> Void)?
    var onNextLevel: ((LevelConfig) -> Void)?

    convenience init(levelConfig: LevelConfig, progress: GameProgress) {
        self.init()
        self.levelConfig = levelConfig
        self.progress = progress
    }

    // MARK: - Ingredients

    static let flour = Ingredient(name: "flour", colour: .systemYellow, imageName: "flour", cookTime: 4)
    static let egg = Ingredient(name: "egg", colour: .systemOrange, imageName: "egg", cookTime: 8)
    static let milk = Ingredient(name: "milk", colour: .systemCyan, imageName: "milk", cookTime: 2)
    static let butter = Ingredient(name: "butter", colour: .systemYellow, imageName: "butter", cookTime: 2)
    static let bread = Ingredient(name: "bread", colour: .brown, imageName: "bread", cookTime: 6)
    static let chocolate = Ingredient(name: "chocolate", colour: .brown, imageName: "chocolate", cookTime: 6)

    static let allIngredients = [egg, butter, bread, flour, milk]

    // MARK: - Recipes

    static let pancakeRecipe = Recipe(
        name: "Pancakes",
        imageName: "pancakes_plate",
        requiredIngredients: [flour, egg, milk],
        basePoints: 1,
        requiresMixing: true
    )

    static let friedEggRecipe = Recipe(
        name: "Fried Egg",
        imageName: "fried_egg_plate",
        requiredIngredients: [egg],
        basePoints: 1,
        requiresMixing: false
    )

    static let scrambledEggRecipe = Recipe(
        name: "Scrambled Egg",
        imageName: "scrambled_egg_plate",
        requiredIngredients: [egg],
        basePoints: 1,
        requiresMixing: true
    )

    static let panToastRecipe = Recipe(
        name: "Pan Toast",
        imageName: "pan_toast_plate",
        requiredIngredients: [bread],
        basePoints: 1,
        requiresMixing: false
    )

    static let allRecipes = [pancakeRecipe, friedEggRecipe, scrambledEggRecipe, panToastRecipe]

    // MARK: - Customer pool

    static let allOrders = [pancakeRecipe, friedEggRecipe, scrambledEggRecipe]

    static let customerPool = [
        Customer(name: "Bear", imageName: "customer_bear", order: pancakeRecipe),
        Customer(name: "Cat", imageName: "customer_cat", order: pancakeRecipe),
        Customer(name: "Dog", imageName: "customer_dog", order: pancakeRecipe),
        Customer(name: "Bunny", imageName: "customer_bunny", order: pancakeRecipe),
        Customer(name: "Frog", imageName: "customer_frog", order: pancakeRecipe),
    ]

    // MARK: - Layers

    private var gameLayer: SKNode!

    // MARK: - Nodes

    private var ingredientShelfNodes: [IngredientNode] = []
    private var mixerNode: MixerNode?
    private var stoveTop: StoveTopNode!
    private var hudNode: HudNode!
    private var recipePanel: RecipePanelNode!

    // Quiz and pickup
    private var activeQuiz: QuizNode?
    private var pendingIngredientNode: IngredientNode?
    private var pickedUpIngredient: IngredientNode?

    // Buttons
    private var mixerBinButton: SKSpriteNode!
    private var panBinButton: SKSpriteNode!

    // Plates
    private var plateSprites: [SKSpriteNode] = []

    // Sink and dirty dishes
    private var dirtyDishSprites: [SKSpriteNode] = []
    private var dirtyDishCount: Int = 0

    // Per-seat state tracking
    struct SeatItem {
        var moneySprite: SKSpriteNode?
        var moneyPayment: Int = 0
        var plateSprite: SKSpriteNode?
        var customerNode: CustomerNode?
    }
    private var seatItems: [Int: SeatItem] = [:]

    // Dish sprites on bench (keyed by customer node) — for eating customers
    private var benchDishSprites: [ObjectIdentifier: SKSpriteNode] = [:]
    private var totalPlates: Int { levelConfig?.plateCount ?? 5 }
    private var platesRemaining: Int = 5
    private var customersServed = 0
    private var missedCustomers = 0
    private var totalCustomersSpawned = 0

    // Door queue
    private var doorQueue: [CustomerNode] = []
    private var doorQueueData: [Customer] = []
    private var doorPosition: CGPoint { CGPoint(x: seatX, y: size.height - 55) }

    // MARK: - Bench and seating

    private var chairCount: Int { levelConfig?.chairCount ?? 5 }
    private var totalCustomerCount: Int { levelConfig?.customerCount ?? 5 }
    private var seatPositions: [CGPoint] = []
    private var customerNodes: [CustomerNode] = []
    private var customerData: [Customer] = []
    private var customerSeatIndices: [ObjectIdentifier: Int] = [:]

    // MARK: - Layout zones

    private let seatX: CGFloat = 55
    private let benchWidth: CGFloat = 140
    private var benchLeftEdge: CGFloat { seatX + 38 }
    private var benchRightEdge: CGFloat { benchLeftEdge + benchWidth }
    private var recipePanelCentreX: CGFloat { size.width - 110 }
    private var recipePanelLeftEdge: CGFloat { recipePanelCentreX - 100 }
    private var kitchenCentreX: CGFloat { (benchRightEdge + recipePanelLeftEdge) / 2 }
    private var plateX: CGFloat { benchRightEdge + (recipePanelLeftEdge - benchRightEdge) * 0.18 }
    private var stoveX: CGFloat { benchRightEdge + (recipePanelLeftEdge - benchRightEdge) * 0.48 }
    private var mixerX: CGFloat { benchRightEdge + (recipePanelLeftEdge - benchRightEdge) * 0.78 }
    private let workstationY: CGFloat = 370

    // MARK: - Scene lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.88, alpha: 1.0)
        platesRemaining = totalPlates
        setupScene()
        showTutorialIfNeeded {
            self.spawnCustomer()
        }
    }

    private func showTutorialIfNeeded(completion: @escaping () -> Void) {
        let level = levelConfig?.level ?? 1
        guard let message = levelConfig?.tutorialMessage,
              !progress.seenTutorials.contains(level) else {
            completion()
            return
        }

        gameLayer.isPaused = true

        // Container node for easy cleanup
        let tutorialContainer = SKNode()
        tutorialContainer.zPosition = 80
        tutorialContainer.name = "tutorialContainer"
        addChild(tutorialContainer)

        // Full-screen dim overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.fillColor = UIColor(white: 0, alpha: 0.6)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 0
        tutorialContainer.addChild(overlay)

        // Full-screen card with padding
        let padding: CGFloat = 30
        let cardW = size.width - padding * 2
        let cardH = size.height - padding * 2
        let card = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 24)
        card.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.98)
        card.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        card.lineWidth = 3
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        card.zPosition = 1
        tutorialContainer.addChild(card)

        let centreX = size.width / 2
        let topY = size.height - padding

        // Title message — centred at top
        let msgLabel = SKLabelNode(text: message)
        msgLabel.fontSize = 28
        msgLabel.fontName = "ChalkboardSE-Bold"
        msgLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        msgLabel.verticalAlignmentMode = .center
        msgLabel.horizontalAlignmentMode = .center
        msgLabel.preferredMaxLayoutWidth = cardW - 60
        msgLabel.numberOfLines = 0
        msgLabel.position = CGPoint(x: centreX, y: topY - 55)
        msgLabel.zPosition = 2
        tutorialContainer.addChild(msgLabel)

        // Dora — large, on the left, comfortably inside the card with whitespace
        let doraTexture = SKTexture(imageNamed: "dora")
        let dora = SKSpriteNode(texture: doraTexture)
        let doraHeight: CGFloat = cardH * 0.65
        let doraScale = doraHeight / doraTexture.size().height
        dora.size = CGSize(width: doraTexture.size().width * doraScale, height: doraHeight)
        dora.position = CGPoint(x: padding + dora.size.width / 2 + 20, y: size.height / 2 - 30)
        dora.zPosition = 2
        tutorialContainer.addChild(dora)

        // Step images in Z-pattern: 1→2 (right), then ↓, then 3→4 (right)
        // Tight 2x2 grid to the right of Dora
        let images = levelConfig?.tutorialImages ?? []
        let labels = levelConfig?.tutorialStepLabels ?? []
        if images.count == 4 {
            let stepSize: CGFloat = 120
            let gap: CGFloat = 14  // tight gap between boxes
            let arrowSize: CGFloat = 20
            let labelHeight: CGFloat = 20

            // Grid area: right of Dora to right card edge
            let gridRight = size.width - padding - 20
            let doraRight = dora.position.x + dora.size.width / 2 + 20
            let gridWidth = gridRight - doraRight
            // Two columns + one arrow gap between them
            let colSpacing = stepSize + arrowSize + gap * 2
            let gridCentreX = doraRight + gridWidth / 2
            let gridCentreY = size.height / 2 - 20

            // Row spacing: step + label + arrow gap
            let rowSpacing = stepSize + labelHeight + arrowSize + gap

            let positions: [(CGFloat, CGFloat)] = [
                (gridCentreX - colSpacing / 2, gridCentreY + rowSpacing / 2),   // 1: top-left
                (gridCentreX + colSpacing / 2, gridCentreY + rowSpacing / 2),   // 2: top-right
                (gridCentreX - colSpacing / 2, gridCentreY - rowSpacing / 2),   // 3: bottom-left
                (gridCentreX + colSpacing / 2, gridCentreY - rowSpacing / 2),   // 4: bottom-right
            ]

            var stepCentres: [CGPoint] = []

            for (i, (cx, cy)) in positions.enumerated() {
                let pos = CGPoint(x: cx, y: cy)
                stepCentres.append(pos)

                // White background frame
                let frame = SKShapeNode(rectOf: CGSize(width: stepSize + 6, height: stepSize + 6), cornerRadius: 8)
                frame.fillColor = UIColor(white: 1, alpha: 0.3)
                frame.strokeColor = UIColor(red: 0.8, green: 0.74, blue: 0.65, alpha: 1.0)
                frame.lineWidth = 2
                frame.position = pos
                frame.zPosition = 1
                tutorialContainer.addChild(frame)

                // Step image
                let tex = SKTexture(imageNamed: images[i])
                let step = SKSpriteNode(texture: tex)
                let texSize = tex.size()
                let sc = min(stepSize / texSize.width, stepSize / texSize.height)
                step.size = CGSize(width: texSize.width * sc, height: texSize.height * sc)
                step.position = pos
                step.zPosition = 2
                tutorialContainer.addChild(step)

                // Green number circle
                let circle = SKShapeNode(circleOfRadius: 12)
                circle.fillColor = UIColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0)
                circle.strokeColor = .clear
                circle.position = CGPoint(x: cx - stepSize / 2 + 12, y: cy + stepSize / 2 - 12)
                circle.zPosition = 4
                tutorialContainer.addChild(circle)

                let numLabel = SKLabelNode(text: "\(i + 1)")
                numLabel.fontSize = 13
                numLabel.fontName = "AvenirNext-Bold"
                numLabel.fontColor = .white
                numLabel.verticalAlignmentMode = .center
                numLabel.position = .zero
                circle.addChild(numLabel)

                // Label below step
                if i < labels.count {
                    let stepLabel = SKLabelNode(text: labels[i])
                    stepLabel.fontSize = 13
                    stepLabel.fontName = "ChalkboardSE-Bold"
                    stepLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
                    stepLabel.verticalAlignmentMode = .top
                    stepLabel.horizontalAlignmentMode = .center
                    stepLabel.position = CGPoint(x: cx, y: cy - stepSize / 2 - 6)
                    stepLabel.zPosition = 2
                    tutorialContainer.addChild(stepLabel)
                }
            }

            // Arrows — small, fitting in the gaps between boxes
            let arrowColour = UIColor(red: 0.55, green: 0.45, blue: 0.3, alpha: 1.0)

            // 1 → 2 (right)
            let a1 = CGPoint(x: (stepCentres[0].x + stepCentres[1].x) / 2, y: stepCentres[0].y)
            let arrow1 = SKLabelNode(text: "➜")
            arrow1.fontSize = 22
            arrow1.fontColor = arrowColour
            arrow1.verticalAlignmentMode = .center
            arrow1.position = a1
            arrow1.zPosition = 2
            tutorialContainer.addChild(arrow1)

            // 2 → 3 (down-left diagonal)
            let a2 = CGPoint(x: gridCentreX, y: gridCentreY)
            let arrow2 = SKLabelNode(text: "➜")
            arrow2.fontSize = 22
            arrow2.fontColor = arrowColour
            arrow2.verticalAlignmentMode = .center
            arrow2.position = a2
            arrow2.zRotation = -.pi * 0.75
            arrow2.zPosition = 2
            tutorialContainer.addChild(arrow2)

            // 3 → 4 (right)
            let a3 = CGPoint(x: (stepCentres[2].x + stepCentres[3].x) / 2, y: stepCentres[2].y)
            let arrow3 = SKLabelNode(text: "➜")
            arrow3.fontSize = 22
            arrow3.fontColor = arrowColour
            arrow3.verticalAlignmentMode = .center
            arrow3.position = a3
            arrow3.zPosition = 2
            tutorialContainer.addChild(arrow3)
        } else if !images.isEmpty {
            // 1-2 images: simple layout to the right of Dora
            let stepSize: CGFloat = images.count == 1 ? 250 : 150
            let gap: CGFloat = 20
            let doraRight = dora.position.x + dora.size.width / 2 + 20
            let gridRight = size.width - padding - 20
            let gridCentreX = (doraRight + gridRight) / 2
            let gridCentreY = size.height / 2 - 20

            let totalWidth = CGFloat(images.count) * stepSize + CGFloat(images.count - 1) * gap
            let startX = gridCentreX - totalWidth / 2 + stepSize / 2

            for (i, imgName) in images.enumerated() {
                let cx = startX + CGFloat(i) * (stepSize + gap)

                // White frame
                let frame = SKShapeNode(rectOf: CGSize(width: stepSize + 6, height: stepSize + 6), cornerRadius: 8)
                frame.fillColor = UIColor(white: 1, alpha: 0.3)
                frame.strokeColor = UIColor(red: 0.8, green: 0.74, blue: 0.65, alpha: 1.0)
                frame.lineWidth = 2
                frame.position = CGPoint(x: cx, y: gridCentreY)
                frame.zPosition = 1
                tutorialContainer.addChild(frame)

                // Step image
                let tex = SKTexture(imageNamed: imgName)
                let step = SKSpriteNode(texture: tex)
                let texSize = tex.size()
                let sc = min(stepSize / texSize.width, stepSize / texSize.height)
                step.size = CGSize(width: texSize.width * sc, height: texSize.height * sc)
                step.position = CGPoint(x: cx, y: gridCentreY)
                step.zPosition = 2
                tutorialContainer.addChild(step)

                // Label below
                if i < labels.count {
                    let stepLabel = SKLabelNode(text: labels[i])
                    stepLabel.fontSize = 14
                    stepLabel.fontName = "ChalkboardSE-Bold"
                    stepLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
                    stepLabel.verticalAlignmentMode = .top
                    stepLabel.horizontalAlignmentMode = .center
                    stepLabel.position = CGPoint(x: cx, y: gridCentreY - stepSize / 2 - 8)
                    stepLabel.zPosition = 2
                    tutorialContainer.addChild(stepLabel)
                }
            }

            // Arrow between images if 2
            if images.count == 2 {
                let arrowColour = UIColor(red: 0.55, green: 0.45, blue: 0.3, alpha: 1.0)
                let ax = (startX + startX + stepSize + gap) / 2
                let arrow = SKLabelNode(text: "➜")
                arrow.fontSize = 22
                arrow.fontColor = arrowColour
                arrow.verticalAlignmentMode = .center
                arrow.position = CGPoint(x: ax, y: gridCentreY)
                arrow.zPosition = 2
                tutorialContainer.addChild(arrow)
            }
        }

        // "Let's Cook!" button at the bottom
        let btn = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 16)
        btn.fillColor = UIColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0)
        btn.strokeColor = UIColor(red: 0.2, green: 0.55, blue: 0.3, alpha: 1.0)
        btn.lineWidth = 2
        btn.position = CGPoint(x: centreX, y: padding + 55)
        btn.zPosition = 2
        btn.name = "tutorialDismiss"
        tutorialContainer.addChild(btn)

        let btnLabel = SKLabelNode(text: "Let's Cook!")
        btnLabel.fontSize = 22
        btnLabel.fontName = "ChalkboardSE-Bold"
        btnLabel.fontColor = .white
        btnLabel.verticalAlignmentMode = .center
        btnLabel.position = .zero
        btnLabel.name = "tutorialDismiss"
        btn.addChild(btnLabel)

        // Store completion for touch handler
        tutorialDismissAction = { [weak self] in
            tutorialContainer.removeFromParent()
            self?.gameLayer.isPaused = false
            self?.progress.seenTutorials.insert(level)
            self?.progress.save()
            self?.tutorialDismissAction = nil
            completion()
        }
    }

    private var tutorialDismissAction: (() -> Void)?

    private func setupScene() {
        gameLayer = SKNode()
        gameLayer.name = "gameLayer"
        addChild(gameLayer)

        setupScoreNode()
        setupDoor()
        setupBench()
        setupIngredientShelf()
        setupKitchenCounter()
        // Only show mixer if this level has recipes that require mixing
        let hasMixingRecipes = levelConfig?.recipeNames.contains(where: { name in
            KitchenScene.allRecipes.first { $0.name == name }?.requiresMixing == true
        }) ?? false
        if hasMixingRecipes {
            setupMixer()
        }
        setupStoveTop()
        setupPlateStack()
        setupSink()
        setupBinButtons()
        setupRecipePanel()
    }

    // MARK: - Layout

    private func setupScoreNode() {
        let hudWidth: CGFloat = 200
        hudNode = HudNode(width: hudWidth)
        hudNode.position = CGPoint(x: size.width - hudWidth / 2 - 10, y: size.height - 50)
        hudNode.zPosition = 2
        gameLayer.addChild(hudNode)
    }

    private func setupDoor() {
        let doorTexture = SKTexture(imageNamed: "door")
        let doorSprite = SKSpriteNode(texture: doorTexture)
        let doorHeight: CGFloat = 100
        let doorScale = doorHeight / doorTexture.size().height
        doorSprite.size = CGSize(width: doorTexture.size().width * doorScale, height: doorHeight)
        doorSprite.position = CGPoint(x: seatX, y: size.height - 55)
        doorSprite.zPosition = 0
        gameLayer.addChild(doorSprite)
    }

    private func setupBench() {
        let benchTopY = size.height - 120
        let benchBottomY: CGFloat = 30
        let benchHeight = benchTopY - benchBottomY
        let benchCentreY = (benchTopY + benchBottomY) / 2

        let segmentHeight = benchHeight / CGFloat(chairCount)

        for i in 0..<chairCount {
            let seatY = benchTopY - segmentHeight * (CGFloat(i) + 0.5)
            let seatPos = CGPoint(x: seatX, y: seatY)
            seatPositions.append(seatPos)

            let stoolTexture = SKTexture(imageNamed: "bar_stool")
            let stool = SKSpriteNode(texture: stoolTexture)
            stool.size = CGSize(width: 55, height: 55)
            stool.position = seatPos
            stool.zPosition = 0
            gameLayer.addChild(stool)
        }

        let benchTexture = SKTexture(imageNamed: "bench_counter")
        let bench = SKSpriteNode(texture: benchTexture)
        bench.size = CGSize(width: benchHeight, height: self.benchWidth)
        bench.zRotation = .pi / 2
        bench.position = CGPoint(x: benchLeftEdge + self.benchWidth / 2, y: benchCentreY)
        bench.zPosition = -1
        gameLayer.addChild(bench)
    }

    private func setupIngredientShelf() {
        // Show only ingredients needed by this level's recipes
        let levelIngredients: [Ingredient]
        if let config = levelConfig {
            let recipeNames = Set(config.recipeNames)
            var seen = Set<String>()
            var ingredients: [Ingredient] = []
            for recipe in KitchenScene.allRecipes where recipeNames.contains(recipe.name) {
                for ing in recipe.requiredIngredients {
                    if seen.insert(ing.name).inserted {
                        ingredients.append(ing)
                    }
                }
            }
            levelIngredients = ingredients
        } else {
            levelIngredients = KitchenScene.allIngredients
        }

        let count = levelIngredients.count

        // Build pantry from individual slot images
        // Slot image is portrait (~78:100 ratio). Compartment is top ~68%, name tag is bottom ~32%.
        let slotTexture = SKTexture(imageNamed: "cupboard_slot")
        let slotWidth: CGFloat = 130
        let slotHeight: CGFloat = slotWidth * (1168.0 / 912.0)  // preserve image aspect ratio
        let slotGap: CGFloat = 4
        let totalWidth = CGFloat(count) * slotWidth + CGFloat(count - 1) * slotGap
        let shelfY = size.height - 105
        let pantryCentreX = (benchRightEdge + recipePanelLeftEdge) / 2
        let startX = pantryCentreX - totalWidth / 2 + slotWidth / 2

        let compartmentRatio: CGFloat = 0.68  // top portion is the square compartment
        let tagRatio: CGFloat = 0.32  // bottom portion is the name tag

        for (index, ingredient) in levelIngredients.enumerated() {
            let slotX = startX + CGFloat(index) * (slotWidth + slotGap)

            // Slot background
            let slot = SKSpriteNode(texture: slotTexture)
            slot.size = CGSize(width: slotWidth, height: slotHeight)
            slot.position = CGPoint(x: slotX, y: shelfY)
            slot.zPosition = -1
            gameLayer.addChild(slot)

            // Ingredient centred in the square compartment (upper portion)
            let compartmentCentreY = shelfY + (slotHeight * tagRatio / 2)
            let spriteSize = slotWidth * 0.6
            let node = IngredientNode(
                ingredient: ingredient,
                spriteSize: spriteSize,
                labelOffsetX: 0,
                labelOffsetY: -(slotHeight * compartmentRatio * 0.5 + slotHeight * tagRatio * 0.5)
            )
            node.position = CGPoint(x: slotX, y: compartmentCentreY)
            node.zPosition = 1
            gameLayer.addChild(node)
            ingredientShelfNodes.append(node)
        }
    }

    private func setupKitchenCounter() {
        let counterWidth = recipePanelLeftEdge - benchRightEdge - 20
        let counterHeight: CGFloat = 280
        let counterTexture = SKTexture(imageNamed: "kitchen_counter")
        let counter = SKSpriteNode(texture: counterTexture)
        counter.size = CGSize(width: counterWidth, height: counterHeight)
        counter.position = CGPoint(x: kitchenCentreX, y: workstationY)
        counter.zPosition = -1
        gameLayer.addChild(counter)
    }

    private func setupMixer() {
        let mixer = MixerNode(size: CGSize(width: 150, height: 150))
        mixer.position = CGPoint(x: mixerX, y: workstationY + 10)
        mixer.zPosition = 1
        gameLayer.addChild(mixer)
        mixerNode = mixer
    }

    private func setupPlateStack() {
        let plateSize: CGFloat = 70
        let stackOffset: CGFloat = 6

        for i in 0..<totalPlates {
            let texture = SKTexture(imageNamed: "plate")
            let plate = SKSpriteNode(texture: texture)
            plate.size = CGSize(width: plateSize, height: plateSize)
            plate.position = CGPoint(x: plateX, y: workstationY - 20 + CGFloat(i) * stackOffset)
            plate.zPosition = CGFloat(i) + 1
            gameLayer.addChild(plate)
            plateSprites.append(plate)
        }
    }

    private func updatePlateStack() {
        for (index, plate) in plateSprites.enumerated() {
            plate.isHidden = index >= platesRemaining
        }
    }

    private func setupStoveTop() {
        stoveTop = StoveTopNode(size: CGSize(width: 170, height: 170))
        stoveTop.position = CGPoint(x: stoveX, y: workstationY + 10)
        stoveTop.zPosition = 1
        stoveTop.canOvercook = levelConfig?.canOvercook ?? true
        gameLayer.addChild(stoveTop)
    }

    private var sinkSize: CGFloat { 130 }
    private var sinkCentreX: CGFloat { benchRightEdge + sinkSize / 2 + 10 }
    private var sinkY: CGFloat { workstationY - 200 }

    private func setupSink() {
        let sinkTexture = SKTexture(imageNamed: "sink")
        let sink = SKSpriteNode(texture: sinkTexture)
        sink.size = CGSize(width: sinkSize, height: sinkSize)
        sink.position = CGPoint(x: sinkCentreX, y: sinkY)
        sink.zPosition = 0
        gameLayer.addChild(sink)
    }

    private func setupBinButtons() {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let trashImage = UIImage(systemName: "trash.fill", withConfiguration: config)!
            .withTintColor(.systemRed, renderingMode: .alwaysOriginal)
        let trashTexture = SKTexture(image: trashImage)

        mixerBinButton = SKSpriteNode(texture: trashTexture)
        mixerBinButton.size = CGSize(width: 30, height: 30)
        mixerBinButton.position = CGPoint(x: mixerX + 90, y: workstationY + 60)
        mixerBinButton.name = "mixerBin"
        mixerBinButton.alpha = 0
        mixerBinButton.isHidden = true
        mixerBinButton.zPosition = 3
        gameLayer.addChild(mixerBinButton)

        panBinButton = SKSpriteNode(texture: trashTexture)
        panBinButton.size = CGSize(width: 30, height: 30)
        panBinButton.position = CGPoint(x: stoveX + 100, y: workstationY + 60)
        panBinButton.name = "panBin"
        panBinButton.alpha = 0
        panBinButton.isHidden = true
        panBinButton.zPosition = 3
        gameLayer.addChild(panBinButton)
    }

    private func setupRecipePanel() {
        let panelTop = size.height - 100
        let panelHeight = panelTop - 10
        let recipes = levelConfig?.recipes ?? KitchenScene.allRecipes
        recipePanel = RecipePanelNode(recipes: recipes, width: 200, height: panelHeight)
        recipePanel.position = CGPoint(x: recipePanelCentreX, y: panelTop - panelHeight / 2)
        gameLayer.addChild(recipePanel)
    }

    // MARK: - Customer seating

    /// Customer patience adjusted for expected concurrency.
    /// More concurrent customers = more patience (20% extra per additional concurrent customer).
    private func adjustedPatience(for recipe: Recipe) -> TimeInterval {
        let baseWait = recipe.waitTime
        let chairs = levelConfig?.chairCount ?? 1
        let interval = levelConfig?.arrivalInterval ?? 0

        // Average service time: how long a customer occupies a seat
        let avgServiceTime = Double(chairs) * 15.0 + baseWait  // rough estimate

        // Expected concurrent customers from Poisson arrival rate
        let concurrent: Int
        if interval > 0 {
            concurrent = min(chairs, Int(ceil(avgServiceTime / interval)))
        } else {
            concurrent = 1  // sequential arrival
        }

        return baseWait + Double(concurrent - 1) * baseWait * 0.2
    }

    private func seatPositionForSlot(_ index: Int) -> CGPoint {
        guard index < seatPositions.count else {
            let lastSeat = seatPositions.last ?? CGPoint(x: seatX, y: 100)
            return CGPoint(x: lastSeat.x, y: lastSeat.y - CGFloat(index - seatPositions.count + 1) * 100)
        }
        return seatPositions[index]
    }

    private var canSpawnMore: Bool { totalCustomersSpawned < totalCustomerCount }

    private func isSeatOccupied(_ index: Int) -> Bool {
        return seatItems[index]?.customerNode != nil
    }

    private func isSeatClear(_ index: Int) -> Bool {
        let item = seatItems[index]
        return item?.customerNode == nil && item?.moneySprite == nil && item?.plateSprite == nil
    }

    private func isSeatDirty(_ index: Int) -> Bool {
        let item = seatItems[index]
        return item?.customerNode == nil && (item?.moneySprite != nil || item?.plateSprite != nil)
    }

    private func hasUnoccupiedSeat() -> Bool {
        for i in 0..<chairCount {
            if !isSeatOccupied(i) { return true }
        }
        return false
    }

    private func firstClearSeatIndex() -> Int? {
        for i in 0..<chairCount {
            if isSeatClear(i) { return i }
        }
        return nil
    }

    private func firstUnoccupiedSeatIndex() -> Int? {
        for i in 0..<chairCount {
            if !isSeatOccupied(i) { return i }
        }
        return nil
    }

    private func spawnCustomer() {
        guard canSpawnMore && hasUnoccupiedSeat() else { return }
        totalCustomersSpawned += 1
        let template = KitchenScene.customerPool.randomElement()!
        let availableRecipes = levelConfig?.recipes ?? KitchenScene.allOrders
        let order = availableRecipes.randomElement()!
        let customer = Customer(name: template.name, imageName: template.imageName, order: order)
        let node = CustomerNode(customer: customer)

        if let clearSeat = firstClearSeatIndex() {
            // Seat is clear — sit immediately
            seatCustomer(node: node, customer: customer, at: clearSeat)
        } else {
            // No clear seat but unoccupied dirty seat exists — wait at door
            addToDoorQueue(node: node, customer: customer)
        }
    }

    private func seatCustomer(node: CustomerNode, customer: Customer, at seatIndex: Int) {
        let seatPos = seatPositionForSlot(seatIndex)
        node.position = seatPos
        node.zPosition = 1
        gameLayer.addChild(node)
        node.animateEntrance()
        customerSeatIndices[ObjectIdentifier(node)] = seatIndex
        seatItems[seatIndex] = SeatItem(customerNode: node)

        // Start customer order timer (if enabled)
        if levelConfig?.hasCustomerTimer ?? true {
            node.onTimerExpired = { [weak self, weak node] in
                self?.handleCustomerLeft(node: node)
            }
            node.startTimer(duration: adjustedPatience(for: customer.order))
        }

        customerNodes.append(node)
        customerData.append(customer)
    }

    private func addToDoorQueue(node: CustomerNode, customer: Customer) {
        node.position = doorPosition
        node.zPosition = 1
        gameLayer.addChild(node)
        node.animateEntrance()

        // 10 second door timer
        node.onDoorTimerExpired = { [weak self, weak node] in
            self?.handleDoorCustomerLeft(node: node)
        }
        node.startDoorTimer(duration: 10.0)

        doorQueue.append(node)
        doorQueueData.append(customer)
    }

    private func handleDoorCustomerLeft(node: CustomerNode?) {
        guard let node, let index = doorQueue.firstIndex(where: { $0 === node }) else { return }
        hudNode.removeSnowflakes(1)
        missedCustomers += 1
        customersServed += 1

        node.animateExit {
            node.removeFromParent()
        }
        doorQueue.remove(at: index)
        doorQueueData.remove(at: index)

        // Try to spawn the next customer immediately
        if canSpawnMore {
            spawnCustomer()
        }

        checkGameEnd()
    }

    private func trySeatDoorCustomer() {
        guard !doorQueue.isEmpty, let clearSeat = firstClearSeatIndex() else { return }
        let node = doorQueue.removeFirst()
        let customer = doorQueueData.removeFirst()
        node.cancelDoorTimer()

        // Animate from door to seat
        let seatPos = seatPositionForSlot(clearSeat)
        node.run(SKAction.move(to: seatPos, duration: 0.3))
        customerSeatIndices[ObjectIdentifier(node)] = clearSeat
        seatItems[clearSeat] = SeatItem(customerNode: node)

        // Start order timer
        node.onTimerExpired = { [weak self, weak node] in
            self?.handleCustomerLeft(node: node)
        }
        node.startTimer(duration: customer.order.waitTime)

        customerNodes.append(node)
        customerData.append(customer)
    }

    private func handleCustomerLeft(node: CustomerNode?) {
        guard let node, let index = customerNodes.firstIndex(where: { $0 === node }) else { return }

        let customer = customerData[index]
        hudNode.removeSnowflakes(customer.order.basePoints)
        missedCustomers += 1
        customersServed += 1

        node.showRejected()

        run(SKAction.wait(forDuration: 1.0)) { [weak self] in
            guard let self else { return }
            guard let idx = self.customerNodes.firstIndex(where: { $0 === node }) else { return }

            node.animateExit {
                node.removeFromParent()
            }
            // Clear customer from seat
            if let seatIdx = self.customerSeatIndices[ObjectIdentifier(node)] {
                self.seatItems[seatIdx]?.customerNode = nil
            }
            self.customerSeatIndices.removeValue(forKey: ObjectIdentifier(node))
            self.customerNodes.remove(at: idx)
            self.customerData.remove(at: idx)

            if self.canSpawnMore {
                self.spawnCustomer()
            }

            self.checkGameEnd()
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // Unfreeze popup — tap anywhere to progress
        if let popup = unfreezePopup {
            popup.handleTap()
            return
        }

        // Tutorial dismiss
        if tutorialDismissAction != nil {
            for node in tappedNodes {
                if node.name == "tutorialDismiss" {
                    tutorialDismissAction?()
                    return
                }
            }
            return // Block all other touches while tutorial is showing
        }

        // Pause menu interactions (always active)
        if pauseOverlay != nil {
            for node in tappedNodes {
                if node.name == "resumeButton" {
                    resumeGame()
                    return
                }
                if node.name == "restartButton" {
                    resumeGame()
                    onReplay?()
                    return
                }
                if node.name == "pauseHomeButton" {
                    resumeGame()
                    onGoHome?()
                    return
                }
            }
            return // Block all other taps while paused
        }

        // Pause button
        for node in tappedNodes {
            if node.name == "pauseButton" {
                pauseGame()
                return
            }
        }

        // 0a. Money collection on bench
        if let seatIndex = findMoneyTap(in: tappedNodes) {
            collectMoney(at: seatIndex)
            return
        }

        // 0a2. Plate collection on bench
        if let seatIndex = findPlateTap(in: tappedNodes) {
            collectPlate(at: seatIndex)
            return
        }

        // 0b. Quiz difficulty dropdown on end screen
        for node in tappedNodes {
            if let name = node.name, name.starts(with: "endDiffOpt_") {
                let numStr = name.replacingOccurrences(of: "endDiffOpt_", with: "")
                if let num = Int(numStr) {
                    progress.quizGrade = num
                    progress.save()
                    endScreenDiffLabel?.text = "Quiz Grade \(num)  ▼"
                    endDiffDropdown?.removeFromParent()
                    endDiffDropdown = nil
                    return
                }
            }
            if node.name == "endDiffToggle" {
                if endDiffDropdown != nil {
                    endDiffDropdown?.removeFromParent()
                    endDiffDropdown = nil
                } else {
                    showEndDiffDropdown()
                }
                return
            }
        }
        if endDiffDropdown != nil {
            endDiffDropdown?.removeFromParent()
            endDiffDropdown = nil
            return
        }

        // 0c. Next button (game end screen)
        for node in tappedNodes {
            if node.name == "replayButton" {
                onReplay?()
                return
            }
            if node.name == "nextLevelButton" {
                handleNextLevel()
                return
            }
            if node.name == "homeButton" {
                onGoHome?()
                return
            }
        }

        // 0b. Active quiz takes priority
        if let quiz = activeQuiz {
            if quiz.handleTap(at: location) {
                return
            }
        }

        // 0c. Pickup mode — ingredient is floating
        if let picked = pickedUpIngredient {
            // Tap X to return ingredient
            if picked.isCloseButtonTap(at: location) {
                cancelPickup()
                return
            }
            // Tap active mixer target
            for node in tappedNodes {
                if findMixerNode(in: node) && (mixerNode?.canReceiveIngredient ?? false) {
                    if mixerNode?.currentIngredients.contains(picked.ingredient) == true {
                        cancelPickup()
                    } else {
                        placeIngredientInMixer(picked)
                    }
                    return
                }
            }
            // Tap active pan target
            for node in tappedNodes {
                if findStoveNode(in: node) && stoveTop.canReceiveIngredient {
                    if stoveTop.currentIngredients.contains(picked.ingredient) {
                        cancelPickup()
                    } else {
                        placeIngredientInPan(picked)
                    }
                    return
                }
            }
            // Tap grey/unavailable target or anything else — do nothing
            return
        }

        // 1. Bin buttons (always available when visible)
        for node in tappedNodes {
            if node.name == "mixerBin" {
                handleMixerBin()
                return
            }
            if node.name == "panBin" {
                handlePanBin()
                return
            }
        }

        // 2. Serving mode — pan is picked up, tap customer to serve
        if gamePhase == .servingCustomer {
            // Tap X on pan → put back
            if stoveTop.isPanCloseButtonTap(at: location) {
                exitServingMode()
                return
            }
            // Tap bin → discard
            for node in tappedNodes {
                if node.name == "panBin" {
                    stoveTop.putDownPan()
                    handlePanBin()
                    hideCustomerServeTargets()
                    gamePhase = .addingIngredients
                    return
                }
            }
            // Tap a customer
            for node in tappedNodes {
                if let customerNode = findCustomerNode(in: node) {
                    if !customerNode.isEating {
                        serveToCustomer(customerNode)
                    }
                    return
                }
            }
            // Anything else → do nothing
            return
        }

        // 3. Tap stove/pan to pick up or start cooking
        for node in tappedNodes {
            if findStoveNode(in: node) {
                if gamePhase == .readyToServe || gamePhase == .burnt {
                    enterServingMode()
                    return
                }
                if stoveTop.panState == .rawBatter {
                    startPanCooking()
                    return
                }
            }
        }

        // 3. Tap mixer to mix or pour
        for node in tappedNodes {
            if findMixerNode(in: node) {
                if mixerNode?.canMix == true {
                    startMixing()
                    return
                }
                if mixerNode?.canPour == true {
                    pourBatterToPan()
                    return
                }
            }
        }

        // 4. Recipe panel
        for node in tappedNodes {
            if node.name?.starts(with: "recipeRow") == true || node.parent?.name?.starts(with: "recipeRow") == true || node.parent?.parent?.name?.starts(with: "recipeRow") == true {
                recipePanel.handleTap(at: location)
                return
            }
            if node.name == "recipePanel" {
                recipePanel.handleTap(at: location)
                return
            }
        }

        // 5. Ingredient taps — start quiz
        for node in tappedNodes {
            if let ingredientNode = findIngredientNode(in: node) {
                if !ingredientNode.isPickedUp {
                    handleIngredientTap(ingredientNode)
                    return
                }
            }
        }
    }

    private func findCustomerNode(in node: SKNode) -> CustomerNode? {
        var current: SKNode? = node
        while let n = current {
            if let cn = n as? CustomerNode { return cn }
            current = n.parent
        }
        return nil
    }

    // MARK: - Serving mode

    private func enterServingMode() {
        gamePhase = .servingCustomer
        stoveTop.removeAction(forKey: "readyPulse")
        stoveTop.setScale(1.0)
        stoveTop.pickUpPan()
        showCustomerServeTargets()
    }

    private func exitServingMode() {
        stoveTop.putDownPan()
        hideCustomerServeTargets()
        // Restore previous phase based on pan state
        gamePhase = stoveTop.panState == .burnt ? .burnt : .readyToServe
        pulseStove()
    }

    private func showCustomerServeTargets() {
        for node in customerNodes {
            node.showServeTarget(active: !node.isEating)
        }
    }

    private func hideCustomerServeTargets() {
        for node in customerNodes {
            node.hideServeTarget()
        }
    }

    private func serveToCustomer(_ customerNode: CustomerNode) {
        guard let result = stoveTop.tapToServe() else { return }

        hideCustomerServeTargets()
        hidePanBin()

        guard let customerIdx = customerNodes.firstIndex(where: { $0 === customerNode }) else { return }
        let activeOrder = customerData[customerIdx].order
        let requiredSet = Set(activeOrder.requiredIngredients)
        let placedSet = Set(result.ingredients)
        let isCorrectOrder = requiredSet == placedSet && activeOrder.requiresMixing == result.wasMixed

        let servedDishImage = PanImageMapping.servedDishImage(for: result.ingredients, wasMixed: result.wasMixed)

        platesRemaining -= 1
        customersServed += 1
        updatePlateStack()

        // Place dish on bench
        placeDishOnBench(for: customerNode, imageName: servedDishImage)

        if isCorrectOrder && !result.isBurnt {
            let bonus = customerNode.isInBonusWindow ? 1 : 0
            customerNode.showCompleted()

            let payment = activeOrder.basePoints + bonus
            let seatIdx = customerSeatIndices[ObjectIdentifier(customerNode)] ?? 0
            customerNode.onFinishedEating = { [weak self] in
                self?.handleCustomerFinishedEating(payment: payment, seatIndex: seatIdx)
            }
            customerNode.startEating(duration: 5.0)
        } else {
            customerNode.showRejected()
            hudNode.removeSnowflakes(activeOrder.basePoints)
            missedCustomers += 1

            run(SKAction.wait(forDuration: 1.5)) { [weak self] in
                self?.removeCustomerAndContinue(customerNode)
            }
        }

        stoveTop.reset()
        hideMixerBin()
        gamePhase = .addingIngredients
    }

    private func removeCustomerAndContinue(_ node: CustomerNode) {
        guard let idx = customerNodes.firstIndex(where: { $0 === node }) else {
            checkGameEnd()
            return
        }

        if let seatIdx = customerSeatIndices[ObjectIdentifier(node)] {
            seatItems[seatIdx]?.customerNode = nil
        }
        customerSeatIndices.removeValue(forKey: ObjectIdentifier(node))
        node.animateExit {
            node.removeFromParent()
        }
        customerNodes.remove(at: idx)
        customerData.remove(at: idx)

        if canSpawnMore {
            spawnCustomer()
        }

        checkGameEnd()
    }

    private func findIngredientNode(in node: SKNode) -> IngredientNode? {
        if let ingredientNode = node as? IngredientNode { return ingredientNode }
        if let parent = node.parent as? IngredientNode { return parent }
        return nil
    }

    private func findMixerNode(in node: SKNode) -> Bool {
        var current: SKNode? = node
        while let n = current {
            if n === mixerNode { return true }
            current = n.parent
        }
        return false
    }

    private func findStoveNode(in node: SKNode) -> Bool {
        var current: SKNode? = node
        while let n = current {
            if n === stoveTop { return true }
            current = n.parent
        }
        return false
    }

    // MARK: - Ingredient handling

    private func handleIngredientTap(_ ingredientNode: IngredientNode) {
        guard activeQuiz == nil else { return }
        guard pickedUpIngredient == nil else { return }

        // Show quiz
        pendingIngredientNode = ingredientNode
        let quiz = QuizNode(sceneSize: size, difficulty: progress.quizGrade)
        let reward = quiz.rewardAmount
        quiz.position = CGPoint(x: size.width / 2, y: size.height / 2)
        quiz.configure(
            onCorrect: { [weak self] in
                guard let self, let node = self.pendingIngredientNode else { return }
                self.hudNode.addSnowflakes(reward)
                self.hudNode.showSnowflakeChange(reward)
                self.enterPickupMode(node)
                self.activeQuiz = nil
                self.pendingIngredientNode = nil
            },
            onWrong: { [weak self] in
                self?.hudNode.removeSnowflakes(1)
                self?.hudNode.showSnowflakeChange(-1)
                self?.activeQuiz = nil
                self?.pendingIngredientNode = nil
            }
        )
        addChild(quiz)
        activeQuiz = quiz
    }

    // MARK: - Pickup mode

    private func enterPickupMode(_ ingredientNode: IngredientNode) {
        pickedUpIngredient = ingredientNode
        ingredientNode.animatePickup()

        // Show drop targets — both mixer and pan
        mixerNode?.showDropTarget(active: mixerNode?.canReceiveIngredient ?? false)
        stoveTop.showDropTarget(active: stoveTop.canReceiveIngredient)
    }

    private func cancelPickup() {
        pickedUpIngredient?.animateReturn()
        pickedUpIngredient = nil
        mixerNode?.hideDropTarget()
        stoveTop.hideDropTarget()
    }

    private func placeIngredientInMixer(_ ingredientNode: IngredientNode) {
        ingredientNode.animateReturn()
        pickedUpIngredient = nil
        mixerNode?.hideDropTarget()
        stoveTop.hideDropTarget()

        mixerNode?.addIngredient(ingredientNode.ingredient)
        showMixerBin()

        if mixerNode?.canMix == true {
            pulseMixer()
        }
    }

    private func placeIngredientInPan(_ ingredientNode: IngredientNode) {
        ingredientNode.animateReturn()
        pickedUpIngredient = nil
        mixerNode?.hideDropTarget()
        stoveTop.hideDropTarget()

        stoveTop.addIngredientDirect(
            ingredientNode.ingredient,
            cookingComplete: { [weak self] in
                self?.onCookingComplete()
            },
            burnt: { [weak self] in
                self?.onBurnt()
            }
        )

        pulseStove()
        showPanBin()
    }

    // MARK: - Pan cooking

    private func startPanCooking() {
        gamePhase = .cooking

        // Set cook time from the recipe's ingredients
        if let order = customerData.first?.order {
            let isTraining = (levelConfig?.level ?? 1) <= 10
            stoveTop.cookingDuration = isTraining ? order.cookTime * 0.5 : order.cookTime
        }

        stoveTop.startCooking()
        showPanBin()
    }

    // MARK: - Mixing

    private func startMixing() {
        gamePhase = .mixing
        mixerNode?.removeAction(forKey: "readyPulse")
        mixerNode?.setScale(1.0)

        mixerNode?.startMixing { [weak self] in
            self?.onMixingComplete()
        }
    }

    private func onMixingComplete() {
        gamePhase = .batterReady

        // Pulse the mixer to indicate "tap me"
        mixerNode?.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])), withKey: "readyPulse")
    }

    // MARK: - Pour batter to pan

    private func pourBatterToPan() {
        mixerNode?.removeAction(forKey: "readyPulse")
        mixerNode?.setScale(1.0)

        guard let ingredients = mixerNode?.pourBatter(), !ingredients.isEmpty else { return }

        // Batter goes to pan but doesn't auto-cook — player taps pan to start
        gamePhase = .addingIngredients
        hideMixerBin()

        stoveTop.receiveBatter(
            ingredients: ingredients,
            cookingComplete: { [weak self] in
                self?.onCookingComplete()
            },
            burnt: { [weak self] in
                self?.onBurnt()
            }
        )

        // Pulse stove to indicate "tap to cook"
        pulseStove()
        showPanBin()
    }

    // MARK: - Cooking

    private func onCookingComplete() {
        gamePhase = .readyToServe
        pulseStove()
    }

    private func onBurnt() {
        gamePhase = .burnt
        // Serve button stays visible — serving burnt food penalises
    }

    // MARK: - Serving

    private func handleCustomerFinishedEating(payment: Int = 0, seatIndex: Int = 0) {
        let autoMoney = levelConfig?.autoCollectMoney ?? false
        let autoClear = levelConfig?.autoClearTable ?? false

        if let customerNode = customerNodes.first {
            removeDishFromBench(for: customerNode)

            if autoClear {
                // Auto-clear: plate is instantly recycled (no manual clearing or washing)
                platesRemaining += 1
                updatePlateStack()
            } else {
                placeDirtyPlateOnBench(seatIndex: seatIndex)
            }

            if payment > 0 && seatIndex < seatPositions.count {
                if autoMoney {
                    // Auto-collect: fly money directly to HUD, no tap needed
                    hudNode.addDollars(payment)
                } else {
                    placeMoneyAtSeat(seatIndex: seatIndex, payment: payment)
                }
            }
        }
        removeFirstCustomerAndContinue()
    }

    private func removeFirstCustomerAndContinue() {
        guard let node = customerNodes.first else {
            checkGameEnd()
            return
        }

        // Clear customer from seat (money/plate may remain)
        if let seatIdx = customerSeatIndices[ObjectIdentifier(node)] {
            seatItems[seatIdx]?.customerNode = nil
        }
        customerSeatIndices.removeValue(forKey: ObjectIdentifier(node))
        node.animateExit {
            node.removeFromParent()
        }
        customerNodes.removeFirst()
        customerData.removeFirst()

        if canSpawnMore {
            spawnCustomer()
        }

        checkGameEnd()
    }

    private func checkGameEnd() {
        let hasCustomers = !customerNodes.isEmpty
        let hasDoorCustomers = !doorQueue.isEmpty
        let hasDirtySeats = (0..<chairCount).contains { isSeatDirty($0) }

        // Condition 1: no customers, no door queue, no dirty seats, no more to spawn → all done
        if !hasCustomers && !hasDoorCustomers && !hasDirtySeats && !canSpawnMore {
            handleGameOver()
            return
        }

        // Condition 2: no plates, no eating customers, no dirty seats, no more spawning possible
        let hasEatingCustomers = customerNodes.contains { $0.isEating }
        if platesRemaining <= 0 && !hasEatingCustomers && !hasDirtySeats && !hasDoorCustomers && !canSpawnMore {
            handleGameOver()
            return
        }
    }

    // MARK: - Bin handling

    private func handleMixerBin() {
        guard mixerNode?.isEmpty == false else { return }
        mixerNode?.removeAction(forKey: "readyPulse")
        mixerNode?.setScale(1.0)
        mixerNode?.reset()
        hideMixerBin()

        gamePhase = .addingIngredients
    }

    private func handlePanBin() {
        guard stoveTop.hasContents else { return }
        stoveTop.removeAction(forKey: "readyPulse")
        stoveTop.setScale(1.0)
        stoveTop.reset()
        mixerNode?.reset()
        hidePanBin()
        hideMixerBin()

        gamePhase = .addingIngredients
    }

    // MARK: - Reset

    private func resetForNextOrder() {
        stoveTop.reset()
        mixerNode?.reset()
        hideMixerBin()
        hidePanBin()

        gamePhase = .addingIngredients

        guard let servedNode = customerNodes.first else { return }

        servedNode.animateExit { [weak self] in
            guard let self else { return }
            servedNode.removeFromParent()
            self.customerNodes.removeFirst()
            self.customerData.removeFirst()
            self.repositionCustomerStrip()
            self.spawnCustomer()
        }
    }


    private func repositionCustomerStrip() {
        for (index, node) in customerNodes.enumerated() {
            let target = seatPositionForSlot(index)
            node.run(SKAction.move(to: target, duration: 0.3))
        }
    }

    // MARK: - Game end

    private var levelEndBonus: Int = 0

    private func handleGameOver() {
        // Include unserved customers in the missed count
        let unserved = totalCustomerCount - customersServed
        missedCustomers += unserved

        // Calculate level-end bonus: 3sf (0 missed), 2sf (1 missed), 1sf (2+ missed)
        if missedCustomers == 0 {
            levelEndBonus = 3
        } else if missedCustomers == 1 {
            levelEndBonus = 2
        } else {
            levelEndBonus = 1
        }
        hudNode.addSnowflakes(levelEndBonus)

        // Negative protection: if net snowflakes are negative, zero them out
        if hudNode.snowflakes < 0 {
            hudNode.snowflakes = 0
        }

        if unserved > 0 {
            showUnservedPopup(count: unserved) { [weak self] in
                self?.showGameEndScreen()
            }
        } else {
            showGameEndScreen()
        }
    }

    private func showUnservedPopup(count: Int, completion: @escaping () -> Void) {
        // No snowflake deduction here — missed customers reduce the level-end bonus instead

        // Show all unserved customers with crosses
        for node in customerNodes {
            node.showRejected()
        }

        // Overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = UIColor(white: 0, alpha: 0.5)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 85
        overlay.name = "unservedOverlay"
        addChild(overlay)

        // Card
        let card = SKShapeNode(rectOf: CGSize(width: 400, height: 200), cornerRadius: 20)
        card.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.98)
        card.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        card.lineWidth = 3
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        card.zPosition = 86
        card.name = "unservedCard"
        addChild(card)

        let titleText = platesRemaining <= 0 ? "No plates left!" : "Time's up!"
        let title = SKLabelNode(text: titleText)
        title.fontSize = 26
        title.fontName = "AvenirNext-Bold"
        title.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
        title.zPosition = 87
        addChild(title)

        let detail = SKLabelNode(text: "\(count) customer\(count == 1 ? "" : "s") left hungry")
        detail.fontSize = 20
        detail.fontName = "AvenirNext-Medium"
        detail.fontColor = UIColor(red: 0.8, green: 0.15, blue: 0.15, alpha: 1.0)
        detail.verticalAlignmentMode = .center
        detail.position = CGPoint(x: size.width / 2, y: size.height / 2 - 10)
        detail.zPosition = 87
        addChild(detail)

        // Auto-dismiss after 2.5s
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run {
                overlay.removeFromParent()
                card.removeFromParent()
                title.removeFromParent()
                detail.removeFromParent()
            },
            SKAction.wait(forDuration: 0.3),
            SKAction.run { completion() }
        ]))
    }

    private func showGameEndScreen() {
        let earnedDollars = hudNode.dollars
        let quizSnow = hudNode.snowflakes - levelEndBonus
        let earnedSnowflakes = hudNode.snowflakes
        let prevDollars = progress.totalDollars
        let prevSnowflakes = progress.totalSnowflakes
        let messageText = earnedDollars > 0 ? "Congratulations!" : "Better luck next time!"

        let cx = size.width / 2
        let brown = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        let blue = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
        let green = UIColor(red: 0.2, green: 0.65, blue: 0.3, alpha: 1.0)

        // Dim overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = UIColor(white: 0, alpha: 0.6)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: cx, y: size.height / 2)
        overlay.zPosition = 90
        addChild(overlay)

        // Card
        let cardH: CGFloat = 580
        let card = SKShapeNode(rectOf: CGSize(width: 460, height: cardH), cornerRadius: 24)
        card.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.98)
        card.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        card.lineWidth = 3
        card.position = CGPoint(x: cx, y: size.height / 2)
        card.zPosition = 91
        addChild(card)

        // Dora — large, fills the top portion
        let doraTexture = SKTexture(imageNamed: "dora")
        let dora = SKSpriteNode(texture: doraTexture)
        let doraHeight: CGFloat = 200
        let doraScale = doraHeight / doraTexture.size().height
        dora.size = CGSize(width: doraTexture.size().width * doraScale, height: doraHeight)
        dora.position = CGPoint(x: cx, y: size.height / 2 + 175)
        dora.zPosition = 92
        addChild(dora)

        // Message
        let message = SKLabelNode(text: messageText)
        message.fontSize = 26
        message.fontName = "AvenirNext-Bold"
        message.fontColor = brown
        message.verticalAlignmentMode = .center
        message.position = CGPoint(x: cx, y: size.height / 2 + 45)
        message.zPosition = 92
        addChild(message)

        // --- Current totals row ---
        let totalsY = size.height / 2 - 10
        let totalsLabel = SKLabelNode(text: "Your total:")
        totalsLabel.fontSize = 14
        totalsLabel.fontName = "AvenirNext-Medium"
        totalsLabel.fontColor = brown
        totalsLabel.alpha = 0.6
        totalsLabel.verticalAlignmentMode = .center
        totalsLabel.position = CGPoint(x: cx, y: totalsY + 28)
        totalsLabel.zPosition = 92
        addChild(totalsLabel)

        // Money total
        let moneyTotalIcon = SKSpriteNode(texture: SKTexture(imageNamed: "money"))
        moneyTotalIcon.size = CGSize(width: 20, height: 20)
        moneyTotalIcon.position = CGPoint(x: cx - 60, y: totalsY)
        moneyTotalIcon.zPosition = 92
        addChild(moneyTotalIcon)

        let moneyTotalLabel = SKLabelNode(text: "$\(prevDollars)")
        moneyTotalLabel.fontSize = 20
        moneyTotalLabel.fontName = "AvenirNext-Bold"
        moneyTotalLabel.fontColor = brown
        moneyTotalLabel.horizontalAlignmentMode = .left
        moneyTotalLabel.verticalAlignmentMode = .center
        moneyTotalLabel.position = CGPoint(x: cx - 42, y: totalsY)
        moneyTotalLabel.zPosition = 92
        addChild(moneyTotalLabel)

        // Snowflake total
        let snowTotalIcon = SKSpriteNode(texture: SKTexture(imageNamed: "snowflake"))
        snowTotalIcon.size = CGSize(width: 20, height: 20)
        snowTotalIcon.position = CGPoint(x: cx + 30, y: totalsY)
        snowTotalIcon.zPosition = 92
        addChild(snowTotalIcon)

        let snowTotalLabel = SKLabelNode(text: "\(prevSnowflakes)")
        snowTotalLabel.fontSize = 20
        snowTotalLabel.fontName = "AvenirNext-Bold"
        snowTotalLabel.fontColor = blue
        snowTotalLabel.horizontalAlignmentMode = .left
        snowTotalLabel.verticalAlignmentMode = .center
        snowTotalLabel.position = CGPoint(x: cx + 48, y: totalsY)
        snowTotalLabel.zPosition = 92
        addChild(snowTotalLabel)

        // --- Earnings row ---
        let earnY = size.height / 2 - 60

        // + $X earned
        let moneyEarn = SKLabelNode(text: "+ $\(earnedDollars)")
        moneyEarn.fontSize = 22
        moneyEarn.fontName = "AvenirNext-Bold"
        moneyEarn.fontColor = green
        moneyEarn.verticalAlignmentMode = .center
        moneyEarn.position = CGPoint(x: cx - 50, y: earnY)
        moneyEarn.zPosition = 92
        addChild(moneyEarn)

        // + Xsf quiz
        let snowEarn = SKLabelNode(text: "+ \(quizSnow) quiz")
        snowEarn.fontSize = 18
        snowEarn.fontName = "AvenirNext-Bold"
        snowEarn.fontColor = blue
        snowEarn.verticalAlignmentMode = .center
        snowEarn.position = CGPoint(x: cx + 50, y: earnY)
        snowEarn.zPosition = 92
        addChild(snowEarn)

        // --- Bonus snowflakes (1-3 icons) ---
        let bonusY = earnY - 60
        let bonusLabel = SKLabelNode(text: "Bonus:")
        bonusLabel.fontSize = 14
        bonusLabel.fontName = "AvenirNext-Medium"
        bonusLabel.fontColor = brown
        bonusLabel.alpha = 0.6
        bonusLabel.verticalAlignmentMode = .center
        bonusLabel.position = CGPoint(x: cx - 60, y: bonusY)
        bonusLabel.zPosition = 92
        addChild(bonusLabel)

        let snowflakeTexture = SKTexture(imageNamed: "snowflake")
        var bonusIcons: [SKSpriteNode] = []
        for i in 0..<3 {
            let icon = SKSpriteNode(texture: snowflakeTexture)
            icon.size = CGSize(width: 26, height: 26)
            icon.position = CGPoint(x: cx - 10 + CGFloat(i) * 32, y: bonusY)
            icon.zPosition = 92
            icon.alpha = 0.25  // start dim, animate in
            addChild(icon)
            bonusIcons.append(icon)
        }

        // --- Animation sequence ---
        func makeBounce() -> SKAction {
            SKAction.sequence([SKAction.scale(to: 1.3, duration: 0.12), SKAction.scale(to: 1.0, duration: 0.12)])
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            // Animate money earning → fly into total
            SKAction.run {
                moneyEarn.run(SKAction.group([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.move(to: moneyTotalLabel.position, duration: 0.3)
                ]))
            },
            SKAction.wait(forDuration: 0.35),
            SKAction.run { [self] in
                moneyTotalLabel.text = "$\(prevDollars + earnedDollars)"
                moneyTotalLabel.run(makeBounce())
            },
            SKAction.wait(forDuration: 0.3),
            // Animate quiz snowflakes → fly into total
            SKAction.run {
                snowEarn.run(SKAction.group([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.move(to: snowTotalLabel.position, duration: 0.3)
                ]))
            },
            SKAction.wait(forDuration: 0.35),
            SKAction.run { [self] in
                snowTotalLabel.text = "\(prevSnowflakes + quizSnow)"
                snowTotalLabel.run(makeBounce())
            },
            SKAction.wait(forDuration: 0.2),
            // Animate bonus snowflakes one by one
            SKAction.run { [self] in
                for i in 0..<levelEndBonus {
                    let delay = Double(i) * 0.3
                    bonusIcons[i].run(SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.fadeAlpha(to: 1.0, duration: 0.2),
                        makeBounce(),
                        SKAction.wait(forDuration: 0.1),
                        SKAction.run { [self] in
                            snowTotalLabel.text = "\(prevSnowflakes + quizSnow + i + 1)"
                            snowTotalLabel.run(makeBounce())
                        }
                    ]))
                }
            },
            SKAction.wait(forDuration: Double(levelEndBonus) * 0.3 + 0.3),
            // Save progress and show buttons
            SKAction.run { [self] in
                progress.totalDollars += earnedDollars
                progress.totalSnowflakes += earnedSnowflakes
                progress.save()
                showEndScreenButtons(cardH: cardH, bonusY: bonusY)
            }
        ]))

    }

    private var endScreenDiffLabel: SKLabelNode?
    private var endDiffDropdown: SKNode?

    private func showEndDiffDropdown() {
        endDiffDropdown?.removeFromParent()

        let brown = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        let container = SKNode()
        container.zPosition = 95
        addChild(container)
        endDiffDropdown = container

        let itemH: CGFloat = 30
        let dropW: CGFloat = 160
        // Position dropdown above the toggle button
        let startY = size.height / 2 - 160  // above the buttons area

        for i in 1...9 {
            let y = startY + CGFloat(9 - i) * itemH

            let bg = SKShapeNode(rectOf: CGSize(width: dropW, height: itemH - 2), cornerRadius: 6)
            bg.fillColor = i == progress.quizGrade
                ? UIColor(red: 0.85, green: 0.80, blue: 0.70, alpha: 0.98)
                : UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.98)
            bg.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 0.5)
            bg.lineWidth = 1
            bg.position = CGPoint(x: size.width / 2, y: y)
            bg.name = "endDiffOpt_\(i)"
            container.addChild(bg)

            let label = SKLabelNode(text: "Level \(i)")
            label.fontSize = 13
            label.fontName = i == progress.quizGrade ? "AvenirNext-Bold" : "AvenirNext-Medium"
            label.fontColor = brown
            label.verticalAlignmentMode = .center
            label.position = .zero
            label.name = "endDiffOpt_\(i)"
            bg.addChild(label)
        }
    }

    private func showEndScreenButtons(cardH: CGFloat, bonusY: CGFloat = 0) {
        let brown = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)

        // Quiz difficulty dropdown button above buttons
        let diffY = size.height / 2 - cardH / 2 + 100
        let diffBg = SKShapeNode(rectOf: CGSize(width: 160, height: 32), cornerRadius: 10)
        diffBg.fillColor = UIColor(red: 0.92, green: 0.88, blue: 0.80, alpha: 1.0)
        diffBg.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        diffBg.lineWidth = 1.5
        diffBg.position = CGPoint(x: size.width / 2, y: diffY)
        diffBg.zPosition = 92
        diffBg.name = "endDiffToggle"
        addChild(diffBg)

        let diffLabel = SKLabelNode(text: "Quiz Grade \(progress.quizGrade)  ▼")
        diffLabel.fontSize = 13
        diffLabel.fontName = "AvenirNext-Bold"
        diffLabel.fontColor = brown
        diffLabel.verticalAlignmentMode = .center
        diffLabel.position = CGPoint(x: 0, y: 0)
        diffLabel.name = "endDiffToggle"
        diffBg.addChild(diffLabel)
        endScreenDiffLabel = diffLabel

        // One-time nudge to upgrade quiz grade (shows at end of L3 if still on grade 1)
        let thisLevel = levelConfig?.level ?? 0
        if thisLevel == 3 && !progress.seenQuizGradeNudge && progress.quizGrade <= 1 {
            let nudgeY = (bonusY + diffY) / 2  // centred between bonus and quiz grade
            let nudge = SKLabelNode(text: "Try Grade 2 for more snowflakes!")
            nudge.fontSize = 14
            nudge.fontName = "ChalkboardSE-Bold"
            nudge.fontColor = UIColor(red: 0.7, green: 0.4, blue: 0.1, alpha: 1.0)
            nudge.verticalAlignmentMode = .center
            nudge.position = CGPoint(x: size.width / 2, y: nudgeY)
            nudge.zPosition = 92
            addChild(nudge)

            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.6),
                SKAction.fadeAlpha(to: 1.0, duration: 0.6)
            ])
            nudge.run(SKAction.repeatForever(pulse))

            progress.seenQuizGradeNudge = true
            progress.save()
        }

        let btnStyle: (SKShapeNode) -> Void = { btn in
            btn.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)
            btn.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
            btn.lineWidth = 2.5
            btn.zPosition = 92
        }
        let lblStyle: (SKLabelNode) -> Void = { [brown] lbl in
            lbl.fontSize = 16
            lbl.fontName = "AvenirNext-Bold"
            lbl.fontColor = brown
            lbl.verticalAlignmentMode = .center
            lbl.zPosition = 93
        }

        let buttonY = size.height / 2 - cardH / 2 + 45
        let buttonSpacing: CGFloat = 145

        let replayBtn = SKShapeNode(rectOf: CGSize(width: 130, height: 44), cornerRadius: 14)
        btnStyle(replayBtn)
        replayBtn.position = CGPoint(x: size.width / 2 - buttonSpacing, y: buttonY)
        replayBtn.name = "replayButton"
        addChild(replayBtn)
        let replayLabel = SKLabelNode(text: "Replay")
        lblStyle(replayLabel)
        replayLabel.position = .zero
        replayLabel.name = "replayButton"
        replayBtn.addChild(replayLabel)

        let currentLevel = levelConfig?.level ?? 1
        let nextConfig = LevelConfig.nextLevel(after: currentLevel)
        if nextConfig != nil {
            let nextBtn = SKShapeNode(rectOf: CGSize(width: 130, height: 44), cornerRadius: 14)
            btnStyle(nextBtn)
            nextBtn.position = CGPoint(x: size.width / 2, y: buttonY)
            nextBtn.name = "nextLevelButton"
            addChild(nextBtn)
            let nextLabel = SKLabelNode(text: "Next Level")
            lblStyle(nextLabel)
            nextLabel.position = .zero
            nextLabel.name = "nextLevelButton"
            nextBtn.addChild(nextLabel)
        }

        let homeBtn = SKShapeNode(rectOf: CGSize(width: 130, height: 44), cornerRadius: 14)
        btnStyle(homeBtn)
        homeBtn.position = CGPoint(x: size.width / 2 + buttonSpacing, y: buttonY)
        homeBtn.name = "homeButton"
        addChild(homeBtn)
        let homeLabel = SKLabelNode(text: "Home")
        lblStyle(homeLabel)
        homeLabel.position = .zero
        homeLabel.name = "homeButton"
        homeBtn.addChild(homeLabel)

        // Fade buttons in
        for node in [replayBtn, homeBtn] {
            node.alpha = 0
            node.run(SKAction.fadeIn(withDuration: 0.3))
        }
    }

    private var unfreezePopup: UnfreezePopupNode?

    private func handleNextLevel() {
        let currentLevel = levelConfig?.level ?? 1
        guard let nextConfig = LevelConfig.nextLevel(after: currentLevel) else { return }

        if progress.isLevelUnlocked(nextConfig.level) {
            onNextLevel?(nextConfig)
        } else {
            let popup = UnfreezePopupNode(config: nextConfig, progress: progress, sceneSize: size)
            popup.onUnfreezeComplete = { [weak self] cfg in
                self?.unfreezePopup = nil
                self?.onNextLevel?(cfg)
            }
            popup.onDismiss = { [weak self] in
                self?.unfreezePopup = nil
            }
            addChild(popup)
            unfreezePopup = popup
        }
    }


    private func restartGame() {
        removeAllChildren()
        removeAllActions()

        ingredientShelfNodes.removeAll()
        seatPositions.removeAll()
        customerNodes.removeAll()
        customerData.removeAll()
        customerSeatIndices.removeAll()
        plateSprites.removeAll()
        dirtyDishSprites.removeAll()
        dirtyDishCount = 0
        benchDishSprites.removeAll()
        seatItems.removeAll()
        doorQueue.removeAll()
        doorQueueData.removeAll()
        platesRemaining = totalPlates
        customersServed = 0
        missedCustomers = 0
        levelEndBonus = 0
        totalCustomersSpawned = 0
        gamePhase = .addingIngredients
        activeQuiz = nil
        pendingIngredientNode = nil

        setupScene()
        spawnCustomer()
    }

    // MARK: - Button visibility helpers

    private func showMixerBin() {
        guard mixerBinButton.isHidden else { return }
        mixerBinButton.isHidden = false
        mixerBinButton.run(SKAction.fadeIn(withDuration: 0.2))
    }

    private func hideMixerBin() {
        mixerBinButton.run(SKAction.fadeOut(withDuration: 0.2)) { [weak self] in
            self?.mixerBinButton.isHidden = true
        }
    }

    private func showPanBin() {
        panBinButton.isHidden = false
        panBinButton.run(SKAction.fadeIn(withDuration: 0.2))
    }

    private func hidePanBin() {
        panBinButton.run(SKAction.fadeOut(withDuration: 0.2)) { [weak self] in
            self?.panBinButton.isHidden = true
        }
    }

    // MARK: - Station pulsing

    private func pulseMixer() {
        mixerNode?.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])), withKey: "readyPulse")
    }

    private func pulseStove() {
        stoveTop.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])), withKey: "readyPulse")
    }

    // MARK: - Dish on bench

    private func placeDishOnBench(for customerNode: CustomerNode, imageName: String) {
        let texture = SKTexture(imageNamed: imageName)
        let dish = SKSpriteNode(texture: texture)
        let maxDim: CGFloat = 90
        let texSize = texture.size()
        let scale = min(maxDim / texSize.width, maxDim / texSize.height)
        dish.size = CGSize(width: texSize.width * scale, height: texSize.height * scale)
        dish.position = CGPoint(x: benchLeftEdge + benchWidth / 2, y: customerNode.position.y)
        dish.zPosition = 2
        gameLayer.addChild(dish)
        benchDishSprites[ObjectIdentifier(customerNode)] = dish
    }

    private func removeDishFromBench(for customerNode: CustomerNode) {
        let key = ObjectIdentifier(customerNode)
        if let dish = benchDishSprites[key] {
            dish.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))
            benchDishSprites.removeValue(forKey: key)
        }
    }

    // MARK: - Money on bench

    private func placeMoneyAtSeat(seatIndex: Int, payment: Int) {
        guard seatIndex < seatPositions.count else { return }
        let seatPos = seatPositions[seatIndex]

        let texture = SKTexture(imageNamed: "money")
        let money = SKSpriteNode(texture: texture)
        money.size = CGSize(width: 60, height: 60)
        money.position = CGPoint(x: benchLeftEdge + benchWidth / 2, y: seatPos.y)
        money.zPosition = 3
        money.name = "benchMoney_\(seatIndex)"
        gameLayer.addChild(money)

        // Pop in animation
        money.setScale(0)
        money.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))

        seatItems[seatIndex, default: SeatItem()].moneySprite = money
        seatItems[seatIndex, default: SeatItem()].moneyPayment = payment
    }

    private func collectMoney(at seatIndex: Int) {
        guard let money = seatItems[seatIndex]?.moneySprite else { return }
        let payment = seatItems[seatIndex]?.moneyPayment ?? 0

        // Fly money to HUD position
        let hudPosition = hudNode.position
        let flyTo = SKAction.move(to: CGPoint(x: hudPosition.x + 30, y: hudPosition.y + 20), duration: 0.4)
        let shrink = SKAction.scale(to: 0.3, duration: 0.4)

        money.run(SKAction.sequence([
            SKAction.group([flyTo, shrink]),
            SKAction.run { [weak self] in
                self?.hudNode.addDollars(payment)
            },
            SKAction.removeFromParent()
        ]))

        seatItems[seatIndex]?.moneySprite = nil
        seatItems[seatIndex]?.moneyPayment = 0

        if isSeatClear(seatIndex) {
            trySeatDoorCustomer()
            if canSpawnMore {
                spawnCustomer()
            }
        }
        checkGameEnd()
    }

    private func placeDirtyPlateOnBench(seatIndex: Int) {
        guard seatIndex < seatPositions.count else { return }
        let seatPos = seatPositions[seatIndex]

        let texture = SKTexture(imageNamed: "dirty_plate")
        let plate = SKSpriteNode(texture: texture)
        plate.size = CGSize(width: 50, height: 50)
        plate.position = CGPoint(x: benchLeftEdge + benchWidth / 2, y: seatPos.y - 25)
        plate.zPosition = 2
        plate.name = "benchPlate_\(seatIndex)"
        gameLayer.addChild(plate)

        seatItems[seatIndex, default: SeatItem()].plateSprite = plate
    }

    private func collectPlate(at seatIndex: Int) {
        guard let plate = seatItems[seatIndex]?.plateSprite else { return }

        // Animate to sink
        let sinkPos = CGPoint(x: sinkCentreX, y: sinkY)
        plate.run(SKAction.sequence([
            SKAction.group([
                SKAction.move(to: sinkPos, duration: 0.3),
                SKAction.scale(to: 0.5, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        addDirtyDish()
        seatItems[seatIndex]?.plateSprite = nil

        if isSeatClear(seatIndex) {
            trySeatDoorCustomer()
            if canSpawnMore {
                spawnCustomer()
            }
        }
        checkGameEnd()
    }

    private func findPlateTap(in tappedNodes: [SKNode]) -> Int? {
        for node in tappedNodes {
            if let name = node.name, name.starts(with: "benchPlate_") {
                return Int(name.replacingOccurrences(of: "benchPlate_", with: ""))
            }
            if let parentName = node.parent?.name, parentName.starts(with: "benchPlate_") {
                return Int(parentName.replacingOccurrences(of: "benchPlate_", with: ""))
            }
        }
        return nil
    }

    private func findMoneyTap(in tappedNodes: [SKNode]) -> Int? {
        for node in tappedNodes {
            if let name = node.name, name.starts(with: "benchMoney_") {
                let indexStr = name.replacingOccurrences(of: "benchMoney_", with: "")
                return Int(indexStr)
            }
            if let parentName = node.parent?.name, parentName.starts(with: "benchMoney_") {
                let indexStr = parentName.replacingOccurrences(of: "benchMoney_", with: "")
                return Int(indexStr)
            }
        }
        return nil
    }

    // MARK: - Dirty dish stack

    private func addDirtyDish() {
        dirtyDishCount += 1
        let texture = SKTexture(imageNamed: "dirty_plate")
        let dish = SKSpriteNode(texture: texture)
        dish.size = CGSize(width: 55, height: 55)
        let stackOffset: CGFloat = 6
        dish.position = CGPoint(x: sinkCentreX + 15, y: sinkY + CGFloat(dirtyDishCount - 1) * stackOffset)
        dish.zPosition = CGFloat(dirtyDishCount) + 1
        gameLayer.addChild(dish)
        dirtyDishSprites.append(dish)
    }

    // MARK: - Pause menu

    private var pauseOverlay: SKNode?

    private func pauseGame() {
        guard pauseOverlay == nil else { return }
        gameLayer.isPaused = true

        let container = SKNode()
        container.zPosition = 200

        // Dimmed background
        let bg = SKShapeNode(rectOf: size)
        bg.fillColor = UIColor(white: 0, alpha: 0.5)
        bg.strokeColor = .clear
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(bg)

        // Card
        let card = SKShapeNode(rectOf: CGSize(width: 300, height: 280), cornerRadius: 20)
        card.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.98)
        card.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        card.lineWidth = 3
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(card)

        // Title
        let title = SKLabelNode(text: "Paused")
        title.fontSize = 28
        title.fontName = "AvenirNext-Bold"
        title.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 65)
        container.addChild(title)

        // Resume button
        let resumeBtn = SKShapeNode(rectOf: CGSize(width: 220, height: 48), cornerRadius: 14)
        resumeBtn.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)
        resumeBtn.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        resumeBtn.lineWidth = 2.5
        resumeBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 + 10)
        resumeBtn.name = "resumeButton"
        container.addChild(resumeBtn)

        let resumeLabel = SKLabelNode(text: "Resume Game")
        resumeLabel.fontSize = 18
        resumeLabel.fontName = "AvenirNext-Bold"
        resumeLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        resumeLabel.verticalAlignmentMode = .center
        resumeLabel.name = "resumeButton"
        resumeBtn.addChild(resumeLabel)

        // Restart button
        let restartBtn = SKShapeNode(rectOf: CGSize(width: 220, height: 48), cornerRadius: 14)
        restartBtn.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)
        restartBtn.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        restartBtn.lineWidth = 2.5
        restartBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        restartBtn.name = "restartButton"
        container.addChild(restartBtn)

        let restartLabel = SKLabelNode(text: "Restart Level")
        restartLabel.fontSize = 18
        restartLabel.fontName = "AvenirNext-Bold"
        restartLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        restartLabel.verticalAlignmentMode = .center
        restartLabel.name = "restartButton"
        restartBtn.addChild(restartLabel)

        // Home button
        let homeBtn = SKShapeNode(rectOf: CGSize(width: 220, height: 48), cornerRadius: 14)
        homeBtn.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)
        homeBtn.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        homeBtn.lineWidth = 2.5
        homeBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 110)
        homeBtn.name = "pauseHomeButton"
        container.addChild(homeBtn)

        let homeLabel = SKLabelNode(text: "Home")
        homeLabel.fontSize = 18
        homeLabel.fontName = "AvenirNext-Bold"
        homeLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        homeLabel.verticalAlignmentMode = .center
        homeLabel.name = "pauseHomeButton"
        homeBtn.addChild(homeLabel)

        addChild(container)
        pauseOverlay = container
    }

    private func resumeGame() {
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        gameLayer.isPaused = false
    }
}

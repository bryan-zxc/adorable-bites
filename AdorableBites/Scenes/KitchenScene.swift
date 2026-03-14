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
    }

    private var gamePhase: GamePhase = .addingIngredients

    // MARK: - Ingredients

    static let flour = Ingredient(name: "flour", colour: .systemYellow, imageName: "flour")
    static let egg = Ingredient(name: "egg", colour: .systemOrange, imageName: "egg")
    static let milk = Ingredient(name: "milk", colour: .systemCyan, imageName: "milk")
    static let butter = Ingredient(name: "butter", colour: .systemYellow, imageName: "butter")
    static let chocolate = Ingredient(name: "chocolate", colour: .brown, imageName: "chocolate")

    static let allIngredients = [milk, egg, flour, butter, chocolate]

    // MARK: - Recipes

    static let pancakeRecipe = Recipe(
        name: "Pancakes",
        imageName: "pancakes",
        requiredIngredients: [flour, egg, milk],
        basePoints: 1
    )

    static let allRecipes = [pancakeRecipe]

    // MARK: - Customer pool

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
    private var mixerNode: MixerNode!
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

    // Dish sprites on bench (keyed by customer node)
    private var benchDishSprites: [ObjectIdentifier: SKSpriteNode] = [:]

    // Money on bench — keyed by seat index, value is (sprite, payment amount)
    private var benchMoneySprites: [Int: (sprite: SKSpriteNode, payment: Int)] = [:]
    private var blockedSeats: Set<Int> = []
    private let totalPlates = 3  // TODO: change back to 5 after testing
    private var platesRemaining = 3
    private var customersServed = 0
    private var totalCustomersSpawned = 0

    // MARK: - Bench and seating

    private let seatCount = 5
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
        setupScene()
        spawnCustomer()
    }

    private func setupScene() {
        gameLayer = SKNode()
        gameLayer.name = "gameLayer"
        addChild(gameLayer)

        setupScoreNode()
        setupBench()
        setupIngredientShelf()
        setupKitchenCounter()
        setupMixer()
        setupStoveTop()
        setupPlateStack()
        setupSink()
        setupBinButtons()
        setupRecipePanel()
    }

    // MARK: - Layout

    private func setupScoreNode() {
        let seatLeftEdge = seatX - 28
        let scoreWidth = benchRightEdge - seatLeftEdge
        hudNode = HudNode(width: scoreWidth)
        hudNode.position = CGPoint(x: (seatLeftEdge + benchRightEdge) / 2, y: size.height - 50)
        hudNode.zPosition = 2
        gameLayer.addChild(hudNode)
    }

    private func setupBench() {
        let benchTopY = size.height - 70
        let benchBottomY: CGFloat = 30
        let benchHeight = benchTopY - benchBottomY
        let benchCentreY = (benchTopY + benchBottomY) / 2

        let segmentHeight = benchHeight / CGFloat(seatCount)

        for i in 0..<seatCount {
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
        let ingredientCount = CGFloat(KitchenScene.allIngredients.count)

        let pantryPadding: CGFloat = 15
        let pantryWidth = recipePanelLeftEdge - benchRightEdge - pantryPadding * 2
        let pantryHeight: CGFloat = 180
        let pantryCentreX = (benchRightEdge + recipePanelLeftEdge) / 2
        let shelfY = size.height - 100

        let pantryTexture = SKTexture(imageNamed: "pantry_cupboard")
        let pantry = SKSpriteNode(texture: pantryTexture)
        pantry.size = CGSize(width: pantryWidth, height: pantryHeight)
        pantry.position = CGPoint(x: pantryCentreX, y: shelfY)
        pantry.zPosition = -1
        gameLayer.addChild(pantry)

        let compartmentWidth = pantryWidth / ingredientCount
        let pantryLeftEdge = benchRightEdge + pantryPadding
        let pantryInset: CGFloat = 22
        let startX = pantryLeftEdge + pantryInset + (pantryWidth - pantryInset * 2) / ingredientCount / 2

        let ingredientY = shelfY + pantryHeight * 0.125
        let labelOffsetY = -pantryHeight * 0.5
        let spriteSize = min(compartmentWidth, pantryHeight * 0.75) * 0.7
        let insetCompartmentWidth = (pantryWidth - pantryInset * 2) / ingredientCount
        for (index, ingredient) in KitchenScene.allIngredients.enumerated() {
            let ingredientX = startX + CGFloat(index) * insetCompartmentWidth
            let tagInset = pantryInset * 0.5
            let tagCompartmentWidth = (pantryWidth - tagInset * 2) / ingredientCount
            let tagX = pantryLeftEdge + tagInset + tagCompartmentWidth * (CGFloat(index) + 0.5)
            let labelOffsetX = tagX - ingredientX
            let node = IngredientNode(ingredient: ingredient, spriteSize: spriteSize, labelOffsetX: labelOffsetX, labelOffsetY: labelOffsetY)
            node.position = CGPoint(x: ingredientX, y: ingredientY)
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
        mixerNode = MixerNode(size: CGSize(width: 150, height: 150))
        mixerNode.position = CGPoint(x: mixerX, y: workstationY + 10)
        mixerNode.zPosition = 1
        gameLayer.addChild(mixerNode)
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
        let panelHeight = size.height - 60
        recipePanel = RecipePanelNode(recipes: KitchenScene.allRecipes, width: 200, height: panelHeight)
        recipePanel.position = CGPoint(x: recipePanelCentreX, y: size.height / 2)
        gameLayer.addChild(recipePanel)
    }

    // MARK: - Customer seating

    private func seatPositionForSlot(_ index: Int) -> CGPoint {
        guard index < seatPositions.count else {
            let lastSeat = seatPositions.last ?? CGPoint(x: seatX, y: 100)
            return CGPoint(x: lastSeat.x, y: lastSeat.y - CGFloat(index - seatPositions.count + 1) * 100)
        }
        return seatPositions[index]
    }

    private var canSpawnMore: Bool { totalCustomersSpawned < seatCount }
    private func firstAvailableSeatIndex() -> Int? {
        // Find the first seat not occupied by a customer and not blocked by money
        let occupiedSeats = Set(customerNodes.map { customerSeatIndices[ObjectIdentifier($0)] ?? -1 })
        for i in 0..<seatCount {
            if !occupiedSeats.contains(i) && !blockedSeats.contains(i) {
                return i
            }
        }
        return nil
    }

    private func spawnCustomer() {
        guard canSpawnMore else { return }
        guard let availableSeat = firstAvailableSeatIndex() else { return }
        totalCustomersSpawned += 1
        let customer = KitchenScene.customerPool.randomElement()!
        let node = CustomerNode(customer: customer)
        let slotIndex = availableSeat
        let seatPos = seatPositionForSlot(slotIndex)
        node.position = seatPos
        node.zPosition = 1
        gameLayer.addChild(node)
        node.animateEntrance()
        customerSeatIndices[ObjectIdentifier(node)] = slotIndex

        // Start customer timer
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
        customersServed += 1

        node.showRejected()

        run(SKAction.wait(forDuration: 1.0)) { [weak self] in
            guard let self else { return }
            guard let idx = self.customerNodes.firstIndex(where: { $0 === node }) else { return }

            node.animateExit {
                node.removeFromParent()
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

        // Pause menu interactions (always active)
        if pauseOverlay != nil {
            for node in tappedNodes {
                if node.name == "resumeButton" {
                    resumeGame()
                    return
                }
                if node.name == "restartButton" {
                    resumeGame()
                    restartGame()
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

        // 0b. Next button (game end screen)
        for node in tappedNodes {
            if node.name == "nextButton" {
                restartGame()
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
                if findMixerNode(in: node) && mixerNode.canReceiveIngredient {
                    if mixerNode.currentIngredients.contains(picked.ingredient) {
                        // Duplicate — just return to shelf
                        cancelPickup()
                    } else {
                        placeIngredientInMixer(picked)
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

        // 2. Tap stove/pan to serve or start cooking
        for node in tappedNodes {
            if findStoveNode(in: node) {
                if gamePhase == .readyToServe || gamePhase == .burnt {
                    serveOrder()
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
                if mixerNode.canMix {
                    startMixing()
                    return
                }
                if mixerNode.canPour {
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
        guard customerData.first?.order != nil else { return }

        // Show quiz
        pendingIngredientNode = ingredientNode
        let quiz = QuizNode(sceneSize: size)
        quiz.position = CGPoint(x: size.width / 2, y: size.height / 2)
        quiz.configure(
            onCorrect: { [weak self] in
                guard let self, let node = self.pendingIngredientNode else { return }
                self.hudNode.addSnowflakes(1)
                self.enterPickupMode(node)
                self.activeQuiz = nil
                self.pendingIngredientNode = nil
            },
            onWrong: { [weak self] in
                self?.hudNode.removeSnowflakes(1)
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

        // Show drop targets
        mixerNode.showDropTarget(active: mixerNode.canReceiveIngredient)
    }

    private func cancelPickup() {
        pickedUpIngredient?.animateReturn()
        pickedUpIngredient = nil
        mixerNode.hideDropTarget()
    }

    private func placeIngredientInMixer(_ ingredientNode: IngredientNode) {
        ingredientNode.animateReturn()
        pickedUpIngredient = nil
        mixerNode.hideDropTarget()

        mixerNode.addIngredient(ingredientNode.ingredient)
        showMixerBin()

        if mixerNode.canMix {
            pulseMixer()
        }
    }

    // MARK: - Pan cooking

    private func startPanCooking() {
        gamePhase = .cooking
        stoveTop.startCooking()
        showPanBin()
    }

    // MARK: - Mixing

    private func startMixing() {
        gamePhase = .mixing
        mixerNode.removeAction(forKey: "readyPulse")
        mixerNode.setScale(1.0)

        mixerNode.startMixing { [weak self] in
            self?.onMixingComplete()
        }
    }

    private func onMixingComplete() {
        gamePhase = .batterReady

        // Pulse the mixer to indicate "tap me"
        mixerNode.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])), withKey: "readyPulse")
    }

    // MARK: - Pour batter to pan

    private func pourBatterToPan() {
        mixerNode.removeAction(forKey: "readyPulse")
        mixerNode.setScale(1.0)

        let ingredients = mixerNode.pourBatter()
        guard !ingredients.isEmpty else { return }

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

    private func serveOrder() {
        guard let result = stoveTop.tapToServe() else { return }

        stoveTop.removeAction(forKey: "readyPulse")
        stoveTop.setScale(1.0)
        hidePanBin()

        guard let activeOrder = customerData.first?.order else { return }
        let requiredSet = Set(activeOrder.requiredIngredients)
        let placedSet = Set(result.ingredients)
        let isCorrectOrder = requiredSet == placedSet

        // Use a plate
        platesRemaining -= 1
        customersServed += 1
        updatePlateStack()

        if isCorrectOrder && !result.isBurnt {
            let bonus = customerNodes.first?.isInBonusWindow == true ? 1 : 0
            customerNodes.first?.showCompleted()

            // Store payment amount for when money is collected later
            let payment = activeOrder.basePoints + bonus

            // Place dish on bench in front of customer
            if let customerNode = customerNodes.first {
                placeDishOnBench(for: customerNode, imageName: activeOrder.imageName)
            }

            // Customer stays to eat — when done, place money on bench
            if let customerNode = customerNodes.first {
                let seatIdx = customerSeatIndices[ObjectIdentifier(customerNode)] ?? 0
                customerNode.onFinishedEating = { [weak self] in
                    self?.handleCustomerFinishedEating(payment: payment, seatIndex: seatIdx)
                }
            }
            customerNodes.first?.startEating(duration: 5.0)
        } else {
            customerNodes.first?.showRejected()
            hudNode.removeSnowflakes(activeOrder.basePoints)

            // Wrong/burnt — customer leaves after brief delay
            run(SKAction.wait(forDuration: 1.5)) { [weak self] in
                self?.removeFirstCustomerAndContinue()
            }
        }

        // Reset stove only — mixer may already have ingredients for the next order
        stoveTop.reset()
        hideMixerBin()
        hidePanBin()

        gamePhase = .addingIngredients
    }

    private func handleCustomerFinishedEating(payment: Int = 0, seatIndex: Int = 0) {
        // Remove dish from bench and add dirty dish to sink
        if let customerNode = customerNodes.first {
            removeDishFromBench(for: customerNode)
            addDirtyDish()

            // Place money on bench at the seat where customer was
            if payment > 0 && seatIndex < seatPositions.count {
                placeMoneyAtSeat(seatIndex: seatIndex, payment: payment)
            }
        }
        removeFirstCustomerAndContinue()
    }

    private func removeFirstCustomerAndContinue() {
        guard let node = customerNodes.first else {
            checkGameEnd()
            return
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
        let hasMoney = !benchMoneySprites.isEmpty
        let hasCustomers = !customerNodes.isEmpty

        // Condition 1: no customers and no money on bench → all done
        if !hasCustomers && !hasMoney {
            handleGameOver()
            return
        }

        // Condition 2: no plates, no eating customers, no money, but someone waiting
        let hasEatingCustomers = customerNodes.contains { $0.isEating }
        if platesRemaining <= 0 && !hasEatingCustomers && !hasMoney && hasCustomers {
            handleGameOver()
            return
        }
    }

    // MARK: - Bin handling

    private func handleMixerBin() {
        guard !mixerNode.isEmpty else { return }
        mixerNode.removeAction(forKey: "readyPulse")
        mixerNode.setScale(1.0)
        mixerNode.reset()
        hideMixerBin()

        gamePhase = .addingIngredients
    }

    private func handlePanBin() {
        guard stoveTop.hasContents else { return }
        stoveTop.removeAction(forKey: "readyPulse")
        stoveTop.setScale(1.0)
        stoveTop.reset()
        mixerNode.reset()
        hidePanBin()
        hideMixerBin()

        gamePhase = .addingIngredients
    }

    // MARK: - Reset

    private func resetForNextOrder() {
        stoveTop.reset()
        mixerNode.reset()
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

    private func handleGameOver() {
        // Total customers is seatCount. We served customersServed of them.
        let unservedCount = seatCount - customersServed
        if unservedCount > 0 {
            showUnservedPopup(count: unservedCount) { [weak self] in
                self?.showGameEndScreen()
            }
        } else {
            showGameEndScreen()
        }
    }

    private func showUnservedPopup(count: Int, completion: @escaping () -> Void) {
        // Deduct snowflakes for unserved customers
        hudNode.removeSnowflakes(count)

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

        let title = SKLabelNode(text: "No plates left!")
        title.fontSize = 26
        title.fontName = "AvenirNext-Bold"
        title.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
        title.zPosition = 87
        addChild(title)

        let detail = SKLabelNode(text: "\(count) customer\(count == 1 ? "" : "s") left hungry  −\(count) snowflakes")
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
        let finalDollars = hudNode.dollars
        let finalSnowflakes = hudNode.snowflakes
        let messageText = finalDollars > 0 ? "Congratulations!" : "Better luck next time!"

        // Dim overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = UIColor(white: 0, alpha: 0.6)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 90
        addChild(overlay)

        // Card
        let card = SKShapeNode(rectOf: CGSize(width: 450, height: 420), cornerRadius: 24)
        card.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.98)
        card.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        card.lineWidth = 3
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        card.zPosition = 91
        addChild(card)

        // Dora
        let doraTexture = SKTexture(imageNamed: "dora")
        let dora = SKSpriteNode(texture: doraTexture)
        let doraHeight: CGFloat = 180
        let doraScale = doraHeight / doraTexture.size().height
        dora.size = CGSize(width: doraTexture.size().width * doraScale, height: doraHeight)
        dora.position = CGPoint(x: size.width / 2, y: size.height / 2 + 70)
        dora.zPosition = 92
        addChild(dora)

        // Message
        let message = SKLabelNode(text: messageText)
        message.fontSize = 30
        message.fontName = "AvenirNext-Bold"
        message.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        message.verticalAlignmentMode = .center
        message.position = CGPoint(x: size.width / 2, y: size.height / 2 - 45)
        message.zPosition = 92
        addChild(message)

        // Money earned
        let moneyIcon = SKSpriteNode(texture: SKTexture(imageNamed: "money"))
        moneyIcon.size = CGSize(width: 24, height: 24)
        moneyIcon.position = CGPoint(x: size.width / 2 - 50, y: size.height / 2 - 85)
        moneyIcon.zPosition = 92
        addChild(moneyIcon)

        let moneyResult = SKLabelNode(text: "$\(finalDollars)")
        moneyResult.fontSize = 22
        moneyResult.fontName = "AvenirNext-Bold"
        moneyResult.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        moneyResult.horizontalAlignmentMode = .left
        moneyResult.verticalAlignmentMode = .center
        moneyResult.position = CGPoint(x: size.width / 2 - 30, y: size.height / 2 - 85)
        moneyResult.zPosition = 92
        addChild(moneyResult)

        // Snowflakes earned
        let snowIcon = SKSpriteNode(texture: SKTexture(imageNamed: "snowflake"))
        snowIcon.size = CGSize(width: 24, height: 24)
        snowIcon.position = CGPoint(x: size.width / 2 - 50, y: size.height / 2 - 115)
        snowIcon.zPosition = 92
        addChild(snowIcon)

        let snowResult = SKLabelNode(text: "\(finalSnowflakes)")
        snowResult.fontSize = 22
        snowResult.fontName = "AvenirNext-Bold"
        snowResult.fontColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
        snowResult.horizontalAlignmentMode = .left
        snowResult.verticalAlignmentMode = .center
        snowResult.position = CGPoint(x: size.width / 2 - 30, y: size.height / 2 - 115)
        snowResult.zPosition = 92
        addChild(snowResult)

        // Play Again button
        let nextBtn = SKShapeNode(rectOf: CGSize(width: 160, height: 50), cornerRadius: 14)
        nextBtn.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)
        nextBtn.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        nextBtn.lineWidth = 2.5
        nextBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 155)
        nextBtn.name = "nextButton"
        nextBtn.zPosition = 92
        addChild(nextBtn)

        let nextLabel = SKLabelNode(text: "Play Again!")
        nextLabel.fontSize = 20
        nextLabel.fontName = "AvenirNext-Bold"
        nextLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        nextLabel.verticalAlignmentMode = .center
        nextLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 155)
        nextLabel.name = "nextButton"
        nextLabel.zPosition = 93
        addChild(nextLabel)
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
        benchMoneySprites.removeAll()
        blockedSeats.removeAll()
        platesRemaining = totalPlates
        customersServed = 0
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
        mixerNode.run(SKAction.repeatForever(SKAction.sequence([
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
        dish.size = CGSize(width: 90, height: 90)
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

        benchMoneySprites[seatIndex] = (sprite: money, payment: payment)
        blockedSeats.insert(seatIndex)
    }

    private func collectMoney(at seatIndex: Int) {
        guard let moneyInfo = benchMoneySprites[seatIndex] else { return }

        let sprite = moneyInfo.sprite
        let payment = moneyInfo.payment

        // Fly money to HUD position
        let hudPosition = hudNode.position
        let flyTo = SKAction.move(to: CGPoint(x: hudPosition.x + 30, y: hudPosition.y + 20), duration: 0.4)
        let shrink = SKAction.scale(to: 0.3, duration: 0.4)

        sprite.run(SKAction.sequence([
            SKAction.group([flyTo, shrink]),
            SKAction.run { [weak self] in
                self?.hudNode.addDollars(payment)
            },
            SKAction.removeFromParent()
        ]))

        benchMoneySprites.removeValue(forKey: seatIndex)
        blockedSeats.remove(seatIndex)

        checkGameEnd()
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
        let card = SKShapeNode(rectOf: CGSize(width: 300, height: 220), cornerRadius: 20)
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

        addChild(container)
        pauseOverlay = container
    }

    private func resumeGame() {
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        gameLayer.isPaused = false
    }
}

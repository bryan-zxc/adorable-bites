import SpriteKit

class KitchenScene: SKScene {

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
        requiredIngredients: [flour, egg, milk]
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

    // MARK: - Nodes

    private var ingredientShelfNodes: [IngredientNode] = []
    private var stoveTop: StoveTopNode!
    private var scoreNode: ScoreNode!
    private var serveButton: SKShapeNode!
    private var serveLabel: SKLabelNode!
    private var recipePanel: RecipePanelNode!

    // MARK: - Bench and seating

    private let seatCount = 5
    private var seatPositions: [CGPoint] = []
    private var customerNodes: [CustomerNode] = []
    private var customerData: [Customer] = []

    // MARK: - Layout zones

    private let seatX: CGFloat = 55
    private let benchWidth: CGFloat = 140
    private var benchLeftEdge: CGFloat { seatX + 38 }
    private var benchRightEdge: CGFloat { benchLeftEdge + benchWidth }
    private var recipePanelCentreX: CGFloat { size.width - 110 }
    private var recipePanelLeftEdge: CGFloat { recipePanelCentreX - 100 }
    private var kitchenCentreX: CGFloat { (benchRightEdge + recipePanelLeftEdge) / 2 }

    // MARK: - Scene lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.88, alpha: 1.0)
        setupScene()
        spawnCustomer()
    }

    private func setupScene() {
        setupScoreNode()
        setupBench()
        setupIngredientShelf()
        setupStoveTop()
        setupServeButton()
        setupRecipePanel()
    }

    // MARK: - Layout

    private func setupScoreNode() {
        let seatLeftEdge = seatX - 28
        let scoreWidth = benchRightEdge - seatLeftEdge
        scoreNode = ScoreNode(width: scoreWidth)
        scoreNode.position = CGPoint(x: (seatLeftEdge + benchRightEdge) / 2, y: size.height - 35)
        scoreNode.zPosition = 2
        addChild(scoreNode)
    }

    private func setupBench() {
        let benchTopY = size.height - 70
        let benchBottomY: CGFloat = 30
        let benchHeight = benchTopY - benchBottomY
        let benchCentreY = (benchTopY + benchBottomY) / 2

        // Stools: divide bench into 6 equal portions (half-portion margin each end, seats in middle 5)
        let portionHeight = benchHeight / CGFloat(seatCount + 1)

        for i in 0..<seatCount {
            let seatY = benchTopY - portionHeight * (CGFloat(i) + 1.0)
            let seatPos = CGPoint(x: seatX, y: seatY)
            seatPositions.append(seatPos)

            let stoolTexture = SKTexture(imageNamed: "bar_stool")
            let stool = SKSpriteNode(texture: stoolTexture)
            stool.size = CGSize(width: 55, height: 55)
            stool.position = seatPos
            stool.zPosition = 0
            addChild(stool)
        }

        // Bench counter — to the right of the stools (kitchen-facing side)
        let benchTexture = SKTexture(imageNamed: "bench_counter")
        let bench = SKSpriteNode(texture: benchTexture)
        bench.size = CGSize(width: benchHeight, height: self.benchWidth)
        bench.zRotation = .pi / 2
        bench.position = CGPoint(x: benchLeftEdge + self.benchWidth / 2, y: benchCentreY)
        bench.zPosition = -1
        addChild(bench)
    }

    private func setupIngredientShelf() {
        let ingredientCount = CGFloat(KitchenScene.allIngredients.count)

        // Pantry with padding on both sides so it doesn't touch bench or recipe panel
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
        addChild(pantry)

        // Place ingredients centred in each compartment
        let compartmentWidth = pantryWidth / ingredientCount
        let pantryLeftEdge = benchRightEdge + pantryPadding
        let pantryInset: CGFloat = 22
        let startX = pantryLeftEdge + pantryInset + (pantryWidth - pantryInset * 2) / ingredientCount / 2

        // Compartment openings occupy the upper ~75%, name tags the lower ~25%
        let ingredientY = shelfY + pantryHeight * 0.125
        let labelOffsetY = -pantryHeight * 0.5
        let spriteSize = min(compartmentWidth, pantryHeight * 0.75) * 0.7
        let insetCompartmentWidth = (pantryWidth - pantryInset * 2) / ingredientCount
        for (index, ingredient) in KitchenScene.allIngredients.enumerated() {
            // Label X offset: shift label from inset position to full-width tag position
            let ingredientX = startX + CGFloat(index) * insetCompartmentWidth
            let tagInset = pantryInset * 0.5
            let tagCompartmentWidth = (pantryWidth - tagInset * 2) / ingredientCount
            let tagX = pantryLeftEdge + tagInset + tagCompartmentWidth * (CGFloat(index) + 0.5)
            let labelOffsetX = tagX - ingredientX
            let node = IngredientNode(ingredient: ingredient, spriteSize: spriteSize, labelOffsetX: labelOffsetX, labelOffsetY: labelOffsetY)
            node.position = CGPoint(x: ingredientX, y: ingredientY)
            node.zPosition = 1
            addChild(node)
            ingredientShelfNodes.append(node)
        }
    }

    private func setupStoveTop() {
        stoveTop = StoveTopNode(size: CGSize(width: 200, height: 200))
        stoveTop.position = CGPoint(x: kitchenCentreX, y: size.height / 2 - 100)
        addChild(stoveTop)
    }

    private func setupServeButton() {
        serveButton = SKShapeNode(rectOf: CGSize(width: 160, height: 50), cornerRadius: 25)
        serveButton.fillColor = UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)
        serveButton.strokeColor = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
        serveButton.lineWidth = 3
        serveButton.position = CGPoint(x: kitchenCentreX, y: 50)
        serveButton.name = "serveButton"
        serveButton.alpha = 0
        serveButton.isHidden = true

        serveLabel = SKLabelNode(text: "SERVE!")
        serveLabel.fontSize = 20
        serveLabel.fontName = "AvenirNext-Bold"
        serveLabel.fontColor = .white
        serveLabel.verticalAlignmentMode = .center
        serveButton.addChild(serveLabel)

        addChild(serveButton)
    }

    private func setupRecipePanel() {
        let panelHeight = size.height - 60
        recipePanel = RecipePanelNode(recipes: KitchenScene.allRecipes, width: 200, height: panelHeight)
        recipePanel.position = CGPoint(x: recipePanelCentreX, y: size.height / 2)
        addChild(recipePanel)
    }

    // MARK: - Customer seating

    private func seatPositionForSlot(_ index: Int) -> CGPoint {
        guard index < seatPositions.count else {
            // Overflow — stack below the last seat
            let lastSeat = seatPositions.last ?? CGPoint(x: seatX, y: 100)
            return CGPoint(x: lastSeat.x, y: lastSeat.y - CGFloat(index - seatPositions.count + 1) * 100)
        }
        return seatPositions[index]
    }

    private func spawnCustomer() {
        let customer = KitchenScene.customerPool.randomElement()!
        let node = CustomerNode(customer: customer)
        let slotIndex = customerNodes.count
        let seatPos = seatPositionForSlot(slotIndex)
        node.position = seatPos
        node.zPosition = 1
        addChild(node)
        node.animateEntrance()

        customerNodes.append(node)
        customerData.append(customer)
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // Check serve button
        if stoveTop.isCooked {
            for node in tappedNodes {
                if node.name == "serveButton" || node.parent?.name == "serveButton" {
                    serveOrder()
                    return
                }
            }
        }

        // Check recipe panel
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

        // Check ingredient taps
        for node in tappedNodes {
            if let ingredientNode = findIngredientNode(in: node) {
                handleIngredientTap(ingredientNode)
                return
            }
        }
    }

    private func findIngredientNode(in node: SKNode) -> IngredientNode? {
        if let ingredientNode = node as? IngredientNode {
            return ingredientNode
        }
        if let parent = node.parent as? IngredientNode {
            return parent
        }
        return nil
    }

    private func handleIngredientTap(_ ingredientNode: IngredientNode) {
        guard !stoveTop.isCooking && !stoveTop.isCooked else { return }
        guard let activeOrder = customerData.first?.order else { return }

        let ingredient = ingredientNode.ingredient
        if stoveTop.currentIngredients.contains(ingredient) { return }

        ingredientNode.animatePop()
        ingredientNode.animateDimmed()
        stoveTop.addIngredient(ingredient)
        checkRecipeCompletion(for: activeOrder)
    }

    // MARK: - Cooking logic

    private func checkRecipeCompletion(for recipe: Recipe) {
        let required = Set(recipe.requiredIngredients)
        let placed = Set(stoveTop.currentIngredients)

        if required.isSubset(of: placed) {
            stoveTop.startCooking { [weak self] in
                self?.showServeButton()
            }
        }
    }

    private func showServeButton() {
        serveButton.isHidden = false
        serveButton.alpha = 0
        serveButton.run(SKAction.fadeIn(withDuration: 0.3))
        serveButton.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])), withKey: "pulse")
    }

    private func serveOrder() {
        serveButton.removeAction(forKey: "pulse")
        serveButton.run(SKAction.fadeOut(withDuration: 0.2)) { [weak self] in
            self?.serveButton.isHidden = true
        }

        customerNodes.first?.showCompleted()
        scoreNode.increment()

        run(SKAction.wait(forDuration: 1.5)) { [weak self] in
            self?.resetForNextOrder()
        }
    }

    private func resetForNextOrder() {
        stoveTop.reset()

        for node in ingredientShelfNodes {
            node.animateReset()
        }

        guard let servedNode = customerNodes.first else { return }

        servedNode.animateExit { [weak self] in
            guard let self = self else { return }
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
}

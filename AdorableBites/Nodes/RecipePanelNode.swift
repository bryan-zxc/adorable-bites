import SpriteKit

class RecipePanelNode: SKNode {

    private let panelBackground: SKShapeNode
    private var recipeRows: [RecipeRowNode] = []
    private let panelWidth: CGFloat
    private let panelHeight: CGFloat

    init(recipes: [Recipe], width: CGFloat = 200, height: CGFloat = 500) {
        self.panelWidth = width
        self.panelHeight = height

        panelBackground = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 16)
        panelBackground.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.95)
        panelBackground.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        panelBackground.lineWidth = 2

        super.init()

        name = "recipePanel"
        addChild(panelBackground)

        // Header
        let headerLabel = SKLabelNode(text: "Recipes")
        headerLabel.fontSize = 18
        headerLabel.fontName = "AvenirNext-Bold"
        headerLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        headerLabel.verticalAlignmentMode = .center
        headerLabel.position = CGPoint(x: 0, y: height / 2 - 25)
        addChild(headerLabel)

        // Divider under header
        let divider = SKShapeNode(rectOf: CGSize(width: width - 30, height: 1.5))
        divider.fillColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: 0, y: height / 2 - 42)
        addChild(divider)

        // Recipe rows
        for (index, recipe) in recipes.enumerated() {
            let row = RecipeRowNode(recipe: recipe, width: width - 24)
            let yPos = height / 2 - 70 - CGFloat(index) * 60
            row.position = CGPoint(x: 0, y: yPos)
            row.name = "recipeRow_\(index)"
            addChild(row)
            recipeRows.append(row)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handleTap(at point: CGPoint) {
        let localPoint = convert(point, from: parent!)
        for row in recipeRows {
            let rowPoint = row.convert(localPoint, from: self)
            if row.hitTest(rowPoint) {
                row.toggle()
                return
            }
        }
    }
}

class RecipeRowNode: SKNode {

    private let recipe: Recipe
    private let rowBackground: SKShapeNode
    private let dishSprite: SKSpriteNode
    private let nameLabel: SKLabelNode
    private let arrowLabel: SKLabelNode
    private var ingredientNodes: [SKNode] = []
    private let rowWidth: CGFloat
    private var isExpanded = false

    init(recipe: Recipe, width: CGFloat) {
        self.recipe = recipe
        self.rowWidth = width

        // Recipe header row
        rowBackground = SKShapeNode(rectOf: CGSize(width: width, height: 50), cornerRadius: 12)
        rowBackground.fillColor = UIColor(red: 0.92, green: 0.88, blue: 0.80, alpha: 1.0)
        rowBackground.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 0.5)
        rowBackground.lineWidth = 1

        let texture = SKTexture(imageNamed: recipe.imageName)
        dishSprite = SKSpriteNode(texture: texture)
        dishSprite.size = CGSize(width: 36, height: 36)
        dishSprite.position = CGPoint(x: -width / 2 + 28, y: 0)

        nameLabel = SKLabelNode(text: recipe.name)
        nameLabel.fontSize = 16
        nameLabel.fontName = "AvenirNext-DemiBold"
        nameLabel.fontColor = UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        nameLabel.verticalAlignmentMode = .center
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -width / 2 + 52, y: 0)

        arrowLabel = SKLabelNode(text: "▸")
        arrowLabel.fontSize = 18
        arrowLabel.fontName = "AvenirNext-Bold"
        arrowLabel.fontColor = UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0)
        arrowLabel.verticalAlignmentMode = .center
        arrowLabel.position = CGPoint(x: width / 2 - 18, y: 0)

        super.init()

        addChild(rowBackground)
        addChild(dishSprite)
        addChild(nameLabel)
        addChild(arrowLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func hitTest(_ point: CGPoint) -> Bool {
        return rowBackground.contains(point)
    }

    func toggle() {
        if isExpanded { collapse() } else { expand() }
    }

    private func expand() {
        isExpanded = true
        arrowLabel.text = "▾"

        for (i, ingredient) in recipe.requiredIngredients.enumerated() {
            let container = SKNode()
            let yOffset: CGFloat = -40 - CGFloat(i) * 44

            // Row background
            let bg = SKShapeNode(rectOf: CGSize(width: rowWidth - 16, height: 38), cornerRadius: 10)
            bg.fillColor = UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1.0)
            bg.strokeColor = .clear
            container.addChild(bg)

            // Ingredient image
            let texture = SKTexture(imageNamed: ingredient.imageName)
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: 28, height: 28)
            sprite.position = CGPoint(x: -rowWidth / 2 + 28, y: 0)
            container.addChild(sprite)

            // Ingredient name
            let label = SKLabelNode(text: ingredient.name)
            label.fontSize = 14
            label.fontName = "AvenirNext-Medium"
            label.fontColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: -rowWidth / 2 + 48, y: 0)
            container.addChild(label)

            container.position = CGPoint(x: 0, y: yOffset)
            container.setScale(0)
            container.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.06),
                SKAction.scale(to: 1.0, duration: 0.15)
            ]))

            addChild(container)
            ingredientNodes.append(container)
        }
    }

    private func collapse() {
        isExpanded = false
        arrowLabel.text = "▸"

        for node in ingredientNodes {
            node.run(SKAction.sequence([
                SKAction.scale(to: 0, duration: 0.1),
                SKAction.removeFromParent()
            ]))
        }
        ingredientNodes.removeAll()
    }
}

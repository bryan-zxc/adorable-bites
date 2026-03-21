import Foundation

struct GameProgress: Codable {
    var totalDollars: Int = 0
    var totalSnowflakes: Int = 0
    var unlockedLevels: Set<Int> = [1]
    var seenTutorials: Set<Int> = []
    var quizGrade: Int = 1  // 1-9, persistent setting
    var seenQuizGradeNudge: Bool = false

    private static let storageKey = "gameProgress"

    static func load() -> GameProgress {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let progress = try? JSONDecoder().decode(GameProgress.self, from: data) else {
            return GameProgress()
        }
        return progress
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: GameProgress.storageKey)
        }
    }

    mutating func unlockLevel(_ level: Int, cost: Int) -> Bool {
        guard totalSnowflakes >= cost else { return false }
        totalSnowflakes -= cost
        unlockedLevels.insert(level)
        save()
        return true
    }

    func isLevelUnlocked(_ level: Int) -> Bool {
        unlockedLevels.contains(level)
    }
}

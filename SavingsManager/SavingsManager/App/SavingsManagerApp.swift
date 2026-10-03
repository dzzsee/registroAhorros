import SwiftUI
import SwiftData

@main
struct SavingsManagerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SavingsCard.self, Transaction.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .onAppear {
            PersistenceService.shared.configure(with: sharedModelContainer)
        }
    }
}
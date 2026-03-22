import SwiftUI
import SwiftData

@main
struct ClaudeWatchApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([SessionRecord.self, DailyStats.self, UsageLimitsRecord.self])
        let config = ModelConfiguration(
            "ClaudeWatch",
            schema: schema,
            cloudKitDatabase: .none
        )
        container = try! ModelContainer(for: schema, configurations: [config])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}

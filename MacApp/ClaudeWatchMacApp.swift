import SwiftUI
import SwiftData

@main
struct ClaudeWatchMacApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([SessionRecord.self, DailyStats.self, UsageLimitsRecord.self])
        let config = ModelConfiguration(
            "ClaudeWatch",
            schema: schema,
            cloudKitDatabase: .none
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ClaudeWatch: Failed to create ModelContainer — \(error)")
        }
        DataSyncService.shared.modelContainer = container
        DataSyncService.shared.startWatching()
    }

    var body: some Scene {
        MenuBarExtra("ClaudeWatch", systemImage: "brain.head.profile") {
            MenuBarView()
                .modelContainer(container)
        }
        .menuBarExtraStyle(.window)
    }
}

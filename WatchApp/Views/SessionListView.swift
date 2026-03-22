import SwiftUI
import SwiftData

struct SessionListView: View {

    @Query(sort: \SessionRecord.startTime, order: .reverse)
    private var sessions: [SessionRecord]

    private var recent: [SessionRecord] { Array(sessions.prefix(20)) }

    var body: some View {
        NavigationStack {
            List(recent, id: \.sessionId) { session in
                NavigationLink(value: session) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(session.projectName.isEmpty ? "Unnamed" : session.projectName)
                                .font(.system(size: 13, weight: .semibold)).lineLimit(1)
                            Spacer()
                            if session.isActive {
                                Circle().fill(.green).frame(width: 6, height: 6)
                            }
                        }
                        HStack {
                            Text(session.startTime, style: .relative)
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                            Spacer()
                            Text(session.formattedCost)
                                .font(.system(size: 11, weight: .medium)).foregroundStyle(Color.claudeOrange)
                        }
                        Text("\(session.totalTokens.formatted()) tokens")
                            .font(.system(size: 10)).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.carousel)
            .navigationTitle("Sessions")
            .navigationDestination(for: SessionRecord.self) { session in
                SessionDetailView(session: session)
            }
            .overlay {
                if recent.isEmpty {
                    ContentUnavailableView("No Sessions", systemImage: "square.stack.3d.up.slash",
                        description: Text("Start coding to see sessions here."))
                }
            }
        }
    }
}

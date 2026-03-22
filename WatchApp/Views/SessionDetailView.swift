import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: SessionRecord

    private var totalTokens: Int { session.totalTokens }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Cost + duration
                HStack(alignment: .firstTextBaseline) {
                    Text(session.formattedCost)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.claudeOrange)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(session.formattedDuration).font(.system(size: 11, weight: .medium))
                        Text(session.startTime, style: .time).font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Token breakdown
                VStack(alignment: .leading, spacing: 5) {
                    Text("Tokens").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    TokenBar(label: "Input", value: session.inputTokens, total: totalTokens, color: .claudeOrange)
                    TokenBar(label: "Output", value: session.outputTokens, total: totalTokens, color: .blue)
                    TokenBar(label: "Cache wr", value: session.cacheCreationTokens, total: totalTokens, color: .purple)
                    TokenBar(label: "Cache rd", value: session.cacheReadTokens, total: totalTokens, color: .teal)
                }

                Divider()

                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    MetaRow(label: "Model", value: session.modelName)
                    MetaRow(label: "Messages", value: "\(session.messageCount)")
                    MetaRow(label: "Tools", value: "\(session.toolCallCount)")
                }

                // First prompt
                if !session.firstPrompt.isEmpty {
                    Divider()
                    Text("Prompt").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    Text(session.firstPrompt).font(.system(size: 11)).lineLimit(4)
                        .foregroundStyle(.primary.opacity(0.85))
                }

                // Summary
                if !session.summary.isEmpty {
                    Divider()
                    Text("Summary").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    Text(session.summary).font(.system(size: 11)).lineLimit(5)
                        .foregroundStyle(.primary.opacity(0.85))
                }
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle(session.projectName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Token Bar

private struct TokenBar: View {
    let label: String
    let value: Int
    let total: Int
    let color: Color

    private var fraction: Double { total > 0 ? Double(value) / Double(total) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
                    .frame(width: 52, alignment: .leading)
                Text(value.formatted()).font(.system(size: 10, weight: .medium))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.2)).frame(height: 5)
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: geo.size.width * fraction, height: 5)
                }
            }
            .frame(height: 5)
        }
    }
}

private struct MetaRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
                .frame(width: 58, alignment: .leading)
            Text(value).font(.system(size: 10, weight: .medium)).lineLimit(1)
        }
    }
}

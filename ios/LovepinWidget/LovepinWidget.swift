import WidgetKit
import SwiftUI

/// Shared keys matching those in WidgetService.dart.
private enum WidgetKeys {
    static let appGroup = "group.com.lovepin.shared"
    static let messageContent = "message_content"
    static let senderName = "sender_name"
    static let imagePath = "image_path"
    static let timestamp = "message_timestamp"
    static let backgroundColor = "theme_background_color"
    static let textColor = "theme_text_color"
    static let accentColor = "theme_accent_color"
}

// MARK: - Timeline Entry

struct LovepinEntry: TimelineEntry {
    let date: Date
    let messageContent: String
    let senderName: String
    let imageURL: String
    let timestamp: String
    let backgroundColor: Color
    let textColor: Color
    let accentColor: Color
}

// MARK: - Timeline Provider

struct LovepinTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> LovepinEntry {
        LovepinEntry(
            date: Date(),
            messageContent: "Your love note will appear here",
            senderName: "Lovepin",
            imageURL: "",
            timestamp: "",
            backgroundColor: Color(hex: "#FFD6E0"),
            textColor: Color(hex: "#2D2D2D"),
            accentColor: Color(hex: "#FF8FAB")
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LovepinEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LovepinEntry>) -> Void) {
        let entry = readEntry()
        // Refresh every 15 minutes.
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func readEntry() -> LovepinEntry {
        let defaults = UserDefaults(suiteName: WidgetKeys.appGroup)

        let content = defaults?.string(forKey: WidgetKeys.messageContent) ?? ""
        let sender = defaults?.string(forKey: WidgetKeys.senderName) ?? ""
        let image = defaults?.string(forKey: WidgetKeys.imagePath) ?? ""
        let ts = defaults?.string(forKey: WidgetKeys.timestamp) ?? ""
        let bg = defaults?.string(forKey: WidgetKeys.backgroundColor) ?? "#FFD6E0"
        let text = defaults?.string(forKey: WidgetKeys.textColor) ?? "#2D2D2D"
        let accent = defaults?.string(forKey: WidgetKeys.accentColor) ?? "#FF8FAB"

        return LovepinEntry(
            date: Date(),
            messageContent: content.isEmpty ? "No messages yet" : content,
            senderName: sender.isEmpty ? "Lovepin" : sender,
            imageURL: image,
            timestamp: ts.isEmpty ? "" : formatRelative(ts),
            backgroundColor: Color(hex: bg),
            textColor: Color(hex: text),
            accentColor: Color(hex: accent)
        )
    }

    private func formatRelative(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else {
            // Try without fractional seconds.
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: isoString) else { return "" }
            return relativeString(from: date)
        }
        return relativeString(from: date)
    }

    private func relativeString(from date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        switch diff {
        case ..<60: return "just now"
        case ..<3600: return "\(Int(diff / 60))m ago"
        case ..<86400: return "\(Int(diff / 3600))h ago"
        default: return "\(Int(diff / 86400))d ago"
        }
    }
}

// MARK: - Widget View

struct LovepinWidgetView: View {
    var entry: LovepinEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Sender
            HStack {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(entry.accentColor)
                Text(entry.senderName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.accentColor)
            }

            // Image (if URL is present, show as async image)
            if !entry.imageURL.isEmpty, let url = URL(string: entry.imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 80)
                            .clipped()
                            .cornerRadius(8)
                    default:
                        EmptyView()
                    }
                }
            }

            // Message
            Text(entry.messageContent)
                .font(.system(size: 15))
                .foregroundColor(entry.textColor)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            // Timestamp
            if !entry.timestamp.isEmpty {
                Text(entry.timestamp)
                    .font(.caption2)
                    .foregroundColor(entry.accentColor)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(entry.backgroundColor)
    }
}

// MARK: - Widget Configuration

@main
struct LovepinWidget: Widget {
    let kind: String = "LovepinWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LovepinTimelineProvider()) { entry in
            LovepinWidgetView(entry: entry)
        }
        .configurationDisplayName("Lovepin")
        .description("Shows the latest love note from your partner.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)

        let r, g, b: Double
        if sanitized.count == 6 {
            r = Double((rgb >> 16) & 0xFF) / 255.0
            g = Double((rgb >> 8) & 0xFF) / 255.0
            b = Double(rgb & 0xFF) / 255.0
        } else {
            r = 1; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}

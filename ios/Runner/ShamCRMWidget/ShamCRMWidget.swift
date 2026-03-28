import WidgetKit
import SwiftUI

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let entry = SimpleEntry(date: currentDate)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget View
struct ShamCRMWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // Фон
            Color.white
            
            VStack(spacing: 12) {
                // Заголовок
                HStack(spacing: 8) {
                    Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                        .resizable()
                        .frame(width: 28, height: 28)
                        .cornerRadius(6)
                    
                    Text("shamCRM")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.12, green: 0.18, blue: 0.32))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Кнопки
                HStack(spacing: 8) {
                    // Dashboard
                    WidgetButton(
                        icon: "chart.bar.fill",
                        label: "Дашборд",
                        group: 1,
                        screen: 0
                    )
                    
                    // Tasks
                    WidgetButton(
                        icon: "checkmark.circle.fill",
                        label: "Задачи",
                        group: 1,
                        screen: 1
                    )
                    
                    // Leads
                    WidgetButton(
                        icon: "person.fill",
                        label: "Лиды",
                        group: 1,
                        screen: 2
                    )
                    
                    // Deals
                    WidgetButton(
                        icon: "briefcase.fill",
                        label: "Сделки",
                        group: 1,
                        screen: 3
                    )
                    
                    // Chats
                    WidgetButton(
                        icon: "message.fill",
                        label: "Чаты",
                        group: 1,
                        screen: 4
                    )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .cornerRadius(16)
    }
}

// MARK: - Widget Button
struct WidgetButton: View {
    let icon: String
    let label: String
    let group: Int
    let screen: Int
    
    var body: some View {
        Link(destination: createDeepLink()) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.12, green: 0.18, blue: 0.32))
                
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(Color.gray)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(red: 0.97, green: 0.97, blue: 0.98))
            .cornerRadius(12)
        }
    }
    
    private func createDeepLink() -> URL {
        // Deep link формат: shamcrm://widget?group=1&screen=0
        let urlString = "shamcrm://widget?group=\(group)&screen=\(screen)"
        return URL(string: urlString)!
    }
}

// MARK: - Widget Configuration
@main
struct ShamCRMWidget: Widget {
    let kind: String = "ShamCRMWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ShamCRMWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("shamCRM")
        .description("Быстрый доступ к разделам shamCRM")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview
struct ShamCRMWidget_Previews: PreviewProvider {
    static var previews: some View {
        ShamCRMWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
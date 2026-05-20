//
//  rmk_widget.swift
//  deeplink_widget
//

import WidgetKit
import SwiftUI

struct RmkProvider: TimelineProvider {
    func placeholder(in context: Context) -> RmkEntry {
        RmkEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (RmkEntry) -> Void) {
        completion(RmkEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RmkEntry>) -> Void) {
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        completion(Timeline(entries: [RmkEntry(date: currentDate)], policy: .after(nextUpdate)))
    }
}

struct RmkEntry: TimelineEntry {
    let date: Date
}

struct rmk_widgetEntryView: View {
    var entry: RmkProvider.Entry

    var body: some View {
        Link(destination: URL(string: "shamcrm://widget?screen=rmk")!) {
            ZStack {
                Color(red: 0.12, green: 0.18, blue: 0.32)

                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.14))
                            .frame(width: 58, height: 58)

                        Image(systemName: "cash.register")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("RMK")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(10)
            }
        }
    }
}

struct rmk_widget: Widget {
    let kind: String = "rmk_widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RmkProvider()) { entry in
            rmk_widgetEntryView(entry: entry)
                .containerBackground(Color(red: 0.12, green: 0.18, blue: 0.32), for: .widget)
        }
        .configurationDisplayName("shamCRM RMK")
        .description("Быстрый вход в RMK")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    rmk_widget()
} timeline: {
    RmkEntry(date: .now)
}

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
                Color(red: 0.10, green: 0.17, blue: 0.31)

                VStack(spacing: 12) {
                    HStack {
                        Image("ic_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                        Spacer()
                    }
                    .padding(.horizontal, 4)

                    Spacer(minLength: 0)

                    VStack(spacing: 6) {
                        Text("RMK")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(red: 0.20, green: 0.78, blue: 0.53))
                                .frame(width: 7, height: 7)

                            Text("Касса")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.82))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 0)
                }
                .padding(14)
            }
        }
    }
}

struct rmk_widget: Widget {
    let kind: String = "rmk_widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RmkProvider()) { entry in
            rmk_widgetEntryView(entry: entry)
                .containerBackground(Color(red: 0.10, green: 0.17, blue: 0.31), for: .widget)
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

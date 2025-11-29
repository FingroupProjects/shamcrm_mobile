//
//  deeplink_widget.swift
//  deeplink_widget
//
//  Created by softtech on 25/11/25.
//

import WidgetKit
import SwiftUI

// MARK: - App Group ID
private let appGroupId = "group.com.softtech.crmTaskManager"

// MARK: - Localization Helper
struct WidgetLocalizations {
    // Supported languages: ru, uz, en
    static let translations: [String: [String: String]] = [
        "ru": [
            "dashboard": "Дашборд",
            "tasks": "Задачи",
            "leads": "Лиды",
            "deals": "Сделки",
            "chats": "Чаты",
            "warehouse": "Учёт",
            "orders": "Заказы",
            "online_store": "Магазин",
            "login_prompt": "Войдите в приложение"
        ],
        "uz": [
            "dashboard": "Boshqaruv",
            "tasks": "Vazifalar",
            "leads": "Lidlar",
            "deals": "Bitimlar",
            "chats": "Chatlar",
            "warehouse": "Hisoblar",
            "orders": "Buyurtmalar",
            "online_store": "Do'kon",
            "login_prompt": "Ilovaga kiring"
        ],
        "en": [
            "dashboard": "Dashboard",
            "tasks": "Tasks",
            "leads": "Leads",
            "deals": "Deals",
            "chats": "Chats",
            "warehouse": "Accounting",
            "orders": "Orders",
            "online_store": "Store",
            "login_prompt": "Log in to the app"
        ]
    ]

    static func getLanguage() -> String {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            return "ru"
        }
        return userDefaults.string(forKey: "app_language") ?? "ru"
    }

    static func translate(_ key: String) -> String {
        let language = getLanguage()
        return translations[language]?[key] ?? translations["ru"]?[key] ?? key
    }
}

// MARK: - Permission Helper
struct PermissionHelper {
    static func getPermissions() -> [String] {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            return []
        }
        return userDefaults.stringArray(forKey: "user_permissions") ?? []
    }

    static func hasPermission(_ permission: String) -> Bool {
        return getPermissions().contains(permission)
    }

    static func hasAnyPermission(_ permissions: [String]) -> Bool {
        let userPermissions = getPermissions()
        return permissions.contains { userPermissions.contains($0) }
    }
}

// MARK: - Widget Button Data
struct WidgetButtonData: Identifiable {
    let id = UUID()
    let icon: String
    let labelKey: String  // Translation key
    let screenIdentifier: String

    var label: String {
        return WidgetLocalizations.translate(labelKey)
    }
}

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), permissions: [], language: "ru")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let permissions = PermissionHelper.getPermissions()
        let language = WidgetLocalizations.getLanguage()
        let entry = SimpleEntry(date: Date(), permissions: permissions, language: language)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let permissions = PermissionHelper.getPermissions()
        let language = WidgetLocalizations.getLanguage()
        let entry = SimpleEntry(date: currentDate, permissions: permissions, language: language)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let permissions: [String]
    let language: String

    func hasPermission(_ permission: String) -> Bool {
        return permissions.contains(permission)
    }

    func hasAnyPermission(_ permissionList: [String]) -> Bool {
        return permissionList.contains { permissions.contains($0) }
    }
}

// MARK: - Widget View
struct deeplink_widgetEntryView : View {
    var entry: Provider.Entry

    // Get visible buttons based on permissions
    var visibleButtons: [WidgetButtonData] {
        var buttons: [WidgetButtonData] = []

        // Dashboard - requires section.dashboard
        if entry.hasPermission("section.dashboard") {
            buttons.append(WidgetButtonData(
                icon: "ic_dashboard",
                labelKey: "dashboard",
                screenIdentifier: "dashboard"
            ))
        }

        // Tasks - requires task.read
        if entry.hasPermission("task.read") {
            buttons.append(WidgetButtonData(
                icon: "ic_tasks",
                labelKey: "tasks",
                screenIdentifier: "tasks"
            ))
        }

        // Leads - requires lead.read
        if entry.hasPermission("lead.read") {
            buttons.append(WidgetButtonData(
                icon: "ic_leads",
                labelKey: "leads",
                screenIdentifier: "leads"
            ))
        }

        // Deals - requires deal.read
        if entry.hasPermission("deal.read") {
            buttons.append(WidgetButtonData(
                icon: "ic_deals",
                labelKey: "deals",
                screenIdentifier: "deals"
            ))
        }

        // Chats - always visible (no permission required)
        buttons.append(WidgetButtonData(
            icon: "ic_chats",
            labelKey: "chats",
            screenIdentifier: "chats"
        ))

        // Warehouse/Accounting - requires accounting_of_goods OR accounting_money
        let hasWarehouseAccess = entry.hasAnyPermission(["accounting_of_goods", "accounting_money"])
        if hasWarehouseAccess {
            buttons.append(WidgetButtonData(
                icon: "ic_warehouse",
                labelKey: "warehouse",
                screenIdentifier: "warehouse"
            ))
        }

        // Orders - requires order.read AND warehouse access
        if entry.hasPermission("order.read") && hasWarehouseAccess {
            buttons.append(WidgetButtonData(
                icon: "ic_orders",
                labelKey: "orders",
                screenIdentifier: "orders"
            ))
        }

        // Online Store - requires order.read WITHOUT warehouse access
        if entry.hasPermission("order.read") && !hasWarehouseAccess {
            buttons.append(WidgetButtonData(
                icon: "ic_online_store",
                labelKey: "online_store",
                screenIdentifier: "online_store"
            ))
        }

        return buttons
    }

    var body: some View {
        VStack(spacing: 8) {
// Header
HStack(spacing: 6) {
// App icon from widget assets
Image("app_icon")
.resizable()
.frame(width: 24, height: 24)
.cornerRadius(5)

Text("shamCRM")
.font(.system(size: 13))
.foregroundColor(Color(red: 0.12, green: 0.18, blue: 0.32))

Spacer()
}
.padding(.horizontal, 16)
.padding(.top, 12)

// Buttons - show based on permissions
if visibleButtons.isEmpty {
// No permissions - show login prompt
VStack(spacing: 4) {
Image(systemName: "person.crop.circle.badge.questionmark")
.font(.system(size: 28))
.foregroundColor(Color.gray)
Text(WidgetLocalizations.translate("login_prompt"))
.font(.system(size: 11))
.foregroundColor(Color.gray)
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
.padding(.bottom, 12)
} else if visibleButtons.count <= 5 {
// Single row for 5 or fewer buttons - use larger size
HStack(spacing: 6) {
ForEach(visibleButtons) { button in
WidgetButton(
icon: button.icon,
label: button.label,
screenIdentifier: button.screenIdentifier,
isLarge: true
)
}
}
.padding(.horizontal, 12)
.padding(.bottom, 12)
} else {
// Two rows for more than 5 buttons - use current size
VStack(spacing: 6) {
// First row - first 4 buttons
HStack(spacing: 6) {
ForEach(Array(visibleButtons.prefix(4))) { button in
WidgetButton(
icon: button.icon,
label: button.label,
screenIdentifier: button.screenIdentifier,
isLarge: false
)
}
}

// Second row - remaining buttons
HStack(spacing: 6) {
ForEach(Array(visibleButtons.dropFirst(4))) { button in
WidgetButton(
icon: button.icon,
label: button.label,
screenIdentifier: button.screenIdentifier,
isLarge: false
)
}
// Add spacers to align buttons to the left if less than 4 in second row
if visibleButtons.count < 8 {
ForEach(0..<(8 - visibleButtons.count), id: \.self) { _ in
Color.clear
.frame(maxWidth: .infinity)
}
}
}
}
.padding(.horizontal, 12)
.padding(.bottom, 8)
}
}
}
}

// MARK: - Widget Button
struct WidgetButton: View {
let icon: String
let label: String
let screenIdentifier: String
let isLarge: Bool  // Controls size based on button count

// Color constants matching Android widget
private let buttonBackgroundColor = Color(red: 0.12, green: 0.18, blue: 0.32) // #1E2E52
private let textColor = Color(red: 0.12, green: 0.18, blue: 0.32) // #1E2E52

// Computed properties for sizes
private var circleSize: CGFloat {
isLarge ? 52 : 45  // Bigger for 1-5 buttons, current for more
}

private var iconSize: CGFloat {
isLarge ? 22 : 19  // Bigger for 1-5 buttons, current for more
}

private var textSize: CGFloat {
isLarge ? 10 : 9  // Bigger text for 1-5 buttons, current for more
}

var body: some View {
Link(destination: createDeepLink()) {
VStack(spacing: 2) {
// Circular button with icon
ZStack {
Circle()
.fill(buttonBackgroundColor)
.frame(width: circleSize, height: circleSize)

Image(icon)
.resizable()
.renderingMode(.template)
.foregroundColor(.white)
.scaledToFit()
.frame(width: iconSize, height: iconSize)
}

// Label text
Text(label)
.font(.system(size: textSize))
.foregroundColor(textColor)
.lineLimit(1)
.minimumScaleFactor(0.7)
}
.frame(maxWidth: .infinity)
}
}

private func createDeepLink() -> URL {
// Deep link format: shamcrm://widget?screen=dashboard
let urlString = "shamcrm://widget?screen=\(screenIdentifier)"
return URL(string: urlString)!
}
}

// MARK: - Widget Configuration
struct deeplink_widget: Widget {
let kind: String = "deeplink_widget"

var body: some WidgetConfiguration {
StaticConfiguration(kind: kind, provider: Provider()) { entry in
deeplink_widgetEntryView(entry: entry)
.containerBackground(Color.white, for: .widget)
}
.configurationDisplayName("shamCRM")
.description("Быстрый доступ к разделам shamCRM")
.supportedFamilies([.systemMedium])
}
}

// MARK: - Preview
#Preview(as: .systemMedium) {
deeplink_widget()
} timeline: {
// Preview with all permissions
SimpleEntry(date: .now, permissions: [
"section.dashboard",
"task.read",
"lead.read",
"deal.read",
"accounting_of_goods",
"order.read"
], language: "ru")
}

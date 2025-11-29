//
//  references_widget.swift
//  deeplink_widget
//
//  Created by softtech on 25/11/25.
//

import WidgetKit
import SwiftUI

// MARK: - App Group ID
private let appGroupId = "group.com.softtech.crmTaskManager"

// MARK: - Localization Helper for References
struct ReferencesWidgetLocalizations {
    // Supported languages: ru, uz, en
    static let translations: [String: [String: String]] = [
        "ru": [
            "warehouse": "Склад",
            "supplier": "Поставщик",
            "product": "Товар",
            "appbar_categories": "Категории",
            "openings": "Первоначальный остаток",
            "cash_desk": "Касса",
            "expense_articles": "Статья расхода",
            "income_articles": "Статья дохода",
            "references_title": "Справочники",
            "login_prompt": "Войдите в приложение"
        ],
        "uz": [
            "warehouse": "Ombor",
            "supplier": "Ta'minotchi",
            "product": "Mahsulot",
            "appbar_categories": "Kategoriyalar",
            "openings": "Dastlabki qoldiq",
            "cash_desk": "Kassa",
            "expense_articles": "Xarajat maqolasi",
            "income_articles": "Daromad maqolasi",
            "references_title": "Ma'lumotnomalar",
            "login_prompt": "Ilovaga kiring"
        ],
        "en": [
            "warehouse": "Warehouse",
            "supplier": "Supplier",
            "product": "Product",
            "appbar_categories": "Categories",
            "openings": "Initial Balance",
            "cash_desk": "Cash Register",
            "expense_articles": "Expense Article",
            "income_articles": "Income Article",
            "references_title": "References",
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

// MARK: - Permission Helper for References
struct ReferencesPermissionHelper {
    static func getPermissions() -> [String] {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            return []
        }
        return userDefaults.stringArray(forKey: "user_permissions") ?? []
    }

    static func hasPermission(_ permission: String) -> Bool {
        return getPermissions().contains(permission)
    }
}

// MARK: - References Button Data
struct ReferencesButtonData: Identifiable {
    let id = UUID()
    let icon: String  // SF Symbol name
    let labelKey: String  // Translation key
    let screenIdentifier: String
    let requiredPermission: String

    var label: String {
        return ReferencesWidgetLocalizations.translate(labelKey)
    }
}

// MARK: - Provider
struct ReferencesProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleReferencesEntry {
        SimpleReferencesEntry(date: Date(), permissions: [], language: "ru")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleReferencesEntry) -> ()) {
        let permissions = ReferencesPermissionHelper.getPermissions()
        let language = ReferencesWidgetLocalizations.getLanguage()
        let entry = SimpleReferencesEntry(date: Date(), permissions: permissions, language: language)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let permissions = ReferencesPermissionHelper.getPermissions()
        let language = ReferencesWidgetLocalizations.getLanguage()
        let entry = SimpleReferencesEntry(date: currentDate, permissions: permissions, language: language)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry
struct SimpleReferencesEntry: TimelineEntry {
    let date: Date
    let permissions: [String]
    let language: String

    func hasPermission(_ permission: String) -> Bool {
        return permissions.contains(permission)
    }
}

// MARK: - Widget View
struct references_widgetEntryView : View {
    var entry: ReferencesProvider.Entry

    // All 8 reference buttons with their permissions
    var allButtons: [ReferencesButtonData] {
        return [
            ReferencesButtonData(
                icon: "building.2",
                labelKey: "warehouse",
                screenIdentifier: "reference_warehouse",
                requiredPermission: "storage.read"
            ),
            ReferencesButtonData(
                icon: "person.2",
                labelKey: "supplier",
                screenIdentifier: "reference_supplier",
                requiredPermission: "supplier.read"
            ),
            ReferencesButtonData(
                icon: "cube.box",
                labelKey: "product",
                screenIdentifier: "reference_product",
                requiredPermission: "product.read"
            ),
            ReferencesButtonData(
                icon: "square.grid.2x2",
                labelKey: "appbar_categories",
                screenIdentifier: "reference_category",
                requiredPermission: "category.read"
            ),
            ReferencesButtonData(
                icon: "chart.bar.doc.horizontal",
                labelKey: "openings",
                screenIdentifier: "reference_openings",
                requiredPermission: "initial_balance.read"
            ),
            ReferencesButtonData(
                icon: "creditcard",
                labelKey: "cash_desk",
                screenIdentifier: "reference_cash_desk",
                requiredPermission: "cash_register.read"
            ),
            ReferencesButtonData(
                icon: "arrow.down.circle",
                labelKey: "expense_articles",
                screenIdentifier: "reference_expense_article",
                requiredPermission: "rko_article.read"
            ),
            ReferencesButtonData(
                icon: "arrow.up.circle",
                labelKey: "income_articles",
                screenIdentifier: "reference_income_article",
                requiredPermission: "pko_article.read"
            )
        ]
    }

    // Get visible buttons based on permissions
    var visibleButtons: [ReferencesButtonData] {
        return allButtons.filter { entry.hasPermission($0.requiredPermission) }
    }

    var body: some View {
        Link(destination: createReferencesDeepLink()) {
VStack(spacing: 8) {
// Header
HStack(spacing: 6) {
// App icon from widget assets
Image("app_icon")
.resizable()
.frame(width: 24, height: 24)
.cornerRadius(5)

Text(ReferencesWidgetLocalizations.translate("references_title"))
.font(.system(size: 13, weight: .semibold))
.foregroundColor(Color(red: 0.12, green: 0.18, blue: 0.32))

Spacer()
}
.padding(.horizontal, 16)
.padding(.top, 12)

// Buttons Grid - 2x4 layout
if visibleButtons.isEmpty {
// No permissions - show login prompt
VStack(spacing: 4) {
Image(systemName: "person.crop.circle.badge.questionmark")
.font(.system(size: 28))
.foregroundColor(Color.gray)
Text(ReferencesWidgetLocalizations.translate("login_prompt"))
.font(.system(size: 11))
.foregroundColor(Color.gray)
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
.padding(.bottom, 12)
} else {
// Two rows - 4 buttons per row
VStack(spacing: 6) {
// First row - first 4 buttons
HStack(spacing: 6) {
ForEach(Array(visibleButtons.prefix(4))) { button in
ReferencesWidgetButton(
icon: button.icon,
label: button.label,
screenIdentifier: button.screenIdentifier
)
}
// Add spacers if less than 4 buttons
if visibleButtons.count < 4 {
ForEach(0..<(4 - visibleButtons.count), id: \.self) { _ in
Color.clear
.frame(maxWidth: .infinity)
}
}
}

// Second row - next 4 buttons
HStack(spacing: 6) {
ForEach(Array(visibleButtons.dropFirst(4).prefix(4))) { button in
ReferencesWidgetButton(
icon: button.icon,
label: button.label,
screenIdentifier: button.screenIdentifier
)
}
// Add spacers if less than 4 buttons in second row
let remainingCount = max(0, visibleButtons.count - 4)
if remainingCount < 4 {
ForEach(0..<(4 - remainingCount), id: \.self) { _ in
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

private func createReferencesDeepLink() -> URL {
// Deep link format: shamcrm://widget?screen=references
let urlString = "shamcrm://widget?screen=references"
return URL(string: urlString)!
}
}

// MARK: - Widget Button
struct ReferencesWidgetButton: View {
let icon: String  // SF Symbol name
let label: String
let screenIdentifier: String

// Color constants matching Android widget
private let buttonBackgroundColor = Color(red: 0.12, green: 0.18, blue: 0.32) // #1E2E52
private let textColor = Color(red: 0.12, green: 0.18, blue: 0.32) // #1E2E52

// Size constants for 2x4 grid
private let circleSize: CGFloat = 45
private let iconSize: CGFloat = 19
private let textSize: CGFloat = 9

var body: some View {
Link(destination: createDeepLink()) {
VStack(spacing: 2) {
// Circular button with icon
ZStack {
Circle()
.fill(buttonBackgroundColor)
.frame(width: circleSize, height: circleSize)

Image(systemName: icon)
.font(.system(size: iconSize, weight: .medium))
.foregroundColor(.white)
}

// Label text
Text(label)
.font(.system(size: textSize))
.foregroundColor(textColor)
.lineLimit(2)
.minimumScaleFactor(0.7)
.multilineTextAlignment(.center)
}
.frame(maxWidth: .infinity)
}
}

private func createDeepLink() -> URL {
// Deep link format: shamcrm://widget?screen=reference_warehouse
let urlString = "shamcrm://widget?screen=\(screenIdentifier)"
return URL(string: urlString)!
}
}

// MARK: - Widget Configuration
struct references_widget: Widget {
let kind: String = "references_widget"

var body: some WidgetConfiguration {
StaticConfiguration(kind: kind, provider: ReferencesProvider()) { entry in
references_widgetEntryView(entry: entry)
.containerBackground(Color.white, for: .widget)
}
.configurationDisplayName("shamCRM Справочники")
.description("Быстрый доступ к справочникам")
.supportedFamilies([.systemMedium])
}
}

// MARK: - Preview
#Preview(as: .systemMedium) {
references_widget()
} timeline: {
// Preview with all permissions
SimpleReferencesEntry(date: .now, permissions: [
"storage.read",
"supplier.read",
"product.read",
"category.read",
"initial_balance.read",
"cash_register.read",
"rko_article.read",
"pko_article.read"
], language: "ru")
}


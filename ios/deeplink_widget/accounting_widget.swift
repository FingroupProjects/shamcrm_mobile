//
//  accounting_widget.swift
//  deeplink_widget
//
//  Created by softtech on 25/11/25.
//

import WidgetKit
import SwiftUI

// MARK: - App Group ID
private let appGroupId = "group.com.softtech.crmTaskManager"

// MARK: - Localization Helper for Accounting
struct AccountingWidgetLocalizations {
    // Supported languages: ru, uz, en
    static let translations: [String: [String: String]] = [
        "ru": [
            "client_sale": "Продажа",
            "client_return": "Возврат от клиента",
            "income_goods": "Приход товаров",
            "transfer": "Перемещение",
            "write_off": "Списание",
            "supplier_return": "Возврат поставщику",
            "money_income": "Приход денег",
            "money_outcome": "Расход денег",
            "accounting_title": "Учет торговли",
            "login_prompt": "Войдите в приложение"
        ],
        "uz": [
            "client_sale": "Mijozga realizatsiya",
            "client_return": "Mijozdan qaytish",
            "income_goods": "Tovar tushumi",
            "transfer": "Ko'chirish",
            "write_off": "Pul chiqimi",
            "supplier_return": "Ta'minotchiga qaytarish",
            "money_income": "Pul tushumi",
            "money_outcome": "Pul chiqimi",
            "accounting_title": "Savdo hisobi",
            "login_prompt": "Ilovaga kiring"
        ],
        "en": [
            "client_sale": "Client sale",
            "client_return": "Client return",
            "income_goods": "Goods receipt",
            "transfer": "Transfer",
            "write_off": "Write-off",
            "supplier_return": "Supplier return",
            "money_income": "Cash receipt",
            "money_outcome": "Cash outflow",
            "accounting_title": "Trade Accounting",
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

// MARK: - Permission Helper for Accounting
struct AccountingPermissionHelper {
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

// MARK: - Accounting Button Data
struct AccountingButtonData: Identifiable {
    let id = UUID()
    let icon: String  // SF Symbol name
    let labelKey: String  // Translation key
    let screenIdentifier: String
    let requiredPermission: String
    
    var label: String {
        return AccountingWidgetLocalizations.translate(labelKey)
    }
}

// MARK: - Provider
struct AccountingProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleAccountingEntry {
        SimpleAccountingEntry(date: Date(), permissions: [], language: "ru")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleAccountingEntry) -> ()) {
        let permissions = AccountingPermissionHelper.getPermissions()
        let language = AccountingWidgetLocalizations.getLanguage()
        let entry = SimpleAccountingEntry(date: Date(), permissions: permissions, language: language)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let permissions = AccountingPermissionHelper.getPermissions()
        let language = AccountingWidgetLocalizations.getLanguage()
        let entry = SimpleAccountingEntry(date: currentDate, permissions: permissions, language: language)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry
struct SimpleAccountingEntry: TimelineEntry {
    let date: Date
    let permissions: [String]
    let language: String
    
    func hasPermission(_ permission: String) -> Bool {
        return permissions.contains(permission)
    }
}

// MARK: - Widget View
struct accounting_widgetEntryView : View {
    var entry: AccountingProvider.Entry
    
    // All 8 accounting buttons with their permissions
    var allButtons: [AccountingButtonData] {
        return [
            AccountingButtonData(
                icon: "cart",
                labelKey: "client_sale",
                screenIdentifier: "client_sale",
                requiredPermission: "expense_document.read"
            ),
            AccountingButtonData(
                icon: "arrow.left",
                labelKey: "client_return",
                screenIdentifier: "client_return",
                requiredPermission: "client_return_document.read"
            ),
            AccountingButtonData(
                icon: "plus.square",
                labelKey: "income_goods",
                screenIdentifier: "income_goods",
                requiredPermission: "income_document.read"
            ),
            AccountingButtonData(
                icon: "arrow.left.arrow.right",
                labelKey: "transfer",
                screenIdentifier: "transfer",
                requiredPermission: "movement_document.read"
            ),
            AccountingButtonData(
                icon: "minus.square",
                labelKey: "write_off",
                screenIdentifier: "write_off",
                requiredPermission: "write_off_document.read"
            ),
            AccountingButtonData(
                icon: "arrow.uturn.backward",
                labelKey: "supplier_return",
                screenIdentifier: "supplier_return",
                requiredPermission: "supplier_return_document.read"
            ),
            AccountingButtonData(
                icon: "plus.circle",
                labelKey: "money_income",
                screenIdentifier: "money_income",
                requiredPermission: "checking_account_pko.read"
            ),
            AccountingButtonData(
                icon: "minus.circle",
                labelKey: "money_outcome",
                screenIdentifier: "money_outcome",
                requiredPermission: "checking_account_rko.read"
            )
        ]
    }
    
    // Get visible buttons based on permissions
    var visibleButtons: [AccountingButtonData] {
        return allButtons.filter { entry.hasPermission($0.requiredPermission) }
    }

    var body: some View {
        Link(destination: createWarehouseDeepLink()) {
            VStack(spacing: 8) {
                // Header
                HStack(spacing: 6) {
                    // App icon from widget assets
                    Image("app_icon")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .cornerRadius(5)
                    
                    Text(AccountingWidgetLocalizations.translate("accounting_title"))
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
                        Text(AccountingWidgetLocalizations.translate("login_prompt"))
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
                                AccountingWidgetButton(
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
                                AccountingWidgetButton(
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
    
    private func createWarehouseDeepLink() -> URL {
        // Deep link format: shamcrm://widget?screen=warehouse
        let urlString = "shamcrm://widget?screen=warehouse"
        return URL(string: urlString)!
    }
}

// MARK: - Widget Button
struct AccountingWidgetButton: View {
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
        // Deep link format: shamcrm://widget?screen=client_sale
        let urlString = "shamcrm://widget?screen=\(screenIdentifier)"
        return URL(string: urlString)!
    }
}

// MARK: - Widget Configuration
struct accounting_widget: Widget {
    let kind: String = "accounting_widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AccountingProvider()) { entry in
            accounting_widgetEntryView(entry: entry)
                .containerBackground(Color.white, for: .widget)
        }
        .configurationDisplayName("shamCRM Учет")
        .description("Быстрый доступ к навигации учета")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemMedium) {
    accounting_widget()
} timeline: {
    // Preview with all permissions
    SimpleAccountingEntry(date: .now, permissions: [
        "expense_document.read",
        "client_return_document.read",
        "income_document.read",
        "movement_document.read",
        "write_off_document.read",
        "supplier_return_document.read",
        "checking_account_pko.read",
        "checking_account_rko.read"
    ], language: "ru")
}


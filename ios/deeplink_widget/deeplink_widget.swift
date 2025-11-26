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
    let label: String
    let screenIdentifier: String
}

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), permissions: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let permissions = PermissionHelper.getPermissions()
        let entry = SimpleEntry(date: Date(), permissions: permissions)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let permissions = PermissionHelper.getPermissions()
        let entry = SimpleEntry(date: currentDate, permissions: permissions)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let permissions: [String]
    
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
                icon: "chart.bar.fill",
                label: "Дашборд",
                screenIdentifier: "dashboard"
            ))
        }
        
        // Tasks - requires task.read
        if entry.hasPermission("task.read") {
            buttons.append(WidgetButtonData(
                icon: "checkmark.circle.fill",
                label: "Задачи",
                screenIdentifier: "tasks"
            ))
        }
        
        // Leads - requires lead.read
        if entry.hasPermission("lead.read") {
            buttons.append(WidgetButtonData(
                icon: "person.fill",
                label: "Лиды",
                screenIdentifier: "leads"
            ))
        }
        
        // Deals - requires deal.read
        if entry.hasPermission("deal.read") {
            buttons.append(WidgetButtonData(
                icon: "briefcase.fill",
                label: "Сделки",
                screenIdentifier: "deals"
            ))
        }
        
        // Chats - always visible (no permission required)
        buttons.append(WidgetButtonData(
            icon: "message.fill",
            label: "Чаты",
            screenIdentifier: "chats"
        ))
        
        // Warehouse/Accounting - requires accounting_of_goods OR accounting_money
        let hasWarehouseAccess = entry.hasAnyPermission(["accounting_of_goods", "accounting_money"])
        if hasWarehouseAccess {
            buttons.append(WidgetButtonData(
                icon: "doc.text.fill",
                label: "Учёт",
                screenIdentifier: "warehouse"
            ))
        }
        
        // Orders - requires order.read AND warehouse access
        if entry.hasPermission("order.read") && hasWarehouseAccess {
            buttons.append(WidgetButtonData(
                icon: "cart.fill",
                label: "Заказы",
                screenIdentifier: "orders"
            ))
        }
        
        // Online Store - requires order.read WITHOUT warehouse access
        if entry.hasPermission("order.read") && !hasWarehouseAccess {
            buttons.append(WidgetButtonData(
                icon: "storefront.fill",
                label: "Магазин",
                screenIdentifier: "online_store"
            ))
        }
        
        return buttons
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
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
            
            // Buttons - show based on permissions
            if visibleButtons.isEmpty {
                // No permissions - show login prompt
                VStack(spacing: 4) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 28))
                        .foregroundColor(Color.gray)
                    Text("Войдите в приложение")
                        .font(.system(size: 11))
                        .foregroundColor(Color.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 12)
            } else if visibleButtons.count <= 5 {
                // Single row for 5 or fewer buttons
                HStack(spacing: 6) {
                    ForEach(visibleButtons) { button in
                        WidgetButton(
                            icon: button.icon,
                            label: button.label,
                            screenIdentifier: button.screenIdentifier
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            } else {
                // Two rows for more than 5 buttons
                VStack(spacing: 6) {
                    // First row - first 4 buttons
                    HStack(spacing: 6) {
                        ForEach(Array(visibleButtons.prefix(4))) { button in
                            WidgetButton(
                                icon: button.icon,
                                label: button.label,
                                screenIdentifier: button.screenIdentifier
                            )
                        }
                    }
                    
                    // Second row - remaining buttons
                    HStack(spacing: 6) {
                        ForEach(Array(visibleButtons.dropFirst(4))) { button in
                            WidgetButton(
                                icon: button.icon,
                                label: button.label,
                                screenIdentifier: button.screenIdentifier
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
    
    var body: some View {
        Link(destination: createDeepLink()) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.12, green: 0.18, blue: 0.32))
                
                Text(label)
                    .font(.system(size: 8))
                    .foregroundColor(Color.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color(red: 0.97, green: 0.97, blue: 0.98))
            .cornerRadius(10)
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
    ])
}

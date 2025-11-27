package com.softtech.crm_task_manager

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.View
import android.widget.RemoteViews

class ShamCRMWidgetProvider : AppWidgetProvider() {
    
    // Button configuration: key (screen identifier), drawable resource
    private data class WidgetButton(
        val key: String,
        val drawableId: Int
    )
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        try {
            // Read visibility flags from Flutter's SharedPreferences
            val visibility = getVisibilityFlags(context)
            
            // Define all buttons (key = screen identifier for navigation)
            val allButtons = listOf(
                WidgetButton("dashboard", R.drawable.ic_dashboard),
                WidgetButton("tasks", R.drawable.ic_tasks),
                WidgetButton("leads", R.drawable.ic_leads),
                WidgetButton("deals", R.drawable.ic_deals),
                WidgetButton("chats", R.drawable.ic_chats),
                WidgetButton("warehouse", R.drawable.ic_warehouse),
                WidgetButton("orders", R.drawable.ic_orders),
                WidgetButton("online_store", R.drawable.ic_online_store)
            )
            
            // Collect visible buttons
            val visibleButtons = allButtons.filter { button ->
                visibility[button.key] ?: true
            }
            
            // Choose layout based on visible button count:
            // - Compact layout (1-4 items): smaller widget with transparent margins
            // - Full layout (5-8 items): fills entire widget area with 2 rows
            val isCompact = visibleButtons.size <= 4
            val layoutId = if (isCompact) {
                R.layout.sham_crm_widget_compact
            } else {
                R.layout.sham_crm_widget
            }
            
            Log.d("ShamCRMWidget", "Using ${if (isCompact) "COMPACT" else "FULL"} layout for ${visibleButtons.size} buttons")
            
            val views = RemoteViews(context.packageName, layoutId)
            
            // Mapping of button keys to label text (Russian labels)
            val labelTextMap = mapOf(
                "dashboard" to "Дашборд",
                "tasks" to "Задачи",
                "leads" to "Лиды",
                "deals" to "Сделки",
                "chats" to "Чаты",
                "warehouse" to "Учёт",
                "orders" to "Заказы",
                "online_store" to "Магазин"
            )
            
            if (isCompact) {
                // Compact layout: single row with 4 slots
                val compactSlots = listOf(
                    Triple(R.id.btn_dashboard, R.id.icon_dashboard, R.id.label_dashboard),
                    Triple(R.id.btn_tasks, R.id.icon_tasks, R.id.label_tasks),
                    Triple(R.id.btn_leads, R.id.icon_leads, R.id.label_leads),
                    Triple(R.id.btn_deals, R.id.icon_deals, R.id.label_deals)
                )
                
                for (i in 0 until 4) {
                    val (containerId, iconId, labelId) = compactSlots[i]
                    
                    if (i < visibleButtons.size) {
                        val button = visibleButtons[i]
                        val originalButtonIndex = allButtons.indexOfFirst { it.key == button.key }
                        
                        views.setViewVisibility(containerId, View.VISIBLE)
                        views.setImageViewResource(iconId, button.drawableId)
                        views.setTextViewText(labelId, labelTextMap[button.key] ?: button.key)
                        
                        val intent = createLaunchIntent(context, button.key)
                        val requestCode = appWidgetId * 100 + originalButtonIndex
                        val pendingIntent = PendingIntent.getActivity(
                            context,
                            requestCode,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(containerId, pendingIntent)
                        
                        Log.d("ShamCRMWidget", "Compact: Assigned ${button.key} to slot $i")
                    } else {
                        views.setViewVisibility(containerId, View.INVISIBLE)
                    }
                }
            } else {
                // Full layout: two rows with 8 slots total
                val fullSlots = listOf(
                    // First row
                    Triple(R.id.btn_dashboard, R.id.icon_dashboard, R.id.label_dashboard),
                    Triple(R.id.btn_tasks, R.id.icon_tasks, R.id.label_tasks),
                    Triple(R.id.btn_leads, R.id.icon_leads, R.id.label_leads),
                    Triple(R.id.btn_deals, R.id.icon_deals, R.id.label_deals),
                    // Second row
                    Triple(R.id.btn_chats, R.id.icon_chats, R.id.label_chats),
                    Triple(R.id.btn_warehouse, R.id.icon_warehouse, R.id.label_warehouse),
                    Triple(R.id.btn_orders, R.id.icon_orders, R.id.label_orders),
                    Triple(R.id.btn_online_store, R.id.icon_online_store, R.id.label_online_store)
                )
                
                for (i in 0 until 8) {
                    val (containerId, iconId, labelId) = fullSlots[i]
                    
                    if (i < visibleButtons.size) {
                        val button = visibleButtons[i]
                        val originalButtonIndex = allButtons.indexOfFirst { it.key == button.key }
                        
                        views.setViewVisibility(containerId, View.VISIBLE)
                        views.setImageViewResource(iconId, button.drawableId)
                        views.setTextViewText(labelId, labelTextMap[button.key] ?: button.key)
                        
                        val intent = createLaunchIntent(context, button.key)
                        val requestCode = appWidgetId * 100 + originalButtonIndex
                        val pendingIntent = PendingIntent.getActivity(
                            context,
                            requestCode,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(containerId, pendingIntent)
                        
                        Log.d("ShamCRMWidget", "Full: Assigned ${button.key} to slot $i")
                    } else {
                        views.setViewVisibility(containerId, View.INVISIBLE)
                    }
                }
                
                // Handle second row visibility for full layout
                if (visibleButtons.size <= 4) {
                    views.setViewVisibility(R.id.second_row_layout, View.GONE)
                } else {
                    views.setViewVisibility(R.id.second_row_layout, View.VISIBLE)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d("ShamCRMWidget", "Widget updated — ID=$appWidgetId, visible buttons: ${visibleButtons.size}, layout: ${if (isCompact) "compact" else "full"}")
        } catch (e: Exception) {
            Log.e("ShamCRMWidget", "Error updating widget: ${e.message}", e)
        }
    }
    
    private fun createLaunchIntent(context: Context, screenKey: String): Intent {
        return Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("screen_identifier", screenKey)
        }
    }
    
    /**
     * Read visibility flags from Flutter's SharedPreferences.
     * Flutter SharedPreferences on Android uses file "FlutterSharedPreferences"
     * and keys are prefixed with "flutter."
     */
    private fun getVisibilityFlags(context: Context): Map<String, Boolean> {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        
        val keys = listOf("dashboard", "tasks", "leads", "deals", "chats", "warehouse", "orders", "online_store")
        val visibility = mutableMapOf<String, Boolean>()
        
        for (key in keys) {
            // Flutter SharedPreferences prefixes keys with "flutter."
            val flutterKey = "flutter.widget_show_$key"
            
            // Default to true if not set (show all buttons by default)
            // Exception: warehouse, orders, online_store default to false (permission-based)
            val defaultValue = when (key) {
                "warehouse", "orders", "online_store" -> false
                else -> true
            }
            visibility[key] = prefs.getBoolean(flutterKey, defaultValue)
        }
        
        Log.d("ShamCRMWidget", "Visibility flags: $visibility")
        return visibility
    }
}

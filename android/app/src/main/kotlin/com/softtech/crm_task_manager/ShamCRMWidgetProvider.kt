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
    
    // Button configuration: key (screen identifier), container ID, icon ID, drawable resource
    private data class WidgetButton(
        val key: String,
        val containerId: Int,
        val iconId: Int,
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
            val views = RemoteViews(context.packageName, R.layout.sham_crm_widget)
            
            // Read visibility flags from Flutter's SharedPreferences
            val visibility = getVisibilityFlags(context)
            
            // Define all buttons (key = screen identifier for navigation)
            val allButtons = listOf(
                WidgetButton("dashboard", R.id.btn_dashboard, R.id.icon_dashboard, R.drawable.ic_dashboard),
                WidgetButton("tasks", R.id.btn_tasks, R.id.icon_tasks, R.drawable.ic_tasks),
                WidgetButton("leads", R.id.btn_leads, R.id.icon_leads, R.drawable.ic_leads),
                WidgetButton("deals", R.id.btn_deals, R.id.icon_deals, R.drawable.ic_deals),
                WidgetButton("chats", R.id.btn_chats, R.id.icon_chats, R.drawable.ic_chats),
                WidgetButton("warehouse", R.id.btn_warehouse, R.id.icon_warehouse, R.drawable.ic_warehouse),
                WidgetButton("orders", R.id.btn_orders, R.id.icon_orders, R.drawable.ic_orders),
                WidgetButton("online_store", R.id.btn_online_store, R.id.icon_online_store, R.drawable.ic_online_store)
            )
            
            // Collect visible buttons
            val visibleButtons = allButtons.filter { button ->
                visibility[button.key] ?: true
            }
            
            // Define slot mappings for first row (4 slots)
            val firstRowSlots = listOf(
                R.id.btn_dashboard,
                R.id.btn_tasks,
                R.id.btn_leads,
                R.id.btn_deals
            )
            
            // Define slot mappings for second row (4 slots)
            val secondRowSlots = listOf(
                R.id.btn_chats,
                R.id.btn_warehouse,
                R.id.btn_orders,
                R.id.btn_online_store
            )
            
            // Get icon and label IDs for each slot
            val slotIconIds = listOf(
                R.id.icon_dashboard, R.id.icon_tasks, R.id.icon_leads, R.id.icon_deals,
                R.id.icon_chats, R.id.icon_warehouse, R.id.icon_orders, R.id.icon_online_store
            )
            
            val slotLabelIds = listOf(
                R.id.label_dashboard, R.id.label_tasks, R.id.label_leads, R.id.label_deals,
                R.id.label_chats, R.id.label_warehouse, R.id.label_orders, R.id.label_online_store
            )
            
            // Mapping of button keys to label text (Russian labels from XML)
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
            
            // Assign visible buttons to slots
            for (i in 0 until 8) {
                val slotContainer = if (i < 4) firstRowSlots[i] else secondRowSlots[i - 4]
                val slotIcon = slotIconIds[i]
                val slotLabel = slotLabelIds[i]
                
                if (i < visibleButtons.size) {
                    // Assign visible button to this slot
                    val button = visibleButtons[i]
                    
                    // Find original index of button in allButtons list for unique requestCode
                    val originalButtonIndex = allButtons.indexOfFirst { it.key == button.key }
                    
                    // Show the slot container
                    views.setViewVisibility(slotContainer, View.VISIBLE)
                    
                    // Set icon programmatically
                    views.setImageViewResource(slotIcon, button.drawableId)
                    
                    // Set label text
                    val labelText = labelTextMap[button.key] ?: button.key
                    views.setTextViewText(slotLabel, labelText)
                    
                    // Create click intent with screen identifier
                    val intent = Intent(context, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        // FLAG_ACTIVITY_NEW_TASK: needed for widget clicks (creates new task if app not running)
                        // FLAG_ACTIVITY_SINGLE_TOP: ensures onNewIntent is called if activity is already on top (singleTop launch mode)
                        // FLAG_ACTIVITY_CLEAR_TOP: clears activities on top of the target
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                                Intent.FLAG_ACTIVITY_SINGLE_TOP or 
                                Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("screen_identifier", button.key)
                    }
                    
                    Log.d("ShamCRMWidget", "Assigned button ${button.key} to slot $i (original index: $originalButtonIndex)")
                    
                    // Use original button index for unique requestCode (not slot index)
                    val requestCode = appWidgetId * 100 + originalButtonIndex
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        requestCode,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    
                    views.setOnClickPendingIntent(slotContainer, pendingIntent)
                } else {
                    // Hide unused slot
                    views.setViewVisibility(slotContainer, View.GONE)
                }
            }
            
            // Hide second row if 4 or fewer buttons visible
            if (visibleButtons.size <= 4) {
                views.setViewVisibility(R.id.second_row_layout, View.GONE)
            } else {
                views.setViewVisibility(R.id.second_row_layout, View.VISIBLE)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d("ShamCRMWidget", "Widget updated — ID=$appWidgetId, visible buttons: ${visibleButtons.size}")
        } catch (e: Exception) {
            Log.e("ShamCRMWidget", "Error updating widget: ${e.message}", e)
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
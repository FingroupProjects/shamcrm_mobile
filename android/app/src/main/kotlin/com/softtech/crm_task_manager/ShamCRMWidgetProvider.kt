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
                WidgetButton("chats", R.id.btn_chats, R.id.icon_chats, R.drawable.ic_chats)
            )
            
            var visibleCount = 0
            
            for ((index, button) in allButtons.withIndex()) {
                val isVisible = visibility[button.key] ?: true
                
                if (isVisible) {
                    // Show button
                    views.setViewVisibility(button.containerId, View.VISIBLE)
                    
                    // Set icon
                    views.setImageViewResource(button.iconId, button.drawableId)
                    
                    // Create click intent with screen identifier (not index)
                    val intent = Intent(context, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("screen_identifier", button.key)
                    }
                    
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        appWidgetId * 10 + index, // Use fixed index for unique request codes
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    
                    views.setOnClickPendingIntent(button.containerId, pendingIntent)
                    visibleCount++
                } else {
                    // Hide button
                    views.setViewVisibility(button.containerId, View.GONE)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d("ShamCRMWidget", "Widget updated — ID=$appWidgetId, visible buttons: $visibleCount")
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
        
        val keys = listOf("dashboard", "tasks", "leads", "deals", "chats")
        val visibility = mutableMapOf<String, Boolean>()
        
        for (key in keys) {
            // Flutter SharedPreferences prefixes keys with "flutter."
            val flutterKey = "flutter.widget_show_$key"
            
            // Default to true if not set (show all buttons by default)
            visibility[key] = prefs.getBoolean(flutterKey, true)
        }
        
        Log.d("ShamCRMWidget", "Visibility flags: $visibility")
        return visibility
    }
}
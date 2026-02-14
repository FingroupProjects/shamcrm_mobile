package com.softtech.crm_task_manager

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

class ReferencesWidgetProvider : AppWidgetProvider() {
    
    // Button configuration: key (screen identifier), drawable resource, permission required
    private data class ReferencesButton(
        val key: String,
        val drawableId: Int,
        val permission: String
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
            // Read permissions from Flutter's SharedPreferences
            val permissions = getPermissions(context)
            
            // Define all 8 reference buttons
            val allButtons = listOf(
                ReferencesButton("reference_warehouse", R.drawable.boxes, "storage.read"),
                ReferencesButton("reference_supplier", R.drawable.supplier, "supplier.read"),
                ReferencesButton("reference_product", R.drawable.box, "product.read"),
                ReferencesButton("reference_category", R.drawable.categories, "category.read"),
                ReferencesButton("reference_openings", R.drawable.conclusion, "initial_balance.read"),
                ReferencesButton("reference_cash_desk", R.drawable.cash_register, "cash_register.read"),
                ReferencesButton("reference_expense_article", R.drawable.downtrend, "rko_article.read"),
                ReferencesButton("reference_income_article", R.drawable.trend, "pko_article.read")
            )
            
            // Filter visible buttons based on permissions
            val visibleButtons = allButtons.filter { button ->
                permissions.contains(button.permission)
            }
            
            // Choose layout based on visible button count
            val isCompact = visibleButtons.size <= 4
            val layoutId = if (isCompact) {
                R.layout.references_widget_compact
            } else {
                R.layout.references_widget
            }
            
            Log.d("ReferencesWidget", "Using ${if (isCompact) "COMPACT" else "FULL"} layout for ${visibleButtons.size} buttons")
            
            val views = RemoteViews(context.packageName, layoutId)

            // Root click opens references screen
            val rootIntent = createLaunchIntent(context, "references")
            val rootPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId * 1000,
                rootIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, rootPendingIntent)
            
            // Use Russian labels directly (hardcoded)
            val labelTextMap = mapOf(
                "reference_warehouse" to "Склад",
                "reference_supplier" to "Поставщик",
                "reference_product" to "Товар",
                "reference_category" to "Категории",
                "reference_openings" to "Первоначальный остаток",
                "reference_cash_desk" to "Касса",
                "reference_expense_article" to "Статья расхода",
                "reference_income_article" to "Статья дохода"
            )
            
            // Widget title removed - no longer needed
            
            if (visibleButtons.isEmpty()) {
                // No permissions - show login prompt
                views.setViewVisibility(R.id.empty_state, View.VISIBLE)
                views.setViewVisibility(R.id.first_row_layout, View.GONE)
                views.setViewVisibility(R.id.second_row_layout, View.GONE)
                
                views.setTextViewText(R.id.empty_state_text, "Войдите в приложение")
            } else {
                views.setViewVisibility(R.id.empty_state, View.GONE)
                
                if (isCompact) {
                    // Compact layout: single row with 4 slots
                    val compactSlots = listOf(
                        Triple(R.id.btn_reference_warehouse, R.id.icon_reference_warehouse, R.id.label_reference_warehouse),
                        Triple(R.id.btn_reference_supplier, R.id.icon_reference_supplier, R.id.label_reference_supplier),
                        Triple(R.id.btn_reference_product, R.id.icon_reference_product, R.id.label_reference_product),
                        Triple(R.id.btn_reference_category, R.id.icon_reference_category, R.id.label_reference_category)
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
                            
                            Log.d("ReferencesWidget", "Compact: Assigned ${button.key} to slot $i")
                        } else {
                            views.setViewVisibility(containerId, View.INVISIBLE)
                        }
                    }
                    
                    views.setViewVisibility(R.id.first_row_layout, View.VISIBLE)
                    views.setViewVisibility(R.id.second_row_layout, View.GONE)
                } else {
                    // Full layout: two rows with 8 slots total
                    val fullSlots = listOf(
                        // First row
                        Triple(R.id.btn_reference_warehouse, R.id.icon_reference_warehouse, R.id.label_reference_warehouse),
                        Triple(R.id.btn_reference_supplier, R.id.icon_reference_supplier, R.id.label_reference_supplier),
                        Triple(R.id.btn_reference_product, R.id.icon_reference_product, R.id.label_reference_product),
                        Triple(R.id.btn_reference_category, R.id.icon_reference_category, R.id.label_reference_category),
                        // Second row
                        Triple(R.id.btn_reference_openings, R.id.icon_reference_openings, R.id.label_reference_openings),
                        Triple(R.id.btn_reference_cash_desk, R.id.icon_reference_cash_desk, R.id.label_reference_cash_desk),
                        Triple(R.id.btn_reference_expense_article, R.id.icon_reference_expense_article, R.id.label_reference_expense_article),
                        Triple(R.id.btn_reference_income_article, R.id.icon_reference_income_article, R.id.label_reference_income_article)
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
                            
                            Log.d("ReferencesWidget", "Full: Assigned ${button.key} to slot $i")
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
                    
                    views.setViewVisibility(R.id.first_row_layout, View.VISIBLE)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d("ReferencesWidget", "Widget updated — ID=$appWidgetId, visible buttons: ${visibleButtons.size}, layout: ${if (isCompact) "compact" else "full"}")
        } catch (e: Exception) {
            Log.e("ReferencesWidget", "Error updating widget: ${e.message}", e)
        }
    }
    
    private fun createLaunchIntent(context: Context, screenKey: String?): Intent {
        return Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (!screenKey.isNullOrEmpty()) {
                putExtra("screen_identifier", screenKey)
            } else {
                removeExtra("screen_identifier")
            }
        }
    }
    
    /**
     * Read permissions from Flutter's SharedPreferences.
     * Flutter SharedPreferences on Android uses file "FlutterSharedPreferences"
     * and keys are prefixed with "flutter."
     * Permissions are stored as JSON array string.
     */
    private fun getPermissions(context: Context): List<String> {
        Log.d("ReferencesWidget", "========== getPermissions() START ==========")
        
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        
        // Debug: Print all keys in SharedPreferences
        val allKeys = prefs.all.keys
        Log.d("ReferencesWidget", "All SharedPreferences keys count: ${allKeys.size}")
        Log.d("ReferencesWidget", "All keys: $allKeys")
        
        // Flutter SharedPreferences prefixes keys with "flutter."
        val flutterKey = "flutter.user_permissions"
        Log.d("ReferencesWidget", "Looking for key: '$flutterKey'")
        
        val permissionsJson = prefs.getString(flutterKey, null)
        
        Log.d("ReferencesWidget", "Raw permissions JSON: $permissionsJson")
        Log.d("ReferencesWidget", "JSON is null: ${permissionsJson == null}")
        Log.d("ReferencesWidget", "JSON is empty: ${permissionsJson?.isEmpty()}")
        
        if (permissionsJson == null || permissionsJson.isEmpty()) {
            Log.d("ReferencesWidget", "No permissions found in SharedPreferences")
            Log.d("ReferencesWidget", "========== getPermissions() END (empty) ==========")
            return emptyList()
        }

        try {
            val jsonArray = JSONArray(permissionsJson)
            Log.d("ReferencesWidget", "JSON array length: ${jsonArray.length()}")
            
            val permissions = mutableListOf<String>()
            for (i in 0 until jsonArray.length()) {
                val permission = jsonArray.getString(i)
                permissions.add(permission)
                Log.d("ReferencesWidget", "Permission [$i]: $permission")
            }
            
            Log.d("ReferencesWidget", "Loaded ${permissions.size} permissions: $permissions")
            Log.d("ReferencesWidget", "========== getPermissions() END (success) ==========")
            return permissions
        } catch (e: Exception) {
            Log.e("ReferencesWidget", "Error parsing permissions JSON: ${e.message}", e)
            Log.e("ReferencesWidget", "Stack trace: ${e.stackTraceToString()}")
            Log.d("ReferencesWidget", "========== getPermissions() END (error) ==========")
            return emptyList()
        }
    }
}

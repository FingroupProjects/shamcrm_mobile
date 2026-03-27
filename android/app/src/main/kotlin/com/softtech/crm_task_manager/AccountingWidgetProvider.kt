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

class AccountingWidgetProvider : AppWidgetProvider() {
    
    // Button configuration: key (screen identifier), drawable resource, permission required
    private data class AccountingButton(
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
            
            // Define all 8 accounting buttons
            // Note: Using simple icons that are available in all Android versions
            // For better icons, consider adding custom drawable resources later
            val allButtons = listOf(
                AccountingButton("client_sale", R.drawable.ic_shop, "expense_document.read"),
                AccountingButton("client_return", R.drawable.ic_return, "client_return_document.read"),
                AccountingButton("income_goods", R.drawable.ic_goods_income, "income_document.read"),
                AccountingButton("transfer", R.drawable.ic_transfer, "movement_document.read"),
                AccountingButton("write_off", R.drawable.ic_box_return, "write_off_document.read"),
                AccountingButton("supplier_return", R.drawable.ic_supplier_return, "supplier_return_document.read"),
                AccountingButton("money_income", R.drawable.ic_money_income, "checking_account_pko.read"),
                AccountingButton("money_outcome", R.drawable.ic_money_outcome, "checking_account_rko.read")
            )
            
            // Filter visible buttons based on permissions
            val visibleButtons = allButtons.filter { button ->
                permissions.contains(button.permission)
            }
            
            // Choose layout based on visible button count
            val isCompact = visibleButtons.size <= 4
            val layoutId = if (isCompact) {
                R.layout.accounting_widget_compact
            } else {
                R.layout.accounting_widget
            }
            
            Log.d("AccountingWidget", "Using ${if (isCompact) "COMPACT" else "FULL"} layout for ${visibleButtons.size} buttons")
            
            val views = RemoteViews(context.packageName, layoutId)

            // Root click opens warehouse screen
            val rootIntent = createLaunchIntent(context, "warehouse")
            val rootPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId * 1000,
                rootIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, rootPendingIntent)
            
            // Use Russian labels directly (hardcoded)
            val labelTextMap = mapOf(
                "client_sale" to "Продажа",
                "client_return" to "Возврат от клиента",
                "income_goods" to "Приход товаров",
                "transfer" to "Перемещение",
                "write_off" to "Списание",
                "supplier_return" to "Возврат поставщику",
                "money_income" to "Приход денег",
                "money_outcome" to "Расход денег"
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
                        Triple(R.id.btn_client_sale, R.id.icon_client_sale, R.id.label_client_sale),
                        Triple(R.id.btn_client_return, R.id.icon_client_return, R.id.label_client_return),
                        Triple(R.id.btn_income_goods, R.id.icon_income_goods, R.id.label_income_goods),
                        Triple(R.id.btn_transfer, R.id.icon_transfer, R.id.label_transfer)
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
                            
                            Log.d("AccountingWidget", "Compact: Assigned ${button.key} to slot $i")
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
                        Triple(R.id.btn_client_sale, R.id.icon_client_sale, R.id.label_client_sale),
                        Triple(R.id.btn_client_return, R.id.icon_client_return, R.id.label_client_return),
                        Triple(R.id.btn_income_goods, R.id.icon_income_goods, R.id.label_income_goods),
                        Triple(R.id.btn_transfer, R.id.icon_transfer, R.id.label_transfer),
                        // Second row
                        Triple(R.id.btn_write_off, R.id.icon_write_off, R.id.label_write_off),
                        Triple(R.id.btn_supplier_return, R.id.icon_supplier_return, R.id.label_supplier_return),
                        Triple(R.id.btn_money_income, R.id.icon_money_income, R.id.label_money_income),
                        Triple(R.id.btn_money_outcome, R.id.icon_money_outcome, R.id.label_money_outcome)
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
                            
                            Log.d("AccountingWidget", "Full: Assigned ${button.key} to slot $i")
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
            Log.d("AccountingWidget", "Widget updated — ID=$appWidgetId, visible buttons: ${visibleButtons.size}, layout: ${if (isCompact) "compact" else "full"}")
        } catch (e: Exception) {
            Log.e("AccountingWidget", "Error updating widget: ${e.message}", e)
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
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        
        // Flutter SharedPreferences prefixes keys with "flutter."
        val flutterKey = "flutter.user_permissions"
        val permissionsJson = prefs.getString(flutterKey, null)
        
        if (permissionsJson == null || permissionsJson.isEmpty()) {
            Log.d("AccountingWidget", "No permissions found in SharedPreferences")
            return emptyList()
        }
        
        try {
            val jsonArray = JSONArray(permissionsJson)
            val permissions = mutableListOf<String>()
            for (i in 0 until jsonArray.length()) {
                permissions.add(jsonArray.getString(i))
            }
            Log.d("AccountingWidget", "Loaded ${permissions.size} permissions: $permissions")
            return permissions
        } catch (e: Exception) {
            Log.e("AccountingWidget", "Error parsing permissions JSON: ${e.message}", e)
            return emptyList()
        }
    }
    
}


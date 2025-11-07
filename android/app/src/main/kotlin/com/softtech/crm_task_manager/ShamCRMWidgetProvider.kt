package com.softtech.crm_task_manager

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews

class ShamCRMWidgetProvider : AppWidgetProvider() {

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
        val views = RemoteViews(context.packageName, R.layout.sham_crm_widget)

        // Контейнеры (для клика)
        val buttonContainers = intArrayOf(
            R.id.btn_dashboard,
            R.id.btn_tasks,
            R.id.btn_leads,
            R.id.btn_deals,
            R.id.btn_chats
        )

        // Иконки (для установки)
        val iconIds = intArrayOf(
            R.id.icon_dashboard,
            R.id.icon_tasks,
            R.id.icon_leads,
            R.id.icon_deals,
            R.id.icon_chats
        )

        // Ресурсы иконок
        val drawableIcons = intArrayOf(
            R.drawable.ic_dashboard,
            R.drawable.ic_tasks,
            R.drawable.ic_leads,
            R.drawable.ic_deals,
            R.drawable.ic_chats
        )

        repeat(5) { index ->
            // Интент
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("group_index", 1)
                putExtra("screen_index", index) // 0=Dashboard, 1=Tasks, 2=Leads, 3=Deals, 4=Chats
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId * 10 + index,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Устанавливаем иконку по ID
            views.setImageViewResource(iconIds[index], drawableIcons[index])

            // Клик по всему блоку
            views.setOnClickPendingIntent(buttonContainers[index], pendingIntent)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
        Log.d("ShamCRMWidget", "Виджет обновлён — ID=$appWidgetId")
    }
}
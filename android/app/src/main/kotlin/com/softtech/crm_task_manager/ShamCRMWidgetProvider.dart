// package com.softtech.crm_task_manager

// import android.appwidget.AppWidgetManager
// import android.appwidget.AppWidgetProvider
// import android.content.Context
// import android.content.Intent
// import android.net.Uri
// import android.widget.RemoteViews
// import android.app.PendingIntent

// class ShamCRMWidgetProvider : AppWidgetProvider() {

//     override fun onUpdate(
//         context: Context,
//         appWidgetManager: AppWidgetManager,
//         appWidgetIds: IntArray
//     ) {
//         for (appWidgetId in appWidgetIds) {
//             updateAppWidget(context, appWidgetManager, appWidgetId)
//         }
//     }

//     private fun updateAppWidget(
//         context: Context,
//         appWidgetManager: AppWidgetManager,
//         appWidgetId: Int
//     ) {
//         val views = RemoteViews(context.packageName, R.layout.sham_crm_widget)

//         // Получаем данные из SharedPreferences
//         val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
//         val companyName = prefs.getString("company_name", "shamCRM") ?: "shamCRM"
//         val tasksCount = prefs.getInt("tasks_count", 0)
//         val leadsCount = prefs.getInt("leads_count", 0)
//         val dealsCount = prefs.getInt("deals_count", 0)
//         val messagesCount = prefs.getInt("messages_count", 0)

//         // Обновляем UI
//         views.setTextViewText(R.id.widget_company_name, companyName)
        
//         if (tasksCount > 0) {
//             views.setTextViewText(R.id.txt_tasks_count, "Задачи ($tasksCount)")
//         } else {
//             views.setTextViewText(R.id.txt_tasks_count, "Задачи")
//         }
        
//         if (leadsCount > 0) {
//             views.setTextViewText(R.id.txt_leads_count, "Лиды ($leadsCount)")
//         } else {
//             views.setTextViewText(R.id.txt_leads_count, "Лиды")
//         }
        
//         if (dealsCount > 0) {
//             views.setTextViewText(R.id.txt_deals_count, "Сделки ($dealsCount)")
//         } else {
//             views.setTextViewText(R.id.txt_deals_count, "Сделки")
//         }
        
//         if (messagesCount > 0) {
//             views.setTextViewText(R.id.txt_chats_count, "Чаты ($messagesCount)")
//         } else {
//             views.setTextViewText(R.id.txt_chats_count, "Чаты")
//         }

//         // Настраиваем клики
//         setClickIntent(context, views, R.id.btn_dashboard, "dashboard")
//         setClickIntent(context, views, R.id.btn_tasks, "tasks")
//         setClickIntent(context, views, R.id.btn_leads, "leads")
//         setClickIntent(context, views, R.id.btn_deals, "deals")
//         setClickIntent(context, views, R.id.btn_chats, "chats")
//         setClickIntent(context, views, R.id.btn_warehouse, "warehouse")

//         appWidgetManager.updateAppWidget(appWidgetId, views)
//     }

//     private fun setClickIntent(
//         context: Context,
//         views: RemoteViews,
//         viewId: Int,
//         section: String
//     ) {
//         val intent = Intent(context, MainActivity::class.java).apply {
//             action = Intent.ACTION_VIEW
//             data = Uri.parse("shamcrm://$section")
//             flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
//         }
        
//         val pendingIntent = PendingIntent.getActivity(
//             context,
//             viewId, // Уникальный request code для каждой кнопки
//             intent,
//             PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
//         )
        
//         views.setOnClickPendingIntent(viewId, pendingIntent)
//     }

//     override fun onEnabled(context: Context) {
//         // Виджет добавлен впервые
//     }

//     override fun onDisabled(context: Context) {
//         // Все виджеты удалены
//     }
// }
package com.softtech.crm_task_manager

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import kotlin.math.abs

object CrmPushNotificationManager {
    private const val CHANNEL_ID = "shamcrm_crm_pushes"
    private const val CHANNEL_NAME = "Уведомления shamCRM"

    fun show(
        context: Context,
        title: String?,
        body: String?,
        type: String?,
        id: String?,
    ) {
        val contentTitle = title?.trim().orEmpty().ifEmpty { "shamCRM" }
        val contentBody = body?.trim().orEmpty().ifEmpty { return }
        ensureChannel(context)

        val notificationId = notificationIdFor(type, id, contentTitle, contentBody)
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (!type.isNullOrBlank()) {
                putExtra("type", type)
            }
            if (!id.isNullOrBlank()) {
                putExtra("id", id)
            }
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        val contentIntent = PendingIntent.getActivity(
            context,
            notificationId,
            openIntent,
            flags,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(contentTitle)
            .setContentText(contentBody)
            .setStyle(NotificationCompat.BigTextStyle().bigText(contentBody))
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(notificationId, notification)
    }

    private fun notificationIdFor(
        type: String?,
        id: String?,
        title: String,
        body: String,
    ): Int {
        val key = listOf(type.orEmpty(), id.orEmpty(), title, body).joinToString("|")
        return 84000 + abs(key.hashCode() % 100000)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Пуши CRM, пока приложение открыто"
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)
    }
}

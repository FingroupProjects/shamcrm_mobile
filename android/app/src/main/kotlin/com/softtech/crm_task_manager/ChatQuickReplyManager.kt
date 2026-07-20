package com.softtech.crm_task_manager

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread
import kotlin.math.abs

object ChatQuickReplyManager {
    const val ACTION_REPLY = "com.softtech.crm_task_manager.CHAT_REPLY"
    const val EXTRA_CHAT_ID = "chat_id"
    const val EXTRA_NOTIFICATION_ID = "notification_id"
    const val KEY_TEXT_REPLY = "chat_reply_text"

    private const val TAG = "ChatQuickReply"
    private const val CHANNEL_ID = "chat_messages"
    private const val CHANNEL_NAME = "Сообщения чата"
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"

    fun isChatMessagePush(data: Map<String, String>): Boolean {
        val type = pick(data, "type", "event")?.lowercase()
        val chatId = resolveChatId(data)
        return type == "message" && !chatId.isNullOrBlank()
    }

    fun showNotification(context: Context, data: Map<String, String>) {
        val chatId = resolveChatId(data) ?: return
        val notificationId = notificationIdFor(chatId, pick(data, "message_id", "messageId"))
        val title = pick(data, "sender_name", "senderName", "title", "gcm.n.title")
            ?: "Новое сообщение"
        val body = pick(data, "message_text", "messageText", "body", "gcm.n.body")
            ?: "Сообщение"

        ensureChannel(context)

        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("type", "message")
            putExtra("id", chatId)
            putExtra("chat_id", chatId)
            putExtra("chat_unique_id", pick(data, "chat_unique_id", "chatUniqueId"))
            putExtra("chat_type", pick(data, "chat_type", "chatType"))
            putExtra("sender_name", title)
            putExtra("message_text", body)
        }
        val openPendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            openIntent,
            pendingIntentFlags(mutable = false),
        )

        val replyIntent = Intent(context, ChatQuickReplyReceiver::class.java).apply {
            action = ACTION_REPLY
            putExtra(EXTRA_CHAT_ID, chatId)
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        }
        val replyPendingIntent = PendingIntent.getBroadcast(
            context,
            notificationId,
            replyIntent,
            pendingIntentFlags(mutable = true),
        )

        val remoteInput = RemoteInput.Builder(KEY_TEXT_REPLY)
            .setLabel("Ответить")
            .build()
        val replyAction = NotificationCompat.Action.Builder(
            android.R.drawable.ic_menu_send,
            "Ответить",
            replyPendingIntent,
        ).addRemoteInput(remoteInput).setAllowGeneratedReplies(true).build()

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(openPendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .addAction(replyAction)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(notificationId, notification)
    }

    fun sendReplyAsync(receiver: android.content.BroadcastReceiver, context: Context, intent: Intent) {
        val results = RemoteInput.getResultsFromIntent(intent)
        val replyText = results?.getCharSequence(KEY_TEXT_REPLY)?.toString()?.trim().orEmpty()
        val chatId = intent.getStringExtra(EXTRA_CHAT_ID).orEmpty()
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, notificationIdFor(chatId, null))

        if (replyText.isBlank() || chatId.isBlank()) {
            return
        }

        showSendingState(context, notificationId)
        val pendingResult = receiver.goAsync()
        thread(name = "chat-quick-reply-send") {
            val sent = runCatching { sendMessage(context.applicationContext, chatId, replyText) }
                .onFailure { Log.e(TAG, "Reply send failed", it) }
                .isSuccess

            if (sent) {
                showSentState(context.applicationContext, notificationId)
            } else {
                showFailedState(context.applicationContext, notificationId, chatId)
            }
            pendingResult.finish()
        }
    }

    private fun sendMessage(context: Context, chatId: String, message: String) {
        val baseUrl = resolveBaseUrl(context)
            ?: throw IllegalStateException("Base URL is not available")
        val token = readPref(context, "token")
            ?: throw IllegalStateException("Auth token is not available")
        val query = buildQuery(context)
        val url = URL("$baseUrl/v2/chat/sendMessage/$chatId$query")
        val body = JSONObject().put("message", message).toString()

        val connection = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = 15000
            readTimeout = 20000
            doOutput = true
            setRequestProperty("Content-Type", "application/json")
            setRequestProperty("Accept", "application/json")
            setRequestProperty("Authorization", "Bearer $token")
            setRequestProperty("Device", "mobile")
        }

        OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { writer ->
            writer.write(body)
        }

        val statusCode = connection.responseCode
        connection.disconnect()
        if (statusCode !in 200..299) {
            throw IllegalStateException("Unexpected status: $statusCode")
        }
    }

    private fun resolveBaseUrl(context: Context): String? {
        val verifiedDomain = readPref(context, "verifiedDomain")
        if (!verifiedDomain.isNullOrBlank() && verifiedDomain != "null") {
            return "https://$verifiedDomain/api"
        }

        val domain = readPref(context, "domain")
        val mainDomain = readPref(context, "mainDomain")
        if (!domain.isNullOrBlank() && !mainDomain.isNullOrBlank()) {
            return "https://$domain-back.$mainDomain/api"
        }

        val enteredDomain = readPref(context, "enteredDomain")
        val enteredMainDomain = readPref(context, "enteredMainDomain")
        if (!enteredDomain.isNullOrBlank() && !enteredMainDomain.isNullOrBlank()) {
            val hostPrefix = if (enteredDomain.endsWith("-back")) enteredDomain else "$enteredDomain-back"
            return "https://$hostPrefix.$enteredMainDomain/api"
        }

        return null
    }

    private fun buildQuery(context: Context): String {
        val params = linkedMapOf<String, String>()
        val organizationId = readPref(context, "selectedOrganization")
        val salesFunnelId = readPref(context, "selected_sales_funnel")

        if (!organizationId.isNullOrBlank() && organizationId != "null") {
            params["organization_id"] = organizationId
        }
        if (!salesFunnelId.isNullOrBlank() && salesFunnelId != "null") {
            params["sales_funnel_id"] = salesFunnelId
        }

        if (params.isEmpty()) return ""
        return params.entries.joinToString(prefix = "?", separator = "&") { (key, value) ->
            "${java.net.URLEncoder.encode(key, "UTF-8")}=${java.net.URLEncoder.encode(value, "UTF-8")}"
        }
    }

    private fun readPref(context: Context, key: String): String? {
        val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val raw = flutterPrefs.getString("flutter.$key", null)
            ?: flutterPrefs.getString(key, null)
        if (!raw.isNullOrBlank()) return raw

        val defaultPrefs = android.preference.PreferenceManager.getDefaultSharedPreferences(context)
        return defaultPrefs.getString("flutter.$key", null)
            ?: defaultPrefs.getString(key, null)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Уведомления о новых сообщениях чата"
        }
        manager.createNotificationChannel(channel)
    }

    private fun showSendingState(context: Context, notificationId: Int) {
        ensureChannel(context)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle("Отправляем ответ...")
            .setOngoing(true)
            .setProgress(0, 0, true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .notify(notificationId, notification)
    }

    private fun showSentState(context: Context, notificationId: Int) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(notificationId)
    }

    private fun showFailedState(context: Context, notificationId: Int, chatId: String) {
        ensureChannel(context)
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("type", "message")
            putExtra("id", chatId)
        }
        val openPendingIntent = PendingIntent.getActivity(
            context,
            notificationId + 1,
            openIntent,
            pendingIntentFlags(mutable = false),
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle("Ответ не отправлен")
            .setContentText("Откройте чат и попробуйте ещё раз")
            .setContentIntent(openPendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .notify(notificationId, notification)
    }

    private fun resolveChatId(data: Map<String, String>): String? =
        pick(data, "chat_id", "chatId", "id")

    private fun pick(data: Map<String, String>, vararg keys: String): String? {
        for (key in keys) {
            val value = data[key]?.trim()
            if (!value.isNullOrEmpty() && !value.equals("null", ignoreCase = true)) {
                return value
            }
        }
        return null
    }

    private fun notificationIdFor(chatId: String, messageId: String?): Int {
        val seed = "${chatId}_${messageId.orEmpty()}".hashCode()
        return abs(seed.takeIf { it != Int.MIN_VALUE } ?: 1)
    }

    private fun pendingIntentFlags(mutable: Boolean): Int {
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or if (mutable) PendingIntent.FLAG_MUTABLE else PendingIntent.FLAG_IMMUTABLE
        }
        return flags
    }
}

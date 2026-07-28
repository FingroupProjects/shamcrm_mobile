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
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread
import kotlin.math.abs

object ChatQuickReplyManager {
    const val ACTION_REPLY = "com.softtech.crm_task_manager.CHAT_REPLY"
    const val ACTION_MARK_READ = "com.softtech.crm_task_manager.CHAT_MARK_READ"
    const val EXTRA_CHAT_ID = "chat_id"
    const val EXTRA_MESSAGE_ID = "message_id"
    const val EXTRA_NOTIFICATION_ID = "notification_id"
    const val KEY_TEXT_REPLY = "chat_reply_text"

    private const val TAG = "ChatQuickReply"
    private const val CHANNEL_ID = "chat_messages"
    private const val CHANNEL_NAME = "Сообщения чата"
    private const val CHAT_HISTORY_PREFS = "chat_notification_history"
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val MAX_HISTORY_MESSAGES = 5

    fun isChatMessagePush(data: Map<String, String>): Boolean {
        val type = pick(data, "type", "event")?.lowercase()
        val explicitChatId = pick(data, "chat_id", "chatId")
        val chatId = resolveChatId(data)
        val hasMessagePayload = !pick(
            data,
            "message_id",
            "messageId",
            "message_text",
            "messageText",
            "sender_name",
            "senderName",
        ).isNullOrBlank()
        val isMessageType = type == "message" || type == "chat_message" || type == "new_message"

        return !chatId.isNullOrBlank() && (isMessageType || (!explicitChatId.isNullOrBlank() && hasMessagePayload))
    }

    fun showNotification(context: Context, data: Map<String, String>) {
        val chatId = resolveChatId(data) ?: return
        val messageId = resolveMessageId(data)
        val notificationId = notificationIdFor(chatId)
        val title = pick(data, "sender_name", "senderName", "title", "gcm.n.title")
            ?: "Новое сообщение"
        val body = pick(data, "message_text", "messageText", "body", "gcm.n.body")
            ?: "Сообщение"
        val history = appendHistory(context, chatId, title, body, messageId)
        val contentTitle = if (history.size > 1) "$title (${history.size})" else title

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

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(contentTitle)
            .setContentText(body)
            .setStyle(buildInboxStyle(contentTitle, history))
            .setContentIntent(openPendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setGroup("chat_$chatId")
            .setShortcutId("chat_$chatId")
            .setNumber(history.size)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .addAction(replyAction)

        if (!messageId.isNullOrBlank()) {
            val markReadIntent = Intent(context, ChatQuickReplyReceiver::class.java).apply {
                action = ACTION_MARK_READ
                putExtra(EXTRA_CHAT_ID, chatId)
                putExtra(EXTRA_MESSAGE_ID, messageId)
                putExtra(EXTRA_NOTIFICATION_ID, notificationId)
            }
            val markReadPendingIntent = PendingIntent.getBroadcast(
                context,
                notificationId + 10_000,
                markReadIntent,
                pendingIntentFlags(mutable = false),
            )
            val markReadAction = NotificationCompat.Action.Builder(
                android.R.drawable.ic_menu_agenda,
                "Пометить прочитанным",
                markReadPendingIntent,
            ).build()
            builder.addAction(markReadAction)
        }

        val notification = builder.build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(notificationId, notification)
    }

    fun sendReplyAsync(receiver: android.content.BroadcastReceiver, context: Context, intent: Intent) {
        val results = RemoteInput.getResultsFromIntent(intent)
        val replyText = results?.getCharSequence(KEY_TEXT_REPLY)?.toString()?.trim().orEmpty()
        val chatId = intent.getStringExtra(EXTRA_CHAT_ID).orEmpty()
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, notificationIdFor(chatId))

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
                clearChatNotification(context.applicationContext, chatId, notificationId)
            } else {
                showFailedState(context.applicationContext, notificationId, chatId)
            }
            pendingResult.finish()
        }
    }

    fun markReadAsync(receiver: android.content.BroadcastReceiver, context: Context, intent: Intent) {
        val chatId = intent.getStringExtra(EXTRA_CHAT_ID).orEmpty()
        val messageId = intent.getStringExtra(EXTRA_MESSAGE_ID).orEmpty()
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, notificationIdFor(chatId))

        if (chatId.isBlank() || messageId.isBlank()) {
            return
        }

        val pendingResult = receiver.goAsync()
        thread(name = "chat-mark-read") {
            val marked = runCatching { markMessagesRead(context.applicationContext, chatId, messageId) }
                .onFailure { Log.e(TAG, "Mark read failed", it) }
                .isSuccess

            if (marked) {
                clearChatNotification(context.applicationContext, chatId, notificationId)
            } else {
                showMarkReadFailedState(context.applicationContext, notificationId, chatId)
            }
            pendingResult.finish()
        }
    }

    private fun sendMessage(context: Context, chatId: String, message: String) {
        postJson(
            context = context,
            path = "/v2/chat/sendMessage/$chatId",
            body = JSONObject().put("message", message),
        )
    }

    private fun markMessagesRead(context: Context, chatId: String, messageId: String) {
        val parsedMessageId = messageId.toLongOrNull() ?: messageId
        postJson(
            context = context,
            path = "/v2/chat/readMessages/$chatId",
            body = JSONObject().put("up_to_message_id", parsedMessageId),
        )
    }

    private fun postJson(context: Context, path: String, body: JSONObject) {
        val baseUrl = resolveBaseUrl(context)
            ?: throw IllegalStateException("Base URL is not available")
        val token = readPref(context, "token")
            ?: throw IllegalStateException("Auth token is not available")
        val query = buildQuery(context)
        val url = URL("$baseUrl$path$query")

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
            writer.write(body.toString())
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

    private fun clearChatNotification(context: Context, chatId: String, notificationId: Int) {
        clearHistory(context, chatId)
        showSentState(context, notificationId)
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

    private fun showMarkReadFailedState(context: Context, notificationId: Int, chatId: String) {
        ensureChannel(context)
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("type", "message")
            putExtra("id", chatId)
        }
        val openPendingIntent = PendingIntent.getActivity(
            context,
            notificationId + 2,
            openIntent,
            pendingIntentFlags(mutable = false),
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle("Не удалось отметить прочитанным")
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

    private fun resolveMessageId(data: Map<String, String>): String? =
        pick(data, "message_id", "messageId", "notification_message_id", "up_to_message_id")

    private fun buildInboxStyle(
        contentTitle: String,
        history: List<ChatNotificationMessage>,
    ): NotificationCompat.InboxStyle {
        val style = NotificationCompat.InboxStyle().setBigContentTitle(contentTitle)
        history.forEach { message ->
            val senderPrefix = if (message.sender.isNotBlank()) "${message.sender}: " else ""
            style.addLine("$senderPrefix${message.text}")
        }
        return style
    }

    private fun appendHistory(
        context: Context,
        chatId: String,
        sender: String,
        text: String,
        messageId: String?,
    ): List<ChatNotificationMessage> {
        val prefs = context.getSharedPreferences(CHAT_HISTORY_PREFS, Context.MODE_PRIVATE)
        val history = readHistory(prefs.getString(chatId, null)).toMutableList()
        if (!messageId.isNullOrBlank()) {
            history.removeAll { it.messageId == messageId }
        }
        history.add(ChatNotificationMessage(sender = sender, text = text, messageId = messageId))

        val trimmed = history.takeLast(MAX_HISTORY_MESSAGES)
        val json = JSONArray()
        trimmed.forEach { message ->
            json.put(
                JSONObject()
                    .put("sender", message.sender)
                    .put("text", message.text)
                    .put("message_id", message.messageId),
            )
        }
        prefs.edit().putString(chatId, json.toString()).apply()
        return trimmed
    }

    private fun readHistory(raw: String?): List<ChatNotificationMessage> {
        if (raw.isNullOrBlank()) return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.optJSONObject(index) ?: continue
                    val text = item.optString("text").trim()
                    if (text.isBlank()) continue
                    add(
                        ChatNotificationMessage(
                            sender = item.optString("sender").trim(),
                            text = text,
                            messageId = item.optString("message_id").trim().takeIf { it.isNotBlank() },
                        ),
                    )
                }
            }
        }.getOrDefault(emptyList())
    }

    private fun clearHistory(context: Context, chatId: String) {
        context.getSharedPreferences(CHAT_HISTORY_PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(chatId)
            .apply()
    }

    private fun pick(data: Map<String, String>, vararg keys: String): String? {
        for (key in keys) {
            val value = data[key]?.trim()
            if (!value.isNullOrEmpty() && !value.equals("null", ignoreCase = true)) {
                return value
            }
        }
        return null
    }

    private fun notificationIdFor(chatId: String): Int {
        val seed = "chat_$chatId".hashCode()
        return abs(seed.takeIf { it != Int.MIN_VALUE } ?: 1)
    }

    private fun pendingIntentFlags(mutable: Boolean): Int {
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or if (mutable) PendingIntent.FLAG_MUTABLE else PendingIntent.FLAG_IMMUTABLE
        }
        return flags
    }

    private data class ChatNotificationMessage(
        val sender: String,
        val text: String,
        val messageId: String?,
    )
}

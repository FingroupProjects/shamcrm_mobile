package com.softtech.crm_task_manager

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class NativeSipForegroundService : Service() {
    companion object {
        private const val TAG = "NativeSipFgService"
        const val ACTION_START = "com.shamcrm.native_sip.START"
        const val ACTION_RESTART = "com.shamcrm.native_sip.RESTART"
        const val ACTION_STOP = "com.shamcrm.native_sip.STOP"

        private const val CHANNEL_SERVICE_ID = "shamcrm_sip_runtime"
        private const val CHANNEL_CALLS_ID = "shamcrm_sip_calls"
        private const val NOTIFICATION_SERVICE_ID = 7301
        private const val NOTIFICATION_CALL_ID = 7302
        private const val RESTART_REQUEST_CODE = 7303

        fun start(context: Context): Boolean {
            return try {
                cancelScheduledRestart(context)
                val intent = Intent(context, NativeSipForegroundService::class.java).apply {
                    action = ACTION_START
                }
                ContextCompat.startForegroundService(context, intent)
                true
            } catch (error: Throwable) {
                Log.e(TAG, "Failed to start foreground SIP service: ${error.message}", error)
                false
            }
        }

        fun stop(context: Context) {
            cancelScheduledRestart(context)
            try {
                context.startService(
                    Intent(context, NativeSipForegroundService::class.java).apply {
                        action = ACTION_STOP
                    },
                )
            } catch (_: Throwable) {
                context.stopService(Intent(context, NativeSipForegroundService::class.java))
            }
        }

        fun scheduleRestart(context: Context, delayMs: Long = 1500L) {
            try {
                val alarmManager =
                    context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val pendingIntent = restartPendingIntent(context)
                val triggerAt = SystemClock.elapsedRealtime() + delayMs

                // На Android 12+ (API 31) нужен setExactAndAllowWhileIdle + разрешение
                // SCHEDULE_EXACT_ALARM или USE_EXACT_ALARM. Без этого Xiaomi HyperOS
                // полностью игнорирует setAndAllowWhileIdle при убитом приложении.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (alarmManager.canScheduleExactAlarms()) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.ELAPSED_REALTIME_WAKEUP,
                            triggerAt,
                            pendingIntent,
                        )
                        Log.d(TAG, "Scheduled exact SIP service restart in ${delayMs}ms")
                    } else {
                        // Нет точного разрешения — используем неточный но хотя бы что-то
                        alarmManager.setAndAllowWhileIdle(
                            AlarmManager.ELAPSED_REALTIME_WAKEUP,
                            triggerAt,
                            pendingIntent,
                        )
                        Log.w(TAG, "canScheduleExactAlarms=false, fallback to setAndAllowWhileIdle")
                    }
                } else {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        triggerAt,
                        pendingIntent,
                    )
                }
            } catch (error: Throwable) {
                Log.e(TAG, "Failed to schedule SIP service restart: ${error.message}", error)
            }
        }

        fun cancelScheduledRestart(context: Context) {
            try {
                val alarmManager =
                    context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                alarmManager.cancel(restartPendingIntent(context))
            } catch (_: Throwable) {
            }
        }

        private fun restartPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, NativeSipForegroundService::class.java).apply {
                action = ACTION_RESTART
            }

            return PendingIntent.getService(
                context,
                RESTART_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }

    private val notificationManager by lazy {
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    private val bridgeObserver: (HashMap<String, Any?>) -> Unit = { event ->
        handleBridgeEvent(event)
    }
    private var explicitStopRequested = false

    override fun onCreate() {
        super.onCreate()
        explicitStopRequested = false
        NativeSipBridge.initialize(applicationContext)
        NativeSipBridge.addObserver(bridgeObserver)
        createNotificationChannels()
        try {
            startForeground(
                NOTIFICATION_SERVICE_ID,
                buildServiceNotification(NativeSipBridge.getStateSnapshot()),
            )
        } catch (error: Throwable) {
            Log.e(TAG, "startForeground failed: ${error.message}", error)
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                explicitStopRequested = true
                cancelScheduledRestart(applicationContext)
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START, ACTION_RESTART -> {
                explicitStopRequested = false
                cancelScheduledRestart(applicationContext)
                NativeSipBridge.restoreRegistrationIfNeeded(startService = false)
                // Подтверждаем WorkManager задачу при каждом старте сервиса.
                // Система иногда вычищает WorkManager задачи — переподтверждаем.
                SipKeepAliveWorker.schedule(applicationContext)
            }
            NativeSipActionReceiver.ACTION_ANSWER -> NativeSipBridge.acceptCall()
            NativeSipActionReceiver.ACTION_DECLINE -> NativeSipBridge.declineCall()
            NativeSipActionReceiver.ACTION_HANGUP -> NativeSipBridge.hangup()
            else -> NativeSipBridge.restoreRegistrationIfNeeded(startService = false)
        }

        updateServiceNotification()
        return START_STICKY
    }

    override fun onDestroy() {
        releaseIncomingCallWakeLock()
        stopForeground(STOP_FOREGROUND_REMOVE)
        NativeSipBridge.removeObserver(bridgeObserver)
        notificationManager.cancel(NOTIFICATION_CALL_ID)
        if (!explicitStopRequested && NativeSipBridge.isPersistentEnabled()) {
            scheduleRestart(applicationContext, delayMs = 2000L)
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        if (!explicitStopRequested && NativeSipBridge.isPersistentEnabled()) {
            scheduleRestart(applicationContext, delayMs = 1000L)
        }
        super.onTaskRemoved(rootIntent)
    }

    private fun handleBridgeEvent(event: HashMap<String, Any?>) {
        if (event["type"]?.toString() == "call") {
            when (event["state"]?.toString()) {
                "incoming" -> {
                    acquireIncomingCallWakeLock()
                    showIncomingCallNotification(event)
                }
                "calling", "ringing", "in_call", "ended", "failed", "idle" -> {
                    releaseIncomingCallWakeLock()
                    notificationManager.cancel(NOTIFICATION_CALL_ID)
                }
            }
        }

        updateServiceNotification()
    }

    // WakeLock — держим CPU/экран живым при входящем звонке в фоне
    private var incomingCallWakeLock: PowerManager.WakeLock? = null

    private fun acquireIncomingCallWakeLock() {
        try {
            if (incomingCallWakeLock?.isHeld == true) return
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            incomingCallWakeLock = pm.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE,
                "shamcrm:incoming_sip_call",
            ).also {
                it.acquire(60_000L) // 60 секунд максимум — после этого освобождается автоматически
            }
            Log.d(TAG, "WakeLock acquired for incoming SIP call")
        } catch (error: Throwable) {
            Log.e(TAG, "Failed to acquire WakeLock: ${error.message}", error)
        }
    }

    private fun releaseIncomingCallWakeLock() {
        try {
            if (incomingCallWakeLock?.isHeld == true) {
                incomingCallWakeLock?.release()
                Log.d(TAG, "WakeLock released")
            }
            incomingCallWakeLock = null
        } catch (_: Throwable) {}
    }

    private fun updateServiceNotification() {
        try {
            notificationManager.notify(
                NOTIFICATION_SERVICE_ID,
                buildServiceNotification(NativeSipBridge.getStateSnapshot()),
            )
        } catch (error: Throwable) {
            Log.e(TAG, "updateServiceNotification failed: ${error.message}", error)
        }
    }

    private fun buildServiceNotification(snapshot: HashMap<String, Any?>): Notification {
        val registrationState = snapshot["registrationState"]?.toString() ?: "disconnected"
        val callState = snapshot["callState"]?.toString() ?: "idle"
        val remoteIdentity = formatIdentity(snapshot["remoteIdentity"]?.toString())
        val text = when {
            callState == "incoming" -> "Входящий звонок: $remoteIdentity"
            callState == "calling" -> "Исходящий звонок: $remoteIdentity"
            callState == "ringing" -> "Ожидаем ответ: $remoteIdentity"
            callState == "in_call" -> "Разговор: $remoteIdentity"
            registrationState == "registered" -> "SIP подключен и ждёт входящие звонки"
            registrationState == "registering" -> "Подключаем SIP..."
            else -> "SIP не подключен"
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_SERVICE_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("SHAMCRM SIP")
            .setContentText(text)
            .setContentIntent(mainActivityPendingIntent(openCall = callState != "idle"))
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)

        if (callState == "incoming") {
            builder.addAction(
                R.mipmap.ic_launcher,
                "Отклонить",
                actionPendingIntent(NativeSipActionReceiver.ACTION_DECLINE),
            )
            builder.addAction(
                R.mipmap.ic_launcher,
                "Ответить",
                actionPendingIntent(NativeSipActionReceiver.ACTION_ANSWER),
            )
        } else if (callState == "calling" || callState == "ringing" || callState == "in_call") {
            builder.addAction(
                R.mipmap.ic_launcher,
                "Завершить",
                actionPendingIntent(NativeSipActionReceiver.ACTION_HANGUP),
            )
        }

        return builder.build()
    }

    private fun showIncomingCallNotification(event: HashMap<String, Any?>) {
        val remoteIdentity = formatIdentity(event["remoteIdentity"]?.toString())

        val notification = NotificationCompat.Builder(this, CHANNEL_CALLS_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Входящий SIP звонок")
            .setContentText(remoteIdentity)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setDefaults(Notification.DEFAULT_ALL) // Включает звук, свет и вибрацию по умолчанию
            .setFullScreenIntent(incomingCallActivityPendingIntent(event), true)
            .setContentIntent(incomingCallActivityPendingIntent(event))
            .addAction(
                R.mipmap.ic_launcher,
                "Отклонить",
                actionPendingIntent(NativeSipActionReceiver.ACTION_DECLINE),
            )
            .addAction(
                R.mipmap.ic_launcher,
                "Ответить",
                actionPendingIntent(NativeSipActionReceiver.ACTION_ANSWER),
            )
            .build()

        try {
            notificationManager.notify(NOTIFICATION_CALL_ID, notification)
            
            // 🔥 ПРИНУДИТЕЛЬНЫЙ ЗАПУСК АКТИВНОСТИ 🔥
            // FullScreenIntent полагается на решение системы (на Xiaomi часто игнорируется).
            // Прямой вызов startActivity намного агрессивнее и срабатывает почти всегда,
            // особенно если есть разрешение "Отображать всплывающие окна".
            val intent = Intent(this, IncomingCallActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra(IncomingCallActivity.EXTRA_CALLER_NAME, remoteIdentity)
            }
            startActivity(intent)
            Log.d(TAG, "Forced startActivity for IncomingCallActivity")
            
        } catch (error: Throwable) {
            Log.e(TAG, "showIncomingCallNotification failed: ${error.message}", error)
        }
    }

    private fun mainActivityPendingIntent(openCall: Boolean): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("open_sip_call", openCall)
        }

        return PendingIntent.getActivity(
            this,
            if (openCall) 1002 else 1001,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun incomingCallActivityPendingIntent(event: HashMap<String, Any?>): PendingIntent {
        val remoteIdentity = formatIdentity(event["remoteIdentity"]?.toString())
        val intent = Intent(this, IncomingCallActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(IncomingCallActivity.EXTRA_CALLER_NAME, remoteIdentity)
        }

        return PendingIntent.getActivity(
            this,
            1003,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun actionPendingIntent(action: String): PendingIntent {
        val intent = Intent(this, NativeSipActionReceiver::class.java).apply {
            this.action = action
        }

        return PendingIntent.getBroadcast(
            this,
            action.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val runtimeChannel = NotificationChannel(
            CHANNEL_SERVICE_ID,
            "SHAMCRM SIP Runtime",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Постоянное SIP-подключение внутри CRM"
            setShowBadge(false)
        }

        // Канал для входящих звонков — максимальная важность со звуком, вибрацией
        // и видимостью на экране блокировки. На Xiaomi HyperOS это критично.
        val callsChannel = NotificationChannel(
            CHANNEL_CALLS_ID,
            "SHAMCRM SIP Звонки",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Входящие SIP звонки"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 400, 200, 400, 200, 400)
            enableLights(true)
            lightColor = 0xFF2196F3.toInt() // синий
            setShowBadge(true)
            setBypassDnd(true)   // Прорываться через режим «Не беспокоить»
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                setAllowBubbles(true)
            }
        }

        notificationManager.createNotificationChannel(runtimeChannel)
        notificationManager.createNotificationChannel(callsChannel)
    }

    private fun formatIdentity(value: String?): String {
        val raw = value?.trim().orEmpty()
        if (raw.isEmpty()) {
            return "Неизвестный номер"
        }

        var normalized = raw
        if (normalized.startsWith("sip:")) {
            normalized = normalized.removePrefix("sip:")
        }
        if (normalized.contains("@")) {
            normalized = normalized.substringBefore("@")
        }
        return normalized.ifEmpty { "Неизвестный номер" }
    }
}

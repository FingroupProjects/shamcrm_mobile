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
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerAt,
                    pendingIntent,
                )
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
                "incoming" -> showIncomingCallNotification(event)
                "calling", "ringing", "in_call", "ended", "failed", "idle" -> {
                    notificationManager.cancel(NOTIFICATION_CALL_ID)
                }
            }
        }

        updateServiceNotification()
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
            .setFullScreenIntent(mainActivityPendingIntent(openCall = true), true)
            .setContentIntent(mainActivityPendingIntent(openCall = true))
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
        }

        val callsChannel = NotificationChannel(
            CHANNEL_CALLS_ID,
            "SHAMCRM SIP Calls",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Входящие SIP звонки"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
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

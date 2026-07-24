package com.softtech.crm_task_manager

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.core.content.ContextCompat

class NativeSipForegroundService : Service() {
    companion object {
        private const val TAG = "NativeSipFgService"
        const val ACTION_START = "com.shamcrm.native_sip.START"
        const val ACTION_RESTART = "com.shamcrm.native_sip.RESTART"
        const val ACTION_STOP = "com.shamcrm.native_sip.STOP"

        private const val CHANNEL_SERVICE_ID = "shamcrm_sip_runtime"
        private const val CHANNEL_CALLS_ID = "shamcrm_sip_calls_silent_v3"
        private val LEGACY_CALL_CHANNEL_IDS = listOf(
            "shamcrm_sip_calls",
            "shamcrm_sip_calls_v2",
        )
        private const val NOTIFICATION_SERVICE_ID = 7301
        private const val NOTIFICATION_CALL_ID = 7302
        private const val RESTART_REQUEST_CODE = 7303
        private const val REGISTRATION_HEARTBEAT_INTERVAL_MS = 45_000L

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
                NativeSipBridge.recordDiagnosticEvent(
                    event = "foreground_service_start_failed",
                    details = hashMapOf(
                        "error" to (error.message ?: error.javaClass.simpleName),
                    ),
                )
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
    private val keyguardManager by lazy {
        getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
    }

    private val bridgeObserver: (HashMap<String, Any?>) -> Unit = { event ->
        handleBridgeEvent(event)
    }
    private val maintenanceHandler = Handler(Looper.getMainLooper())
    private val registrationHeartbeat = object : Runnable {
        override fun run() {
            try {
                NativeSipBridge.maintainRegistration("foreground-service-heartbeat")
            } finally {
                maintenanceHandler.postDelayed(this, REGISTRATION_HEARTBEAT_INTERVAL_MS)
            }
        }
    }
    private var explicitStopRequested = false
    private var incomingCallRingtone: Ringtone? = null

    override fun onCreate() {
        super.onCreate()
        explicitStopRequested = false
        NativeSipBridge.initialize(applicationContext)
        NativeSipBridge.recordDiagnosticEvent(
            event = "foreground_service_created",
            details = hashMapOf(
                "persistentEnabled" to NativeSipBridge.isPersistentEnabled(),
            ),
        )
        NativeSipBridge.addObserver(bridgeObserver)
        createNotificationChannels()
        startRegistrationHeartbeat()
        try {
            startSipForeground(buildServiceNotification(NativeSipBridge.getStateSnapshot()))
            reconcileIncomingCallFromSnapshot("service-created")
        } catch (error: Throwable) {
            Log.e(TAG, "startForeground failed: ${error.message}", error)
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        NativeSipBridge.recordDiagnosticEvent(
            event = "foreground_service_started",
            details = hashMapOf(
                "action" to (intent?.action ?: "system-restart"),
                "startId" to startId,
            ),
        )
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
                startRegistrationHeartbeat()
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
        reconcileIncomingCallFromSnapshot("service-started")
        return START_STICKY
    }

    override fun onDestroy() {
        NativeSipBridge.recordDiagnosticEvent(
            event = "foreground_service_destroyed",
            details = hashMapOf(
                "explicitStop" to explicitStopRequested,
                "persistentEnabled" to NativeSipBridge.isPersistentEnabled(),
            ),
        )
        stopIncomingCallRingtone()
        releaseIncomingCallWakeLock()
        stopRegistrationHeartbeat()
        stopForeground(STOP_FOREGROUND_REMOVE)
        NativeSipBridge.removeObserver(bridgeObserver)
        notificationManager.cancel(NOTIFICATION_CALL_ID)
        // Do not schedule a second service instance from onDestroy().
        // Android keeps this service sticky and the FCM/WorkManager recovery
        // paths handle a real process death. Scheduling an Alarm here causes a
        // needless unregister/register cycle when the task is removed from
        // recents and can create overlapping service starts on OEM devices.
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startSipForeground(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_SERVICE_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL,
            )
        } else {
            startForeground(NOTIFICATION_SERVICE_ID, notification)
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        NativeSipBridge.recordDiagnosticEvent(
            event = "foreground_service_task_removed",
            details = hashMapOf(
                "persistentEnabled" to NativeSipBridge.isPersistentEnabled(),
            ),
        )
        // Removing the app task must not restart SIP. The service is declared
        // with stopWithTask=false and remains the owner of the Linphone core;
        // a normal recents swipe should therefore leave registration intact.
        // Recovery after an actual process kill is handled by START_STICKY,
        // FCM and WorkManager instead of an unconditional Alarm restart.
        super.onTaskRemoved(rootIntent)
    }

    private fun handleBridgeEvent(event: HashMap<String, Any?>) {
        when (event["type"]?.toString()) {
            "call" -> {
                val state = event["state"]?.toString()
                Log.d(
                    TAG,
                    "handleBridgeEvent(call): state=$state, remote=${event["remoteIdentity"]}, appForeground=${NativeSipBridge.isAppInForeground()}, deviceLocked=${isDeviceLocked()}",
                )
                when (state) {
                    "incoming" -> {
                        if (NativeSipBridge.isIncomingAnswerPending()) {
                            clearIncomingPresentation("incoming-event-answer-pending")
                        } else {
                            logIncomingUiDecision("call-event")
                            acquireIncomingCallWakeLock()
                            notificationManager.cancel(NOTIFICATION_CALL_ID)
                            showIncomingCallNotification(event)
                            if (shouldPlaySystemIncomingRingtone()) {
                                startIncomingCallRingtone()
                            } else {
                                stopIncomingCallRingtone()
                            }
                        }
                    }
                    "calling", "ringing", "in_call", "ended", "failed", "idle" -> {
                        stopIncomingCallRingtone()
                        releaseIncomingCallWakeLock()
                        notificationManager.cancel(NOTIFICATION_CALL_ID)
                    }
                }
            }
            "app_visibility" -> {
                handleAppVisibilityEvent(event)
            }
        }

        updateServiceNotification()
    }

    private fun handleAppVisibilityEvent(event: HashMap<String, Any?>) {
        val callState = event["callState"]?.toString()
        Log.d(
            TAG,
            "handleAppVisibilityEvent: appForeground=${event["appForeground"]}, callState=$callState, remote=${event["remoteIdentity"]}, deviceLocked=${isDeviceLocked()}",
        )
        if (callState != "incoming") {
            stopIncomingCallRingtone()
            return
        }

        val incomingEvent = hashMapOf<String, Any?>(
            "type" to "call",
            "state" to "incoming",
            "remoteIdentity" to event["remoteIdentity"],
        )

        logIncomingUiDecision("app-visibility")
        notificationManager.cancel(NOTIFICATION_CALL_ID)
        showIncomingCallNotification(incomingEvent)

        if (shouldPlaySystemIncomingRingtone()) {
            startIncomingCallRingtone()
        } else {
            stopIncomingCallRingtone()
        }
    }

    /**
     * Registration can restore and deliver an INVITE before this service has
     * attached its bridge observer. Recover the current incoming state so the
     * call UI is not lost during a cold FCM wake-up.
     */
    private fun reconcileIncomingCallFromSnapshot(source: String) {
        val snapshot = NativeSipBridge.getStateSnapshot()
        if (snapshot["callState"]?.toString() != "incoming" ||
            NativeSipBridge.isIncomingAnswerPending()
        ) {
            if (NativeSipBridge.isIncomingAnswerPending()) {
                clearIncomingPresentation("snapshot-answer-pending")
            }
            return
        }

        val incomingEvent = hashMapOf<String, Any?>(
            "type" to "call",
            "state" to "incoming",
            "remoteIdentity" to snapshot["remoteIdentity"],
        )
        NativeSipBridge.recordDiagnosticEvent(
            event = "incoming_ui_recovered",
            details = hashMapOf(
                "source" to source,
                "remoteIdentity" to snapshot["remoteIdentity"],
                "appForeground" to NativeSipBridge.isAppInForeground(),
            ),
        )
        acquireIncomingCallWakeLock()
        notificationManager.cancel(NOTIFICATION_CALL_ID)
        showIncomingCallNotification(incomingEvent)
        if (shouldPlaySystemIncomingRingtone()) {
            startIncomingCallRingtone()
        }
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

    private fun startRegistrationHeartbeat() {
        maintenanceHandler.removeCallbacks(registrationHeartbeat)
        maintenanceHandler.postDelayed(registrationHeartbeat, REGISTRATION_HEARTBEAT_INTERVAL_MS)
    }

    private fun stopRegistrationHeartbeat() {
        maintenanceHandler.removeCallbacks(registrationHeartbeat)
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
            registrationState == "registered" -> "Телефония подключена и ждёт входящие звонки"
            registrationState == "registering" -> "Подключаем телефонию..."
            else -> "Телефония не подключена"
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_SERVICE_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("SHAMCRM Телефония")
            .setContentText(text)
            .setSubText("Телефония")
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
        if (NativeSipBridge.isIncomingAnswerPending()) {
            clearIncomingPresentation("notification-answer-pending")
            return
        }
        val remoteIdentity = formatIdentity(event["remoteIdentity"]?.toString())
        val declineIntent = actionPendingIntent(NativeSipActionReceiver.ACTION_DECLINE)
        val answerIntent = actionPendingIntent(NativeSipActionReceiver.ACTION_ANSWER)
        val caller = Person.Builder()
            .setName(remoteIdentity)
            .setImportant(true)
            .build()

        val notification = NotificationCompat.Builder(this, CHANNEL_CALLS_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("SHAMCRM: входящий звонок")
            .setContentText("Входящий звонок")
            .setSubText("Телефония")
            .setColor(0xFF1E88E5.toInt())
            .setColorized(true)
            .setStyle(
                NotificationCompat.CallStyle.forIncomingCall(
                    caller,
                    declineIntent,
                    answerIntent,
                )
                    .setAnswerButtonColorHint(0xFF4CD964.toInt())
                    .setDeclineButtonColorHint(0xFFFF3B30.toInt()),
            )
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(mainActivityPendingIntent(openCall = true))
            .build()

        try {
            notificationManager.notify(NOTIFICATION_CALL_ID, notification)
            Log.d(TAG, "Incoming call notification posted")
            NativeSipBridge.recordDiagnosticEvent(
                event = "incoming_notification_posted",
                details = hashMapOf(
                    "remoteIdentity" to remoteIdentity,
                    "notificationsEnabled" to notificationManager.areNotificationsEnabled(),
                ),
            )
        } catch (error: Throwable) {
            Log.e(TAG, "showIncomingCallNotification failed: ${error.message}", error)
            NativeSipBridge.recordDiagnosticEvent(
                event = "incoming_notification_failed",
                details = hashMapOf(
                    "error" to (error.message ?: error.javaClass.simpleName),
                ),
            )
        }
    }

    private fun clearIncomingPresentation(reason: String) {
        stopIncomingCallRingtone()
        releaseIncomingCallWakeLock()
        notificationManager.cancel(NOTIFICATION_CALL_ID)
        NativeSipBridge.recordDiagnosticEvent(
            event = "incoming_presentation_cleared",
            details = hashMapOf("reason" to reason),
        )
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

        LEGACY_CALL_CHANNEL_IDS.forEach { legacyChannelId ->
            try {
                notificationManager.deleteNotificationChannel(legacyChannelId)
            } catch (_: Throwable) {
            }
        }

        val runtimeChannel = NotificationChannel(
            CHANNEL_SERVICE_ID,
            "SHAMCRM Телефония Runtime",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Постоянное подключение телефонии внутри CRM"
            setShowBadge(false)
        }

        // Канал входящих звонков без собственного notification sound:
        // единственный звук проигрывает сервис через RingtoneManager.
        val callsChannel = NotificationChannel(
            CHANNEL_CALLS_ID,
            "SHAMCRM Телефония Звонки",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Входящие звонки"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(null, null)
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

    private fun shouldPlaySystemIncomingRingtone(): Boolean {
        return true
    }

    private fun isDeviceLocked(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            keyguardManager.isDeviceLocked
        } else {
            @Suppress("DEPRECATION")
            keyguardManager.isKeyguardLocked
        }
    }

    private fun logIncomingUiDecision(source: String) {
        Log.d(
            TAG,
            "Incoming UI decision[$source]: useNotification=true, playRingtone=${shouldPlaySystemIncomingRingtone()}, appForeground=${NativeSipBridge.isAppInForeground()}, deviceLocked=${isDeviceLocked()}",
        )
    }

    private fun startIncomingCallRingtone() {
        try {
            if (incomingCallRingtone?.isPlaying == true) {
                return
            }

            val ringtoneUri =
                RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_RINGTONE)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                    ?: return
            val ringtone = RingtoneManager.getRingtone(this, ringtoneUri) ?: return
            ringtone.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                ringtone.isLooping = true
            }
            ringtone.play()
            incomingCallRingtone = ringtone
            Log.d(TAG, "System incoming call ringtone started")
        } catch (error: Throwable) {
            Log.e(TAG, "Failed to start system incoming call ringtone: ${error.message}", error)
        }
    }

    private fun stopIncomingCallRingtone() {
        try {
            if (incomingCallRingtone?.isPlaying == true) {
                incomingCallRingtone?.stop()
            }
        } catch (_: Throwable) {
        } finally {
            incomingCallRingtone = null
        }
    }

    private fun openFlutterCallUi() {
        try {
            startActivity(
                Intent(this, MainActivity::class.java).apply {
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP,
                    )
                    putExtra("open_sip_call", true)
                },
            )
        } catch (error: Throwable) {
            Log.e(TAG, "Failed to open Flutter call UI from overlay: ${error.message}", error)
        }
    }
}

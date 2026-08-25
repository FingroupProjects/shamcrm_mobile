package com.softtech.crm_task_manager

import android.app.AlarmManager
import android.app.ActivityOptions
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
        private const val CHANNEL_CALLS_ID = "shamcrm_sip_calls_v4"
        private val LEGACY_CALL_CHANNEL_IDS = listOf(
            "shamcrm_sip_calls",
            "shamcrm_sip_calls_v2",
            "shamcrm_sip_calls_silent_v3",
        )
        private const val NOTIFICATION_SERVICE_ID = 7301
        private const val NOTIFICATION_CALL_ID = 7302
        private const val RESTART_REQUEST_CODE = 7303
        private const val ANSWER_ACTIVITY_REQUEST_CODE = 7304
        private const val REGISTRATION_HEARTBEAT_INTERVAL_MS = 45_000L
        @Volatile
        private var serviceRunning = false
        @Volatile
        private var serviceStartRequested = false

        @Synchronized
        fun start(context: Context): Boolean {
            NativeSipBridge.initialize(context.applicationContext)
            if (!NativeSipBridge.shouldKeepRuntimeAlive()) {
                Log.d(TAG, "Skip foreground SIP service: line was never connected")
                return false
            }
            if (serviceRunning || serviceStartRequested) {
                return true
            }
            serviceStartRequested = true
            return try {
                cancelScheduledRestart(context)
                val intent = Intent(context, NativeSipForegroundService::class.java).apply {
                    action = ACTION_START
                }
                ContextCompat.startForegroundService(context, intent)
                true
            } catch (error: Throwable) {
                serviceStartRequested = false
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
            if (!serviceRunning && !serviceStartRequested) {
                return
            }
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
    private var incomingPresentationKey: String? = null
    private var microphoneForegroundTypeActive = false
    private var incomingUiRetryCount = 0
    private val incomingUiWatchdog = object : Runnable {
        override fun run() {
            val snapshot = NativeSipBridge.getStateSnapshot()
            val callState = snapshot["callState"]?.toString()
            if (
                callState != "incoming" ||
                NativeSipBridge.isAppInForeground() ||
                IncomingCallActivity.isVisible() ||
                IncomingCallUiPolicy.prefersSystemIncomingUi()
            ) {
                Log.d(
                    TAG,
                    "Incoming UI watchdog stopped: callState=$callState, appForeground=${NativeSipBridge.isAppInForeground()}, activityVisible=${IncomingCallActivity.isVisible()}, systemIncomingUi=${IncomingCallUiPolicy.prefersSystemIncomingUi()}",
                )
                return
            }

            incomingUiRetryCount += 1
            val incomingEvent = hashMapOf<String, Any?>(
                "type" to "call",
                "state" to "incoming",
                "remoteIdentity" to snapshot["remoteIdentity"],
            )
            Log.d(TAG, "Incoming UI watchdog retry=$incomingUiRetryCount")
            NativeSipBridge.recordDiagnosticEvent(
                event = "incoming_ui_watchdog_retry",
                details = hashMapOf(
                    "retry" to incomingUiRetryCount,
                    "notificationsEnabled" to notificationManager.areNotificationsEnabled(),
                    "fullScreenAllowed" to canUseFullScreenIntent(),
                    "systemIncomingUi" to IncomingCallUiPolicy.prefersSystemIncomingUi(),
                ),
            )
            incomingPresentationKey = null
            showIncomingCallNotification(incomingEvent)
            launchIncomingCallUiIfNeeded(incomingEvent, "watchdog-$incomingUiRetryCount")
            if (incomingUiRetryCount >= 2) {
                return
            }
            maintenanceHandler.postDelayed(this, 900L)
        }
    }

    override fun onCreate() {
        super.onCreate()
        serviceRunning = true
        serviceStartRequested = false
        explicitStopRequested = false
        NativeSipBridge.initialize(applicationContext)
        createNotificationChannels()
        NativeSipBridge.recordDiagnosticEvent(
            event = "foreground_service_created",
            details = hashMapOf(
                "persistentEnabled" to NativeSipBridge.isPersistentEnabled(),
            ),
        )
        // startForegroundService() requires startForeground() even when we
        // immediately decide the line was never connected and should stop.
        try {
            startSipForeground(buildServiceNotification(NativeSipBridge.getStateSnapshot()))
        } catch (error: Throwable) {
            Log.e(TAG, "startForeground failed: ${error.message}", error)
            explicitStopRequested = true
            stopSelf()
            return
        }
        if (!NativeSipBridge.shouldKeepRuntimeAlive()) {
            Log.d(TAG, "Stop idle SIP service: user never connected the line")
            stopIdleRuntime("service-created")
            return
        }
        NativeSipBridge.addObserver(bridgeObserver)
        startRegistrationHeartbeat()
        reconcileIncomingCallFromSnapshot("service-created")
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
                stopIdleRuntime("explicit-stop")
                return START_NOT_STICKY
            }
            ACTION_START, ACTION_RESTART -> {
                if (!NativeSipBridge.shouldKeepRuntimeAlive()) {
                    stopIdleRuntime("idle-start")
                    return START_NOT_STICKY
                }
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
            else -> {
                if (!NativeSipBridge.shouldKeepRuntimeAlive()) {
                    stopIdleRuntime("idle-restart")
                    return START_NOT_STICKY
                }
                NativeSipBridge.restoreRegistrationIfNeeded(startService = false)
            }
        }

        updateServiceNotification()
        reconcileIncomingCallFromSnapshot("service-started")
        return START_STICKY
    }

    private fun stopIdleRuntime(reason: String) {
        explicitStopRequested = true
        cancelScheduledRestart(applicationContext)
        SipKeepAliveWorker.cancel(applicationContext)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.d(TAG, "Idle SIP runtime stopped: $reason")
    }

    override fun onDestroy() {
        serviceRunning = false
        serviceStartRequested = false
        NativeSipBridge.recordDiagnosticEvent(
            event = "foreground_service_destroyed",
            details = hashMapOf(
                "explicitStop" to explicitStopRequested,
                "persistentEnabled" to NativeSipBridge.isPersistentEnabled(),
            ),
        )
        cancelIncomingUiWatchdog()
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
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_SERVICE_ID, notification)
            return
        }

        // Тип microphone обязателен, чтобы Android 11+ не глушил микрофон,
        // когда пользователь сворачивает приложение во время разговора.
        // Тип можно повышать повторным вызовом startForeground при активном
        // звонке (в этот момент приложение на переднем плане).
        if (isActiveCallState(currentCallState())) {
            try {
                startForeground(
                    NOTIFICATION_SERVICE_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL or
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
                )
                microphoneForegroundTypeActive = true
                return
            } catch (error: Throwable) {
                // Android 14+ может отклонить тип microphone (нет разрешения
                // RECORD_AUDIO или старт из фона). phoneCall-сервис в этом
                // случае всё равно лучше, чем падение.
                Log.w(
                    TAG,
                    "startForeground with microphone type failed: ${error.message}",
                )
            }
        }

        startForeground(
            NOTIFICATION_SERVICE_ID,
            notification,
            ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL,
        )
        microphoneForegroundTypeActive = false
    }

    private fun currentCallState(): String? {
        return NativeSipBridge.getStateSnapshot()["callState"]?.toString()
    }

    private fun isActiveCallState(callState: String?): Boolean {
        return callState == "incoming" ||
            callState == "calling" ||
            callState == "ringing" ||
            callState == "in_call"
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
                        } else if (NativeSipBridge.isAppInForeground()) {
                            cancelIncomingUiWatchdog()
                            clearIncomingNotification("incoming-event-app-foreground")
                            stopIncomingCallRingtone()
                        } else {
                            logIncomingUiDecision("call-event")
                            acquireIncomingCallWakeLock()
                            showIncomingCallNotification(event)
                            launchIncomingCallUiIfNeeded(event, "call-event")
                            if (shouldPlaySystemIncomingRingtone()) {
                                startIncomingCallRingtone()
                            } else {
                                stopIncomingCallRingtone()
                            }
                            scheduleIncomingUiWatchdog()
                        }
                    }
                    "calling", "ringing", "in_call", "ended", "failed", "idle" -> {
                        cancelIncomingUiWatchdog()
                        incomingPresentationKey = null
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
            cancelIncomingUiWatchdog()
            stopIncomingCallRingtone()
            return
        }
        if (event["appForeground"] == true) {
            cancelIncomingUiWatchdog()
            clearIncomingNotification("app-became-foreground")
            stopIncomingCallRingtone()
            return
        }

        val incomingEvent = hashMapOf<String, Any?>(
            "type" to "call",
            "state" to "incoming",
            "remoteIdentity" to event["remoteIdentity"],
        )

        logIncomingUiDecision("app-visibility")
        showIncomingCallNotification(incomingEvent)
        launchIncomingCallUiIfNeeded(incomingEvent, "app-visibility")

        if (shouldPlaySystemIncomingRingtone()) {
            startIncomingCallRingtone()
        } else {
            stopIncomingCallRingtone()
        }
        scheduleIncomingUiWatchdog()
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
        showIncomingCallNotification(incomingEvent)
        launchIncomingCallUiIfNeeded(incomingEvent, source)
        if (shouldPlaySystemIncomingRingtone()) {
            startIncomingCallRingtone()
        }
        scheduleIncomingUiWatchdog()
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
            val snapshot = NativeSipBridge.getStateSnapshot()
            val notification = buildServiceNotification(snapshot)
            val wantsMicrophoneType = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                isActiveCallState(snapshot["callState"]?.toString())
            if (wantsMicrophoneType != microphoneForegroundTypeActive) {
                startSipForeground(notification)
            } else {
                notificationManager.notify(NOTIFICATION_SERVICE_ID, notification)
            }
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
                answerActivityPendingIntent(),
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
        if (NativeSipBridge.isAppInForeground()) {
            clearIncomingNotification("notification-app-foreground")
            return
        }
        val remoteIdentity = formatIdentity(event["remoteIdentity"]?.toString())
        val presentationKey = "incoming|$remoteIdentity"
        if (incomingPresentationKey == presentationKey) {
            return
        }
        val declineIntent = actionPendingIntent(NativeSipActionReceiver.ACTION_DECLINE)
        val answerIntent = answerActivityPendingIntent()
        val launchCustomIncomingUi = IncomingCallUiPolicy.shouldLaunchCustomIncomingActivity(
            NativeSipBridge.isAppInForeground(),
        )
        val contentIntent = if (launchCustomIncomingUi) {
            incomingCallActivityPendingIntent(event)
        } else {
            mainActivityPendingIntent(openCall = true)
        }
        val caller = Person.Builder()
            .setName(remoteIdentity)
            .setImportant(true)
            .build()

        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_CALLS_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(remoteIdentity)
            .setContentText("Входящий звонок")
            .setSubText("shamCRM")
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
            .setContentIntent(contentIntent)

        if (launchCustomIncomingUi) {
            notificationBuilder.setFullScreenIntent(contentIntent, true)
        }

        try {
            notificationManager.notify(NOTIFICATION_CALL_ID, notificationBuilder.build())
            incomingPresentationKey = presentationKey
            val fullScreenAllowed = canUseFullScreenIntent()
            Log.d(
                TAG,
                "Incoming call notification posted: fullScreenAllowed=$fullScreenAllowed, notificationsEnabled=${notificationManager.areNotificationsEnabled()}",
            )
            NativeSipBridge.recordDiagnosticEvent(
                event = "incoming_notification_posted",
                details = hashMapOf(
                    "remoteIdentity" to remoteIdentity,
                    "fullScreenAllowed" to fullScreenAllowed,
                    "notificationsEnabled" to notificationManager.areNotificationsEnabled(),
                    "channelImportance" to notificationManager
                        .getNotificationChannel(CHANNEL_CALLS_ID)
                        ?.importance,
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
        cancelIncomingUiWatchdog()
        incomingPresentationKey = null
        stopIncomingCallRingtone()
        releaseIncomingCallWakeLock()
        notificationManager.cancel(NOTIFICATION_CALL_ID)
        NativeSipBridge.recordDiagnosticEvent(
            event = "incoming_presentation_cleared",
            details = hashMapOf("reason" to reason),
        )
    }

    private fun clearIncomingNotification(reason: String) {
        val hadPresentation = incomingPresentationKey != null
        incomingPresentationKey = null
        notificationManager.cancel(NOTIFICATION_CALL_ID)
        if (hadPresentation) {
            NativeSipBridge.recordDiagnosticEvent(
                event = "incoming_notification_cleared",
                details = hashMapOf("reason" to reason),
            )
        }
    }

    private fun mainActivityPendingIntent(openCall: Boolean): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
            )
            putExtra("open_sip_call", openCall)
        }

        return createActivityPendingIntent(
            requestCode = if (openCall) 1002 else 1001,
            intent = intent,
        )
    }

    private fun incomingCallActivityPendingIntent(event: HashMap<String, Any?>): PendingIntent {
        return createActivityPendingIntent(
            requestCode = 1003,
            intent = incomingCallActivityIntent(event),
        )
    }

    private fun createActivityPendingIntent(
        requestCode: Int,
        intent: Intent,
    ): PendingIntent {
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val options = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ActivityOptions.makeBasic()
                .setPendingIntentCreatorBackgroundActivityStartMode(
                    ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
                )
                .toBundle()
        } else {
            null
        }

        return PendingIntent.getActivity(
            this,
            requestCode,
            intent,
            flags,
            options,
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

    private fun answerActivityPendingIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            action = NativeSipActionReceiver.ACTION_ANSWER
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("open_sip_call", true)
            putExtra("sip_notification_action", "answer")
        }
        val options = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ActivityOptions.makeBasic()
                .setPendingIntentCreatorBackgroundActivityStartMode(
                    ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
                )
                .toBundle()
        } else {
            null
        }
        return PendingIntent.getActivity(
            this,
            ANSWER_ACTIVITY_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            options,
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
        return !NativeSipBridge.isAppInForeground()
    }

    private fun shouldLaunchIncomingCallUi(): Boolean {
        return IncomingCallUiPolicy.shouldLaunchCustomIncomingActivity(
            NativeSipBridge.isAppInForeground(),
        )
    }

    private fun isDeviceLocked(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            keyguardManager.isDeviceLocked
        } else {
            @Suppress("DEPRECATION")
            keyguardManager.isKeyguardLocked
        }
    }

    private fun canUseFullScreenIntent(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            notificationManager.canUseFullScreenIntent()
        } else {
            true
        }
    }

    private fun logIncomingUiDecision(source: String) {
        Log.d(
            TAG,
            "Incoming UI decision[$source]: launchActivity=${shouldLaunchIncomingCallUi()}, activityVisible=${IncomingCallActivity.isVisible()}, fullScreenAllowed=${canUseFullScreenIntent()}, playRingtone=${shouldPlaySystemIncomingRingtone()}, appForeground=${NativeSipBridge.isAppInForeground()}, deviceLocked=${isDeviceLocked()}",
        )
    }

    private fun launchIncomingCallUiIfNeeded(event: HashMap<String, Any?>, source: String) {
        if (!shouldLaunchIncomingCallUi()) {
            Log.d(TAG, "Incoming UI launch skipped[$source]: customActivity=${shouldLaunchIncomingCallUi()}, systemIncomingUi=${IncomingCallUiPolicy.prefersSystemIncomingUi()}")
            return
        }
        if (IncomingCallActivity.isVisible()) {
            Log.d(TAG, "Incoming UI launch skipped[$source]: IncomingCallActivity already visible")
            return
        }
        Log.d(
            TAG,
            "Incoming UI launch[$source]: remote=${event["remoteIdentity"]}, deviceLocked=${isDeviceLocked()}",
        )
        NativeSipBridge.recordDiagnosticEvent(
            event = "incoming_ui_launch",
            details = hashMapOf(
                "source" to source,
                "remoteIdentity" to event["remoteIdentity"],
                "deviceLocked" to isDeviceLocked(),
                "fullScreenAllowed" to canUseFullScreenIntent(),
                "notificationsEnabled" to notificationManager.areNotificationsEnabled(),
            ),
        )
        launchIncomingCallActivity(event, source)
    }

    private fun incomingCallActivityIntent(event: HashMap<String, Any?>): Intent {
        val remoteIdentity = formatIdentity(event["remoteIdentity"]?.toString())
        return Intent(this, IncomingCallActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS,
            )
            putExtra(IncomingCallActivity.EXTRA_CALLER_NAME, remoteIdentity)
        }
    }

    private fun launchIncomingCallActivity(event: HashMap<String, Any?>, source: String) {
        val intent = incomingCallActivityIntent(event)
        try {
            // phoneCall foreground service may start the incoming-call activity
            // even when POST_NOTIFICATIONS is denied and full-screen intent
            // never fires. PendingIntent.send() is silently dropped on many OEMs.
            startActivity(intent)
            NativeSipBridge.recordDiagnosticEvent(
                event = "incoming_activity_start_sent",
                details = hashMapOf(
                    "source" to source,
                    "remoteIdentity" to intent.getStringExtra(IncomingCallActivity.EXTRA_CALLER_NAME),
                    "notificationsEnabled" to notificationManager.areNotificationsEnabled(),
                ),
            )
            Log.d(TAG, "IncomingCallActivity startActivity sent[$source]")
        } catch (error: Throwable) {
            Log.e(TAG, "IncomingCallActivity startActivity failed[$source]: ${error.message}", error)
            NativeSipBridge.recordDiagnosticEvent(
                event = "incoming_activity_start_failed",
                details = hashMapOf(
                    "source" to source,
                    "error" to (error.message ?: error.javaClass.simpleName),
                ),
            )
            launchIncomingCallUiFallback(event)
        }
    }

    private fun launchIncomingCallUiFallback(event: HashMap<String, Any?>) {
        val pendingIntent = incomingCallActivityPendingIntent(event)

        try {
            val options = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ActivityOptions.makeBasic()
                    .setPendingIntentBackgroundActivityStartMode(
                        ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
                    )
                    .toBundle()
            } else {
                null
            }

            pendingIntent.send(
                this,
                0,
                null,
                null,
                null,
                null,
                options,
            )
            Log.d(TAG, "IncomingCallActivity launch fallback sent via PendingIntent")
        } catch (error: PendingIntent.CanceledException) {
            Log.e(TAG, "IncomingCallActivity fallback was canceled: ${error.message}", error)
            openFlutterCallUi()
        } catch (error: Throwable) {
            Log.e(TAG, "IncomingCallActivity fallback failed: ${error.message}", error)
            NativeSipBridge.recordDiagnosticEvent(
                event = "incoming_call_ui_open_failed",
                details = hashMapOf(
                    "source" to "pending-intent",
                    "error" to (error.message ?: error.javaClass.simpleName),
                ),
            )
            openFlutterCallUi()
        }
    }

    private fun scheduleIncomingUiWatchdog() {
        maintenanceHandler.removeCallbacks(incomingUiWatchdog)
        incomingUiRetryCount = 0
        maintenanceHandler.postDelayed(incomingUiWatchdog, 900L)
    }

    private fun cancelIncomingUiWatchdog() {
        maintenanceHandler.removeCallbacks(incomingUiWatchdog)
        incomingUiRetryCount = 0
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
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
                    )
                    putExtra("open_sip_call", true)
                },
            )
        } catch (error: Throwable) {
            Log.e(TAG, "Failed to open Flutter call UI from overlay: ${error.message}", error)
        }
    }
}

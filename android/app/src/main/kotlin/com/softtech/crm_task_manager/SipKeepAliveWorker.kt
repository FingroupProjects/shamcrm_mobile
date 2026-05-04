package com.softtech.crm_task_manager

import android.content.Context
import android.util.Log
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * WorkManager периодическая задача — резервный механизм для поддержания SIP-соединения.
 *
 * Запускается каждые 15 минут (минимум WorkManager) даже если:
 *  - Приложение убито из Recent Apps
 *  - AlarmManager был заблокирован Xiaomi
 *  - Устройство перезагружено
 *
 * WorkManager использует Android JobScheduler (системный API), который:
 *  - Не может быть заблокирован производителем
 *  - Гарантированно выполняется при наличии сети
 *  - Переживает перезагрузку устройства
 */
class SipKeepAliveWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {

    override fun doWork(): Result {
        return try {
            NativeSipBridge.initialize(applicationContext)

            if (!NativeSipBridge.isPersistentEnabled()) {
                Log.d(TAG, "SIP keep-alive: not enabled, skipping")
                return Result.success()
            }

            Log.d(TAG, "SIP keep-alive: checking service health...")

            // Запустить ForegroundService если он не работает
            val started = NativeSipForegroundService.start(applicationContext)
            Log.d(TAG, "SIP keep-alive: service start result = $started")

            Result.success()
        } catch (error: Throwable) {
            Log.e(TAG, "SIP keep-alive failed: ${error.message}", error)
            Result.retry()
        }
    }

    companion object {
        private const val TAG = "SipKeepAliveWorker"

        // Уникальное имя задачи — гарантирует что только одна копия работает в системе
        private const val WORK_NAME = "shamcrm_sip_keep_alive_v2"

        /**
         * Запланировать периодическую задачу через WorkManager.
         * ExistingPeriodicWorkPolicy.KEEP — не перезапускать если уже запущена.
         */
        fun schedule(context: Context) {
            try {
                val constraints = Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()

                val request = PeriodicWorkRequestBuilder<SipKeepAliveWorker>(
                    15, TimeUnit.MINUTES,
                    5, TimeUnit.MINUTES, // flex interval — окно срабатывания
                ).setConstraints(constraints).build()

                WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                    WORK_NAME,
                    ExistingPeriodicWorkPolicy.KEEP,
                    request,
                )
                Log.d(TAG, "SIP keep-alive WorkManager scheduled (every 15 min)")
            } catch (error: Throwable) {
                Log.e(TAG, "Failed to schedule SIP keep-alive: ${error.message}", error)
            }
        }

        /**
         * Отменить периодическую задачу (вызывается при явном отключении SIP).
         */
        fun cancel(context: Context) {
            try {
                WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
                Log.d(TAG, "SIP keep-alive WorkManager cancelled")
            } catch (error: Throwable) {
                Log.e(TAG, "Failed to cancel SIP keep-alive: ${error.message}", error)
            }
        }
    }
}

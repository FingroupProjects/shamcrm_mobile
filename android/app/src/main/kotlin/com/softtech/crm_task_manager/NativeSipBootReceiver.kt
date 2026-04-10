package com.softtech.crm_task_manager

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class NativeSipBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        NativeSipBridge.initialize(context.applicationContext)

        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED -> {
                if (NativeSipBridge.isPersistentEnabled()) {
                    NativeSipForegroundService.start(context.applicationContext)
                }
            }
        }
    }
}

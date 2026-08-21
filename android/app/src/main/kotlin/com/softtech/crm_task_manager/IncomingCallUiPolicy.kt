package com.softtech.crm_task_manager

import android.os.Build

object IncomingCallUiPolicy {
    fun prefersSystemIncomingUi(): Boolean {
        val tokens = listOf(
            Build.MANUFACTURER,
            Build.BRAND,
            Build.DEVICE,
        ).map { it.orEmpty().lowercase() }
        return tokens.any { token ->
            token.contains("xiaomi") ||
                token.contains("redmi") ||
                token.contains("poco") ||
                token.contains("blackshark")
        }
    }

    fun shouldLaunchCustomIncomingActivity(appInForeground: Boolean): Boolean {
        return !appInForeground && !prefersSystemIncomingUi()
    }
}

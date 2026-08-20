package com.softtech.crm_task_manager

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log

/**
 * Custom shamCRM incoming-call screen is disabled.
 * Incoming calls are presented by the system CallStyle notification /
 * OEM native incoming-call UI (see NativeSipForegroundService).
 *
 * The previous layout lives in [R.layout.activity_incoming_call].
 * To restore it, set LAUNCH_CUSTOM_INCOMING_CALL_ACTIVITY = true
 * in NativeSipForegroundService and put the old UI back here.
 */
class IncomingCallActivity : Activity() {

    companion object {
        private const val TAG = "IncomingCallActivity"
        const val EXTRA_CALLER_NAME = "caller_name"

        fun isVisible(): Boolean = false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(
            TAG,
            "Custom incoming UI disabled, caller=${intent.getStringExtra(EXTRA_CALLER_NAME)}",
        )
        finishAndRemoveTask()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        finishAndRemoveTask()
    }
}

package com.softtech.avezov

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class NativeSipActionReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_ANSWER = "com.shamcrm.native_sip.ANSWER"
        const val ACTION_DECLINE = "com.shamcrm.native_sip.DECLINE"
        const val ACTION_HANGUP = "com.shamcrm.native_sip.HANGUP"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        NativeSipBridge.initialize(context.applicationContext)

        when (intent?.action) {
            ACTION_ANSWER -> NativeSipBridge.acceptCall()
            ACTION_DECLINE -> NativeSipBridge.declineCall()
            ACTION_HANGUP -> NativeSipBridge.hangup()
        }
    }
}

package com.softtech.crm_task_manager

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ChatQuickReplyReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ChatQuickReplyManager.ACTION_REPLY) {
            ChatQuickReplyManager.sendReplyAsync(this, context, intent)
        }
    }
}

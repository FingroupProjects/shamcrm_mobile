package com.softtech.crm_task_manager

import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.util.Log
import org.linphone.core.Core

/**
 * Bluetooth and communication-mode helpers for SIP calls.
 *
 * Linphone only lists a headset after SCO is up. Headphones that were
 * already connected for music therefore disappear from the in-app picker
 * until we put the stream in communication mode and start SCO.
 */
object SipCallAudio {
    const val SYNTHETIC_BLUETOOTH_ID = "system-bluetooth"
    private const val TAG = "SipCallAudio"

    fun audioManager(context: Context): AudioManager {
        return context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    fun enterCallMode(context: Context) {
        try {
            audioManager(context).mode = AudioManager.MODE_IN_COMMUNICATION
        } catch (error: Throwable) {
            Log.w(TAG, "Failed to set MODE_IN_COMMUNICATION: ${error.message}")
        }
    }

    fun leaveCallMode(context: Context) {
        try {
            val manager = audioManager(context)
            @Suppress("DEPRECATION")
            if (manager.isBluetoothScoOn) {
                manager.stopBluetoothSco()
                manager.isBluetoothScoOn = false
            }
            manager.mode = AudioManager.MODE_NORMAL
        } catch (error: Throwable) {
            Log.w(TAG, "Failed to restore audio mode: ${error.message}")
        }
    }

    @SuppressLint("MissingPermission")
    fun connectedBluetoothName(context: Context): String? {
        val manager = audioManager(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val device = manager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                .firstOrNull { isBluetoothOutput(it) }
            val name = device?.productName?.toString()?.trim().orEmpty()
            if (name.isNotEmpty()) return name
            if (device != null) return "Bluetooth-наушники"
        }
        @Suppress("DEPRECATION")
        if (manager.isBluetoothA2dpOn || manager.isBluetoothScoOn) {
            return "Bluetooth-наушники"
        }
        return null
    }

    fun isBluetoothHeadsetConnected(context: Context): Boolean {
        return connectedBluetoothName(context) != null
    }

    fun isBluetoothAudioOn(context: Context): Boolean {
        val manager = audioManager(context)
        @Suppress("DEPRECATION")
        if (manager.isBluetoothScoOn) return true
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        return try {
            manager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).any { device ->
                isBluetoothOutput(device) && device.isSink
            } && manager.mode == AudioManager.MODE_IN_COMMUNICATION
        } catch (_: Throwable) {
            false
        }
    }

    fun reloadLinphoneDevices(core: Core) {
        try {
            core.reloadSoundDevices()
        } catch (error: Throwable) {
            Log.w(TAG, "reloadSoundDevices failed: ${error.message}")
        }
    }

    fun prepareForCall(context: Context, core: Core, preferBluetooth: Boolean) {
        // Do not call startBluetoothSco(). On Xiaomi/HyperOS that looks like a
        // second GSM/HFP call and shows "another call is already connecting".
        // Linphone routes to the headset after MODE_IN_COMMUNICATION.
        enterCallMode(context)
        reloadLinphoneDevices(core)
        if (!preferBluetooth) {
            return
        }
        Log.d(TAG, "Bluetooth preferred; waiting for Linphone device list")
    }

    private fun isBluetoothOutput(device: AudioDeviceInfo): Boolean {
        return when (device.type) {
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
            AudioDeviceInfo.TYPE_BLE_HEADSET,
            AudioDeviceInfo.TYPE_BLE_SPEAKER,
            -> true
            else -> false
        }
    }
}

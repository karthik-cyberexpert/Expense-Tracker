package com.expensetracker.expense_tracker

import android.app.*
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.*

class UpiMonitorService : Service() {
    private val CHANNEL_ID = "upi_monitor_channel"
    private val NOTIFICATION_ID = 101
    private val EXIT_NOTIFICATION_ID = 102
    
    private var isMonitoring = false
    private val handler = Handler(Looper.getMainLooper())
    private var lastApp: String? = null
    private var isInUpiApp = false
    private var lastUpiApp: String? = null
    private var lastExitTime: Long = 0

    private val upiApps = listOf(
        "com.google.android.apps.nbu.paisa.user", // Google Pay (IN)
        "com.google.android.apps.walletnfcrel",  // GPay (Global)
        "com.phonepe.app",                       // PhonePe
        "net.one97.paytm",                       // Paytm
        "in.amazon.mShop.android.shopping",      // Amazon Pay
        "com.dreamplug.androidapp",              // CRED
        "com.nextbillion.groww",                 // Groww
        "com.whatsapp",                          // WhatsApp
        "com.upi.axispay",                       // BHIM Axis Pay
        "in.org.npci.upiapp",                    // BHIM
        "com.freecharge.android",                // Freecharge
        "com.mobikwik_new",                      // MobiKwik
        "com.msf.kbank.mobile",                  // Kotak
        "com.jupiter.money",                     // Jupiter
        "in.niyo.barnes",                        // Niyo
        "com.icicibank.pockets",                 // Pockets
        "com.csam.icici.bank.imobile"            // iMobile
    )

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!isMonitoring) return
            checkForegroundApp()
            handler.postDelayed(this, 1500) // Poll every 1.5 seconds
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP_SERVICE") {
            stopMonitoring()
            stopSelf()
            return START_NOT_STICKY
        }
        
        startForeground(NOTIFICATION_ID, createForegroundNotification())
        startMonitoring()
        return START_STICKY
    }

    private fun startMonitoring() {
        if (!isMonitoring) {
            isMonitoring = true
            handler.post(pollRunnable)
        }
    }

    private fun stopMonitoring() {
        isMonitoring = false
        handler.removeCallbacks(pollRunnable)
    }

    private fun checkForegroundApp() {
        val currentApp = getForegroundApp() ?: return
        
        // Loud logging for debugging
        if (currentApp != lastApp) {
            Log.d("UpiMonitor", "Foreground changed: $lastApp -> $currentApp")
        }

        if (upiApps.contains(currentApp)) {
            if (!isInUpiApp) {
                Log.d("UpiMonitor", "TARGET UPI APP ENTERED: $currentApp")
                isInUpiApp = true
                lastUpiApp = currentApp
            }
        } else {
            // Check if we are transitioning to a system overlay or something neutral 
            // instead of a full app exit. 
            val ignorePackages = listOf("android", "com.android.systemui", "com.google.android.gms")
            if (isInUpiApp && !ignorePackages.contains(currentApp)) {
                val now = System.currentTimeMillis()
                if (now - lastExitTime > 3000) { // 3-second cooldown
                    Log.d("UpiMonitor", "TARGET UPI APP EXITED: $lastUpiApp (current: $currentApp)")
                    showExitNotification(lastUpiApp!!)
                    lastExitTime = now
                }
                isInUpiApp = false
            }
        }
        lastApp = currentApp
    }

    private fun getForegroundApp(): String? {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        
        // Use UsageEvents for more accurate real-time detection
        val events = usageStatsManager.queryEvents(time - 1000 * 5, time)
        val event = android.app.usage.UsageEvents.Event()
        var lastPackage: String? = null
        
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND) {
                lastPackage = event.packageName
            }
        }
        
        if (lastPackage != null) return lastPackage

        // Fallback for some devices
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_BEST, time - 1000 * 60, time)
        if (stats != null && stats.isNotEmpty()) {
            val sortedStats = stats.sortedByDescending { it.lastTimeUsed }
            return sortedStats[0].packageName
        }
        return null
    }

    private fun showExitNotification(appName: String) {
        val friendlyName = when (appName) {
            "com.google.android.apps.nbu.paisa.user" -> "Google Pay"
            "com.phonepe.app" -> "PhonePe"
            "net.one97.paytm" -> "Paytm"
            "in.amazon.mShop.android.shopping" -> "Amazon Pay"
            else -> "Payment App"
        }

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/add_transaction")
            putExtra("source_app", friendlyName)
            putExtra("timestamp", System.currentTimeMillis())
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_edit)
            .setContentTitle("Did you just make a payment?")
            .setContentText("Tap to add your $friendlyName transaction to Expense Tracker.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(EXIT_NOTIFICATION_ID, notification)
    }

    private fun createForegroundNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("UPI Monitor Active")
            .setContentText("Helping you track your expenses automatically")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "UPI Monitor Service Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopMonitoring()
        super.onDestroy()
    }
}

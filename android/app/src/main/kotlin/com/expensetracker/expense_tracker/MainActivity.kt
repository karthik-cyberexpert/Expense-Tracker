package com.expensetracker.expense_tracker

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.expensetracker.expense_tracker/upi_monitor"
    private var pendingRoute: String? = null
    private var pendingSource: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    startMonitorService()
                    result.success(true)
                }
                "stopService" -> {
                    stopMonitorService()
                    result.success(true)
                }
                "checkUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsagePermission" -> {
                    requestUsageStatsPermission()
                    result.success(true)
                }
                "getPendingNotificationData" -> {
                    val data = mutableMapOf<String, String>()
                    pendingRoute?.let { data["route"] = it }
                    pendingSource?.let { data["source"] = it }
                    pendingRoute = null
                    pendingSource = null
                    result.success(data)
                }
                "isServiceRunning" -> {
                    result.success(isServiceRunning())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val route = intent.getStringExtra("route")
        val source = intent.getStringExtra("source_app")
        if (route != null) {
            pendingRoute = route
            pendingSource = source
            // Notify Flutter that a new deep link is available
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, CHANNEL).invokeMethod("onDeepLink", mapOf("route" to route, "source" to source))
            }
        }
    }

    private fun startMonitorService() {
        val intent = Intent(this, UpiMonitorService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopMonitorService() {
        val intent = Intent(this, UpiMonitorService::class.java).apply {
            action = "STOP_SERVICE"
        }
        startService(intent)
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        }
        val isAllowed = mode == AppOpsManager.MODE_ALLOWED
        Log.d("UsagePermission", "Permission Status: $isAllowed (Mode: $mode)")
        return isAllowed
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    private fun isServiceRunning(): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        for (service in manager.getRunningServices(Int.MAX_VALUE)) {
            if (UpiMonitorService::class.java.name == service.service.className) {
                return true
            }
        }
        return false
    }
}

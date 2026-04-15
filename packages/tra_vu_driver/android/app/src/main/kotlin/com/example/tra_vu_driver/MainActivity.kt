package com.example.tra_vu_driver
 
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Ensure notification channel is created at the native level
        // to avoid RemoteServiceException: Bad notification for startForeground
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Tra-Vu Driver Tracking"
            val descriptionText = "Tracking location for dispatch..."
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel("tra_vu_driver_tracking", name, importance).apply {
                description = descriptionText
            }
            
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}

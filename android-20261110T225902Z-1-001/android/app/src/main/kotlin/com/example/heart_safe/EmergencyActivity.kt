package com.example.heart_safe

import android.os.Bundle
import android.view.WindowManager
import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class EmergencyActivity: FlutterActivity() {
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
        setShowWhenLocked(true)
        setTurnScreenOn(true)
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        keyguardManager.requestDismissKeyguard(this, null)
    }
    
    // إضافة الـ Flags القديمة لضمان العمل على كل النسخ
    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                   WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON or
                   WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                   WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
}
}
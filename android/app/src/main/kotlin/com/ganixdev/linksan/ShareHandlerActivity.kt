package com.ganixdev.linksan

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class ShareHandlerActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Handle the shared text
        val intent = intent
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (sharedText != null) {
                // Pass the shared text to the main activity or handle it
                val mainIntent = Intent(this, MainActivity::class.java)
                mainIntent.putExtra("shared_text", sharedText)
                startActivity(mainIntent)
            }
        }

        // Finish this activity so it doesn't stay in the background
        finish()
    }
}

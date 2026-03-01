package com.example.lovepin

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.net.URL
import kotlinx.coroutines.*

/**
 * AppWidgetProvider for the Lovepin home screen widget.
 *
 * Reads message data and theme colours from SharedPreferences (written by the
 * Flutter `home_widget` plugin) and renders a RemoteViews layout showing the
 * latest love note — optionally with an image.
 */
class LovepinWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // First widget placed on home screen.
    }

    override fun onDisabled(context: Context) {
        // Last widget removed from home screen.
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences = context.getSharedPreferences(
                PREFS_NAME, Context.MODE_PRIVATE
            )

            val messageContent = prefs.getString("message_content", "") ?: ""
            val senderName = prefs.getString("sender_name", "") ?: ""
            val imagePath = prefs.getString("image_path", "") ?: ""
            val timestamp = prefs.getString("message_timestamp", "") ?: ""

            // Theme colours
            val bgColor = prefs.getString("theme_background_color", "#FFD6E0") ?: "#FFD6E0"
            val textColor = prefs.getString("theme_text_color", "#2D2D2D") ?: "#2D2D2D"
            val accentColor = prefs.getString("theme_accent_color", "#FF8FAB") ?: "#FF8FAB"

            val views = RemoteViews(context.packageName, R.layout.lovepin_widget)

            // Background tint
            try {
                views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor(bgColor))
            } catch (_: Exception) {}

            // Sender name
            if (senderName.isNotEmpty()) {
                views.setTextViewText(R.id.widget_sender, senderName)
                try {
                    views.setTextColor(R.id.widget_sender, Color.parseColor(accentColor))
                } catch (_: Exception) {}
            } else {
                views.setTextViewText(R.id.widget_sender, "Lovepin")
            }

            // Message content
            if (messageContent.isNotEmpty()) {
                views.setTextViewText(R.id.widget_message, messageContent)
            } else {
                views.setTextViewText(R.id.widget_message, "No messages yet")
            }
            try {
                views.setTextColor(R.id.widget_message, Color.parseColor(textColor))
            } catch (_: Exception) {}

            // Timestamp
            if (timestamp.isNotEmpty()) {
                views.setTextViewText(R.id.widget_timestamp, formatTimestamp(timestamp))
                try {
                    views.setTextColor(R.id.widget_timestamp, Color.parseColor(accentColor))
                } catch (_: Exception) {}
            } else {
                views.setTextViewText(R.id.widget_timestamp, "")
            }

            // Image — load asynchronously if available
            if (imagePath.isNotEmpty()) {
                views.setViewVisibility(R.id.widget_image, android.view.View.VISIBLE)
                // Load image in background
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val url = URL(imagePath)
                        val bitmap: Bitmap = BitmapFactory.decodeStream(url.openStream())
                        views.setImageViewBitmap(R.id.widget_image, bitmap)
                        appWidgetManager.updateAppWidget(appWidgetId, views)
                    } catch (_: Exception) {
                        views.setViewVisibility(R.id.widget_image, android.view.View.GONE)
                        appWidgetManager.updateAppWidget(appWidgetId, views)
                    }
                }
            } else {
                views.setViewVisibility(R.id.widget_image, android.view.View.GONE)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun formatTimestamp(isoTimestamp: String): String {
            return try {
                val instant = java.time.Instant.parse(isoTimestamp)
                val local = instant.atZone(java.time.ZoneId.systemDefault())
                val now = java.time.ZonedDateTime.now()
                val diff = java.time.Duration.between(local, now)

                when {
                    diff.toMinutes() < 1 -> "just now"
                    diff.toMinutes() < 60 -> "${diff.toMinutes()}m ago"
                    diff.toHours() < 24 -> "${diff.toHours()}h ago"
                    else -> "${diff.toDays()}d ago"
                }
            } catch (_: Exception) {
                ""
            }
        }
    }
}

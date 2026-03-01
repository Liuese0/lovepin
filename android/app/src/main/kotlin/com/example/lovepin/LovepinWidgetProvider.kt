package com.example.lovepin

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * AppWidgetProvider for the Lovepin home screen widget.
 *
 * Reads message data and theme colours from SharedPreferences (written by the
 * Flutter `home_widget` plugin) and renders a layout showing the latest love
 * note from the partner with sender name, message text, and timestamp.
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

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val messageContent = prefs.getString("message_content", null) ?: ""
            val senderName = prefs.getString("sender_name", null) ?: ""
            val timestamp = prefs.getString("message_timestamp", null) ?: ""

            // Theme colours
            val bgColor = prefs.getString("theme_background_color", "#FFD6E0") ?: "#FFD6E0"
            val textColor = prefs.getString("theme_text_color", "#2D2D2D") ?: "#2D2D2D"
            val accentColor = prefs.getString("theme_accent_color", "#FF8FAB") ?: "#FF8FAB"

            val views = RemoteViews(context.packageName, R.layout.lovepin_widget)

            // --- Click to open app ---
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            // --- Background colour ---
            try {
                views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor(bgColor))
            } catch (_: Exception) {
            }

            // --- Sender name (with "From" prefix) ---
            val displayName = if (senderName.isNotEmpty()) senderName else "Your Love"
            views.setTextViewText(R.id.widget_sender, "From $displayName")
            trySetTextColor(views, R.id.widget_sender, accentColor)

            // --- Divider colour (accent with transparency) ---
            try {
                val accent = Color.parseColor(accentColor)
                val dividerColor = Color.argb(50, Color.red(accent), Color.green(accent), Color.blue(accent))
                views.setInt(R.id.widget_divider, "setColorFilter", dividerColor)
            } catch (_: Exception) {
            }

            // --- Message content ---
            views.setTextViewText(
                R.id.widget_message,
                if (messageContent.isNotEmpty()) messageContent else "No messages yet"
            )
            trySetTextColor(views, R.id.widget_message, textColor)

            // --- Timestamp ---
            if (timestamp.isNotEmpty()) {
                views.setTextViewText(R.id.widget_timestamp, formatTimestamp(timestamp))
                views.setViewVisibility(R.id.widget_timestamp, View.VISIBLE)
                trySetTextColor(views, R.id.widget_timestamp, accentColor)
            } else {
                views.setViewVisibility(R.id.widget_timestamp, View.GONE)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun trySetTextColor(views: RemoteViews, viewId: Int, hexColor: String) {
            try {
                views.setInt(viewId, "setTextColor", Color.parseColor(hexColor))
            } catch (_: Exception) {
            }
        }

        /**
         * Parse an ISO-8601 timestamp and return a human-friendly relative string.
         * Uses SimpleDateFormat for compatibility with API 21+.
         */
        private fun formatTimestamp(isoTimestamp: String): String {
            return try {
                val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
                format.timeZone = TimeZone.getTimeZone("UTC")
                // Strip fractional seconds and timezone suffix for parsing
                val cleaned = isoTimestamp
                    .replace(Regex("\\.[0-9]+"), "")
                    .replace("Z", "")
                val date = format.parse(cleaned) ?: return ""
                val diffMs = Date().time - date.time
                val diffMin = diffMs / 60_000

                when {
                    diffMin < 1 -> "just now"
                    diffMin < 60 -> "${diffMin}m ago"
                    diffMin < 1440 -> "${diffMin / 60}h ago"
                    else -> "${diffMin / 1440}d ago"
                }
            } catch (_: Exception) {
                ""
            }
        }
    }
}

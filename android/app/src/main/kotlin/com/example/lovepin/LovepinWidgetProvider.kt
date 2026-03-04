package com.example.lovepin

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import java.io.File
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
            val imagePath = prefs.getString("image_path", null) ?: ""

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

            // --- Sender name ---
            val displayName = if (senderName.isNotEmpty()) senderName else "Your Love"
            val senderLabel = if (displayName == "You") "You" else "From $displayName"
            views.setTextViewText(R.id.widget_sender, senderLabel)
            trySetTextColor(views, R.id.widget_sender, accentColor)

            // --- Divider colour (accent with transparency) ---
            try {
                val accent = Color.parseColor(accentColor)
                val dividerColor = Color.argb(50, Color.red(accent), Color.green(accent), Color.blue(accent))
                views.setInt(R.id.widget_divider, "setColorFilter", dividerColor)
            } catch (_: Exception) {
            }

            // --- Message photo ---
            if (imagePath.isNotEmpty()) {
                try {
                    val file = File(imagePath)
                    Log.d("LovepinWidget", "Image path: $imagePath, exists: ${file.exists()}, size: ${if (file.exists()) file.length() else 0}")
                    if (file.exists() && file.length() > 0) {
                        // Scale down to fit widget and stay under Binder IPC limit
                        val scaled = decodeScaledBitmap(file.absolutePath, 500, 300)
                        if (scaled != null) {
                            views.setImageViewBitmap(R.id.widget_image, scaled)
                            views.setViewVisibility(R.id.widget_image, View.VISIBLE)
                            Log.d("LovepinWidget", "Image set: ${scaled.width}x${scaled.height}")
                        } else {
                            Log.w("LovepinWidget", "Failed to decode bitmap")
                            views.setViewVisibility(R.id.widget_image, View.GONE)
                        }
                    } else {
                        Log.w("LovepinWidget", "Image file missing or empty")
                        views.setViewVisibility(R.id.widget_image, View.GONE)
                    }
                } catch (e: Exception) {
                    Log.e("LovepinWidget", "Image load error", e)
                    views.setViewVisibility(R.id.widget_image, View.GONE)
                }
            } else {
                views.setViewVisibility(R.id.widget_image, View.GONE)
            }

            // --- Message content ---
            views.setTextViewText(
                R.id.widget_message,
                if (messageContent.isNotEmpty()) messageContent else if (imagePath.isNotEmpty()) "" else "No messages yet"
            )
            // Hide text if only photo with no caption
            if (messageContent.isEmpty() && imagePath.isNotEmpty()) {
                views.setViewVisibility(R.id.widget_message, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_message, View.VISIBLE)
            }
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

        /**
         * Decode a bitmap from [path] scaled down so neither dimension exceeds
         * [maxW]×[maxH].  This keeps the Binder transaction well under the ~1 MB
         * limit that RemoteViews imposes.
         */
        private fun decodeScaledBitmap(path: String, maxW: Int, maxH: Int): Bitmap? {
            // First pass — read dimensions only
            val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, opts)
            val w = opts.outWidth
            val h = opts.outHeight
            if (w <= 0 || h <= 0) return null

            // Calculate inSampleSize (power of 2)
            var sampleSize = 1
            while (w / sampleSize > maxW || h / sampleSize > maxH) {
                sampleSize *= 2
            }

            // Second pass — decode with downsampling
            val decodeOpts = BitmapFactory.Options().apply { inSampleSize = sampleSize }
            return BitmapFactory.decodeFile(path, decodeOpts)
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

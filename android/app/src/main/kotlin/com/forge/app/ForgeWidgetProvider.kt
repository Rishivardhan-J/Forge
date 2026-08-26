package com.forge.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import com.example.forge.R

class ForgeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            
            // Set up intent for the list view service
            val intent = Intent(context, ForgeWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            
            views.setRemoteAdapter(R.id.widget_list_view, intent)
            views.setEmptyView(R.id.widget_list_view, R.id.widget_empty_text)
            
            // Deep link click intent for the whole widget
            val pendingIntent = HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("forge://home"))
            views.setOnClickPendingIntent(R.id.widget_list_view, pendingIntent)
            views.setPendingIntentTemplate(R.id.widget_list_view, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list_view)
        }
    }
}

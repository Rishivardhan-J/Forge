package com.forge.app

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import com.example.forge.R

class ForgeWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ForgeWidgetViewsFactory(this.applicationContext)
    }
}

class ForgeWidgetViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private var data: JSONArray = JSONArray()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val widgetData = HomeWidgetPlugin.getData(context)
        val jsonString = widgetData.getString("forge_today_summary", "[]")
        try {
            data = JSONArray(jsonString)
        } catch (e: Exception) {
            data = JSONArray()
        }
    }

    override fun onDestroy() {}

    override fun getCount(): Int = data.length()

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_list_item)
        try {
            val item = data.getJSONObject(position)
            val name = item.getString("name")
            val status = item.getString("status")

            views.setTextViewText(R.id.item_habit_name, name)

            // Teal: #26A69A, Amber: #FFA726, Muted: #8E8E93, Error/Missed: #CF6679
            val color = when (status) {
                "done", "doneViaTwoMinute" -> Color.parseColor("#26A69A")
                "pending" -> Color.parseColor("#8E8E93")
                "missed" -> Color.parseColor("#CF6679")
                "excused" -> Color.parseColor("#FFA726")
                else -> Color.parseColor("#8E8E93")
            }
            
            // In a real app we might use a dynamic shape, but setting color filter works on some versions.
            // A reliable way for older widgets is setInt on setColorFilter or changing background resource.
            // Since we use a shape drawable, we can tint it.
            views.setInt(R.id.item_status_indicator, "setColorFilter", color)
            
            // Add fillInIntent for clicking
            val fillInIntent = Intent()
            views.setOnClickFillInIntent(R.id.item_habit_name, fillInIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}

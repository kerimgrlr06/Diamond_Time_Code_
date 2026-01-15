package com.example.diamond_time

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

// 1. Standart/Geniş Widget (Vakit + Sayaç + Ayet)
class AppWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        updateAllWidgets(context, appWidgetManager, appWidgetIds, widgetData, R.layout.widget_layout)
    }
}

// 2. Mini Sayaç (Sadece 00:00:00)
class WidgetMiniProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        updateAllWidgets(context, appWidgetManager, appWidgetIds, widgetData, R.layout.widget_mini_layout)
    }
}

// 3. Vakit Listesi (Tüm Liste)
class WidgetListProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        updateAllWidgets(context, appWidgetManager, appWidgetIds, widgetData, R.layout.widget_info_list)
    }
}

// 4. Günün Ayeti (Sadece Metin Odaklı)
class WidgetExtra1Provider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        updateAllWidgets(context, appWidgetManager, appWidgetIds, widgetData, R.layout.widget_info_extra1)
    }
}

// 5. Hicri Takvim & Vakit
class WidgetExtra2Provider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        updateAllWidgets(context, appWidgetManager, appWidgetIds, widgetData, R.layout.widget_info_extra2)
    }
}

// ✅ ORTAK GÜNCELLEME MOTORU
fun updateAllWidgets(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences, layout: Int) {
    for (id in ids) {
        val views = RemoteViews(context.packageName, layout).apply {
            
            // Flutter tarafında 'saveWidgetData' ile gönderdiğin isimleri (key) burada yakalıyoruz
            val vakitIsmi = data.getString("vakit_adi", "Diamond Time")
            val kalanSure = data.getString("kalan_sure", "--:--:--")
            val gununAyeti = data.getString("gunun_ayeti", "Huzurlu Vakitler...")

            // Her widget'ta bu ID'lerin olması gerekmez, try-catch sistemiyle hatayı önlüyoruz
            try { setTextViewText(R.id.widget_title, vakitIsmi) } catch (e: Exception) {}
            try { setTextViewText(R.id.widget_vakit, kalanSure) } catch (e: Exception) {}
            try { setTextViewText(R.id.widget_ayet, gununAyeti) } catch (e: Exception) {}
        }
        manager.updateAppWidget(id, views)
    }
}
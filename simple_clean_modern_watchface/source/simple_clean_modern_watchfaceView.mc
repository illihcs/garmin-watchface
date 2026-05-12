import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;
import Toybox.Position;
import Toybox.Math;

class simple_clean_modern_watchfaceView extends WatchUi.WatchFace {

    private var screenWidth = 0;
    private var screenHeight = 0;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Clear background
        // For AMOLED, ensuring mostly black background is essential to save power.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Screen dimensions (Epix 2 Pro 47mm is 416x416)
        var cx = screenWidth / 2;
        var cy = screenHeight / 2;

        // --- TIME ---
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour && hours > 12) {
            hours = hours - 12;
        } else if (hours == 0 && !System.getDeviceSettings().is24Hour) {
            hours = 12;
        }
        var timeString = Lang.format("$1$:$2$", [hours, clockTime.min.format("%02d")]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        // Use a large numeric font for time
        dc.drawText(cx, cy - 60, Graphics.FONT_NUMBER_HOT, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- DATE ---
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$, $2$ $3$", [info.day_of_week, info.day, info.month]);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 15, Graphics.FONT_MEDIUM, dateString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- BATTERY ---
        var stats = System.getSystemStats();
        var batteryPct = stats.battery;
        var batY = cy + 60;
        
        // Draw Battery Icon
        var batColor = Graphics.COLOR_GREEN;
        if (batteryPct < 20) {
            batColor = Graphics.COLOR_RED;
        } else if (batteryPct < 40) {
            batColor = Graphics.COLOR_YELLOW;
        }
        
        // Draw outline
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(cx - 20, batY - 8, 40, 16);
        dc.drawRectangle(cx + 20, batY - 4, 3, 8); // positive terminal
        
        // Draw fill
        dc.setColor(batColor, Graphics.COLOR_TRANSPARENT);
        var fillWidth = (36 * (batteryPct / 100.0)).toNumber();
        if (fillWidth > 0) {
            dc.fillRectangle(cx - 18, batY - 6, fillWidth, 12);
        }

        // Draw battery text
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, batY + 20, Graphics.FONT_XTINY, batteryPct.format("%d") + "%", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- HEART RATE ---
        var hrValue = "--";
        var activityInfo = Activity.getActivityInfo();
        if (activityInfo != null && activityInfo.currentHeartRate != null) {
            hrValue = activityInfo.currentHeartRate.toString();
        } else {
            // Try to get historical HR if current is null
            var hrIterator = ActivityMonitor.getHeartRateHistory(1, true);
            if (hrIterator != null) {
                var sample = hrIterator.next();
                if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    hrValue = sample.heartRate.toString();
                }
            }
        }
        var leftX = cx - 90;
        drawHeartIcon(dc, leftX, batY - 15, Graphics.COLOR_RED);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX, batY + 15, Graphics.FONT_TINY, hrValue, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- STEPS ---
        var stepCount = 0;
        var actMonInfo = ActivityMonitor.getInfo();
        if (actMonInfo != null && actMonInfo.steps != null) {
            stepCount = actMonInfo.steps;
        }
        var rightX = cx + 90;
        drawShoeIcon(dc, rightX, batY - 15, Graphics.COLOR_BLUE);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX, batY + 15, Graphics.FONT_TINY, stepCount.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- SUNRISE / SUNSET ---
        // Fetch sunrise and sunset times
        var sunriseStr = "--:--";
        var sunsetStr = "--:--";
        
        if (Toybox has :Weather) {
            var conditions = Weather.getCurrentConditions();
            if (conditions != null && conditions.observationLocationPosition != null) {
                var location = conditions.observationLocationPosition;
                var sunriseMoment = Weather.getSunrise(location, now);
                var sunsetMoment = Weather.getSunset(location, now);
                
                if (sunriseMoment != null) {
                    var srInfo = Gregorian.info(sunriseMoment, Time.FORMAT_SHORT);
                    var srHr = srInfo.hour;
                    if (!System.getDeviceSettings().is24Hour && srHr > 12) { srHr -= 12; }
                    else if (!System.getDeviceSettings().is24Hour && srHr == 0) { srHr = 12; }
                    sunriseStr = Lang.format("$1$:$2$", [srHr, srInfo.min.format("%02d")]);
                }
                
                if (sunsetMoment != null) {
                    var ssInfo = Gregorian.info(sunsetMoment, Time.FORMAT_SHORT);
                    var ssHr = ssInfo.hour;
                    if (!System.getDeviceSettings().is24Hour && ssHr > 12) { ssHr -= 12; }
                    else if (!System.getDeviceSettings().is24Hour && ssHr == 0) { ssHr = 12; }
                    sunsetStr = Lang.format("$1$:$2$", [ssHr, ssInfo.min.format("%02d")]);
                }
            }
        }
        
        var dateLeftX = cx - 90;
        var dateRightX = cx + 90;
        var dateY = cy + 15;
        
        drawSunIcon(dc, dateLeftX, dateY - 20, Graphics.COLOR_YELLOW, true); // Sunrise
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dateLeftX, dateY + 10, Graphics.FONT_XTINY, sunriseStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawSunIcon(dc, dateRightX, dateY - 20, Graphics.COLOR_ORANGE, false); // Sunset
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dateRightX, dateY + 10, Graphics.FONT_XTINY, sunsetStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }
    
    // --- VECTOR ICON HELPERS ---
    
    private function drawHeartIcon(dc as Dc, x as Number, y as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - 4, y - 2, 5);
        dc.fillCircle(x + 4, y - 2, 5);
        dc.fillPolygon([
            [x - 8, y],
            [x + 8, y],
            [x, y + 9]
        ] as Array< [Numeric, Numeric] >);
    }
    
    private function drawShoeIcon(dc as Dc, x as Number, y as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(x, y - 3, 5, 8); 
        dc.fillEllipse(x, y + 4, 4, 6); 
        dc.fillCircle(x - 4, y - 8, 2); 
        dc.fillCircle(x - 1, y - 9, 2);
        dc.fillCircle(x + 2, y - 9, 1);
        dc.fillCircle(x + 4, y - 8, 1);
    }
    
    private function drawSunIcon(dc as Dc, x as Number, y as Number, color as Number, isSunrise as Boolean) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        
        // Half sun
        dc.fillCircle(x, y, 7);
        
        // Hide the bottom half
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x - 10, y, 20, 10);
        
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        // Horizon line
        dc.setPenWidth(2);
        dc.drawLine(x - 10, y + 1, x + 10, y + 1);
        
        // Sun rays
        dc.drawLine(x - 10, y - 5, x - 7, y - 3);
        dc.drawLine(x - 6, y - 9, x - 4, y - 6);
        dc.drawLine(x, y - 11, x, y - 8);
        dc.drawLine(x + 6, y - 9, x + 4, y - 6);
        dc.drawLine(x + 10, y - 5, x + 7, y - 3);
        
        // Arrow up or down
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (isSunrise) {
            dc.drawLine(x, y - 4, x, y + 8);
            dc.drawLine(x - 3, y - 1, x, y - 4);
            dc.drawLine(x + 3, y - 1, x, y - 4);
        } else {
            dc.drawLine(x, y - 4, x, y + 8);
            dc.drawLine(x - 3, y + 5, x, y + 8);
            dc.drawLine(x + 3, y + 5, x, y + 8);
        }
        dc.setPenWidth(1);
    }
}

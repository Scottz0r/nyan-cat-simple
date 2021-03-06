using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time.Gregorian;

class NyanCatSimpleView extends WatchUi.WatchFace {

    // Color constants for text and bg stuff.
    const NYAN_BG          = 0x000055;
    const NYAN_FG_TXT      = 0xFFFFFF;
    const NYAN_TIME_SHADOW = 0x000000;

    // For shadows, offset from base position.
    const SHADOW_OFF_X = 3;
    const SHADOW_OFF_Y = 3;

    // Battery constants.
    const BATTERY_HAPPY  = 0x00FF00;
    const BATTERY_MEH    = 0xFFAA00;
    const BATTERY_SAD    = 0xFF0000;
    const BATTERY_WIDTH  = 30;
    const BATTERY_HEIGHT = 10;
    const BATTERY_NUB_H  = 4;
    const BATTERY_NUB_W  = 2;

    // Colors for RNG accent (from rainbow)
    const accentArray = [
        0xFF0000,	// Red
        0xFFAA00,	// Orange
        0xFFFF00,	// Yellow
        0x00FF00,	// Green
        0x55AAFF	// Light Blue
        //0x5500FF	// Violet
    ];

    // Set prevMinute to this to force redraw. This is used to find a difference to
    // the prior minute to avoid high-power mode onUpdate() spam. Making this 0 will
    // break the WatchFace when showing/switch during the first minute of the hour.
    const FORCE_REDRAW = -1;

    var prevMinute; // Tracks the last minute to prevent spam in high power mode.

    var nyanCatBitmap; // Nyan cat image.

    function initialize() {
        WatchFace.initialize();

        prevMinute = FORCE_REDRAW;
    }

    function onLayout(dc) {
        // Initialize Nyan Cat bitmap and set position (centered around top 1/4 of screen).
        nyanCatBitmap = new WatchUi.Bitmap({
            :rezId=>Rez.Drawables.NyanCat,
            :locX=>0,
            :locY=>0
        });

        var bmPosY = (dc.getHeight() / 4) - (nyanCatBitmap.getDimensions()[1] / 2);
        nyanCatBitmap.setLocation(0, bmPosY);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        prevMinute = FORCE_REDRAW;
    }

    // Update the view
    function onUpdate(dc) {
        // Get time to see if a full update is needed.
        var clockTime = System.getClockTime();

        if(clockTime.min != prevMinute) {
            drawFullScreen(dc);
        }
        //else {
        //    System.println("Not drawing");
        //}

        prevMinute = clockTime.min;
    }

    function drawFullScreen(dc) {
        // Refresh background.
        dc.setColor(NYAN_BG, NYAN_BG);
        dc.clear();

        // DEBUGGING - for debugging: Draw some alignment lines.
        //dc.setColor(0xFFFF55, Graphics.COLOR_TRANSPARENT);
        //dc.drawRectangle(dc.getWidth() / 2, 0, 1, dc.getHeight());

        // Draw Nyan Cat
        nyanCatBitmap.draw(dc);

        var deviceSettings = System.getDeviceSettings();
        var dateInfo = Gregorian.info(Time.now(), Time.FORMAT_LONG);

        // Day of week and day of month (under Nyan cat).
        var dateString = Lang.format("$1$ $2$", [dateInfo.day_of_week, dateInfo.day]);
        var datePosY = (dc.getHeight() / 2) - 10;

        dc.setColor(NYAN_FG_TXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            (dc.getWidth() / 2),
            datePosY,
            Graphics.FONT_XTINY,
            dateString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );

        // Get and show the current time. Adjust based off of 12/24 hour format.
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        var minute = clockTime.min.format("%02d");

        if(!deviceSettings.is24Hour){
            if(hour > 12){
                hour -= 12;
            }
            else if(hour == 0){
                hour = 12;
            }
        }

        var timePosY = dc.getHeight() / 2 + 30;

        // Compute full size of text to know how to position this.
        // The padding on each side of this full text will be (dc.getWidth - fullTimeWidth) / 2.
        var fullTimeString = Lang.format("$1$:$2$", [hour, minute]);
        var fullTimeWidth = dc.getTextWidthInPixels(fullTimeString, Graphics.FONT_NUMBER_THAI_HOT);
        var timeStartPosX = (dc.getWidth() - fullTimeWidth) / 2;

        // Draw a shadow of the full time.
        dc.setColor(NYAN_TIME_SHADOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            (timeStartPosX + SHADOW_OFF_X),
            (timePosY + SHADOW_OFF_Y),
            Graphics.FONT_NUMBER_THAI_HOT,
            fullTimeString,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );

        // Draw hour and colon part. Save size to know how to offset the minutes.
        var hourString = Lang.format("$1$:", [hour]);
        var hourTimeSize = dc.getTextWidthInPixels(hourString, Graphics.FONT_NUMBER_THAI_HOT);

        dc.setColor(NYAN_FG_TXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            timeStartPosX,
            timePosY,
            Graphics.FONT_NUMBER_THAI_HOT,
            hourString,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );

        // Darw the minutes from the last pixel from the hour & color string. Use random accent color.
        var accentColor = getRngAccent();
        var minuteString = minute.toString();//Lang.format("$1$", [minute]);

        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            (timeStartPosX + hourTimeSize),
            timePosY,
            Graphics.FONT_NUMBER_THAI_HOT,
            minuteString,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );

        drawBattery(dc);
    }

    // Draw a battery graphic in the bottom 1/8th of the screen.
    function drawBattery(dc) {
        var systemStatus = System.getSystemStats();

        // Battery graphic. Set to lower 1/8 of screen.
        var batteryY = (dc.getHeight() / 8 * 7) - (BATTERY_HEIGHT / 2);
        var batteryX = (dc.getWidth() / 2) - (BATTERY_WIDTH / 2);

        // Battery color is based off of percent as well. Based off of Nyan image.
        var batteryColor = BATTERY_HAPPY;
        if(systemStatus.battery >= 20.0 && systemStatus.battery < 50.0){
            batteryColor = BATTERY_MEH;
        }
        else if(systemStatus.battery < 20.0){
            batteryColor = BATTERY_SAD;
        }

        // Fill battery charge rectange.
        dc.setColor(batteryColor, NYAN_BG);
        dc.fillRectangle(
          batteryX,
          batteryY,
          (BATTERY_WIDTH * (systemStatus.battery / 100.0)),
          BATTERY_HEIGHT
          );

        // Draw rectangle border
        dc.setColor(NYAN_FG_TXT, NYAN_BG);
        dc.drawRectangle(batteryX, batteryY, BATTERY_WIDTH, BATTERY_HEIGHT);

        // Draw a little battery positive terminal nub.
        // The Y position of this will be the middle of the battery less half of the height of the nub.
        var batteryNubY = batteryY + (BATTERY_HEIGHT / 2) - (BATTERY_NUB_H / 2);
        dc.fillRectangle(
          (batteryX + BATTERY_WIDTH),
          batteryNubY,
          BATTERY_NUB_W,
          BATTERY_NUB_H)
          ;
    }

    // Get a RNG accent color.
    function getRngAccent() {
        var rng = Math.rand();
        var i = rng % accentArray.size();
        return accentArray[i];
    }

    //function onPartialUpdate(dc) {
    //}

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    //function onHide() {
    //}

    // The user has just looked at their watch. Timers and animations may be started here.
    //function onExitSleep() {
    //}

    // Terminate any active timers and prepare for slow updates.
    //function onEnterSleep() {
    //}

}

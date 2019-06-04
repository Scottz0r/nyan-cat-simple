using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time.Gregorian;

class NyanCatSimpleView extends WatchUi.WatchFace {

	const NYAN_BG = 0x000055;
	const NYAN_FG_TXT = 0xFFFFFF;
	const NYAN_ACCENT = 0xFFAAFF;
	
	const BATTERY_HAPPY = 0x00FF00;
	const BATTERY_MEH = 0xFFAA00;
	const BATTERY_SAD = 0xFF0000;
	const BATTERY_WIDTH = 30;
	const BATTERY_HEIGHT = 8;

	var nyanCatBitmap;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        // Initialize Nyan Cat bitmap and set position (centered around top 1/4 of screen.)
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
    }

    // Update the view
    function onUpdate(dc) {
    	var deviceSettings = System.getDeviceSettings();
    	var systemStatus = System.getSystemStats();
    
    	// Draw background.
    	dc.setColor(NYAN_BG, Graphics.COLOR_TRANSPARENT);
    	dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
    
    	// TODO - for debugging: Draw some alignment lines.
    	//dc.setColor(0xFFFF55, Graphics.COLOR_TRANSPARENT);
    	//dc.drawRectangle(dc.getWidth() / 2, 0, 1, dc.getHeight());
    
		// Draw Nyan Cat
        nyanCatBitmap.draw(dc);

		// Get and show date
		var dateInfo = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var dateString = Lang.format("$1$ $2$", [dateInfo.day_of_week, dateInfo.day]);
        var datePosY = (dc.getHeight() / 2) - 10;
        
        dc.setColor(NYAN_FG_TXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, datePosY, Graphics.FONT_XTINY, dateString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    
    	// TODO - Accent the minutes. How to do this?
    
        // Get and show the current time. Adjust based off of 12/24 hour format.
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        
        if(hour > 12 && !deviceSettings.is24Hour){
        	hour -= 12;
        }
        
        var timeString = Lang.format("$1$:$2$", [hour, clockTime.min.format("%02d")]);
		var timePosY = dc.getHeight() / 2 + 30;
		
		dc.setColor(NYAN_FG_TXT, Graphics.COLOR_TRANSPARENT);
		dc.drawText(dc.getWidth() / 2, timePosY, Graphics.FONT_NUMBER_THAI_HOT, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
				
		// Battery graphic. Set to lower 1/8 of screen.
		var batteryY = (dc.getHeight() / 8 * 7) - (BATTERY_HEIGHT / 2);
		var batteryX = dc.getWidth() / 2 - (BATTERY_WIDTH / 2);
				
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
		dc.fillRectangle(batteryX, batteryY, BATTERY_WIDTH * (systemStatus.battery / 100.0), BATTERY_HEIGHT);
		
		// Draw rectangle border
		dc.setColor(NYAN_FG_TXT, NYAN_BG);
		dc.drawRectangle(batteryX, batteryY, BATTERY_WIDTH, BATTERY_HEIGHT);
    }

	//function onPartialUpdate(dc) {
	//}

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

}

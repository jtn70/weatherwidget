/**
 * drawingarea.d
 *
 * Code for drawing window with Cairo. weatherwiget application
 * 
 * Authors: 
 *   Jens Torgeir Næss, jtn70 at hotmail dot com
 * 
 * Version: 1.0
 *
 * Date: February 20, 2014
 *
 * Copyright: (C) 2014  Jens Torgeir Næss
 *
 * License:
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import application;
import forecast;

import std.conv;
import std.stdio;
import std.datetime;
import std.format;
import std.string;

import gtk.Widget;
import gtk.DrawingArea;

import cairo.Context;
import cairo.ImageSurface;

import pango.PgCairo;
import pango.PgLayout;
import pango.PgFontDescription;

class MainDrawingArea : DrawingArea
{
    static string weekdayname[] = 
        ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    forecast wfc;
    ImageSurface wicon;
    DateTime sdate;
    DateTime edate;
    DateTime workDate;

    this()
    {
        wfc = new forecast(weatherservice, location);
        addOnDraw(&mainDrawCallback);
    }

    bool mainDrawCallback(Context cr, Widget widget)
    {
        cr.save();
        {
            // Draw background, rounded opaque rectangle.
            // cr.setSourceRgba(0.75, 0.75, 0.75, 1);
            // drawRoundedRectangle(&cr, 1, 1, to!double(windowwidth)-1, to!double(windowheight)-1, 40);
            // cr.stroke();
            // cr.setSourceRgba(0, 0, 0, 0.6); 
            // drawRoundedRectangle(&cr, 2, 2, to!double(windowwidth)-2, to!double(windowheight-2), 40);  
            // cr.fill();
            // cr.stroke();
            
            // drawRectBorderUL(&cr, 1, 1, to!double(windowwidth), to!double(windowheight));
            // drawRectBorderUL(&cr, 1, 1, to!double(windowwidth), to!double(windowheight));

            cr.setSourceRgba(0, 0, 0, 0.6);
            drawRectBorder(cr, 3, 3, to!double(windowwidth)-4, to!double(windowheight)-4);
            cr.stroke();
            cr.fill();

            cr.setSourceRgba(0.8, 0.8, 0.8, 1);
            drawRectBorderUL(cr, 0, 0, to!double(windowwidth)-1, to!double(windowheight)-1);
            cr.setSourceRgba(0.4, 0.4, 0.4, 1);
            drawRectBorderLR(cr, 0, 0, to!double(windowwidth)-1, to!double(windowheight)-1);
            cr.stroke();

            cr.setSourceRgba(0.4, 0.4, 0.4, 1);
            drawRectBorderUL(cr, 2,2, to!double(windowwidth)-3, to!double(windowheight)-3);
            cr.setSourceRgba(0.8, 0.8, 0.8, 1);
            drawRectBorderLR(cr, 2,2, to!double(windowwidth)-3, to!double(windowheight)-3);
            cr.stroke();

            cr.setSourceRgba(0.75, 0.75, 0.75, 1);
            drawRectBorder(cr, 1, 1, to!double(windowwidth)-2, to!double(windowheight)-2);
            cr.stroke();


            
            // Draw current weathericon
            wicon = ImageSurface.createFromPng(composeWiconFilename(wfc.weatherSymbol()));
            cr.setSourceSurface(wicon, 60, 20);
            cr.paintWithAlpha(0.8);

            drawDivider(cr, 40);

            // Display current weatherinformation
            cr.selectFontFace("Bitstream Vera Sans", cairo_font_slant_t.NORMAL, cairo_font_weight_t.NORMAL);
            cr.setFontSize(14);
            cr.setSourceRgba(1, 1, 1, 1);
            printText(cr, 10, 20, wfc.locationText);
            cr.setSourceRgba(0.7, 0.7, 0.7, 1);
            cr.setFontSize(9);
            sdate = wfc.updateLastTime();
            edate = wfc.updateNextTime();
            printText(cr, 10, 32, (format("Updated: %02d:%02d.   Next update: %02d:%02d", sdate.hour, sdate.minute, edate.hour, edate.minute)));
            cr.setSourceRgba(1, 1, 1, 1);
            cr.setFontSize(26);
            printText(cr, 10, 70, format("%s °C", wfc.temperature()));
            cr.setFontSize(14);
            printText(cr, 10, 84, format("%s", wfc.weatherSymbolText()));
            cr.setFontSize(10);
            cr.setSourceRgba(0.7, 0.7, 0.7, 1);
            printText(cr, 10, 100, format("Feels like %0.0f °C", wfc.temperatureWindchill())); 
            printText(cr, 10, 115, format("Precipitation: %s mm", wfc.precipitation()));
            printText(cr, 10, 130, format("Wind: %s (%s m/s)", wfc.windSpeedName(), wfc.windSpeed()));
            printText(cr, 10, 145, format("~ direction: %s (%s°)", wfc.windDirectionCode(), wfc.windDirection()));
            printText(cr, 10, 160, format("Pressure: %s (%s)", wfc.pressure(), wfc.pressureTrendText()));
            sdate = wfc.timeSunrise();
            edate = wfc.timeSunset();
            printText(cr, 10, 175, format("Sunrise: %02d:%02d   Sunset: %02d:%02d", sdate.hour, sdate.minute, edate.hour, edate.minute));
            
            drawDivider(cr, 185);
    
            // Next period (= the period in 6 hours)
            sdate = cast(DateTime)Clock.currTime + dur!"hours"(6);

            // Next graphic (scaled to 50%)
            cr.scale(0.5, 0.5);
            wicon = ImageSurface.createFromPng(composeWiconFilename(wfc.weatherSymbol(sdate), sdate));
            cr.setSourceSurface(wicon, 130 * 2, 185 * 2);
            cr.paintWithAlpha(0.9);
            cr.scale(2, 2);


            cr.setSourceRgba(1, 1, 1, 1);
            cr.setFontSize(14);
            printText(cr, 10, 200, wfc.periodText(sdate).capitalize());
            cr.setFontSize(16);
            printText(cr, 10, 220, format("%s °C", wfc.temperature(sdate)));
            cr.setFontSize(10);
            cr.setSourceRgba(0.7, 0.7, 0.7, 1);
            printText(cr, 10, 235, format("%s", wfc.weatherSymbolText(sdate)));

            drawDivider(cr, 250);

            // Next day (= 12.01 next day)
            sdate = cast(DateTime)Clock.currTime + dur!"days"(1);
            sdate.hour = 12;
            sdate.minute = 1;
        
            // Graphic scaled to 50%
            cr.scale(0.5, 0.5);
            wicon = ImageSurface.createFromPng(composeWiconFilename(wfc.weatherSymbol(sdate), sdate));
            cr.setSourceSurface(wicon, 130 * 2, 245 * 2);
            cr.paintWithAlpha(0.9);
            cr.scale(2, 2);

            cr.setSourceRgba(1, 1, 1, 1);
            cr.setFontSize(14);
            printText(cr, 10, 270, "Tomorrow");
            cr.setFontSize(10);
            cr.setSourceRgba(0.7, 0.7, 0.7, 1);
            printText(cr, 10, 282, format("%s %s.", weekdayname[sdate.dayOfWeek], sdate.day));
            cr.setSourceRgba(1, 1, 1, 1);
            cr.setFontSize(16);
            printText(cr, 10, 300, format("%s °C", wfc.temperature(sdate)));
            cr.setSourceRgba(0.7, 0.7, 0.7, 1);
            cr.setFontSize(10);
            printText(cr, 10, 315, format("%s", wfc.weatherSymbolText(sdate)));
            drawDivider(cr, 325);

            // 2 days (12.01)
            sdate = sdate + dur!"days"(2);


            // Graphics scaled 50%
            cr.scale(0.5, 0.5);
            wicon = ImageSurface.createFromPng(composeWiconFilename(wfc.weatherSymbol(sdate), sdate));
            cr.setSourceSurface(wicon, 130 * 2, 325 * 2);
            cr.paintWithAlpha(0.9);
            cr.scale(2, 2);

            cr.setSourceRgba(1, 1, 1, 1);
            cr.setFontSize(14);
            printText(cr, 10, 340, format("%s %s.", weekdayname[sdate.dayOfWeek], sdate.day));
            cr.setFontSize(16);
            printText(cr, 10, 360, format("%s °C", wfc.temperature(sdate)));
            cr.setSourceRgba(0.7, 0.7, 0.7, 1);
            cr.setFontSize(10);
            printText(cr, 10, 375, format("%s", wfc.weatherSymbolText(sdate)));


        }
        cr.restore();

        return true;
    }

    void drawDivider(ref Context cr, int ypos)
    {
        double width;
        width = cr.getLineWidth();
        cr.setLineWidth(0.8);
        cr.setSourceRgba(1, 1, 1, 1);
        cr.moveTo(4, ypos);
        cr.lineTo(to!double(windowwidth)-4, ypos);
        cr.stroke();
        cr.setLineWidth(width);
    }

    void printText(ref Context cr, int xpos, int ypos, string text)
    {
        cr.moveTo(xpos, ypos);
        cr.showText(text);
    }

    /**
     * Draw a rounded rectangle
     * 
     * Algirithm from http://cairographics.org/cookbook/roundedrectangles Method C
     *
     *  A****BQ
     * H      C
     * *      *
     * *      *
     * G      D
     *  F****E
     */
    private void drawRoundedRectangle(ref Context cr, double x, double y, double w, double h, double r)
    {
        cr.moveTo(x+r, y);                          // Move to A
        cr.lineTo(x+w-r, y);                        // Straight line to B
        cr.curveTo(x+w, y, x+w, y, x+w, y+r);  // Curve to C, Control points are both at Q
        cr.lineTo(x+w,y+h-r);                       // Move to D
        cr.curveTo(x+w, y+h, x+w, y+h, x+w-r, y+h); // Curve to E
        cr.lineTo(x+r, y+h);                        // Line to F
        cr.curveTo(x, y+h, x, y+h, x, y+h-r);       // Curve to G
        cr.lineTo(x, y+r);                          // Curve to H
        cr.curveTo(x, y, x, y, x+r, y);             // Curve to A
        return;
    }

    private void drawRectBorderUL(ref Context cr, double x, double y, double w, double h)
    {
        cr.moveTo(x,y+h);
        cr.lineTo(x,y);
        cr.lineTo(x+w-1,y);
    }

    private void drawRectBorderLR(ref Context cr, double x, double y, double w, double h)
    {
        cr.moveTo(x+1,y+h);
        cr.lineTo(x+w,y+h);
        cr.lineTo(x+w,y);
    }

    private void drawRectBorder(ref Context cr, double x, double y, double w, double h)
    {
        cr.moveTo(x,y);
        cr.lineTo(x+w,y);
        cr.lineTo(x+w,y+h);
        cr.lineTo(x,y+h);
        cr.lineTo(x,y);
    }

    private string composeWiconFilename(int weathertype, DateTime seltime = cast(DateTime)Clock.currTime())
    {
        string filename;
       
        if (seltime.timeOfDay > wfc.timeSunrise().timeOfDay && seltime.timeOfDay < wfc.timeSunset.timeOfDay)
            filename =  wiconsdir ~ to!string(weathertype) ~ ".day.png";
        else
            filename = wiconsdir ~ to!string(weathertype) ~ ".night.png";
       
        return filename;
    }


}
/**
 * window.d
 *
 * Code for main window, weatherwiget application
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
import drawingarea;
import about;

import std.string;
import std.conv;

import gdk.Event;
import gdk.Screen;
import gdk.Visual;

import gtk.Main;
import gtk.MainWindow;
import gtk.AboutDialog;
import gtk.Widget;
import gtk.DrawingArea;
import gtk.Menu;
import gtk.MenuItem;
import gtk.SeparatorMenuItem;

class WeatherWindow : MainWindow
{
    Menu popupmenu;
    Screen screen;
    Visual visual;
    MainDrawingArea mda;

    this()
    {
        super(format("weatherwidget: %s", verstring));

        // Initialize popup menu
        popupmenu = new Menu();
        MenuItem menuQuitItem = new MenuItem("Quit");
        MenuItem menuAboutItem = new MenuItem("About");
        menuAboutItem.addOnButtonRelease(&onAbout);
        menuQuitItem.addOnButtonRelease(&onQuit);
        popupmenu.append(menuAboutItem);
        popupmenu.append(new SeparatorMenuItem());
        popupmenu.append(menuQuitItem);

        // Turn transparency on
        screen = getScreen();
        visual = screen.getRgbaVisual();
        if (visual && screen.isComposited() == true)
            setVisual(visual); 

        // Set various gtk window settings
        setAppPaintable(true);
        setDecorated(false);
        setKeepBelow(true);
        setSkipTaskbarHint(true);
        setSkipPagerHint(true);
        setAcceptFocus(true);

        // Set default window size and move the window
        setDefaultSize (windowwidth, windowheight);
        move (windowxpos, windowypos);

        mda = new MainDrawingArea();

        mda.addOnButtonPress(&onButtonPress);
        popupmenu.attachToWidget(mda, null);

        add (mda);
        mda.show();
        showAll();
    }

    public bool onQuit(Event event, Widget widget)
    {
        if (event.type == EventType.BUTTON_RELEASE)
        {
            GdkEventButton* buttonEvent = event.button;

            if (buttonEvent.button == 1)
            {
                Main.quit();
                return true;
            }
        }
        return false;
    }

    public bool onAbout(Event event, Widget widget)
    {
        if (event.type == EventType.BUTTON_RELEASE)
        {
            GdkEventButton* buttonEvent = event.button;

            if (buttonEvent.button == 1)
            {
                AboutDialog about = new About();

                about.run();
                about.hide();

                return true;
            }
        }
        return false;
    }

    public bool onButtonPress(Event event, Widget widget)
    {
        if (event.type == EventType.BUTTON_PRESS)
        {
            GdkEventButton* buttonEvent = event.button;

            if (buttonEvent.button == 3)
            {
                popupmenu.showAll();
                popupmenu.popup(buttonEvent.button, buttonEvent.time);

                return true;
            }
        }
        return false;
    }
}
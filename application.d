/**
 * weatherwidget.d
 *
 * weatherwiget application
 *
 * Compile with: 
 *  dmd -release -O -inline application.d window.d drawingarea.d forecast.d kxml/xml.d -L-lphobos2 -L-lcurl -L-lgtkd-2 -ofweatherwidget  
 *     There is an error with the DMD linker, the only solution is to build the project with:
 *     -release -O -inline
 * 
 * Run with: ./weatherwidget -x=20 -y=500
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

module weatherwidget;

import window;

import std.stdio;
import std.getopt;
import std.conv;

import gtk.Main;
import gtk.MainWindow;

public const string verstring = "1.0";
public const string copstring = "Copyright (C) 2014  Jens Torgeir Næss";
public const string licstring = "GNU General Public License v3";
public const string wiconsdir = "/home/jtnadmin/Code/weather/icons/";

public int windowxpos = 20;
public int windowypos = 20;
public int windowwidth = 240;
public int windowheight = 420;
public string weatherservice = "yr";
public string location = "";

void main(string[] args)
{
    bool ver = false;
    bool hlp = false;
    string argxpos;
    string argypos;

    Main.init(args);

    getopt(args,
        "xpos|x", &argxpos,
        "ypos|y", &argypos,
        "help|h", &hlp,
        "version|v", &ver,
        "weatherservice|w", &weatherservice,
        "location|l", &location);

    if (hlp == true)
    {
        showHelptext();
        return;
    }

    if (ver == true)
    {
        showVersion();
        return;
    }

    if (argxpos != "")
        windowxpos = to!int(argxpos);
    if (argypos != "")
        windowypos = to!int(argypos);

    if (weatherservice == "" || location == "")
    {
        writeln ("ERROR: The weatherservice name or the location name is not specified.");
        writeln ("       Use --help for command line options.");
        return;
    }

    new WeatherWindow();

    Main.run();
}

private void showHelptext()
{
    writeln("Usage: textclock [OPTION]...");
    writeln("Display a textclock widget on the desktop.");
    writeln("");
    writeln("Options:");
    writeln("  -x, --xpos=[PIX]    horizontal position of the widget window (in pixels)");
    writeln("  -y, --ypos=[PIX]    vertical position of the widget window (in pixels)");
    writeln("  -v, --version       version information");
    writeln("  -h, --help          help for the widget (this information :-)");
    writeln("  -w, --weatherservice=[name] currently only yr.no is availiable,");
    writeln("                      leave blank or write yr as weatherservice.");
    writeln("  -l, --location=[location] the location you want information for.");
    writeln("");
    writeln("[PIX] is a whole number from 1 to the horizontal/vertical monitor pixel size");
    writeln("[location] YR: on the form [Country]/[County]/[Town]/[Place]. Test on yr.no");
}

private void showVersion()
{
    writeln("textclock   Version: ", verstring);
    writeln(copstring);
    writeln(licstring);
}

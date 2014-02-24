/**
 * about.d
 *
 * Code for about window, weatherwiget application
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

import std.string;

import gtk.AboutDialog;

class About : AboutDialog
{
    this()
    {
        super();
        setProgramName("weatherwidget");
        setVersion("1.0");
        setCopyright("Copyright (c) 2014   Jens Torgeir Næss");
        setComments("A small application that displays the weather.\nCurrently only working with YR.NO");
        setLicenseType(GtkLicense.GPL_3_0);
        setWebsite("https://github.com/jtn70/weatherwidget");
        setWebsiteLabel("https://github.com/jtn70/weatherwidget");
        setAuthors(["Jens Torgeir Næss"]);
        setLogo(null);
        setArtists(["VClouds",
                    "http://vclouds.deviantart.com/art/VClouds-Weather-2-179058977",
                    "The art is licensed under CC (Creative Commons).",
                    "https://creativecommons.org/"]);
        addCreditSection("YR.NO", ["Please see http://www.yr.no for further information."]);
    }

}
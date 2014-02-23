weatherwidget
=============

A window on the desktop with weather information

Compile with: 
dmd -release -O -inline application.d window.d drawingarea.d forecast.d kxml/xml.d -L-lphobos2 -L-lcurl -L-lgtkd-2 -ofweatherwidget  
     There is an error with the DMD linker, the only solution is to build the project with:
     -release -O -inline
 
Run with: ./weatherwidget -x=20 -y=500
 
Authors: 
Jens Torgeir Næss, jtn70 at hotmail dot com
 
Version: 1.0

Date: February 20, 2014

Copyright: (C) 2014  Jens Torgeir Næss

License:
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

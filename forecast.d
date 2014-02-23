/***************************
 * 
 * forecast.d Weather forecast library
 *
 * Authors: Jens Torgeir Næss, jtn70 at hotmail dot com
 *
 * Version: 0.01a
 * 
 * License: GPLv3
 * 
 * This library will get weather forecasts from different internet weather
 * service providers. 
 *
 * Weather service providers:
 * - http://www.yr.no/  Special restrictions apply, please see the site or
 *                      the accompanying text file. The library adheres to
 *                      the restrictions.
 *
 * Properties:
 * linkUrl, linkText,
 * locationText, locationAltitude, locationLatitude, locationLongitude,
 * locationTimezone, locationUtcOffsetMinutes, timeSunrise, timeSunset
 * updateCheck, updateLastTime, updateNextTime
 * Functions:
 * downloadForecast,  updateForecast, text, textDay, textValidFrom,
 * textValidTo, precipitation, precipitationMin, precipitationMax, 
 * weatherSumbol, weatherSymbolText, windDirection, windDirectionCode, 
 * windDirectionName, windSpeed, windSpeedName, temperature, 
 * temperatureWindchill, pressure, pressureTrend, pressureTrendText
 *
 * Provides the follwing helper functions:
 * toFeet, toFarenheit, toKmh, toMph
 *
 * Example:
 *  forecast wfc = new forecast(weatherservice, location);
 *  temp = wfc.temperature();
 *
 * History: 
 * Originally written for Python 3.3 
 * Version 0.01a Is the first D version 
 * - Only service for http://www.yr.no
 */

import kxml.xml;

import std.stdio;
import std.string;
import std.array;
import std.file;
import std.net.curl;
import std.uuid;
import std.path;
import std.datetime;
import std.conv;
import std.math;

enum pressuretrend : byte {
    sinking = -1,
    stable = 0,
    rising = 1
}

alias pressuretrend temperaturetrend;

enum dayperiod : byte {
    night = 0,
    morning = 1,
    afternoon = 2,
    evening = 3
}




/****************
 * 
 * The forecast class uses the kxml xml parser, this is
 * because the std.xml parser in phobvos is suboptimal. 
 * The class will switch to std.xml parser when this is 
 * updated to a better implementation.
 * 
 * Every function that handles xml data in the class,
 * opens and parses a new instance of the xml file.
 * This is deliberate and open to discussion.
 *
 * The class currently only implement yr as provider,
 * and does not have logic yet for other providers.
 */
class forecast
{
    private string weatherservice;
    private string url;
    public string tempfilename;
   

    this(string weatherservice, string location)
    {
        this.weatherservice = weatherservice;

        debug writeln("Weatherservice: ", this.weatherservice);
        
        switch (this.weatherservice)
        {
            case "yr":
                this.url = "www.yr.no/place";
                this.url = this.url ~ dirSeparator ~ location ~ dirSeparator ~ "forecast.xml";
                this.tempfilename = this.url.replace("/", "_").replace(".","_").replace(":", "_");
                this.tempfilename = tempDir() ~ dirSeparator ~ this.tempfilename ~ ".temp";
                debug writeln("Weatherservice URL: ", this.url);
                debug writeln("Temporary filename: ", this.tempfilename);
                updateForecast();
                break;
            default:
                throw new Exception("Unknown weatherservice.");
        }
    }

    public void updateForecast()
    {
        if (exists(tempfilename))
        {
            debug writeln("Temporary file exists.");
            if (updateCheck())
            {
                debug writeln("Updating forecast.");
                downloadForecast();
            }
            else
            {
                debug writeln("Forecast not updated. Current time < next update.");
            }

        }
        else
        {
            debug writeln("Temporary file does not exist.");
            downloadForecast();
        }
    }

    /**
     * Check if weatherforecast should be updated.
     * This checks if current time is greater or equal to 
     * next projected update time. 
     *
     * Returns: bool
     *      true  - weatherforecast need update.
     *      false - weather forecast does no need update.
     */
    @property public bool updateCheck()
    {
        if (Clock.currTime() >= SysTime(updateNextTime()))
            return true;
        else
            return false;
    }

    /**
     * Last time the weather forecast was updated.
     * Returns: 
     *  (DateTime) of last forecast update.
     */
    @property public DateTime updateLastTime()
    { return DateTime.fromISOExtString(getXmlString("weatherdata/meta/lastupdate")); }

    /**
     * Projected next time of weather update.
     * Returns: 
     *  (DateTime) of next projected weather update.
     */
    @property public DateTime updateNextTime()
    { return DateTime.fromISOExtString(getXmlString("weatherdata/meta/nextupdate")); }

    /***
     * Find the selected location string.
     * For example: Stavanger(City) Norway.
     * Returns:
     *  (string) location of the forecast.
     */
    @property public string locationText()
    {
        return getXmlString("weatherdata/location/name") ~ " (" ~
            getXmlString("weatherdata/location/type") ~ ") in " ~
            getXmlString("weatherdata/location/country");
    }

    /**
     * Location altitude in (metres above sealevel)
     * Returns: 
     *  (int) metres above sealevel
     */
    @property public int locationAltitude()
    { return to!int(getXmlStringAttribute("weatherdata/location/location", "altitude")); }

    @property public string locationLatitude()
    { return getXmlStringAttribute("weatherdata/location/location", "latitude"); }

    @property public string locationLongitude()
    { return getXmlStringAttribute("weatherdata/location/location", "longitude"); }

    @property public string locationTimezoneText()
    { return getXmlStringAttribute("weatherdata/location/timezone", "id"); }

    @property public int locationUtcOffsetMinutes()
    { return to!int(getXmlStringAttribute("weatherdata/location/timezone", "utcoffsetMinutes")); }

    @property public string linkUrl()
    { return getXmlStringAttribute("weatherdata/credit/link", "url"); }

    @property public string linkText()
    { return getXmlStringAttribute("weatherdata/credit/link", "text"); }

    @property public DateTime timeSunrise()
    { return DateTime.fromISOExtString(getXmlStringAttribute("weatherdata/sun", "rise")); }

    @property public DateTime timeSunset()
    { return DateTime.fromISOExtString(getXmlStringAttribute("weatherdata/sun", "set")); }

    public string textDay(DateTime seltime = cast(DateTime)Clock.currTime)
    {
        string rawXml;
        string result = "";
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/text/location/time");

        if (seltime < DateTime(Date.fromISOExtString(searchList[0].getAttribute("from")), TimeOfDay(0, 0, 0)))
            seltime = DateTime(Date.fromISOExtString(searchList[0].getAttribute("from")), TimeOfDay(0, 0, 1));

        if (validTextTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if ((DateTime(Date.fromISOExtString(currNode.getAttribute("from")), TimeOfDay(0, 0, 0)) < seltime) &&
                    (DateTime(Date.fromISOExtString(currNode.getAttribute("to")), TimeOfDay(23, 59, 59)) >= seltime))
                {
                    XmlNode[] searchResult = currNode.parseXPath("title");
                    return searchResult[0].getCData();
                }
            }
        }
        throw new DateTimeException("DateTime out of range." );       
    }

    public DateTime textValidFrom(DateTime seltime = cast(DateTime)Clock.currTime)
    {
        string rawXml;

        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/text/location/time");

        if (seltime < DateTime(Date.fromISOExtString(searchList[0].getAttribute("from")), TimeOfDay(0, 0, 0)))
            seltime = DateTime(Date.fromISOExtString(searchList[0].getAttribute("from")), TimeOfDay(0, 0, 1));

        if (validTextTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime(Date.fromISOExtString(currNode.getAttribute("from")), TimeOfDay(0, 0, 0)) < seltime &&
                    DateTime(Date.fromISOExtString(currNode.getAttribute("to")), TimeOfDay(23, 59, 59)) >= seltime)
                {
                    return DateTime(Date.fromISOExtString(currNode.getAttribute("from")), TimeOfDay(0, 0, 0));
                }
            }
        }
        
        throw new DateTimeException("DateTime out of range");
    }

    public DateTime textValidTo(DateTime seltime = cast(DateTime)Clock.currTime)
    {
        string rawXml;

        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/text/location/time");

         if (seltime < DateTime(Date.fromISOExtString(searchList[0].getAttribute("from")), TimeOfDay(0, 0, 0)))
            seltime = DateTime(Date.fromISOExtString(searchList[0].getAttribute("from")), TimeOfDay(0, 0, 1));

        if (validTextTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime(Date.fromISOExtString(currNode.getAttribute("from")), TimeOfDay(0, 0, 0)) < seltime &&
                    DateTime(Date.fromISOExtString(currNode.getAttribute("to")), TimeOfDay(23, 59, 59)) >= seltime)
                {
                    return DateTime(Date.fromISOExtString(currNode.getAttribute("to")), TimeOfDay(23, 59, 59));
                }
            }
        }

        throw new DateTimeException("DateTime out of range");
    }

    public string text(DateTime seltime = cast(DateTime)Clock.currTime)
    {
        string rawXml;

        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/text/location/time");

        if (seltime < DateTime(Date.fromISOExtString(searchList[0].getAttribute("from")), TimeOfDay(0, 0, 0)))
            seltime = DateTime(Date.fromISOExtString(searchList[0].getAttribute("from")), TimeOfDay(0, 0, 1));

        if (validTextTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime(Date.fromISOExtString(currNode.getAttribute("from")), TimeOfDay(0, 0, 0)) < seltime &&
                    DateTime(Date.fromISOExtString(currNode.getAttribute("to")), TimeOfDay(23, 59, 59)) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("body");

                    return replaceFirst(replaceFirst(searchResult[0].getCData(), "<strong>", ""), "</strong>", "");
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    public DateTime validFrom(DateTime seltime = cast(DateTime)Clock.currTime)
    {

        string rawXml;
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");
        
        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    return DateTime.fromISOExtString(currNode.getAttribute("from"));
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    public DateTime validTo(DateTime seltime = cast(DateTime)Clock.currTime)
    {
        string rawXml;
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");
        
        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    return DateTime.fromISOExtString(currNode.getAttribute("to"));
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    public dayperiod period(DateTime seltime = cast(DateTime)Clock.currTime)
    {
        string rawXml;
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");
        
        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    return cast(dayperiod)to!int(currNode.getAttribute("period"));
                }
            }
        }
        throw new DateTimeException("DateTime out of range");        
    }

    public string periodText(DateTime seltime = cast(DateTime)Clock.currTime)
    {
        dayperiod dp = period(seltime);

        if (dp == dayperiod.night)
            return "night";
        if (dp == dayperiod.morning)
            return "morning";
        if (dp == dayperiod.afternoon)
            return "afternoon";
        else
            return "evening";
    }

    public int weatherSymbol(DateTime seltime = cast(DateTime)Clock.currTime)
    {
        string rawXml;
            
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);
        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("symbol");

                    return to!int(searchResult[0].getAttribute("number"));
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }   
    
    public string weatherSymbolText(DateTime seltime = cast(DateTime)Clock.currTime)
    {
        string rawXml;
        
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);

        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("symbol");

                    return searchResult[0].getAttribute("name");
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }
    
    public float precipitation(DateTime seltime = cast(DateTime)Clock.currTime) 
    {
        string rawXml;
            
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("precipitation");

                    return to!float(searchResult[0].getAttribute("value"));
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    public float precipitationMin(DateTime seltime = cast(DateTime)Clock.currTime) 
    {
        string rawXml;
            
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("precipitation");

                    return to!float(searchResult[0].getAttribute("minvalue"));
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    public float precipitationMax(DateTime seltime = cast(DateTime)Clock.currTime) 
    {
        string rawXml;
            
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("precipitation");

                    return to!float(searchResult[0].getAttribute("maxvalue"));
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    public float windDirection(DateTime seltime = cast(DateTime)Clock.currTime) 
    {
        string rawXml;
            
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("windDirection");

                    return to!float(searchResult[0].getAttribute("deg"));
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    public string windDirectionCode(DateTime seltime = cast(DateTime)Clock.currTime) 
    {
        string rawXml;
            
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("windDirection");

                    return searchResult[0].getAttribute("code");
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    public string windDirectionText(DateTime seltime = cast(DateTime)Clock.currTime) 
    {
        string rawXml;
            
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("windDirection");

                    return searchResult[0].getAttribute("name");
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    public float windSpeed(DateTime seltime = cast(DateTime)Clock.currTime) 
    {
        string rawXml;
            
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("windSpeed");

                    return to!float(searchResult[0].getAttribute("mps"));
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    public string windSpeedName(DateTime seltime = cast(DateTime)Clock.currTime) 
    {
        string rawXml;
            
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("windSpeed");

                    return searchResult[0].getAttribute("name");
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    public float temperature(DateTime seltime = cast(DateTime)Clock.currTime) 
    {
        string rawXml;
            
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("temperature");

                    return to!float(searchResult[0].getAttribute("value"));
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    /**
     * The temperature trend is computed with the current temperature and the 
     * forecasted temperature in 6 hours. You can only get the trend for 
     * the current forecast.
     *
     * Returns:
     *  (temperaturetrend) that can be temperaturetrend.sinking, temperaturetrend.rising or
     *                     temperaturetrend.stable
     */
    @property
    public temperaturetrend temperatureTrend()
    {
        float ctemp = temperature();
        float ntemp = temperature(cast(DateTime)Clock.currTime + dur!"hours"(6));

        if ( ctemp == ntemp )
            return temperaturetrend.stable;
        else if ( ctemp > ntemp )
            return temperaturetrend.sinking;
        else
            return temperaturetrend.rising;
    }

    /**
     * The temperature trend is computed with the current temperature and the 
     * forecasted temperature in 6 hours. You can only get the trend for
     * the current forecast.
     *
     * Returns:
     *  (string) that can have the value "sinking", "stable" or "rising"
     */
    @property
    public string temperatureTrendText()
    {
        temperaturetrend tt = pressureTrend();

        if (tt == temperaturetrend.stable)
            return "stable";
        else if (tt == temperaturetrend.sinking)
            return "sinking";
        else 
            return "rising";
    }


    /**
     * The windchill is computed using formula from yr.no. This formula is 
     * developed by Environment Canada in 2000.
     *
     * The formula used for computing the windchill is: 
     *
     * W = 13.12 + 0.6215*T - 11.37*power(V, 0.16) + 0.3965*T*power(V*0.16)
     *
     * W = windchill index
     *
     * T = Temperature in degrees celsius, mesured 2 metres above the ground
     *
     * V = Windspeed in km/hour measured 10 metres above the ground
     *
     * T & V is included in a standard meterological observation.
     *
     * Params:
     *  seltime = DateTime that the forecast should be fetched for.
     *  none = Forecast should be fetched for the current date and time.
     *
     * Returns:
     *  (float) The winchill in degrees celcius
     */
    public float temperatureWindchill(DateTime seltime = cast(DateTime)Clock.currTime)
    {
        float chill;
        float temp = temperature(seltime);
        float wind = windSpeed(seltime) * 3.6;  // Convert mps to km/h

        chill = 13.12 + (0.6215 * temp) - (11.37 * pow(wind, 0.16)) + (0.3965 * temp * pow(wind, 0.16));
        return chill;
    }

    /**
     * Pressure for a selected date and time.
     *
     * Params:
     *  seltime = DateTime that the forecast should be fetched for.
     *  none = Forecast should be fetched for the current date and time.
     *
     * Returns:
     *  (float) The pressure in mbar
     *
     * Throws:
     *  DateTimeException if the DateTime that the forecast is wanted for
     *  is out of range of the downloaded forecast.
     */
    public float pressure(DateTime seltime = cast(DateTime)Clock.currTime) 
    {
        string rawXml;
            
        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        if (seltime < DateTime.fromISOExtString(searchList[0].getAttribute("from")))
            seltime = DateTime.fromISOExtString(searchList[0].getAttribute("from")) + dur!"minutes"(1);


        if (validTabularTime(seltime))
        {
            foreach (XmlNode currNode; searchList)
            {
                if (DateTime.fromISOExtString(currNode.getAttribute("from")) < seltime &&
                    DateTime.fromISOExtString(currNode.getAttribute("to")) >= seltime)
                {
                    XmlNode[] searchResult = currNode.parseXPath("pressure");

                    return to!float(searchResult[0].getAttribute("value"));
                }
            }
        }
        throw new DateTimeException("DateTime out of range");
    }

    /**
     * The pressuretrend is computed with the current pressure and the 
     * forecasted pressure in 12 hours. You can only get the trend for 
     * the current forecast.
     *
     * Returns:
     *  (pressuretrend) that can be pressuretrend.sinking, pressuretrend.rising or
     *                  pressuretrend.stable
     */
    @property
    public pressuretrend pressureTrend()
    {
        float currentp = pressure();
        float nextp = pressure(cast(DateTime)Clock.currTime + dur!"hours"(12));

        if ( currentp == nextp )
            return pressuretrend.stable;
        else if ( currentp > nextp )
            return pressuretrend.sinking;
        else
            return pressuretrend.rising;
    }

    /**
     * The pressuretrend is computed with the current pressure and the 
     * forecasted pressure in 12 hours. You can only get the trend for
     * the current forecast.
     *
     * Returns:
     *  (string) that can have the value "sinking", "stable" or "rising"
     */
    @property
    public string pressureTrendText()
    {
        pressuretrend pt = pressureTrend();

        if ( pt == pressuretrend.stable )
            return "stable";
        else if ( pt == pressuretrend.sinking )
            return "sinking";
        else 
            return "rising";
    }


//  =======================================================================
//    PRIVATE functions

    /* Downloads forecast from url specified in this.url to
     * a temporary file.
     * Check if downloaded file contains xml, if not-
     * Throw exeption.
     * If exception on download, use old one. and return False
     * If download ok, return True
     */
    private bool downloadForecast()
    {
        try 
        {
            debug writeln("Downloading forecast.");
            auto uuid = randomUUID();
            string tmpfile = tempDir() ~ dirSeparator ~ uuid.toString();
            debug writeln("Temporary filename: ", tmpfile);
            download(url, tmpfile);
            debug writeln("Forecast downloaded.");

            // File should be checked for validity here.
            
            if ( exists(tempfilename) ) 
                remove(tempfilename);
            rename(tmpfile, tempfilename);
            return true;
        }
        catch (Exception e)
        {
            throw new Exception("Download not possible.");
        }
    }

    private string getXmlString(string xpath)
    {
        string rawXml;

        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath(xpath);

        return searchList[0].getCData();
    }

    private string getXmlStringAttribute(string xpath, string xattribute)
    {
        string rawXml;

        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath(xpath);

        return searchList[0].getAttribute(xattribute);
    }

    private bool validTextTime(DateTime searchtime)
    {
        string rawXml;

        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/text/location/time");

        foreach (XmlNode currNode; searchList)
        {
            if (DateTime(Date.fromISOExtString(currNode.getAttribute("from")), TimeOfDay(0, 0, 0)) < searchtime &&
                DateTime(Date.fromISOExtString(currNode.getAttribute("to")), TimeOfDay(23, 59, 59)) >= searchtime)
            {
                return true;
            }
        }
        return false;
    }

    private bool validTabularTime(DateTime searchtime)
    {
        string rawXml;

        rawXml = readText(tempfilename);

        XmlNode xmlData = rawXml.readDocument();
        XmlNode[] searchList = xmlData.parseXPath("weatherdata/forecast/tabular/time");

        foreach (XmlNode currNode; searchList)
        {
            if (DateTime.fromISOExtString(currNode.getAttribute("from")) < searchtime &&
                DateTime.fromISOExtString(currNode.getAttribute("to")) >= searchtime)
            {
                return true;
            }
        }
        return false;
    }
}

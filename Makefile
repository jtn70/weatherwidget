# Define DMD as compiler
CC = dmd
CFLAGS = -c
LFLAGS = -release -O -inline
LIBS = -L-lphobos2 -L-lcurl -L-lgtkd-2
APP = weatherwidget

all:	weatherwidget

weatherwidget:	about.o application.o drawingarea.o forecast.o window.o xml.o
					$(CC) $(LFLAGS) application.o about.o drawingarea.o forecast.o window.o xml.o $(LIBS) -of$(APP)
					strip $(APP)

about.o:	about.d
			$(CC) $(CFLAGS) about.d

application.o:	application.d
				$(CC) $(CFLAGS) application.d

drawingarea.o:	drawingarea.d
				$(CC) $(CFLAGS) drawingarea.d

forecast.o:		forecast.d
				$(CC) $(CFLAGS) forecast.d

window.o:		window.d
				$(CC) $(CFLAGS) window.d

xml.o:			kxml/xml.d
				$(CC) $(CFLAGS) kxml/xml.d

clean:			
				rm -rf *.o weatherwidget
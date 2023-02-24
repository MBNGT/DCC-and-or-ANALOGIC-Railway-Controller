//////////////////////////////////////////////////////////////////////////
//  PROCESSING RAILWAY CONTROLLER
//  From 2013-2015 Gregg E. Berman'works
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see http://www.gnu.org/licenses
//
//////////////////////////////////////////////////////////////////////////
//
//    A circuit customization and some new functions have been done 
//      from 2022-2023 by EMA (mbmngt):
//      - new circuit design : 3 main tracks and 2 secondary tracks
//      - an analogic command of the cab (DCC is not used)
//      - a track division in "cantons" : 
//        each main track have 4 cantons
//        each secondary track have several cantons
//      - an automatic cab'control by current sensors check along the tracks
//      - some complementary windows to control signals, turnouts and sensors
//
//     All of this is support by an Arduino Mega and 5 Arduino Nano :
//      - Processing <-> Mega by serial communication
//      - Mega <-> Nano by I2C communication
//
//     In future, more functions wil be done :
//      - Tunouts command from Mega
//      - Traffic signals command from Mega
//      - Accessories and other lights command from one of the Nano
//      - Customization of Autopilot function to adapt it to the new circuit
//
//    Nota : For that, the Processing and Mega applications have been modified
//      some keyboard commands have been modified (see Help window)
//      in main sheet the read operation track current function have been desactivated
//      but the previous DCC functions always could be used with these new functions. 
//
//////////////////////////////////////////////////////////////////////////
//      
//  PROCESSING RAILWAY CONTROLLER is a Java program written using the 64-bit Processing Library
//  and Processing IDE (version 3.01).
//
//  PROCESSING RAILWAY CONTROLLER provides users with a fully customizeable graphical
//  front end for the total control of model trains and model train layouts
//  via its companion program, Base Station.
//
//  Base Station allows a standard Arduino Uno with an Arduino Motor Shield
//  to be used as a fully-functioning digital command and control (DCC) Base Station
//  for controlling model train layouts that conform to current National Model
//  Railroad Association (NMRA) DCC standards.
//
//  PROCESSING RAILWAY CONTROLLER communicates with Base Station using simple text commands sent
//  via a standard USB Serial Cord at speeds of up to 115200 Baud.  A Bluetooth Wireless
//  Connection may be used in place of a USB Serial Cord without any software modification.
//
//  This version of PROCESSING RAILWAY CONTROLLER supports:
//
//  * Multi-Cab / Multi-Throttle configurations using 128-step speed control
//  * 2-byte and 4-byte cab addresses
//  * Customizable cab function buttons F0-F12
//  * User-created multi-layout track plan
//  * Customizeable turnouts and crossovers with controls integrated into track plan
//  * Customizeable routes with configurable buttons
//  * Customizeable routes with route buttons integrated into track plan
//  * Master Power Button
//  * Customizable key-controls
//  * Real-time current monitor
//  * Optional track-integrated Sensors
//  * Optional user-created Auto Pilot routines (when used with track-integrated Sensors)
//  * Manual activation/de-activation of accessory functions using 512 addresses, each with 4 sub-addresses
//  * Programming on the Main Operations Track
//      - write configuration variable bytes
//      - set/clear specific configuration variable bits
//  * Programming on the Programming Track
//      - write configuration variable bytes
//      - read configuration variable bytes
//
//  With the exception of a standard 15V power supply for the Arduino Uno that can
//  be purchased in any electronics store, no additional hardware is required.
//  
//  Neither Base Station nor PROCESSING RAILWAY CONTROLLER use any known proprietary or
//  commercial hardware, software, interfaces, specifications, or methods related
//  to the control of model trains using NMRA DCC standards.  Both programs are wholly
//  original, developed by the author, and are not derived from any known commercial,
//  free, or open-source model railroad control packages by any other parties.
//  
//  However, Base Station and PROCESSING RAILWAY CONTROLLER do heavily rely on the IDEs and
//  embedded libraries associated with Arduino and Processing.  Tremendous thanks to those
//  responsible for these terrific open-source initiatives that enable programs like
//  DCC++ to be developed and distributed in the same fashion.
//  
//  REFERENCES:
//
//    NMRA DCC Standards:          http://www.nmra.org/standards/DCC/standards_rps/DCCStds.html
//    Arduino:                     http://www.arduino.cc/
//    Processing:                  http://processing.org/
//    GNU General Public License:  http://opensource.org/licenses/GPL-3.0
//
//////////////////////////////////////////////////////////////////////////

import processing.serial.*;
import processing.net.*; 
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.util.*;

final String   CONTROLLER_VERSION  = "3.0";
final int      BASE_BAUD       =    115200;
final int      SCREEN_WIDTH    =    1350;
final int      SCREEN_HEIGHT   =    738;
final String   STATUS_FILE     =    "dccStatus.xml";

//////////////////////////////////////////////////////////////////////////

void settings() {
  size(SCREEN_WIDTH, SCREEN_HEIGHT);
}

//////////////////////////////////////////////////////////////////////////

void setup() {
  Initialize();
}

//////////////////////////////////////////////////////////////////////////

void draw() {

  background(backgroundColor);

  for (DccComponent dcc : dccComponents)
    dcc.display();

  // if this is the first frame, just display components and return (otherwise user 
  //    stare at a blank screen while serial is opening
  if (frameCount==1)    
    return;

  // is this is the second frame, open the serial port --- 
  //    screen will have already been displayed in prior frame
  if (frameCount==2)    
    aPort.open(arduinoPortXML.getContent());

  for (int i=buttonQueue2.size()-1; i>=0; i--) {
    buttonQueue2.get(i).init();
    buttonQueue2.remove(i);
  }

  for (int i=buttonQueue.size()-1; i>=0; i--) {
    buttonQueue2.add(buttonQueue.get(i));
    ;
    buttonQueue.remove(i);
  }

  if (!mousePressed) {
    cursorType=ARROW;
    previousComponent=selectedComponent;
    selectedComponent=null;

    int nComponents = dccComponents.size();

    for (int i=nComponents-1; i>=0; i--)
      dccComponents.get(i).check();

    cursor(cursorType);
  }

  int m=millis();
  //if (m-lastTime>250 && aPort!=null && currentMeter.isOn) {
  //if (m-lastTime>1000 && aPort!=null && currentMeter.isOn) {
    //lastTime=m;
    //aPort.write("<c>");    //***** READ MAIN OPERATIONS TRACK CURRENT  ****/
    /*   case 'c':     // <c>
     *    reads current being drawn on main operations track
     *    returns: <c CURRENT> 
     *    where CURRENT = 0-1024, based on exponentially-smoothed weighting scheme
     *
     *    reads current sensors
     *    returns: <C CURRENT> 
     *    where CURRENT = 0-1024, based on exponentially-smoothed weighting scheme
     */
  //}

  msgBoxClock.setMessage(nf(hour(), 2)+":"+nf(minute(), 2)+":"+nf(second(), 2));

  if (saveXMLFlag) {
    try {
      saveXML(dccStatusXML, STATUS_FILE);
      saveXMLFlag=false;
    } 
    catch(Exception e) {
      println("Couldn't save. Will retry");
    }
  }

  autoPilot.safetyCheck();

  for (int i=0; i<locoButtons.size(); i++) {
    LocoButton loco = locoButtons.get(i);
    //loco.LocoRoutes();
    loco.LocoRoutes_Cantons();
  }
} // draw

//////////////////////////////////////////////////////////////////////////
//    Class DccComponent
//////////////////////////////////////////////////////////////////////////

abstract class DccComponent {
  Window window=null;
  int xPos, yPos;
  String componentName="NAME NOT DEFINED";
  abstract void display();
  void check() {
  };
  void pressed() {
  };
  void rightClick() {
  };
  void shiftPressed() {
  };
  void released() {
  };
  void drag() {
  };
  void init() {
  };

  protected int xWindow() {
    if (window==null)
      return 0;
    return window.xPos;
  }

  protected int yWindow() {
    if (window==null)
      return 0;
    return window.yPos;
  }
} // DccComponent class

//////////////////////////////////////////////////////////////////////////

interface CallBack {
  void execute(int n, String c);
}

//////////////////////////////////////////////////////////////////////////

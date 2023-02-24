//////////////////////////////////////////////////////////////////////////  //<>//
//  PROCESSING RAILWAY CONTROLLER: Event Handlers
//      Sheet : eventHandlers
//
//  Top-level processing of mouse, keyboard, and serial events.
//  Most of the real functionality is contained in other methods,
//  functions, and classes called by these handlers
//
//////////////////////////////////////////////////////////////////////////

void mouseDragged() {
  if (selectedComponent!=null)
    selectedComponent.drag();
}  //  mouseDragged

//////////////////////////////////////////////////////////////////////////

void mousePressed() {

  if (activeInputBox!=null) {
    for (InputBox inputBox : activeInputBox.linkedBoxes)
      inputBox.setIntValue(activeInputBox.getIntValue());
    //println("Active Box ",activeInputBox," linked Box ",activeInputBox.linkedBoxes);
  }

  activeInputBox=null;
  if (selectedComponent!=null) {
    if (keyPressed == true && key == CODED) {
      if (keyCode == SHIFT) {
        selectedComponent.shiftPressed();
      } else if (keyCode == CONTROL) {
        msgBoxMain.setMessage("Component Name: "+selectedComponent.componentName, color(30, 30, 150));
      }
    } else if (mouseButton==LEFT) {
      selectedComponent.pressed();
      //println("Selected Left ",selectedComponent);
    } else {
      selectedComponent.rightClick();
      //println("Selected Right ",selectedComponent);
    }
  }
}  //  mousePressed

//////////////////////////////////////////////////////////////////////////

void mouseReleased() {
  if (selectedComponent!=null)
    selectedComponent.released();
}  //  mouseReleased

//////////////////////////////////////////////////////////////////////////

void keyPressed() {
  keyCommand(key, keyCode);
}  //keyPressed

//////////////////////////////////////////////////////////////////////////

void keyReleased() {
  keyCommandReleased(key, keyCode);
}  //  keyReleased

//////////////////////////////////////////////////////////////////////////

void serialEvent(Serial p) {
  receivedString(p.readString());
}   //   serialEvent

//////////////////////////////////////////////////////////////////////////

void clientEvent(Client c) {
  String s;
  s=c.readStringUntil('>');
  if (s!=null)
    receivedString(s);
}  //  clientEvent

//////////////////////////////////////////////////////////////////////////

void receivedString(String s) {   
  if (s.charAt(0)!='<')
    return;

  String c=s.substring(2, s.length()-1);
  println(s.charAt(0), s.charAt(1), s.charAt(2), s.charAt(3));

  switch(s.charAt(1)) {

  case '*':   //  SHOW PACKETS - DIAGNOSTIC MODE ONLY  
    msgBoxDiagIn.setMessage(c, color(30, 30, 150));
    break;

  case 'c':    //   READ MAIN OPERATIONS TRACK CURRENT
    currentMeter.addSample(int(c));
    break;

  case 'G':    //  SIGNALS MANAGEMENT
    if (SignalsHM.get(int(c))!=null) {
      SignalsHM.get(int(c)).pressed();
    }
    break;

  case 'H':    //  CREATE/EDIT/REMOVE/SHOW & OPERATE A TURN-OUT
    int[] h=int(splitTokens(c));
    if (trackButtonsHM.get(h[0])!=null) {
      trackButtonsHM.get(h[0]).update(h[1]);
    } else if (remoteButtonsHM.get(h[0])!=null) {
      if (h[1]==((remoteButtonsHM.get(h[0]).buttonType==ButtonType.T_COMMAND)?1:0))
        remoteButtonsHM.get(h[0]).turnOn();
      else
        remoteButtonsHM.get(h[0]).turnOff();
    }
    break;

  case 'i':    //  Arduino connection messages  
    baseID=c;
    msgBoxMain.setMessage("Found "+baseID, color(0, 150, 0));
    break;

  case 'L':    //  LED LIGHT STRIP
    int[] z=int(splitTokens(c));
    println ("z[0]:", z[0], "   z[1]:", z[1], "   z[2]:", z[2]);
    color tempColor;
    tempColor=color(z[0], z[1], z[2]);
    colorMode(HSB, 1.0, 1.0, 1.0);
    ledColorButton.hue=hue(tempColor);
    ledColorButton.sat=saturation(tempColor);
    ledColorButton.val=brightness(tempColor);
    ledColorButton.update(0);
    colorMode(RGB, 255);        
    break;

    //  New
  case 'N':    //  Arduino technic messages  
    baseID=c;
    msgBoxTech.setMessage(baseID, color(0, 150, 0));
    break;
    //  New

  case 'p':    //  TURN ON / OFF POWER FROM MOTOR SHIELD TO TRACKS
    if (c.equals("10")) {
      powerButton.isOn=true;
      msgBoxMain.setMessage("Track Power On", color(30, 30, 150));
    } else if (c.equals("00")) {
      powerButton.isOn=false;
      msgBoxMain.setMessage("Track Power Off", color(30, 30, 150));
    } else if (c.equals("20")) {
      msgBoxMain.setMessage("MAIN Track Current Overload - Power Off", color(200, 30, 30));
      powerButton.isOn=false;
    } else if (c.equals("30")) {
      msgBoxMain.setMessage("PROG Track Current Overload - Power Off", color(200, 30, 30));
      powerButton.isOn=false;
    }
    break;

  case 'Q':    //  SHOW STATUS OF ALL SENSORS 
    int[] nQ=int(splitTokens(c, " "));
    println ("num:", nQ[0], "   current:", nQ[1]);
    if (SensorsHM.get(int(nQ[0]))!=null) {
      SensorsHM.get(int(nQ[0])).pressed();
      TrackSensor t=SensorsHM.get(nQ[0]);
      t.SensorActive=true;
      t.SensorValue=nQ[1];
    }
    break;

  case 'q':    //  SHOW STATUS OF ALL SENSORS 
    int[] nq=int(splitTokens(c, " "));
    println ("num:", nq[0], "   current:", nq[1]);
    if (SensorsHM.get(int(nq[0]))!=null) {
      SensorsHM.get(int(nq[0])).pressed();
      TrackSensor t=SensorsHM.get(nq[0]);
      t.SensorActive=false;
      t.SensorValue=nq[1];
    }
    break;

  case 'r':   //  READ CONFIGURATION VARIABLE BYTE FROM ENGINE DECODER ON PROGRAMMING TRACK
    String[] cs=splitTokens(c, "|");
    println ("cs[0]:", cs[0], "   cs[1]:", cs[1], "   cs[2]:", cs[2]);
    callBacks.get(int(cs[0])).execute(int(cs[1]), cs[2]);
    break;

  case 'T':   //  SET ENGINE THROTTLES USING 128-STEP SPEED CONTROL 
    int[] n=int(splitTokens(c));
    println ("nReg-n[0]:", n[0], "   tSpeedn[1]:", n[1], "   tDirectn[2]:", n[2], "   cabButtons.size():", cabButtons.size());
    if (n[0]>cabButtons.size())
      break;
    CabButton t=cabButtons.get(n[0]-1);
    if (n[2]==1) {
      t.speed=n[1];
    } else
      t.speed=-n[1];
    break;

  case 'U':    //  AUTOPROGRAM
    autoPilot.cabList.clear();        
    autoPilot.setProgram(AutoProgram.SINGLE_CAB_RUN);
    autoPilot.turnOn();
    break;

  case 'Y':    //   CREATE/EDIT/REMOVE/SHOW & OPERATE AN OUTPUT PIN
    int[] h1=int(splitTokens(c));
    println ("h1[0]:", h1[0], "   h1[1]:", h1[1], "   h1[2]:", h1[2]);
    if (remoteButtonsHM.get(h1[0])!=null) {
      if (h1[1]==1)
        remoteButtonsHM.get(h1[0]).turnOn();
      else
        remoteButtonsHM.get(h1[0]).turnOff();
    }
    break;
  }
}  //  receivedString

//////////////////////////////////////////////////////////////////////////

void keyCommand(char k, int kC) {

  if (activeInputBox!=null) {
    activeInputBox.keyStroke(k, kC);
    return;
  }
  //println ("keyCommand", "   k:", k, "   kC:", kC);

  if (k==CODED) {
    switch(kC) {
    case UP: //  Increase throttle
      if (throttleA.cabButton!=null) {
        if (!keyHold)
          throttleA.pressed();
        throttleA.keyControl(10);
      }
      break;
    case DOWN: //  Decrease throttle
      if (throttleA.cabButton!=null) {
        if (!keyHold)
          throttleA.pressed();
        throttleA.keyControl(-10);
      }
      break;
    case LEFT:  //  Stop throttle
      if (throttleA.cabButton!=null) {
        throttleA.keyControl(0);
      }
      break;
    case RIGHT:  //  Emergency stop throttle
      if (throttleA.cabButton!=null) {
        throttleA.cabButton.stopThrottle();
      }
      break;
    }
  } // key is coded

  else {
    switch(k) {
    case ' ': // Turn off track Power
      powerButton.turnOff();
      break;

    case 'A':  //  Accessory control view
      //case 'a':  //  Old Accessory control view
      accWindow.toggle();  //  Accessory control
      break;

    case 'c':  //  Current meter
      currentMeter.isOn=!currentMeter.isOn;
      break;

    case 'd':  //  Serial communication diagnostic view
      diagWindow.toggle();
      break;

    case 'e':  //  Extra / miscellaneous functions view
      extrasWindow.toggle();
      break;

    case 'F':    //  aPort.write("<3>"
      aPort.write("<3>");
      break;

    case 'f':    //  aPort.write("<2>"
      aPort.write("<2>");
      break;

    case 'G':  //  Signal status view
      SignalWindow1.toggle();
      SignalWindow2.toggle();
      break;

    case 'h':  //  Help menu view
      helpWindow.toggle();
      break;

      /*
    case 'i':    //  Old layout2
       if (layoutBridge.equals(layout2))
       layoutBridge.copy(layout);
       else
       layoutBridge.copy(layout2);
       break;
       */

    case 'K':  //  Cab status view
      //case 'L':  //  Old Cab status view
      CabWindow.toggle();
      break;

    case 'k':  //  Cab description view
      //case 'q':  //  Old Cab description view
      imageWindow.toggle();
      break;

    case 'l':  //  led light strip control view
      ledWindow.toggle();
      break;

    case 'n':   //  For Cab 5 switch between the two series of functions
      if (throttleA.cabButton!=null) {
        throttleA.cabButton.fbWindow.close();
        throttleA.cabButton.fbWindow=throttleA.cabButton.windowList.get((throttleA.cabButton.windowList.indexOf(throttleA.cabButton.fbWindow)+1)%throttleA.cabButton.windowList.size());
        throttleA.cabButton.fbWindow.open();
      }
      break;

    case 'o':  //  Program Operation track view
      opWindow.toggle();
      break;

    case 'P':  //  Power button
      powerButton.turnOn();
      break;

    case 'p':  //  Program programming track view
      progWindow.toggle();
      break;

    case 'S':  //  Sensor status view
      SensorWindow.toggle();
      break;

    case 's':  //  Select serial conection view
      portWindow.toggle();
      break;

    case 'T':  //  Turnout status view
      TurnWindow.toggle();
      break;

    case 'x':  //  Auto pilot status view
      autoWindow.toggle();
      break;

    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
      cabButtons.get(int(k)-int('1')).pressed();  //  Select the cab
      locoButtons.get(int(k)-int('1')).pressed();  //  Select the Loco
      break;
    }
  } // key not coded

  keyHold=true;
}  //  keyCommand

//////////////////////////////////////////////////////////////////////////

void keyCommandReleased(char k, int kC) {

  keyHold=false;

  if (k==CODED) {
    switch(kC) {
    }
  } // key is coded

  else {
    switch(k) {
    }
  } // key not coded
}  //  keyCommandReleased


//////////////////////////////////////////////////////////////////////////

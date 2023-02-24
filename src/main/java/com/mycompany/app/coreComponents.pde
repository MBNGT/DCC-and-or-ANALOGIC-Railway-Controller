//////////////////////////////////////////////////////////////////////////
//  PROCESSING RAILWAY CONTROLLER: Core Components
//      Sheet : CoreComponents
//
//  PowerButton  -  send power on/off command to the Base Station
//
//  CurrentMeter -  monitors main track current draw from the Base Station
//               -  displays scrolling bar chart of current measured
//
//  HelpButton   -  toggles Help Window
//
//  QuitButton   -  quits PROCESSING RAILWAY CONTROLLER
//               -  connection to Base Station terminated
//               -  NOTE: track power remains on and trains will continue to operate
//                  since DCC+ Base Station operates independently!
//
//  AccessoryButton   -  sends a DCC ACCESSORY COMMAND to the Base Station
//                       to either activate or de-activate an accessory depending on
//                       whether the button is labeled "ON" or "OFF"
//                    -  two pre-specified input boxes are used: one for the user
//                       to input the desired accessory address, and one for
//                       accessory number (sub-address)
//                    -  the default configuration of PROCESSING RAILWAY CONTROLLER defines an
//                       Accessory Window that includes these two input boxes as well
//                       as ON and OFF buttons.
//
//  CleaningCarButton -  sends a DCC THROTTLE COMMAND to the Base Station that operates
//                       a mobile decoder with a pre-specified cab number
//                    -  this decoder drives a motor that spins a cleaning pad in a
//                       track-cleaning car
//                    -  clicking the button toggles the throttle between either 0 or 126 (max speed)
//                    -  the default configuration of PROCESSING RAILWAY CONTROLLER defines an
//                       Extras Window that includes this button
//
//  LEDColorButton    -  provide for interactive control of an LED-RGB Light Strip

//////////////////////////////////////////////////////////////////////////
//  Class PowerButton
//////////////////////////////////////////////////////////////////////////

class PowerButton extends RectButton {

  PowerButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText) {
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText);
  }

  PowerButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(0), fontSize, bText, ButtonType.NORMAL);
  } // PowerButton

  //////////////////////////////////////////////////////////////////////////

  void turnOn() {
    aPort.write("<1>");    //***** TURN ON POWER FROM MOTOR SHIELD TO TRACKS  ****/
    /*    case '1':      // <1>
     *   For DCC management :
     *    enables power from the motor shield to the main operations and programming tracks
     *   For canton management :
     *    enables power for all the tracks without canton considerations
     *  For all management
     *    returns: <p1>
     */
  }  //  PowerButton turnOn

  //////////////////////////////////////////////////////////////////////////

  void shiftPressed() {
    aPort.write("<Z 1 0>");    //***** CREATE/EDIT/REMOVE/SHOW & OPERATE AN OUTPUT PIN  ****/    
    /*   case 'Z':       // <Z ID ACTIVATE>
     *   For DCC management :
     *    sets output ID to either the "active" or "inactive" state
     *    ID: the numeric ID (0-32767) of the output to control
     *    ACTIVATE: 0 (active) or 1 (inactive)
     *    returns: <Y ID ACTIVATE> or <X> if output ID does not exist    
     *
     *    <Z ID PIN IFLAG>:            creates a new output ID, with specified PIN and IFLAG values.  
     *    if output ID already exists, it is updated with specificed PIN and IFLAG.  
     *    note: output state will be immediately set to ACTIVE/INACTIVE and pin will be set to HIGH/LOW 
     *      according to IFLAG value specifcied (see below).  
     *    returns: <O> if successful and <X> if unsuccessful (e.g. out of memory)  
     *
     *    <Z ID>:                      deletes definition of output ID  
     *    returns: <O> if successful and <X> if unsuccessful (e.g. ID does not exist)  
     *
     *    <Z>:                         lists all defined output pins  
     *    returns: <Y ID PIN IFLAG STATE> for each defined output pin or <X> if no output pins defined  
     *      where  
     *        ID: the numeric ID (0-32767) of the output  
     *        PIN: the arduino pin number to use for the output  
     *        STATE: the state of the output (0=INACTIVE / 1=ACTIVE)  
     *        IFLAG: defines the operational behavior of the output based on bits 0, 1, and 2 as follows:  
     *        IFLAG, bit 0:   0 = forward operation (ACTIVE=HIGH / INACTIVE=LOW)  
     *                        1 = inverted operation (ACTIVE=LOW / INACTIVE=HIGH)  
     *        IFLAG, bit 1:   0 = state of pin restored on power-up to either ACTIVE or INACTIVE   
     *                              depending on state before power-down; state of pin set to INACTIVE when first 
     *                              created  
     *                        1 = state of pin set on power-up, or when first created, to either   
     *                              ACTIVE of INACTIVE depending on IFLAG, bit 2  
     *        IFLAG, bit 2:   0 = state of pin set to INACTIVE uponm power-up or when first created  
     *                        1 = state of pin set to ACTIVE uponm power-up or when first created   
     *  For canton management :
     *    TBD
     */
  }  //  PowerButton shiftPressed

  //////////////////////////////////////////////////////////////////////////

  void turnOff() {
    aPort.write("<0>");    //***** TURN OFF POWER FROM MOTOR SHIELD TO TRACKS  ****/
    /*    case '0':     // <0>
     *   For DCC management :
     *    disables power from the motor shield to the main operations and programming tracks
     *  For canton management :
     *    enables power for each selected tracks's canton
     *  For all management :
     *    returns: <p0>
     */
  }  //  PowerButton turnOff
} // PowerButton Class

//////////////////////////////////////////////////////////////////////////
//  Class CurrentMeter
//////////////////////////////////////////////////////////////////////////

class CurrentMeter extends DccComponent {
  int nSamples, kHeight;
  int maxCurrent;
  int[] samples;
  int sampleIndex;
  int nGridLines;
  boolean isOn;

  CurrentMeter(int xPos, int yPos, int nSamples, int kHeight, int maxCurrent, int nGridLines) {
    this.xPos=xPos;
    this.yPos=yPos;
    this.nSamples=nSamples;
    this.kHeight=kHeight;
    this.maxCurrent=maxCurrent;
    this.nGridLines=nGridLines;
    this.isOn=true;
    samples=new int[nSamples];
    sampleIndex=nSamples-1;
    dccComponents.add(this);
  } // CurrentMeter

  //////////////////////////////////////////////////////////////////////////

  void display() {
    int i;
    rectMode(CORNER);
    noFill();
    strokeWeight(1);
    textFont(buttonFont, 8);
    textAlign(LEFT, CENTER);
    stroke(200);
    rect(xPos, yPos, nSamples+1, kHeight+2); // Display zone
    if (isOn)
      stroke(50, 200, 100); // color if Current meter is on
    else
      stroke(200, 100, 100); // color if Current meter is off
    for (i=0; i<nSamples; i++) { // Curve of Current Meter
      line(xPos+1+i, yPos+kHeight+1, xPos+1+i, yPos+kHeight+1-samples[(sampleIndex+i)%nSamples]*kHeight/maxCurrent);
    }
    stroke(200);
    for (i=1; i<nGridLines; i++) { // Rows
      line(xPos+1, yPos+kHeight+1-kHeight*i/nGridLines, xPos+1+nSamples, yPos+kHeight+1-kHeight*i/nGridLines);
    }
    fill(255);
    for (i=0; i<=nGridLines; i++) { // Graduation sur le cote droit
      text(nf(i*2000/nGridLines, 0)+" mA", xPos+10+nSamples, yPos+kHeight+1-kHeight*i/nGridLines);
    }
  }  //  CurrentMeter display

  //////////////////////////////////////////////////////////////////////////

  void addSample(int s) {

    samples[sampleIndex]=s;    
    sampleIndex=(sampleIndex+1)%nSamples;
  }  //  CurrentMeter addSample
} // CurrentMeter Class

//////////////////////////////////////////////////////////////////////////
//  Class AccessoryButton
//////////////////////////////////////////////////////////////////////////

class AccessoryButton extends EllipseButton {
  InputBox accAddInput, accSubAddInput;

  AccessoryButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox accAddInput, InputBox accSubAddInput) {
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText, accAddInput, accSubAddInput);
  }

  AccessoryButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox accAddInput, InputBox accSubAddInput) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.ONESHOT);
    this.accAddInput=accAddInput;
    this.accSubAddInput=accSubAddInput;
  } // AccessoryButton

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    super.pressed();
    int accAddress=accAddInput.getIntValue();
    int accSubAddress=accSubAddInput.getIntValue();
    if (accAddress>511)
      msgBoxMain.setMessage("Error - Accessory Address must be in range 0-511", color(255, 30, 30));
    else if (accSubAddress>3)
      msgBoxMain.setMessage("Error - Accessory Sub Address must be in range 0-3", color(255, 30, 30));
    else
      aPort.write("<a"+accAddress+" "+accSubAddress+" "+(bText.equals("ON")?1:0)+">");    //***** OPERATE STATIONARY ACCESSORY DECODERS  ****/
    /*    <a ADDRESS SUBADDRESS ACTIVATE>
     *    turns an accessory (stationary) decoder on or off
     *    ADDRESS:  the primary address of the decoder (0-511)
     *    SUBADDRESS: the subaddress of the decoder (0-3)
     *    ACTIVATE: 1=on (set), 0=off (clear)
     *    Note that many decoders and controllers combine the ADDRESS and 
     *        SUBADDRESS into a single number, N, from  1 through a max of 2044, 
     *        where
     *        N = (ADDRESS - 1) * 4 + SUBADDRESS + 1, for all ADDRESS>0
     *        OR
     *        ADDRESS = INT((N - 1) / 4) + 1
     *        SUBADDRESS = (N - 1) % 4
     *    returns: NONE
     */
  }  //  AccessoryButton pressed
} // AccessoryButton Class

//////////////////////////////////////////////////////////////////////////
//  Class Quit Button
//////////////////////////////////////////////////////////////////////////

class QuitButton extends RectButton {

  QuitButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText) {
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText);
  }

  QuitButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.NORMAL);
  } // QuitButton

  //////////////////////////////////////////////////////////////////////////

  void turnOn() {
    super.turnOn();
    //
    //  Need to reset all commands and to have speed to 0 before exit
    //    To be finished
    powerButton.turnOff();    // Turn off track Power

    exit();
  }  //  QuitButton turnOn
} // QuitButton Class

//////////////////////////////////////////////////////////////////////////
//  Class Help Button
//////////////////////////////////////////////////////////////////////////

class HelpButton extends EllipseButton {

  HelpButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText) {
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText);
  }

  HelpButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.ONESHOT);
  } // PowerButton

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    super.pressed();
    helpWindow.toggle();
  }  //  HelpButton pressed
} // HelpButton Class

//////////////////////////////////////////////////////////////////////////
//  Class CleaningCar Button
//////////////////////////////////////////////////////////////////////////

class CleaningCarButton extends RectButton {
  int cab;
  int reg;

  CleaningCarButton(int cab, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText) {
    this(null, cab, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText);
  }

  CleaningCarButton(Window window, int cab, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(0), fontSize, bText, ButtonType.NORMAL);
    reg=cabButtons.size()+1;
    this.cab=cab;
  } // CleaningCarButton

  //////////////////////////////////////////////////////////////////////////
  //  Without canton management
  //////////////////////////////////////////////////////////////////////////

  void turnOn() {
    super.turnOn();
    aPort.write("<t"+reg+" "+cab+" 126 1>");    //***** SET ENGINE THROTTLES USING 128-STEP SPEED CONTROL ****/    
    /*    case 't':       // <t REGISTER CAB SPEED DIRECTION>
     *    sets the throttle for a given register/cab combination 
     *    REGISTER: an internal register number, from 1 through MAX_MAIN_REGISTERS 
     *      (inclusive), to store the DCC packet used to control this throttle setting
     *    CAB:  the short (1-127) or long (128-10293) address of the engine decoder
     *    SPEED: throttle speed from 0-126, or -1 for emergency stop (resets SPEED to 0)
     *    DIRECTION: 1=forward, 0=reverse.  Setting direction when speed=0 or speed=-1 
     *      only effects directionality of cab lighting for a stopped train
     *
     *    returns: <T REGISTER SPEED DIRECTION>
     */
  }  //  CleaningCarButton turnOn

  //////////////////////////////////////////////////////////////////////////
  //  In case of canton management
  //////////////////////////////////////////////////////////////////////////

  void turnOnCanton() {
    //super.turnOnCanton();
    aPort.write("<t"+reg+" "+cab+" 126 1 0>");    //***** SET ENGINE THROTTLES USING 128-STEP SPEED CONTROL WITH CANTON MANAGEMENT ****/    
    /*    case 't':       // <t REGISTER CAB SPEED DIRECTION CANTON>
     *    sets the throttle for a given register/cab combination 
     *    REGISTER: an internal register number, from 1 through MAX_MAIN_REGISTERS 
     *      (inclusive), to store the DCC packet used to control this throttle setting
     *    CAB:  the short (1-127) or long (128-10293) address of the engine decoder
     *        In case of cantons management, it define the track to turn on the power 
     *    SPEED: throttle speed from 0-126, or -1 for emergency stop (resets SPEED to 0)
     *    DIRECTION: 1=forward, 0=reverse.  Setting direction when speed=0 or speed=-1 
     *      only effects directionality of cab lighting for a stopped train
     *    CANTON = 0 All cantons of the track must be considered
     *
     *    returns: <T REGISTER SPEED DIRECTION>
     */
  }  //  CleaningCarButton turnOnCanton


  //////////////////////////////////////////////////////////////////////////
  //  Without canton management
  //////////////////////////////////////////////////////////////////////////

  void turnOff() {
    super.turnOff();
    aPort.write("<t"+reg+" "+cab+" 0 1>");     //***** SET ENGINE THROTTLES USING 128-STEP SPEED CONTROL ****/    
    /*    case 't':       // <t REGISTER CAB SPEED DIRECTION>
     *    sets the throttle for a given register/cab combination 
     *    REGISTER: an internal register number, from 1 through MAX_MAIN_REGISTERS 
     *      (inclusive), to store the DCC packet used to control this throttle setting
     *    CAB:  the short (1-127) or long (128-10293) address of the engine decoder
     *    SPEED: throttle speed from 0-126, or -1 for emergency stop (resets SPEED to 0)
     *    DIRECTION: 1=forward, 0=reverse.  Setting direction when speed=0 or speed=-1 
     *      only effects directionality of cab lighting for a stopped train
     *
     *    returns: <T REGISTER SPEED DIRECTION>
     */
  }  //  CleaningCarButton turnOff

  //////////////////////////////////////////////////////////////////////////
  //  In case of canton management
  //////////////////////////////////////////////////////////////////////////

  void turnOffCanton() {
    //super.turnOffCanton();
    aPort.write("<t"+reg+" "+cab+" 0 1 0>");     // SET ENGINE THROTTLES USING 128-STEP SPEED CONTROL with cantons management    
    /*    case 't':       // <t REGISTER CAB SPEED DIRECTION CANTON>
     *    sets the throttle for a given register/cab combination 
     *    REGISTER: an internal register number, from 1 through MAX_MAIN_REGISTERS 
     *      (inclusive), to store the DCC packet used to control this throttle setting
     *    CAB:  the short (1-127) or long (128-10293) address of the engine decoder
     *        In case of cantons management, it define the track to turn off the power 
     *    SPEED: throttle speed from 0-126, or -1 for emergency stop (resets SPEED to 0)
     *    DIRECTION: 1=forward, 0=reverse.  Setting direction when speed=0 or speed=-1 
     *      only effects directionality of cab lighting for a stopped train
     *    CANTON = 0 All track cantons must be considered in cantons management
     *
     *    returns: <T REGISTER SPEED DIRECTION>
     */
  }  //  CleaningCarButton turnOffCanton

  //////////////////////////////////////////////////////////////////////////

  void shiftPressed() {
    autoPilot.clean();
  }  //  CleaningCarButton shiftPressed
} // CleaningCarButton Class

//////////////////////////////////////////////////////////////////////////
//  Class LED Color Button
//////////////////////////////////////////////////////////////////////////

class LEDColorButton extends DccComponent {

  int bWidth, bHeight;
  float hue;
  float sat;
  float val;

  LEDColorButton(Window window, int xPos, int yPos, int bWidth, int bHeight, float hue, float sat, float val) {
    this.xPos=xPos;
    this.yPos=yPos;
    this.bWidth=bWidth;
    this.bHeight=bHeight;
    this.hue=hue;
    this.sat=sat;
    this.val=val;
    this.window=window;
    window.windowComponents.add(this);
  }  //  LEDColorButton

  //////////////////////////////////////////////////////////////////////////

  void display() {
    rectMode(CENTER);
    colorMode(HSB, 1.0, 1.0, 1.0);
    fill(hue, sat, val);
    rect(xPos+xWindow(), yPos+yWindow(), bWidth, bHeight);
    colorMode(RGB, 255);
  }  //  LEDColorButton display

  //////////////////////////////////////////////////////////////////////////

  void update(int s) {
    color c;
    colorMode(HSB, 1.0, 1.0, 1.0);
    c=color(hue, sat, val);
    colorMode(RGB, 255);
    aPort.write("<g RGB "+int(red(c))+" "+int(green(c))+" "+int(blue(c))+" "+s+">");     // ??????
    ledHueMsg.setMessage("Hue:   "+int(hue*360), color(200, 200, 200));
    ledSatMsg.setMessage("Sat:   "+int(sat*100), color(200, 200, 200));
    ledValMsg.setMessage("Val:   "+int(val*100), color(200, 200, 200));
    ledRedMsg.setMessage("Red:   "+int(red(c)), color(200, 200, 200));
    ledGreenMsg.setMessage("Green: "+int(green(c)), color(200, 200, 200));
    ledBlueMsg.setMessage("Blue:  "+int(blue(c)), color(200, 200, 200));
  }  //  LEDColorButton update
} // LEDColorButton Class

//////////////////////////////////////////////////////////////////////////
//  Class LED Value Selector
//////////////////////////////////////////////////////////////////////////

class LEDValSelector extends DccComponent {

  int bWidth, bHeight;
  LEDColorButton cButton;
  PImage valBox;

  LEDValSelector(Window window, int xPos, int yPos, int bWidth, int bHeight, LEDColorButton cButton) {
    this.xPos=xPos;
    this.yPos=yPos;
    this.bWidth=bWidth;
    this.bHeight=bHeight;
    this.cButton=cButton;
    valBox = createImage(bWidth+1, bHeight+1, RGB);
    this.window=window;
    window.windowComponents.add(this);

    colorMode(HSB, 1.0, 1.0, 1.0);
    valBox.loadPixels();

    for (int y=0; y<valBox.height; y++) {
      for (int x=0; x<valBox.width; x++) {
        valBox.pixels[x+y*valBox.width]=color(0, 0, float(x)/float(bWidth));    // since x will be maximum at width of box, normalize by bWidth which is one less than box width to ensure max brightness is 1.0
      }
    }

    valBox.updatePixels();
    colorMode(RGB, 255);
  }  //  LEDValSelector

  //////////////////////////////////////////////////////////////////////////

  void display() {

    imageMode(CORNER);
    colorMode(HSB, 1.0, 1.0, 1.0);
    tint(cButton.hue, cButton.sat, 1.0);
    image(valBox, xPos+xWindow(), yPos+yWindow());
    noTint();    
    fill(0.0, 0.0, 1.0);
    noStroke();
    pushMatrix();
    translate(xPos+xWindow()+cButton.val*float(bWidth), yPos+yWindow()-2);
    triangle(0, 0, -5, -10, 5, -10);
    translate(0, bHeight+4);
    triangle(0, 0, -5, 10, 5, 10);
    rectMode(CORNER);
    rect(-5, 10, 10, 10);
    fill(0, 0, 0);
    triangle(0, 15, -5, 20, 5, 20);
    popMatrix();
    colorMode(RGB, 255);
  }  //  LEDValSelector display

  //////////////////////////////////////////////////////////////////////////

  void check() {

    if (selectedComponent==null && mouseX>=xPos+xWindow()+cButton.val*float(bWidth)-5 && mouseX<=xPos+xWindow()+cButton.val*float(bWidth)+5 && mouseY>=yPos+yWindow()+bHeight+2 && mouseY<=yPos+yWindow()+bHeight+22) {
      cursorType=HAND;
      selectedComponent=this;
    }
  }  //  LEDValSelector check

  //////////////////////////////////////////////////////////////////////////

  void drag() {
    cButton.val=constrain(float(mouseX-xPos-xWindow())/bWidth, 0.0, 1.0);
    cButton.update(0);
  }  //  LEDValSelector drag

  //////////////////////////////////////////////////////////////////////////

  void released() {
    cButton.update(1);
  }  //  LEDValSelector released
} // LEDValSelector Class

//////////////////////////////////////////////////////////////////////////
//  Class LED Color Selector
//////////////////////////////////////////////////////////////////////////

class LEDColorSelector extends DccComponent {
  PImage colorWheel;
  int radius;
  LEDColorButton cButton;

  LEDColorSelector(Window window, int xPos, int yPos, int radius, LEDColorButton cButton) {
    float d, h;

    this.xPos=xPos;
    this.yPos=yPos;
    this.radius=radius;
    this.cButton=cButton;
    colorWheel=createImage(radius*2+1, radius*2+1, RGB);
    this.window=window;
    window.windowComponents.add(this);

    colorWheel.loadPixels();        
    colorMode(HSB, 1.0, 1.0, 1.0);

    for (int i=0, y=radius; y>=-radius; y--) {
      for (int x=-radius; x<=radius; x++) {
        d=sqrt(x*x+y*y);
        if (d<0.5) {
          colorWheel.pixels[i]=color(0.0, 0.0, 1.0);      // center of wheel always has zero saturation (hue does not matter)
        } else
          if (d>radius) {
            colorWheel.pixels[i]=color(0.0, 0.0, 0.0);        // outside of wheel is always fully black (hue and saturation does not matter)
          } else {
            h=acos(float(x)/d);                            // find angle in radians
            if (y<0)                                        // adjust angle to reflect lower half of wheel
              h=TWO_PI-h;
            colorWheel.pixels[i]=color(h/TWO_PI, d/float(radius), 1.0);    // hue is based on angle normalized to 1.0, saturation is based on distance to center normalized to 1.0, brightness is always 1.0
          }
        i++;
      } // x-loop
    }  // y-loop

    colorMode(RGB, 255);
    colorWheel.updatePixels();
  }  //  LEDColorSelector

  //////////////////////////////////////////////////////////////////////////

  void display() {
    imageMode(CENTER);
    colorMode(HSB, 1.0, 1.0, 1.0);
    image(colorWheel, xPos+xWindow(), yPos+yWindow());
    colorMode(RGB, 255);
  }  //  LEDColorSelector display

  //////////////////////////////////////////////////////////////////////////

  void check() {
    if (selectedComponent==null && ((pow(mouseX-xPos-xWindow(), 2)+pow(mouseY-yPos-yWindow(), 2))<=pow(radius, 2))) {
      cursorType=CROSS;
      selectedComponent=this;
    }
  }  //  LEDColorSelector check

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    drag();
  }  //  LEDColorSelector pressed

  //////////////////////////////////////////////////////////////////////////

  void drag() {
    float d, h;
    color selectedColor;

    d=sqrt(pow(mouseX-xPos-xWindow(), 2)+pow(mouseY-yPos-yWindow(), 2));
    if (d<0.5) {
      h=0.0;
    } else {
      h=acos(float(mouseX-xPos-xWindow())/d);
      if (mouseY>(yPos+yWindow()))
        h=TWO_PI-h;
      cButton.hue=h/TWO_PI;
      cButton.sat=constrain(d/float(radius), 0.0, 1.0);
    }

    cButton.update(0);
  }  //  LEDColorSelector drag

  //////////////////////////////////////////////////////////////////////////

  void released() {
    cButton.update(1);
  }  //  LEDColorSelector released
} // LEDColorSelector Class

//////////////////////////////////////////////////////////////////////////

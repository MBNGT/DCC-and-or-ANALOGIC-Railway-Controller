//////////////////////////////////////////////////////////////////////////
//  PROCESSING RAILWAY CONTROLLER: Classes for Cab Throttle and Cab Function Controls
//      Sheet : dCabs
//
//  Throttle  -  creates a sliding throttle to set the speed and direction
//               of one or more locomotive cabs
//            -  cabs are selected by clicking any of the cab buttons
//               that have been associated with the throttle
//            -  multiple throttles, each with a distinct set of cab buttons,
//               is allowed. It is also possible to define one throttle per
//               cab, in which case a visible cab button would not be needed
//               since there is nothing to select
//            -  moving the slider up or down sends a DCC Throttle Command to
//               the Base Station with the cab address and register number
//               specified by the selected can button
//            -  throttle commands assume mobile decoders are configured for 128-step speed control
//               with speeds ranging from a minimum of 0 to a maximum of 126.
//            -  the throttle command sent to the Base Station also codes whether motion
//               is forward or backward
//            -  negative throttle numbers are NOT used to indicate reverse motion
//            -  a negative throttle number is used to instruct the Base Station
//               to initiate an immediate emergency stop of the specified cab.
//            -  this is in contrast to setting the throttle to 0, in which case the
//               cab will stop according to any deceleration parameters (which may allow the locomotive
//               to coast before stopping)
//            -  throttle slider can also be controlled with arrows as follows:
//
//               * UP ARROW    = increase speed by one unit in the forward direction
//                              (which decreases speed if already moving in the reverse direction)
//               * DOWN ARROW  = increase speed by one unit in the reverse direction
//                              (which decreases speed if already moving in the forward direction)
//               * LEFT ARROW  = set speed to zero (locomotive will coast to stop if configured with deceleration)
//               * RIGHT ARROW = emergency stop (locomotive will stop immediately, ignoring any deceleration parameters)
//
//            -  Note: throttle slider and arrow buttons will not permit single action that causes locomotive
//                     to stop and then reverse.  This allows users to move slider or press arrow keys to slow
//                     locomotive to zero without worrying about overshooting and reversing direction.  Once slider is
//                     at zero, reclick to start sliding in reverse direction.
//
//  CabButton -  defines a button to activate a given cab address for a given throttle
//            -  in addition to the cab address (which can be short or long), the button
//               contains:
////               * informaiton on which register number the Base Station
//                     should use for throttle commands to this cab
//                 * a data structure indicating which cab functions (lights, horns, etc.)
//                     are defined for this cab
//
//  FunctionButton  -  sends a CAB Function Command to the Base Station to
//                     activate or de-activate any cab function F0-F12
//                  -  function buttons are always associated with a particular throttle, but
//                     are dynamically configured according to the cab selected
//                     to be active for that throttle
//                  -  configuration information for each function button is stored in
//                     a data structure contained within each cab button
//                  -  configuration data includes the name of each button and whether the function
//                     should:
//                     * be toggled from on to off, or off to on, with each mouse click (e.g. a headlight)
//                     * be activated upon pressing the mouse button but de-active when the mouse
//                         button is released (e.g. a horn)
//                     * be turned on and then immediately off with a single mouse click (e.g. coupler sounds)
//
//////////////////////////////////////////////////////////////////////////
//  Class Throttle
//////////////////////////////////////////////////////////////////////////

class Throttle extends DccComponent {
  final int KMAXPOS=126;
  final int KMINPOS=-126;
  int kWidth=50;
  int kHeight=15;
  int sPos, sSpeed;
  int kMaxTemp, kMinTemp;
  float tScale;
  CabButton cabButton=null;

  Throttle(int xPos, int yPos, float tScale) {
    this.xPos=xPos;
    this.yPos=yPos;
    this.tScale=tScale;
    dccComponents.add(this);
  } // Throttle

  //////////////////////////////////////////////////////////////////////////
  //   Vertical scale with speed cursor
  //////////////////////////////////////////////////////////////////////////

  void display() {
    int i;
    rectMode(CENTER);
    ellipseMode(CENTER);
    strokeWeight(1);
    noStroke();
    fill(255); // Echelle pour le curseur des vitesses
    rect(xPos, yPos, kWidth/2.0, (KMAXPOS-KMINPOS)*tScale);
    fill(0);
    rect(xPos, yPos, kWidth/4.0, (KMAXPOS-KMINPOS)*tScale);

    stroke(0);    
    for (i=0; i<KMAXPOS*tScale; i+=10*tScale)
      line(xPos-kWidth/4.0, yPos-i, xPos+kWidth/4.0, yPos-i);
    for (i=0; i>KMINPOS*tScale; i-=10*tScale)
      line(xPos-kWidth/4.0, yPos-i, xPos+kWidth/4.0, yPos-i);

    if (cabButton==null)
      return;

    noStroke();  // bouton ovale curseur des vitesses
    // println("Throttle display", yPos, "  ", cabButton.speed, "  ", tScale);
    for (i=kWidth; i>0; i--) {
      fill(230-(i*2), 230-(i*2), 255-(i*3));
      ellipse(xPos, yPos-cabButton.speed*tScale, i, i/2);
    }
  }  //  Throttle display

  //////////////////////////////////////////////////////////////////////////

  void check() {
    if (cabButton==null)
      return;

    if (selectedComponent==null && (mouseX-xPos)*(mouseX-xPos)/(kWidth*kWidth/4.0)+(mouseY-(yPos-cabButton.speed*tScale))*(mouseY-(yPos-cabButton.speed*tScale))/(kWidth*kWidth/16.0)<=1) {
      cursorType=HAND;
      selectedComponent=this;
    }
  }  //  Throttle check

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    sPos=mouseY;
    sSpeed=cabButton.speed;

    if (sSpeed>0) {
      kMaxTemp=KMAXPOS;
      kMinTemp=0;
    } else if (sSpeed<0) {
      kMaxTemp=0;
      kMinTemp=KMINPOS;
    } else {
      kMaxTemp=KMAXPOS;
      kMinTemp=KMINPOS;
    }

    noCursor();
  }  //  Throttle pressed

  //////////////////////////////////////////////////////////////////////////

  void drag() {
    int tPos;

    tPos=constrain(int((sPos-mouseY)/tScale)+sSpeed, kMinTemp, kMaxTemp);

    if (tPos>0)
      kMinTemp=0;
    else if (tPos<0)
      kMaxTemp=0;

    //cabButton.setThrottle(tPos);    //  Without Canton management tPos = speed
    cabButton.setThrottleCanton(tPos, cabButton.current_Canton);    //  Cantons management : tPos = speed and all cantons of the track = 0
  }  //  Throttle drag

  //////////////////////////////////////////////////////////////////////////

  void keyControl(int m) {
    int tPos;

    if (m==0) {                                    // emergency stop
      tPos=0;
      cabButton.throttleSpeed=ThrottleSpeed.STOP;
    } else {
      tPos=constrain(sSpeed+=m, kMinTemp, kMaxTemp);
    }

    if (tPos>0)
      kMinTemp=0;
    else if (tPos<0)
      kMaxTemp=0;

    //cabButton.setThrottle(tPos);    //  Without canton management TPos = speed
    cabButton.setThrottleCanton(tPos, cabButton.current_Canton);    //  With cantons management: tPos = speed and all cantons of the track = 0
  }  //  Throttle keyControl
} // Throttle Class

//////////////////////////////////////////////////////////////////////////
//  Class CabButton
//////////////////////////////////////////////////////////////////////////

class CabButton extends RectButton {
  int reg, cab;
  int speed=0;
  int baseHue;
  int current_Canton = 0;    //  Need for cantons management
  int current_Speed = 0;    //  Need for cantons management
  String name;
  RouteButton sidingRoute;
  int sidingSensor=0;
  int parkingSensor=0;
  Track refTrack;
  int trackPoint;
  float lLength;
  XML speedXML, cabDefaultXML;
  XML throttleDefaultsXML;
  ThrottleSpeed throttleSpeed=ThrottleSpeed.STOP;  
  Window fbWindow;
  ArrayList<Window> windowList = new ArrayList<Window>();
  int[] fStatus = new int[29];
  HashMap<CabFunction, FunctionButton> functionsHM = new HashMap<CabFunction, FunctionButton>();
  Throttle throttle;
  PImage cabImage;
  String cabFile;
  Window editWindow;
  InputBox cabNumInput;

  CabButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, int cab, Throttle throttle) {
    super(null, xPos, yPos, bWidth, bHeight, baseHue, color(0), fontSize, str(cab), ButtonType.NORMAL);
    this.cab=cab;
    this.throttle=throttle;
    this.baseHue=baseHue;
    cabButtons.add(this);
    reg=cabButtons.size();
    cabFile=("cab-"+cab+".jpg");
    cabImage=loadImage(cabFile);        
    name="Cab"+cab;
    cabsHM.put(name, this);    
    colorMode(HSB, 255);
    editWindow = new Window(xPos-(bWidth/2), yPos-(bHeight/2), bWidth, bHeight, color(baseHue, 255, 255), color(255, 0, 0));   
    cabNumInput = new InputBox(this);

    speedXML=autoPilotXML.getChild(name);
    if (speedXML==null) {
      speedXML=autoPilotXML.addChild(name);
      speedXML.setContent(ThrottleSpeed.STOP.name());
    }

    cabDefaultXML=cabDefaultsXML.getChild(name);
    if (cabDefaultXML==null) {
      cabDefaultXML=cabDefaultsXML.addChild(name);
    }
  } // CabButton

  //////////////////////////////////////////////////////////////////////////
  //   Speed screen display
  //////////////////////////////////////////////////////////////////////////

  void display() {
    super.display();

    imageMode(CENTER);
    fill(30);                
    rect(xPos+bWidth/2+30, yPos, 42, 20); // Position (X,Y) largeur, hauteur
    stroke(backgroundColor);
    line(xPos+bWidth/2+23, yPos-10, xPos+bWidth/2+23, yPos+10);
    line(xPos+bWidth/2+37, yPos-10, xPos+bWidth/2+37, yPos+10);
    textFont(throttleFont, 22);
    if (speed>0)
      fill(0, 255, 0); // Green
    else if (speed<0)
      fill(255, 0, 0); // Red
    else
      fill(255, 255, 0); // Yellow
    text(nf(abs(speed), 3), xPos+bWidth/2+30, yPos);
  }  //  CabButton display

  //////////////////////////////////////////////////////////////////////////
  // Cab's function screen display
  //////////////////////////////////////////////////////////////////////////

  void functionButtonWindow(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor) {
    if (windowList.size()==1)                  // there is already one defined window and another is requested -- add a NextFunctionsButton to the original window
      new NextFunctionsButton(fbWindow, this, kWidth/2, kHeight+5, 40, 15, 60, 8, "More...");  // (window, cButton, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText)

    fbWindow=new Window(xPos, yPos, kWidth, kHeight, backgroundColor, outlineColor);
    windowList.add(fbWindow);

    if (windowList.size()>1)                  // there are at least two defined windows -- add a NextFunctionsButton to this window
      new NextFunctionsButton(fbWindow, this, kWidth/2, kHeight+5, 40, 15, 60, 8, "More...");
  }  //  CabButton functionButtonWindow

  //////////////////////////////////////////////////////////////////////////

  void setFunction(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, int fNum, String name, ButtonType buttonType, CabFunction ... cFunc) {
    new FunctionButton(fbWindow, xPos, yPos, bWidth, bHeight, baseHue, fontSize, this, fNum, name, buttonType, cFunc);
  }  //  CabButton setFunction

  //////////////////////////////////////////////////////////////////////////

  void activateFunction(CabFunction cFunc, boolean s) {
    if (functionsHM.containsKey(cFunc))
      functionsHM.get(cFunc).activateFunction(s);
  }  //  CabButton activateFunction

  //////////////////////////////////////////////////////////////////////////

  void turnOn() {
    // println("CabButton turnOn");
    if (throttle.cabButton!=null) {
      throttle.cabButton.fbWindow.close();
      throttle.cabButton.turnOff();
    }

    super.turnOn();
    fbWindow.show();
    throttle.cabButton=this;
    opCabInput.setIntValue(cab);
  }  //  CabButton turnOn

  //////////////////////////////////////////////////////////////////////////

  void turnOff() {
    super.turnOff();
    fbWindow.close();
    throttle.cabButton=null;
  }  //  CabButton turnOff

  //////////////////////////////////////////////////////////////////////////

  void shiftPressed() {
    autoPilot.parkCab(this);    // ????????
  }  //  CabButton shiftPressed

  //////////////////////////////////////////////////////////////////////////

  void rightClick() {
    editWindow.open();    //  Right clic on cab number may modify the cab number
  }  //  CabButton rightClick

  //////////////////////////////////////////////////////////////////////////
  //   Speed definition for Arduino
  //////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////
  //  Without Cantons management
  //////////////////////////////////////////////////////////////////////////

  void setThrottle(int tPos) {
    //println("CabButton setThrottle  tPos");
    aPort.write("<t"+reg+" "+cab+" "+abs(tPos)+" "+int(tPos>0)+">");    //***** SET ENGINE THROTTLES USING 128-STEP SPEED CONTROL ****/    
    /*  case 't':       // <t REGISTER CAB SPEED DIRECTION>
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
    if (throttleSpeed!=ThrottleSpeed.STOP) {
      throttleDefaultsXML.setInt(throttleSpeed.name(), tPos);
    }
    speed = tPos;
  }  //  CabButton setThrottle

  //////////////////////////////////////////////////////////////////////////
  //  In case of cantons management
  //////////////////////////////////////////////////////////////////////////

  void setThrottleCanton(int tPos, int tCanton) {
    println("setThrottle cab", cab, "  tPos", tPos, "  tCanton", tCanton);
    aPort.write("<t"+reg+" "+cab+" "+abs(tPos)+" "+int(tPos>0)+" "+int(tCanton)+">");    //***** SET ENGINE THROTTLES USING 128-STEP SPEED CONTROL ****/    
    /*  case 't':       // <t REGISTER CAB SPEED DIRECTION CANTON>
     *    sets the throttle for a given register/cab combination 
     *    REGISTER: an internal register number, from 1 through MAX_MAIN_REGISTERS 
     *      (inclusive), to store the DCC packet used to control this throttle setting
     *    CAB:  the short (1-127) or long (128-10293) address of the engine decoder
     *        In cantons management, it define the track to put the power 
     *    SPEED: throttle speed from 0-126, or -1 for emergency stop (resets SPEED to 0)
     *    DIRECTION: 1=forward, 0=reverse.  Setting direction when speed=0 or speed=-1 
     *      only effects directionality of cab lighting for a stopped train
     *    CANTON : define the canton to be considered on the track
     *
     *    returns: <T REGISTER SPEED DIRECTION>
     */
 
    if (throttleSpeed!=ThrottleSpeed.STOP) {
     throttleDefaultsXML.setInt(throttleSpeed.name(), tPos);
     }
    speed = tPos;
  }  //  CabButton setThrottleCanton

  //////////////////////////////////////////////////////////////////////////
  //  Without Canton management
  //////////////////////////////////////////////////////////////////////////

  void setThrottle(ThrottleSpeed throttleSpeed) {
    // println("CabButton setThrottle ThrottleSpeed");
    this.throttleSpeed=throttleSpeed;
    setThrottle(throttleDefaultsXML.getInt(throttleSpeed.name()));
    speedXML.setContent(throttleSpeed.name());
    activateFunction(CabFunction.F_LIGHT, true); //  activation du phare avant de la loco
    activateFunction(CabFunction.R_LIGHT, true); //  activation du phare arriere de la loco
    activateFunction(CabFunction.D_LIGHT, true);
  }  //  CabButton setThrottle

  //////////////////////////////////////////////////////////////////////////
  // DccStatus.xml : default speed storage - See coreConstants.java
  //    See DccStatus file to known cab speed default values
  ////////////////////////////////////////////////////////////////////////

  void setThrottleDefaults(int fullSpeed, int slowSpeed, int reverseSpeed, int reverseSlowSpeed, int factorSpeed) {
    // println("CabButton setTrottleDefaults");

    throttleDefaultsXML=cabDefaultXML.getChild("throttleDefaults");

    if (throttleDefaultsXML==null) {    //  Les valeurs dans le fichier DccStatus ne sont pas dans le même ordre
      throttleDefaultsXML=cabDefaultXML.addChild("throttleDefaults");
      throttleDefaultsXML.setInt(ThrottleSpeed.FULL.name(), fullSpeed);
      throttleDefaultsXML.setInt(ThrottleSpeed.SLOW.name(), slowSpeed);
      throttleDefaultsXML.setInt(ThrottleSpeed.REVERSE.name(), reverseSpeed);
      throttleDefaultsXML.setInt(ThrottleSpeed.REVERSE_SLOW.name(), reverseSlowSpeed);
      throttleDefaultsXML.setInt(ThrottleSpeed.FACTOR.name(), factorSpeed);
      throttleDefaultsXML.setInt(ThrottleSpeed.STOP.name(), 0);
    }
  }  //  CabButton setThrottleDefaults

  //////////////////////////////////////////////////////////////////////////
  //
  //////////////////////////////////////////////////////////////////////////

  void setSidingDefaults(RouteButton sidingRoute, int parkingSensor, int sidingSensor) {
    // println("CabButton setSiding");
    this.sidingRoute=sidingRoute;
    this.parkingSensor=parkingSensor;
    this.sidingSensor=sidingSensor;
  }  //  CabButton setSidingDefault

  //////////////////////////////////////////////////////////////////////////
  //  Emergency Stop throttle with DCC management
  //////////////////////////////////////////////////////////////////////////

  void stopThrottle() {
    // println("CabButton stopThrottle");
    aPort.write("<t"+reg+" "+cab+" -1 0>");    //***** SET ENGINE THROTTLES USING 128-STEP SPEED CONTROL ****/    
    /*  case 't':       // <t REGISTER CAB SPEED DIRECTION>
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
    throttleSpeed=ThrottleSpeed.STOP;
  }  //  CabButton stopThrottle

  //////////////////////////////////////////////////////////////////////////
  //  Emergency Stop throttle with Canton management
  //////////////////////////////////////////////////////////////////////////

  void stopThrottleCanton(int tCanton) {    //  In case of cantons management
    // println("CabButton stopThrottle Canton");
    for (cab = 1; cab<=7; cab++) {
      aPort.write("<t"+reg+" "+cab+" 0 0"+" "+int(tCanton)+">");    //  SET ENGINE THROTTLES USING 128-STEP SPEED CONTROL with cantons management
    }
    /*  case 't':       // <t REGISTER CAB SPEED DIRECTION CANTON>  in case of cantons management
     *    sets the throttle for a given register/cab combination 
     *    REGISTER: an internal register number, from 1 through MAX_MAIN_REGISTERS 
     *      (inclusive), to store the DCC packet used to control this throttle setting
     *    CAB:  the short (1-127) or long (128-10293) address of the engine decoder
     *        In case of cantons management, it define the track to put the power 
     *    SPEED: throttle speed from 0-126, or -1 for emergency stop (resets SPEED to 0)
     *    DIRECTION: 1=forward, 0=reverse.  Setting direction when speed=0 or speed=-1 
     *      only effects directionality of cab lighting for a stopped train
     *    CANTON : define the canton to be considered on the track
     *
     *    returns: <T REGISTER SPEED DIRECTION>
     */
    throttleSpeed=ThrottleSpeed.STOP;
  }  //  CabButton stopThrottleCanton

  //////////////////////////////////////////////////////////////////////////

  String toString() {
    return(name);
  }
} // CabButton Class

//////////////////////////////////////////////////////////////////////////
//  Class Cab FunctionButton
//////////////////////////////////////////////////////////////////////////

class FunctionButton extends RectButton {
  int fNum;
  CabButton cabButton;
  String name;
  int oneShotCount;
  int fPolarity;

  FunctionButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, CabButton cabButton, int fNum, String name, ButtonType buttonType, CabFunction[] cFunc) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(0), fontSize, name, buttonType);
    this.fNum=abs(fNum)%29;        // ensures fNum is always between 0 and 28, inclusive
    this.cabButton=cabButton;
    this.name=name;
    for (int i=0; i<cFunc.length; i++)
      cabButton.functionsHM.put(cFunc[i], this);
    if (buttonType==ButtonType.REVERSE)
      this.fPolarity=1;
  } // FunctionButton

  //////////////////////////////////////////////////////////////////////////

  void display() {
    if (buttonType==ButtonType.ONESHOT && oneShotCount>0) {    //  Type de bouton volatil 
      oneShotCount--;
      isOn=true;
    } else
      isOn=(cabButton.fStatus[fNum]!=fPolarity);    //  Type de bouton avec deux états stables
    super.display();
  }  //  FunctionButton display

  //////////////////////////////////////////////////////////////////////////

  void turnOn() {
    activateFunction(true);
  }  //  FunctionButton turnOn

  //////////////////////////////////////////////////////////////////////////

  void turnOff() {
    activateFunction(false);
  }  //  FunctionButton turnOff

  //////////////////////////////////////////////////////////////////////////

  void released() {
    if (buttonType==ButtonType.HOLD)
      turnOff();
  }  //  FunctionButton released

  //////////////////////////////////////////////////////////////////////////
  //  OPERATE ENGINE DECODER FUNCTIONS F0-F28 ==> See Railway_Control_Mega Arduino file
  //  Ces fonctions sont définies pour les Dcc ==> voir le codage des Dcc
  //////////////////////////////////////////////////////////////////////////

  void activateFunction(boolean s) {    //  Ces fonctions seront codée pour adresser les Dcc
    int f=0;
    int e=0;

    if (s) {    //  s = true
      cabButton.fStatus[fNum]=1-fPolarity;
      if (buttonType==ButtonType.ONESHOT) {
        fPolarity=1-fPolarity;
        oneShotCount=1;
      }
    } else {    //  s = false
      cabButton.fStatus[fNum]=fPolarity;
    }

    if (fNum<5) {    // functions F0-F4 are single byte instructions of form 1-0-0-F0-F4-F3-F2-F1
      /* 
       *    To set functions F0-F4 on (=1) or off (=0):
       *      
       *    BYTE1:  128 + F1*1 + F2*2 + F3*4 + F4*8 + F0*16
       *    BYTE2:  omitted
       */
      f=(1<<7)
        +(cabButton.fStatus[0]<<4)
        +(cabButton.fStatus[4]<<3)
        +(cabButton.fStatus[3]<<2)
        +(cabButton.fStatus[2]<<1)
        +cabButton.fStatus[1];
    } else if (fNum<9) {    // functions F5-F8 are single byte instructions of form 1-0-1-1-F8-F7-F6-F5
      /*
       *    To set functions F5-F8 on (=1) or off (=0):
       *    BYTE1:  176 + F5*1 + F6*2 + F7*4 + F8*8
       *    BYTE2:  omitted
       */
      f=(1<<7)
        +(1<<5)
        +(1<<4)
        +(cabButton.fStatus[8]<<3)
        +(cabButton.fStatus[7]<<2)
        +(cabButton.fStatus[6]<<1)
        +cabButton.fStatus[5];
    } else if (fNum<13) {    // functions F9-F12 are single byte instructions of form 1-0-1-0-F12-F11-F10-F9
      /*
       *    To set functions F9-F12 on (=1) or off (=0):
       *    BYTE1:  160 + F9*1 +F10*2 + F11*4 + F12*8
       *    BYTE2:  omitted
       */
      f=(1<<7)
        +(1<<5)
        +(cabButton.fStatus[12]<<3)
        +(cabButton.fStatus[11]<<2)
        +(cabButton.fStatus[10]<<1)
        +cabButton.fStatus[9];
    } else if (fNum<21) {    //  functions F13-F20 are two-byte instructions of form 0xDE followed by F20-F19-F18-F17-F16-F15-F14-F13
      /*
       *    To set functions F13-F20 on (=1) or off (=0):
       *    BYTE1: 222 
       *    BYTE2: F13*1 + F14*2 + F15*4 + F16*8 + F17*16 + F18*32 + F19*64 + F20*128
       */
      f=222;                             // 0xDE
      e=(cabButton.fStatus[20]<<7)
        +(cabButton.fStatus[19]<<6)
        +(cabButton.fStatus[18]<<5)
        +(cabButton.fStatus[17]<<4)
        +(cabButton.fStatus[16]<<3)
        +(cabButton.fStatus[15]<<2)
        +(cabButton.fStatus[14]<<1)
        +cabButton.fStatus[13];
    } else if (fNum<29) {    //  functions F21-F28 are two-byte instructions of form 0xDF followed by F28-F27-F26-F25-F24-F23-F22-F21
      /*
       *    To set functions F21-F28 on (=1) of off (=0):
       *    BYTE1: 223
       *    BYTE2: F21*1 + F22*2 + F23*4 + F24*8 + F25*16 + F26*32 + F27*64 + F28*128
       */
      f=223;                             // 0xDF
      e=(cabButton.fStatus[28]<<7)
        +(cabButton.fStatus[27]<<6)
        +(cabButton.fStatus[26]<<5)
        +(cabButton.fStatus[25]<<4)
        +(cabButton.fStatus[24]<<3)
        +(cabButton.fStatus[23]<<2)
        +(cabButton.fStatus[22]<<1)
        +cabButton.fStatus[21];
    }

    if (fNum<13)
      aPort.write("<f"+cabButton.cab+" "+f+">");    //***** OPERATE ENGINE DECODER FUNCTIONS F0-F28 ****/    
    /*    case 'f':       // <f CAB BYTE1 [BYTE2]>
     *    turns on and off engine decoder functions F0-F28 (F0 is sometimes called FL)  
     *    NOTE: setting requests transmitted directly to mobile engine decoder --- 
     *        current state of engine functions is not stored by this program
     *    CAB:  the short (1-127) or long (128-10293) address of the engine decoder
     *    To set functions F0-F4 on (=1) or off (=0):
     *    BYTE1:  128 + F1*1 + F2*2 + F3*4 + F4*8 + F0*16
     *    BYTE2:  omitted
     *    To set functions F5-F8 on (=1) or off (=0):
     *    BYTE1:  176 + F5*1 + F6*2 + F7*4 + F8*8
     *    BYTE2:  omitted
     *    To set functions F9-F12 on (=1) or off (=0):
     *    BYTE1:  160 + F9*1 +F10*2 + F11*4 + F12*8
     *    BYTE2:  omitted
     *    To set functions F13-F20 on (=1) or off (=0):
     *    BYTE1: 222 
     *    BYTE2: F13*1 + F14*2 + F15*4 + F16*8 + F17*16 + F18*32 + F19*64 + F20*128
     *    To set functions F21-F28 on (=1) of off (=0):
     *    BYTE1: 223
     *    BYTE2: F21*1 + F22*2 + F23*4 + F24*8 + F25*16 + F26*32 + F27*64 + F28*128
     *    returns: NONE
     */
    else
      aPort.write("<f"+cabButton.cab+" "+f+" "+e+">");
  }  //  FunctionButton activateFunction
} // FunctionButton Class

//////////////////////////////////////////////////////////////////////////
//  Class NextFunctionsButton
//////////////////////////////////////////////////////////////////////////

class NextFunctionsButton extends RectButton {
  CabButton cButton;

  NextFunctionsButton(Window window, CabButton cButton, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(0), fontSize, bText, ButtonType.ONESHOT);
    this.cButton=cButton;
  } // NextFunctionsButton

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    super.pressed();
    cButton.fbWindow.close();
    cButton.fbWindow=throttleA.cabButton.windowList.get((throttleA.cabButton.windowList.indexOf(throttleA.cabButton.fbWindow)+1)%throttleA.cabButton.windowList.size());
    cButton.fbWindow.open();
  }  //  NextFunctionsButton pressed
} // NextFunctionsButton Class
  //////////////////////////////////////////////////////////////////////////

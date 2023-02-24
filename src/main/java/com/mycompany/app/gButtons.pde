////////////////////////////////////////////////////////////////////////// //<>//
//  PROCESSING RAILWAY CONTROLLER: Generic Ellipse and Rectangle Buttons  //<>//
//      Sheet : gButtons
//
//  EllipseButton - base class for creating simple buttons
//                - operating buttons that extend EllipseButton should
//                  over-ride these methods with functionality specific
//                  to that button
//
//  RectButton    - variant of EllipseButton that define a rectanglular button
//
//////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
//    Class EllipseButton
//////////////////////////////////////////////////////////////////////////

class EllipseButton extends DccComponent {
  int bWidth, bHeight;
  int baseHue;
  color textColor;
  int fontSize;
  String bText;
  ButtonType buttonType;
  int remoteCode;
  boolean isOn=false;

  EllipseButton() {
    this(width/2, height/2, 80, 50, 100, color(0), 16, "Button", ButtonType.NORMAL);
  }

  EllipseButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, ButtonType buttonType) {
    this(null, xPos, yPos, bWidth, bHeight, baseHue, textColor, fontSize, bText, buttonType);
  }

  EllipseButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, ButtonType buttonType) {
    this.xPos=xPos;
    this.yPos=yPos;
    this.bWidth=bWidth;
    this.bHeight=bHeight;
    this.bText=bText;
    this.fontSize=fontSize;
    this.baseHue=baseHue;
    this.textColor=textColor;
    this.window=window;
    this.buttonType=buttonType;
    if (window==null)
      dccComponents.add(this);
    else
      window.windowComponents.add(this);
  } // EllipseButton

  //////////////////////////////////////////////////////////////////////////

  void display() {
    colorMode(HSB, 255);
    ellipseMode(CENTER);
    noStroke();
    fill(color(baseHue, 255, isOn?255:125));
    ellipse(xPos+xWindow(), yPos+yWindow(), bWidth, bHeight);
    fill(textColor);
    textFont(buttonFont, fontSize);
    textAlign(CENTER, CENTER);
    text(bText, xPos+xWindow(), yPos+yWindow());
    if (buttonType==ButtonType.ONESHOT && isOn)
      turnOff();
    colorMode(RGB, 255);
  }  //  EllipseButton display

  //////////////////////////////////////////////////////////////////////////

  void check() {
    if (selectedComponent==null && (mouseX-xPos-xWindow())*(mouseX-xPos-xWindow())/(bWidth*bWidth/4.0)+(mouseY-yPos-yWindow())*(mouseY-yPos-yWindow())/(bHeight*bHeight/4.0)<=1) {
      cursorType=HAND;
      selectedComponent=this;
    }
  }  //  EllipseButton check

  //////////////////////////////////////////////////////////////////////////

  void turnOn() {
    isOn=true;
  }  //  EllipseButton turnOn

  //////////////////////////////////////////////////////////////////////////

  void turnOff() {
    isOn=false;
  }  //  EllipseButton turnOff

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    if (buttonType==ButtonType.T_COMMAND) {
      aPort.write("<T"+remoteCode+" "+(isOn?"0>":"1>"));    //***** CREATE/EDIT/REMOVE/SHOW & OPERATE A TURN-OUT  ****/    
    /*    case 'T':       // <T ID THROW>
     *   <T ID THROW>:                sets turnout ID to either the "thrown" or "unthrown" position
     *   ID: the numeric ID (0-32767) of the turnout to control
     *   THROW: 0 (unthrown) or 1 (thrown)
     *   returns: <H ID THROW> or <X> if turnout ID does not exist        
     *   <T ID ADDRESS SUBADDRESS>:   creates a new turnout ID, with specified ADDRESS and  SUBADDRESS      
     *       if turnout ID already exists, it is updated with specificed ADDRESS and SUBADDRESS      
     *       returns: <O> if successful and <X> if unsuccessful (e.g . out of memory)       
     *   <T ID>: deletes definition of turnout ID      
     *       returns: <O> if successful and <X> if unsuccessful (e.g. ID does not exist)      
     *   <T>: lists all defined turnouts      
     *         returns: <H ID ADDRESS SUBADDRESS THROW> for each defined turnout or <X> if no turnouts defined      
     *         where      
     *          ID: the numeric ID (0-32767) of the turnout to control      
     *          ADDRESS:  the primary address of the decoder controlling this turnout (0-511)      
     *          SUBADDRESS: the subaddress of the decoder controlling this turnout (0-3)      
     *         Once all turnouts have been properly defined, use the <E> command to store their definitions to EEPROM.      
     *         If you later make edits/additions/deletions to the turnout definitions, you must       
     *          invoke the <E> command if you want those new definitions updated in the EEPROM.        
     *         You can also clear everything stored in the EEPROM by invoking the <e> command.      
     *         To "throw" turnouts that have been defined use:      
     *   <T ID THROW>:   sets turnout ID to either the "thrown" or "unthrown" position      
     *       returns: <H ID THROW>, or <X> if turnout ID does not exist      
     *       where      
     *          ID: the numeric ID (0-32767) of the turnout to control      
     *          THROW: 0 (unthrown) or 1 (thrown)      
     */
      return;
    }

    if (buttonType==ButtonType.TI_COMMAND) {
      aPort.write("<T"+remoteCode+" "+(isOn?"1>":"0>"));
      return;
    }

    if (buttonType==ButtonType.Z_COMMAND) {
      aPort.write("<Z"+remoteCode+" "+(isOn?"0>":"1>"));    //***** CREATE/EDIT/REMOVE/SHOW & OPERATE AN OUTPUT PIN  ****/    
    /*    case 'Z':       // <Z ID ACTIVATE>
     *   sets output ID to either the "active" or "inactive" state
     *   ID: the numeric ID (0-32767) of the output to control
     *   ACTIVATE: 0 (active) or 1 (inactive)
     *   returns: <Y ID ACTIVATE> or <X> if output ID does not exist    
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
     */
      return;
    }

    if (isOn)
      turnOff();
    else
      turnOn();
  }  //  EllipseButton pressed

  //////////////////////////////////////////////////////////////////////////

  void released() {
    if (buttonType==ButtonType.HOLD)
      turnOff();
  }  //  EllipseButton released
} // EllipseButton Class

//////////////////////////////////////////////////////////////////////////
//    Class RectButton
//////////////////////////////////////////////////////////////////////////

class RectButton extends EllipseButton {

  RectButton() {
    super(width/2, height/2, 80, 50, 100, color(0), 16, "Button", ButtonType.NORMAL);
  }

  RectButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, ButtonType buttonType) {
    super(null, xPos, yPos, bWidth, bHeight, baseHue, textColor, fontSize, bText, buttonType);
  }

  RectButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, ButtonType buttonType) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, textColor, fontSize, bText, buttonType);
  }

  RectButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, ButtonType buttonType, int remoteCode) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, textColor, fontSize, bText, buttonType);
    this.remoteCode=remoteCode;
    remoteButtonsHM.put(remoteCode, this);
  } // RectangleButton

  //////////////////////////////////////////////////////////////////////////

  void display() {
    colorMode(HSB, 255);
    rectMode(CENTER);
    noStroke();
    fill(color(baseHue, 255, isOn?255:125));
    rect(xPos+xWindow(), yPos+yWindow(), bWidth, bHeight);
    fill(textColor);
    textFont(buttonFont, fontSize);
    textAlign(CENTER, CENTER);
    text(bText, xPos+xWindow(), yPos+yWindow());
    if (buttonType==ButtonType.ONESHOT && isOn)
      turnOff();
    colorMode(RGB, 255);
  }  //  RectButton display

  //////////////////////////////////////////////////////////////////////////

  void check() {
    if (selectedComponent==null && (mouseX>xPos+xWindow()-bWidth/2)&&(mouseX<xPos+xWindow()+bWidth/2)&&(mouseY>yPos+yWindow()-bHeight/2)&&(mouseY<yPos+yWindow()+bHeight/2)) {
      cursorType=HAND;
      selectedComponent=this;
    }
  }  //  RectButton check
} // RectButton Class

//////////////////////////////////////////////////////////////////////////
//    Class TriangleButton
//////////////////////////////////////////////////////////////////////////

class TriangleButton extends EllipseButton {

  TriangleButton() {
    super(width/2, height/2, 80, 50, 100, color(0), 10, "Loco", ButtonType.NORMAL);
  }

  TriangleButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, ButtonType buttonType) {
    super(null, xPos, yPos, bWidth, bHeight, baseHue, textColor, fontSize, bText, buttonType);
  }

  TriangleButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, ButtonType buttonType) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, textColor, fontSize, bText, buttonType);
  }

  TriangleButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, ButtonType buttonType, int remoteCode) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, textColor, fontSize, bText, buttonType);
    this.remoteCode=remoteCode;
    remoteButtonsHM.put(remoteCode, this);
  } // TriangleButton

  //////////////////////////////////////////////////////////////////////////

  void display() {
    colorMode(HSB, 255);
    rectMode(CENTER);
    strokeWeight(1);
    stroke(color(255, 255, 0));
    fill(color(baseHue, 255, isOn?255:125));
    //    if(isActive)
    //      fill(color(125,0,125));

    float x1Pos, x2Pos, x3Pos;
    float y1Pos, y2Pos, y3Pos;
    int rayon=10;
    x1Pos = xPos+xWindow();
    y1Pos = yPos-rayon+yWindow();
    x2Pos = xPos+(rayon*sqrt(3)/2)+xWindow();
    y2Pos = yPos+(rayon/2)+yWindow();
    x3Pos = xPos-(rayon*sqrt(3)/2)+xWindow();
    y3Pos = yPos+(rayon/2)+yWindow();

    triangle(x1Pos, y1Pos, x2Pos, y2Pos, x3Pos, y3Pos); // Sommet 1 : X,Y, sommet 2 : X,Y, sommet 3 : X,Y

    fill(textColor);
    textFont(buttonFont, fontSize);
    textAlign(CENTER, CENTER);
    text(bText, xPos+xWindow(), yPos+yWindow());
    if (buttonType==ButtonType.ONESHOT && isOn)
      turnOff();
    colorMode(RGB, 255);
  }  //  TriangleButton display

  //////////////////////////////////////////////////////////////////////////

  void check() {
    if (selectedComponent==null && (mouseX>xPos+xWindow()-bWidth/2)&&(mouseX<xPos+xWindow()+bWidth/2)&&(mouseY>yPos+yWindow()-bHeight/2)&&(mouseY<yPos+yWindow()+bHeight/2)) {
      cursorType=HAND;
      selectedComponent=this;
    }
  }  //  TriangleButton check
} // TriangleButton Class
  //////////////////////////////////////////////////////////////////////////

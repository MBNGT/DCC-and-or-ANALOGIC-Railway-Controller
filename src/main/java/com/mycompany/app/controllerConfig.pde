////////////////////////////////////////////////////////////////////////// //<>// //<>//
//  PROCESSING RAILWAY CONTROLLER: Configuration and Initialization
//      Sheet : ControllerConfig
//
//  * Defines all global variables and objects
//
//  * Reads and loads previous status data from status files
//
//  * Implements track layout(s), throttles, track buttons, route buttons,
//    cab buttons, function buttons, windows, current meter,
//    and all other user-specified components
//
//////////////////////////////////////////////////////////////////////////
// DECLARE "GLOBAL" VARIABLES and OBJECTS
////////////////////////////////////////////////////////////////////////

PApplet Applet = this;    // Refers to this program --- needed for Serial class

int cursorType;
String baseID;
boolean keyHold=false;
boolean saveXMLFlag=false;
int lastTime;
PFont throttleFont, messageFont, buttonFont;
color backgroundColor;
XML dccStatusXML, arduinoPortXML, SensorButtonsXML, SignalButtonsXML, LocoButtonsXML, autoPilotXML, cabDefaultsXML, serverListXML;

DccComponent selectedComponent, previousComponent;

////////////////////////////////////////////////////////////////////////
//  Array list
////////////////////////////////////////////////////////////////////////

ArrayList<DccComponent> dccComponents = new ArrayList<DccComponent>();
ArrayList<CabButton> cabButtons = new ArrayList<CabButton>();
ArrayList<LocoButton> locoButtons = new ArrayList<LocoButton>();  
ArrayList<CallBack> callBacks = new ArrayList<CallBack>();
ArrayList<DccComponent> buttonQueue = new ArrayList<DccComponent>();
ArrayList<DccComponent> buttonQueue2 = new ArrayList<DccComponent>();
ArrayList<MessageBox> msgAutoCab = new ArrayList<MessageBox>();
ArrayList<RouteButton> aRouteButtons = new ArrayList<RouteButton>();  //  Turnout right way
ArrayList<RouteButton> bRouteButtons = new ArrayList<RouteButton>();  //  Turnout deviant way
ArrayList<TrackButton> aTrackButtons = new ArrayList<TrackButton>(); // liste des dTurnouts avec tPos=0 ==> activé
ArrayList<TrackButton> bTrackButtons = new ArrayList<TrackButton>(); // liste des dTurnouts avec tPos=1 ==> non activé
ArrayList<Track> rTracks = new ArrayList<Track>(); // Liste des tracks
HashMap<String, CabButton> cabsHM = new HashMap<String, CabButton>();
HashMap<Integer, LocoButton> LocosHM = new HashMap<Integer, LocoButton>();    
HashMap<Integer, EllipseButton> remoteButtonsHM = new HashMap<Integer, EllipseButton>();
HashMap<Integer, TrackButton> trackButtonsHM = new HashMap<Integer, TrackButton>();  
HashMap<Integer, TrackSensor> SensorsHM = new HashMap<Integer, TrackSensor>();    
HashMap<Integer, SignalButton> SignalsHM = new HashMap<Integer, SignalButton>();    
HashMap<Integer, Track> Voie_A = new HashMap<Integer, Track>(); 
HashMap<Integer, Track> Voie_B = new HashMap<Integer, Track>(); 
HashMap<Integer, Track> Voie_C = new HashMap<Integer, Track>(); 
HashMap<Integer, Track> Voie_D = new HashMap<Integer, Track>(); 
HashMap<Integer, Track> Voie_A_B = new HashMap<Integer, Track>(); 
HashMap<Integer, Track> Voie_B_A = new HashMap<Integer, Track>(); 
HashMap<Integer, Track> Voie_B_C = new HashMap<Integer, Track>(); 
HashMap<Integer, Track> Voie_Clean = new HashMap<Integer, Track>(); 
HashMap<Track, Integer> Canton_A = new HashMap<Track, Integer>();   //  In case of cantons management
HashMap<Track, Integer> Canton_B = new HashMap<Track, Integer>();   //  In case of cantons management
HashMap<Track, Integer> Canton_C = new HashMap<Track, Integer>();   //  In case of cantons management
HashMap<Track, Integer> Canton_D = new HashMap<Track, Integer>();   //  In case of cantons management
HashMap<Track, Integer> Canton_GB = new HashMap<Track, Integer>();   //  In case of cantons management
HashMap<Track, Integer> Canton_GH = new HashMap<Track, Integer>();   //  In case of cantons management
HashMap<Track, Integer> Canton_A_B = new HashMap<Track, Integer>();   //  In case of cantons management
HashMap<Track, Integer> Canton_B_A = new HashMap<Track, Integer>();   //  In case of cantons management
HashMap<Track, Integer> Canton_B_C = new HashMap<Track, Integer>();   //  In case of cantons management
HashMap<Track, Integer> Canton_Clean = new HashMap<Track, Integer>();   //  In case of cantons management

////////////////////////////////////////////////////////////////////////
//  Interface
////////////////////////////////////////////////////////////////////////

ArduinoPort       aPort;
PowerButton       powerButton;
QuitButton        quitButton;
AutoPilotButton   autoPilot;
CleaningCarButton cleaningCab;
Throttle          throttleA;
Layout            layout, layout2, layoutBridge;
MessageBox        msgBoxMain, msgBoxDiagIn, msgBoxDiagOut, msgBoxClock, msgBoxTech;
CurrentMeter      currentMeter;
Window            mainWindow, accWindow, progWindow, portWindow, extrasWindow;
Window            opWindow, diagWindow, autoWindow, SensorWindow, ledWindow;
Window            SignalWindow1, SignalWindow2, CabWindow, TurnWindow;
ImageWindow       imageWindow;
JPGWindow         helpWindow;
MessageBox        msgAutoState, msgAutoTimer;
InputBox          activeInputBox;
InputBox          accAddInput, accSubAddInput;
InputBox          progCVInput, progHEXInput, progDECInput, progBINInput;
InputBox          opCabInput, opCVInput, opHEXInput, opDECInput, opBINInput, opBitInput;
InputBox          shortAddInput, longAddInput;
MessageBox        activeAddBox;
MessageBox        portBox, portNumBox;
MessageBox        ledHueMsg, ledSatMsg, ledValMsg, ledRedMsg, ledGreenMsg, ledBlueMsg;
PortScanButton    portScanButton;
LEDColorButton    ledColorButton;

////////////////////////////////////////////////////////////////////////
// DECLARE TRACK BUTTONS, ROUTE BUTTONS, and CAB BUTTONS WHICH WILL BE DEFINED BELOW AND USED "GLOBALLY"  
////////////////////////////////////////////////////////////////////////

//  old track button
TrackButton      tButton1, tButton2, tButton3, tButton4, tButton5;
TrackButton      tButton6, tButton7, tButton8, tButton9, tButton10;
TrackButton      tButton11, tButton12, tButton13, tButton14, tButton15;
TrackButton      tButton16, tButton17, tButton18, tButton19, tButton21, tButton22;
TrackButton      tButton20, tButton30, tButton40, tButton50;

//  new track button
TrackButton      tButton101, tButton102, tButton103, tButton104, tButton105;
TrackButton      tButton106, tButton107, tButton108, tButton109, tButton110;
TrackButton      tButton111, tButton112, tButton113, tButton114, tButton115;
TrackButton      tButton116, tButton117, tButton118, tButton119;

//  route button
RouteButton      rButton20, rButton21, rButton22, rButton23, rButton24, rButton25;
RouteButton      rButton26, rButton27, rButton28, rButton29, rButtonClean, rButtonReset;

//  Cab button
CabButton        cab1, cab2, cab3, cab4, cab5, cab6, cab7;

//  Loco button
LocoButton       Loco1, Loco2, Loco3, Loco4, Loco5, Loco6, Loco7;

//  Sensor button
TrackSensor      Sensor1, Sensor2, Sensor3, Sensor4, Sensor5;
TrackSensor      Sensor6, Sensor7, Sensor8, Sensor9, Sensor10;
TrackSensor      Sensor11, Sensor12, Sensor13, Sensor14, Sensor15, Sensor16;

//  Signal button
SignalButton      SButton1, SButton2, SButton3, SButton4, SButton5;
SignalButton      SButton6, SButton7, SButton8, SButton9, SButton10;
SignalButton      SButton11, SButton12, SButton13, SButton14, SButton15;
SignalButton      SButton16, SButton17, SButton18, SButton19, SButton20;
SignalButton      SButton21, SButton22, SButton23, SButton24, SButton25;
SignalButton      SButton26, SButton27, SButton28, SButton29, SButton30;
SignalButton      SButton31, SButton32, SButton33, SButton34, SButton35, SButton36;

////////////////////////////////////////////////////////////////////////
//  Initialize --- configures everything!
////////////////////////////////////////////////////////////////////////

void Initialize() {
  colorMode(RGB, 255);
  throttleFont=loadFont("OCRAExtended-26.vlw");
  messageFont=loadFont("LucidaConsole-18.vlw");
  buttonFont=loadFont("LucidaConsole-18.vlw");
  rectMode(CENTER);
  textAlign(CENTER, CENTER);
  backgroundColor=color(50, 50, 60);

  aPort=new ArduinoPort();

  // READ, OR CREATE IF NEEDED, XML DCC STATUS FILE

  dccStatusXML=loadXML(STATUS_FILE);
  if (dccStatusXML==null) {
    dccStatusXML=new XML("dccStatus");
  }

  arduinoPortXML=dccStatusXML.getChild("arduinoPort");
  if (arduinoPortXML==null) {
    arduinoPortXML=dccStatusXML.addChild("arduinoPort");
    arduinoPortXML.setContent("Emulator");
  }

  serverListXML=dccStatusXML.getChild("serverList");
  if (serverListXML==null) {
    serverListXML=dccStatusXML.addChild("serverList");
    serverListXML.setContent("127.0.0.1");
  }

  SensorButtonsXML=dccStatusXML.getChild("SensorButtons");
  if (SensorButtonsXML==null) {
    SensorButtonsXML=dccStatusXML.addChild("SensorButtons");
  }

  SignalButtonsXML=dccStatusXML.getChild("SignalButtons");
  if (SignalButtonsXML==null) {
    SignalButtonsXML=dccStatusXML.addChild("SignalButtons");
  }

  LocoButtonsXML=dccStatusXML.getChild("LocoButtons");
  if (LocoButtonsXML==null) {
    LocoButtonsXML=dccStatusXML.addChild("LocoButtons");
  }

  autoPilotXML=dccStatusXML.getChild("autoPilot");
  if (autoPilotXML==null) {
    autoPilotXML=dccStatusXML.addChild("autoPilot");
  }

  cabDefaultsXML=dccStatusXML.getChild("cabDefaults");
  if (cabDefaultsXML==null) {
    cabDefaultsXML=dccStatusXML.addChild("cabDefaults");
  }

  saveXMLFlag=true;

  // CREATE THE ACCESSORY CONTROL WINDOW

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  accWindow = new Window(600, 500, 300, 160, color(200, 200, 200), color(200, 50, 50));
  new DragBar(accWindow, 0, 0, 300, 10, color(200, 50, 50));
  new CloseButton(accWindow, 288, 0, 10, 10, color(200, 50, 50), color(255, 255, 255));
  new MessageBox(accWindow, 150, 22, 0, 0, color(200, 200, 200), 20, "Accessory Control", color(200, 50, 50));
  new MessageBox(accWindow, 20, 60, -1, 0, color(200, 200, 200), 16, "Acc Address (0-511):", color(200, 50, 50));

  accAddInput = new InputBox(accWindow, 230, 60, 16, color(200, 200, 200), color(50, 50, 200), 3, InputType.DEC);
  new MessageBox(accWindow, 20, 90, -1, 0, color(200, 200, 200), 16, "Sub Address   (0-3):", color(200, 50, 50));

  accSubAddInput = new InputBox(accWindow, 230, 90, 16, color(200, 200, 200), color(50, 50, 200), 1, InputType.DEC);
  new AccessoryButton(accWindow, 90, 130, 55, 25, 100, 18, "ON", accAddInput, accSubAddInput);
  new AccessoryButton(accWindow, 210, 130, 55, 25, 0, 18, "OFF", accAddInput, accSubAddInput);

  accAddInput.setNextBox(accSubAddInput);
  accSubAddInput.setNextBox(accAddInput);

  // CREATE THE SERIAL PORT WINDOW

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  portWindow = new Window(500, 200, 500, 170, color(200, 200, 200), color(200, 50, 50));
  new DragBar(portWindow, 0, 0, 500, 10, color(200, 50, 50));
  new CloseButton(portWindow, 488, 0, 10, 10, color(200, 50, 50), color(255, 255, 255));
  new MessageBox(portWindow, 250, 22, 0, 0, color(200, 200, 200), 20, "Select Arduino Port", color(200, 50, 50));

  portScanButton = new PortScanButton(portWindow, 100, 60, 85, 20, 100, 18, "SCAN");
  new PortScanButton(portWindow, 400, 60, 85, 20, 0, 18, "CONNECT");
  new PortScanButton(portWindow, 120, 140, 15, 20, 120, 18, "<");
  new PortScanButton(portWindow, 380, 140, 15, 20, 120, 18, ">");

  portBox = new MessageBox(portWindow, 250, 100, 380, 25, color(250, 250, 250), 20, "", color(50, 150, 50));
  portBox.setMessage("Please press SCAN", color(150, 50, 50));
  portNumBox = new MessageBox(portWindow, 250, 140, 0, 0, color(200, 200, 200), 20, "", color(50, 50, 50));

  // CREATE THE PROGRAMMING CVs ON THE PROGRAMMING TRACK WINDOW

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  progWindow = new Window(500, 275, 500, 400, color(200, 180, 200), color(50, 50, 200));
  new DragBar(progWindow, 0, 0, 500, 10, color(50, 50, 200));
  new CloseButton(progWindow, 488, 0, 10, 10, color(50, 50, 200), color(255, 255, 255));
  new RectButton(progWindow, 250, 30, 210, 30, 40, color(0), 18, "Programming Track", ButtonType.TI_COMMAND, 101);        

  new MessageBox(progWindow, 20, 90, -1, 0, color(200, 180, 200), 16, "CV (1-1024):", color(50, 50, 200));
  new MessageBox(progWindow, 20, 130, -1, 0, color(200, 180, 200), 16, "Value (HEX):", color(50, 50, 200));
  new MessageBox(progWindow, 20, 160, -1, 0, color(200, 180, 200), 16, "Value (DEC):", color(50, 50, 200));
  new MessageBox(progWindow, 20, 190, -1, 0, color(200, 180, 200), 16, "Value (BIN):", color(50, 50, 200));
  progCVInput = new InputBox(progWindow, 150, 90, 16, color(200, 180, 200), color(200, 50, 50), 4, InputType.DEC);
  progHEXInput = new InputBox(progWindow, 150, 130, 16, color(200, 180, 200), color(200, 50, 50), 2, InputType.HEX);
  progDECInput = new InputBox(progWindow, 150, 160, 16, color(200, 180, 200), color(200, 50, 50), 3, InputType.DEC);
  progBINInput = new InputBox(progWindow, 150, 190, 16, color(200, 180, 200), color(200, 50, 50), 8, InputType.BIN);
  progCVInput.setNextBox(progHEXInput);
  progHEXInput.setNextBox(progDECInput);
  progDECInput.setNextBox(progBINInput);
  progDECInput.linkBox(progHEXInput);
  progBINInput.setNextBox(progHEXInput);
  progBINInput.linkBox(progHEXInput);        
  new ProgWriteReadButton(progWindow, 300, 90, 65, 25, 100, 14, "READ", progCVInput, progHEXInput);
  new ProgWriteReadButton(progWindow, 390, 90, 65, 25, 0, 14, "WRITE", progCVInput, progHEXInput);

  new MessageBox(progWindow, 20, 240, -1, 0, color(200, 180, 200), 16, "ENGINE ADDRESSES", color(50, 50, 200));
  new MessageBox(progWindow, 20, 280, -1, 0, color(200, 180, 200), 16, "Short  (1-127):", color(50, 50, 200));
  new MessageBox(progWindow, 20, 310, -1, 0, color(200, 180, 200), 16, "Long (0-10239):", color(50, 50, 200));
  new MessageBox(progWindow, 20, 340, -1, 0, color(200, 180, 200), 16, "Active        :", color(50, 50, 200));
  shortAddInput = new InputBox(progWindow, 190, 280, 16, color(200, 180, 200), color(200, 50, 50), 3, InputType.DEC);
  longAddInput = new InputBox(progWindow, 190, 310, 16, color(200, 180, 200), color(200, 50, 50), 5, InputType.DEC);
  activeAddBox = new MessageBox(progWindow, 190, 340, -1, 0, color(200, 180, 200), 16, "?", color(200, 50, 50));
  new ProgAddReadButton(progWindow, 300, 240, 65, 25, 100, 14, "READ", shortAddInput, longAddInput, activeAddBox);
  new ProgShortAddWriteButton(progWindow, 300, 280, 65, 25, 0, 14, "WRITE", shortAddInput);
  new ProgLongAddWriteButton(progWindow, 300, 310, 65, 25, 0, 14, "WRITE", longAddInput);
  new ProgLongShortButton(progWindow, 300, 340, 65, 25, 0, 14, "Long", activeAddBox);
  new ProgLongShortButton(progWindow, 390, 340, 65, 25, 0, 14, "Short", activeAddBox);

  // CREATE THE PROGRAMMING CVs ON THE MAIN OPERATIONS TRACK WINDOW

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  opWindow = new Window(500, 370, 500, 300, color(220, 200, 200), color(50, 50, 200));
  new DragBar(opWindow, 0, 0, 500, 10, color(50, 50, 200));
  new CloseButton(opWindow, 488, 0, 10, 10, color(50, 50, 200), color(255, 255, 255));
  new MessageBox(opWindow, 250, 30, 0, 0, color(220, 200, 200), 20, "Operations Programming", color(50, 100, 50));
  new MessageBox(opWindow, 20, 90, -1, 0, color(220, 200, 200), 16, "Cab Number :", color(50, 50, 200));
  new MessageBox(opWindow, 20, 120, -1, 0, color(220, 200, 200), 16, "CV (1-1024):", color(50, 50, 200));
  new MessageBox(opWindow, 20, 160, -1, 0, color(220, 200, 200), 16, "Value (HEX):", color(50, 50, 200));
  new MessageBox(opWindow, 20, 190, -1, 0, color(220, 200, 200), 16, "Value (DEC):", color(50, 50, 200));
  new MessageBox(opWindow, 20, 220, -1, 0, color(220, 200, 200), 16, "Value (BIN):", color(50, 50, 200));
  opCabInput = new InputBox(opWindow, 150, 90, 16, color(220, 200, 200), color(200, 50, 50), 5, InputType.DEC);
  opCVInput = new InputBox(opWindow, 150, 120, 16, color(220, 200, 200), color(200, 50, 50), 4, InputType.DEC);
  opHEXInput = new InputBox(opWindow, 150, 160, 16, color(220, 200, 200), color(200, 50, 50), 2, InputType.HEX);
  opDECInput = new InputBox(opWindow, 150, 190, 16, color(220, 200, 200), color(200, 50, 50), 3, InputType.DEC);
  opBINInput = new InputBox(opWindow, 150, 220, 16, color(220, 200, 200), color(200, 50, 50), 8, InputType.BIN);
  opCVInput.setNextBox(opHEXInput);
  opHEXInput.setNextBox(opDECInput);
  opDECInput.setNextBox(opBINInput);
  opDECInput.linkBox(opHEXInput);
  opBINInput.setNextBox(opHEXInput);
  opBINInput.linkBox(opHEXInput);        
  new OpWriteButton(opWindow, 300, 90, 65, 25, 0, 14, "WRITE", opCVInput, opHEXInput);
  new MessageBox(opWindow, 20, 260, -1, 0, color(220, 200, 200), 16, "  Bit (0-7):", color(50, 50, 200));
  opBitInput = new InputBox(opWindow, 150, 260, 16, color(220, 200, 200), color(200, 50, 50), 1, InputType.DEC);
  new OpWriteButton(opWindow, 300, 260, 65, 25, 50, 14, "SET", opCVInput, opBitInput);
  new OpWriteButton(opWindow, 390, 260, 65, 25, 150, 14, "CLEAR", opCVInput, opBitInput);

  // CREATE THE DCC++ CONTROL <-> Base Station COMMUNICATION DIAGNOSTICS WINDOW

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  diagWindow = new Window(500, 560, 500, 120, color(175), color(50, 200, 50));
  new DragBar(diagWindow, 0, 0, 500, 10, color(50, 200, 50));
  new CloseButton(diagWindow, 488, 0, 10, 10, color(50, 200, 50), color(255, 255, 255));
  new MessageBox(diagWindow, 250, 20, 0, 0, color(175), 18, "Diagnostics Window", color(50, 50, 200));
  new MessageBox(diagWindow, 10, 60, -1, 0, color(175), 18, "Sent:", color(50, 50, 200));
  msgBoxDiagOut=new MessageBox(diagWindow, 250, 60, 0, 0, color(175), 18, "---", color(50, 50, 200));
  new MessageBox(diagWindow, 10, 90, -1, 0, color(175), 18, "Proc:", color(50, 50, 200));
  msgBoxDiagIn=new MessageBox(diagWindow, 250, 90, 0, 0, color(175), 18, "---", color(50, 50, 200));

  // CREATE THE AUTOPILOT DIAGNOSTICS WINDOW 

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  autoWindow = new Window(550, 350, 500, 330, color(175), color(50, 200, 50));
  new DragBar(autoWindow, 0, 0, 500, 10, color(50, 200, 50));
  new CloseButton(autoWindow, 488, 0, 10, 10, color(50, 200, 50), color(255, 255, 255));
  new MessageBox(autoWindow, 250, 20, 0, 0, color(175), 18, "AutoPilot Window", color(50, 50, 150));
  msgAutoState=new MessageBox(autoWindow, 0, 180, -1, 0, color(175), 18, "?", color(50, 50, 250));
  msgAutoTimer=new MessageBox(autoWindow, 55, 310, -1, 0, color(175), 18, "Timer =", color(50, 50, 250));

  // CREATE THE SENSORS DIAGNOSTICS WINDOW 

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  SensorWindow = new Window(650, 280, 550, 400, color(0), color(50, 200, 50)); // Position x et y, Largeur, Hauteur, Couleur de fond, Couleur du bord
  new DragBar(SensorWindow, 0, 0, 550, 10, color(50, 200, 50)); // Position, largeur, hauteur, couleur de fond
  new CloseButton(SensorWindow, 538, 0, 10, 10, color(50, 200, 50), color(255, 255, 255));
  new MessageBox(SensorWindow, 250, 20, 0, 0, color(175), 18, "Sensors Window", color(50, 250, 150));

  // CREATE THE SIGNAL DIAGNOSTICS WINDOW 

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  SignalWindow1 = new Window(200, 200, 500, 460, color(0), color(50, 200, 50));
  new DragBar(SignalWindow1, 0, 0, 500, 10, color(50, 200, 50));
  new CloseButton(SignalWindow1, 488, 0, 10, 10, color(50, 200, 50), color(255, 255, 255));
  new MessageBox(SignalWindow1, 250, 20, 0, 0, color(175), 18, "Signals Window", color(50, 250, 150));

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  SignalWindow2 = new Window(800, 200, 500, 460, color(0), color(50, 200, 50));
  new DragBar(SignalWindow2, 0, 0, 500, 10, color(50, 200, 50));
  new CloseButton(SignalWindow2, 488, 0, 10, 10, color(50, 200, 50), color(255, 255, 255));
  new MessageBox(SignalWindow2, 250, 20, 0, 0, color(175), 18, "Signals Window", color(50, 250, 150));

  // CREATE THE TURNOUT DIAGNOSTICS WINDOW 

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  TurnWindow = new Window(200, 200, 500, 460, color(0), color(50, 200, 50));
  new DragBar(TurnWindow, 0, 0, 500, 10, color(50, 200, 50));
  new CloseButton(TurnWindow, 488, 0, 10, 10, color(50, 200, 50), color(255, 255, 255));
  new MessageBox(TurnWindow, 250, 20, 0, 0, color(175), 18, "Turnouts Window", color(50, 250, 150));

  // CREATE THE CAB DIAGNOSTICS WINDOW 

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  CabWindow = new Window(330, 485, 850, 200, color(0), color(50, 200, 50));
  new DragBar(CabWindow, 0, 0, 850, 10, color(50, 200, 50));
  new CloseButton(CabWindow, 838, 0, 10, 10, color(50, 200, 50), color(255, 255, 255));
  new MessageBox(CabWindow, 425, 20, 0, 0, color(175), 18, "Cab status Window", color(50, 250, 150));

  // CREATE THE HELP WINDOW

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  helpWindow=new JPGWindow("helpMenu.jpg", 1000, 650, 100, 50, color(0, 100, 0));    

  // CREATE THE EXTRAS WINDOW:

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  extrasWindow = new Window(550, 420, 500, 250, color(255, 255, 175), color(100, 100, 200));
  new DragBar(extrasWindow, 0, 0, 500, 10, color(100, 100, 200));
  new CloseButton(extrasWindow, 488, 0, 10, 10, color(100, 100, 200), color(255, 255, 255));
  new MessageBox(extrasWindow, 250, 20, 0, 0, color(175), 18, "Extra Functions", color(50, 50, 200));
  //new RectButton(extrasWindow, 260, 80, 120, 50, color(0), 16, "Sound\nEffects", 0);        

  // CREATE THE LED LIGHT-STRIP WINDOW:

  //  Def Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  ledWindow = new Window(500, 200, 550, 425, color(0), color(0, 0, 200));
  new DragBar(ledWindow, 0, 0, 550, 10, color(0, 0, 200));
  new CloseButton(ledWindow, 538, 0, 10, 10, color(0, 0, 200), color(200, 200, 200));
  new MessageBox(ledWindow, 275, 20, 0, 0, color(175), 18, "LED Light Strip", color(200, 200, 200));
  ledColorButton=new LEDColorButton(ledWindow, 310, 175, 30, 201, 0.0, 0.0, 1.0);
  new LEDColorSelector(ledWindow, 150, 175, 100, ledColorButton);
  new LEDValSelector(ledWindow, 50, 330, 200, 30, ledColorButton);
  ledHueMsg = new MessageBox(ledWindow, 360, 80, -1, 0, color(175), 18, "Hue:   -", color(200, 200, 200));
  ledSatMsg = new MessageBox(ledWindow, 360, 115, -1, 0, color(175), 18, "Sat:   -", color(200, 200, 200));
  ledValMsg = new MessageBox(ledWindow, 360, 150, -1, 0, color(175), 18, "Val:   -", color(200, 200, 200));
  ledRedMsg = new MessageBox(ledWindow, 360, 185, -1, 0, color(175), 18, "Red:   -", color(200, 200, 200));
  ledGreenMsg = new MessageBox(ledWindow, 360, 220, -1, 0, color(175), 18, "Green: -", color(200, 200, 200));
  ledBlueMsg = new MessageBox(ledWindow, 360, 255, -1, 0, color(175), 18, "Blue:  -", color(200, 200, 200));

  // CREATE TOP-OF-SCREEN MESSAGE BAR AND HELP BUTTON

  msgBoxMain=new MessageBox(width/2, 12, width, 25, color(200), 15, "Searching for Base Station: "+arduinoPortXML.getContent(), color(30, 30, 150));
  new HelpButton(width-50, 12, 22, 22, 150, 20, "?");

  // CREATE DOWN-OF-SCREEN TECHNIC MESSAGES BOX

  msgBoxTech=new MessageBox(width/2, 700, width, 25, color(200), 15, "Technic messages from Base Station: "+arduinoPortXML.getContent(), color(30, 30, 150));

  // CREATE CLOCK

  msgBoxClock=new MessageBox(30, 700, -100, 30, backgroundColor, 20, "00:00:00", color(255, 255, 255));

  // CREATE POWER BUTTON, QUIT BUTTON, and CURRENT METER

  //  Def button(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor)
  powerButton=new PowerButton(75, 475, 120, 30, 100, 18, "FULL POWER");
  quitButton=new QuitButton(200, 475, 100, 30, 250, 18, "QUIT");
  currentMeter = new CurrentMeter(25, 550, 150, 100, 675, 5);

  // CREATE THROTTLE, DEFINE CAB BUTTONS, and SET FUNCTIONS FOR EACH CAB

  int tAx=175;  // Origine pour les boutons des cabs
  int tAy=225;
  int TrackX=0;  // Origine pour le dessin des voies
  int TrackY=500; 
  int rX=800;  // Origine pour les boutons des voies
  int rY=550;

  throttleA=new Throttle(tAx, tAy, 1.3);  // xPos, yPos, tScale

  cab1 = new CabButton(tAx-125, tAy-150, 50, 30, 0, 15, 1, throttleA); // Position (X,Y), largeur, hauteur, Couleur, Font size, nom=cab, vitesse
  cab1.setThrottleDefaults(100, 50, -50, -45, 18); // default speed values ==> see DccStatus.xml
  cab1.functionButtonWindow(220, 59, 70, 340, backgroundColor, backgroundColor);  // Position (X,Y),largeur, hauteur, couleur background, couleur outline
  cab1.setFunction(35, 15, 60, 22, 60, 10, 0, "Headlight", ButtonType.NORMAL, CabFunction.F_LIGHT); //  Bouton pour activation du front light de la loco
  cab1.setFunction(35, 45, 60, 22, 60, 10, 1, "Tailight", ButtonType.NORMAL, CabFunction.R_LIGHT);  //  Bouton pour activation du rear light de la loco

  cab2 = new CabButton(tAx-125, tAy-100, 50, 30, 25, 15, 2, throttleA); // xPos, yPos,  bWidth, bHeight, baseHue, fontSize, cab, Throttle throttle
  cab2.setThrottleDefaults(53, 30, -20, -13, 20);
  cab2.functionButtonWindow(220, 59, 70, 340, backgroundColor, backgroundColor);
  cab2.setFunction(35, 15, 60, 22, 60, 10, 0, "Headlight", ButtonType.NORMAL, CabFunction.F_LIGHT); //  Front light de la loco
  cab2.setFunction(35, 45, 60, 22, 60, 10, 1, "Tailight", ButtonType.NORMAL, CabFunction.R_LIGHT);

  cab3 = new CabButton(tAx-125, tAy-50, 50, 30, 50, 15, 3, throttleA);
  cab3.setThrottleDefaults(77, 46, -34, -30, 15);
  cab3.functionButtonWindow(220, 59, 70, 340, backgroundColor, backgroundColor);
  cab3.setFunction(35, 15, 60, 22, 60, 10, 0, "Lights", ButtonType.NORMAL, CabFunction.F_LIGHT, CabFunction.R_LIGHT);

  cab4 = new CabButton(tAx-125, tAy, 50, 30, 75, 15, 4, throttleA);
  cab4.setThrottleDefaults(50, 25, -25, -15, 18);
  cab4.functionButtonWindow(220, 59, 70, 340, backgroundColor, backgroundColor);
  cab4.setFunction(35, 15, 60, 22, 60, 10, 0, "Headlight", ButtonType.NORMAL, CabFunction.F_LIGHT);
  cab4.setFunction(35, 45, 60, 22, 60, 10, 1, "Tailight", ButtonType.NORMAL, CabFunction.R_LIGHT);

  cab5 = new CabButton(tAx-125, tAy+50, 50, 30, 100, 15, 5, throttleA);
  cab5.setThrottleDefaults(34, 14, -5, -3, 25);
  cab5.functionButtonWindow(220, 59, 70, 340, backgroundColor, backgroundColor);
  cab5.setFunction(35, 15, 60, 22, 60, 10, 10, "Radiator\nFan", ButtonType.NORMAL);  //  Bouton pour activation du bruit du ventilateur
  cab5.setFunction(35, 45, 60, 22, 60, 10, 11, "Air Fill\n/Release", ButtonType.ONESHOT);  //  Bouton pour activation du 
  cab5.setFunction(35, 75, 60, 22, 60, 10, 14, "Passenger\nDep/Arr", ButtonType.ONESHOT);  //  Bouton pour activation du 
  cab5.setFunction(35, 105, 60, 22, 60, 10, 18, "City\nSounds", ButtonType.ONESHOT);  //  Bouton pour activation du bruit de la cité
  cab5.setFunction(35, 135, 60, 22, 60, 10, 19, "Farm\nSounds", ButtonType.ONESHOT);  //  Bouton pour activation du bruit d'une ferme
  cab5.setFunction(35, 165, 60, 22, 60, 10, 21, "Lumber\nMill", ButtonType.ONESHOT);  //  Bouton pour activation du 
  cab5.setFunction(35, 195, 60, 22, 60, 10, 20, "Industry\nSounds", ButtonType.ONESHOT);  //  Bouton pour activation du bruit de l'industrie
  cab5.setFunction(35, 225, 60, 22, 60, 10, 13, "Crossing\nHorn", ButtonType.ONESHOT, CabFunction.S_HORN);  //  Bouton pour activation du bruit d'une corne de croisement
  cab5.setFunction(35, 255, 60, 22, 60, 10, 22, "Alternate\nHorn", ButtonType.NORMAL);  //  Bouton pour activation du 
  cab5.setFunction(35, 285, 60, 22, 60, 10, 8, "Mute", ButtonType.NORMAL);  //  Bouton pour activation de la coupure du son
  cab5.functionButtonWindow(220, 59, 70, 340, backgroundColor, backgroundColor);
  cab5.setFunction(35, 15, 60, 22, 60, 10, 0, "Headlight", ButtonType.NORMAL, CabFunction.F_LIGHT);  //  Bouton pour activation du 
  cab5.setFunction(35, 45, 60, 22, 60, 10, 1, "Bell", ButtonType.NORMAL, CabFunction.BELL);  //   Bouton pour activation de la cloche
  cab5.setFunction(35, 75, 60, 22, 60, 10, 2, "Horn", ButtonType.HOLD, CabFunction.HORN);  //  Bouton pour activation de la corne
  cab5.setFunction(35, 105, 60, 22, 60, 10, 3, "MARS\nLight", ButtonType.REVERSE, CabFunction.D_LIGHT);  //  Bouton pour activation du 
  cab5.setFunction(35, 135, 16, 22, 60, 10, 9, "1", ButtonType.NORMAL);  //  Bouton pour activation du 
  cab5.setFunction(14, 135, 16, 22, 60, 10, 5, "+", ButtonType.ONESHOT);  //  Bouton pour activation du 
  cab5.setFunction(56, 135, 16, 22, 60, 10, 6, "-", ButtonType.ONESHOT);  //  Bouton pour activation du 
  cab5.setFunction(35, 165, 60, 22, 60, 10, 15, "Freight\nDep/Arr", ButtonType.ONESHOT);  //  Bouton pour activation du 
  cab5.setFunction(35, 195, 60, 22, 60, 10, 16, "Facility\nShop", ButtonType.ONESHOT);  //  Bouton pour activation du 
  cab5.setFunction(35, 225, 60, 22, 60, 10, 17, "Crew\nRadio", ButtonType.ONESHOT);  //  Bouton pour activation du 
  cab5.setFunction(35, 255, 60, 22, 60, 10, 7, "Coupler", ButtonType.ONESHOT);  //  Bouton pour activation du 
  cab5.setFunction(35, 285, 60, 22, 60, 10, 4, "Dynamic\nBrake", ButtonType.NORMAL);  //  Bouton pour activation du 
  cab5.setFunction(35, 315, 60, 22, 60, 10, 12, "Brake\nSqueal", ButtonType.ONESHOT);  //  Bouton pour activation du 

  cab6 = new CabButton(tAx-125, tAy+100, 50, 30, 125, 15, 6, throttleA);
  cab6.setThrottleDefaults(34, 25, -24, -18, 22);
  cab6.functionButtonWindow(220, 59, 70, 340, backgroundColor, backgroundColor);
  cab6.setFunction(35, 15, 60, 22, 60, 10, 0, "Headlight", ButtonType.NORMAL, CabFunction.F_LIGHT);  //  Bouton pour activation du 
  cab6.setFunction(35, 45, 60, 22, 60, 10, 1, "Tailight", ButtonType.NORMAL, CabFunction.R_LIGHT);  //  Bouton pour activation du 

  cab7 = new CabButton(tAx-125, tAy+150, 50, 30, 150, 15, 7, throttleA);
  cab7.setThrottleDefaults(61, 42, -30, -22, 25);    
  cab7.functionButtonWindow(220, 59, 70, 340, backgroundColor, backgroundColor);
  cab7.setFunction(35, 15, 60, 22, 60, 10, 1, "Headlight", ButtonType.NORMAL, CabFunction.F_LIGHT);  //  Bouton pour activation du 
  cab7.setFunction(35, 45, 60, 22, 60, 10, 0, "Tailight", ButtonType.NORMAL, CabFunction.R_LIGHT);  //  Bouton pour activation du 
  cab7.setFunction(35, 75, 60, 22, 60, 10, 3, "D-Lights", ButtonType.NORMAL, CabFunction.D_LIGHT);  //  Bouton pour activation du 

  //  CREATE THE IMAGE WINDOW FOR THROTTLE A (must be done AFTER throttle A is defined above)

  imageWindow=new ImageWindow(throttleA, 975, 450, 200, 50, color(200, 50, 50));    

  // CREATE AUTO PILOT BUTTON and CLEANING CAR BUTTON (must be done AFTER cab buttons are defined above)

  autoPilot=new AutoPilotButton(325, 550, 100, 50, 30, 16, "AUTO\nPILOT");
  //  cleaningCab=new CleaningCarButton(extrasWindow, 28, 80, 80, 120, 50, 40, 16, "Cleaning\nCar");        
  cleaningCab=new CleaningCarButton(28, 325, 630, 100, 50, 40, 16, "Cleaning\nCar");        

  // CREATE MAIN LAYOUT AND DEFINE ALL TRACKS

  layout=new Layout(325, 50, 1000, 80*25.4, 36*25.4); // Origine en haut à gauche : xcorner , ycorner, echelle, largeur fonction echelle, hauteur fonction echelle

  // Voie A
  Track ZoneA1 = new Track(layout, TrackX, TrackY, 350, -90, 90); // Ligne courbe quart haut ouest : rayon, orientation, direction initiale (trigo)
  Track ZoneA2 = new Track(ZoneA1, 1, 50); // Aiguillage entre voie A et B direct ligne droite de voie A vers voie A 
  Track ZoneA3 = new Track(ZoneA1, 1, 100, -35.5); // Aiguillage entre voie A et B dévié ligne courbe à droite de voie A vers Voie B
  Track ZoneA4 = new Track(ZoneA3, 1, 100, 35.5); // Aiguillage entre voie A et B dévié ligne courbe à gauche de voie A vers Voie B
  Track ZoneA5 = new Track(ZoneA2, 1, 70); // Aiguillage entre voie A et GB direct ligne droite de voie A vers Voie Gare Basse
  Track ZoneA6 = new Track(ZoneA2, 1, 250, 25); // Aiguillage entre voie A et GB dévié ligne courbe à gauche de voie A vers Gare Basse
  Track ZoneA7 = new Track(ZoneA5, 1, 1130); // Ligne droite quai de gauche à droite
  Track ZoneA8 = new Track(ZoneA7, 1, 50); // Aiguillage entre Voie B et A  direct ligne droite de Voie A vers voie A
  Track ZoneA9 = new Track(ZoneA8, 1, 350, -90); // Ligne courbe quart haut est
  Track ZoneA10 = new Track(ZoneA9, 1, 350, -90); // Ligne courbe quart haut ouest
  Track ZoneA11 = new Track(ZoneA10, 1, 350, -180); // Ligne courbe demi est ouest
  Track ZoneA12 = new Track(ZoneA11, 1, 350, -90); // Ligne courbe quart bas est
  Track ZoneA13 = new Track(ZoneA12, 1, 350, -90); // Ligne courbe quart bas est
  Track ZoneA14 = new Track(ZoneA13, 1, 510); // Ligne droite quai de droite à gauche
  Track ZoneA15 = new Track(ZoneA14, 1, 50); // Aiguillage entre voie B et A direct ligne droite de Voie A vers Voie A
  Track ZoneA16 = new Track(ZoneA15, 1, 468); // Ligne droite quai de droite à gauche
  Track ZoneA17 = new Track(ZoneA16, 1, 62); // Aiguillage entre voie A et B direct ligne droite de Voie A vers Voie A
  Track ZoneA18 = new Track(ZoneA16, 1, 100, -35.5); // Aiguillage entre voie A et B dévié ligne courbe à droite de Voie A vers Voie B
  Track ZoneA19 = new Track(ZoneA18, 1, 100, 35.5); // Croisement voie B : ligne courbe à gauche de Voie A vers Voie B
  Track ZoneA20 = new Track(ZoneA17, 1, 210); // Ligne droite quai de droite à gauche
  Track ZoneA21 = new Track(ZoneA20, 1, 350, -90); // Ligne courbe quart bas ouest
  Track ZoneA22 = new Track(ZoneA21, 1, 350, -90); // Ligne courbe quart haut ouest
  Track ZoneA23 = new Track(ZoneA22, 1, 350, -180); // Ligne courbe demi est ouest
  Track ZoneA24 = new Track(ZoneA23, 1, 350, -90); // Ligne courbe quart bas ouest

  // Voie Garage gare basse
  Track ZoneGB1 = new Track(ZoneA6, 1, 75); // Ligne droite
  Track ZoneGB2 = new Track(ZoneA6, 1, 100, -25); // Aiguillage dévié ligne courbe à droite vers Gare Basse Voie 1
  Track ZoneGB3 = new Track(ZoneGB2, 1, 800); // Ligne droite Gare Basse Voie 1 de gauche à droite
  Track ZoneGB4 = new Track(ZoneGB1, 1, 75); // Ligne droite
  Track ZoneGB5 = new Track(ZoneGB1, 1, 100, -25); // Aiguillage dévié ligne courbe à droite vers Gare Base Voie 2
  Track ZoneGB6 = new Track(ZoneGB5, 1, 800); // Ligne droite Gare Basse Voie 2 de gauche à droite
  Track ZoneGB7 = new Track(ZoneGB4, 1, 75); // Ligne droite
  Track ZoneGB8 = new Track(ZoneGB4, 1, 100, -25); // Aiguillage dévié ligne courbe à droite vers Gare Basse Voie 3
  Track ZoneGB9 = new Track(ZoneGB8, 1, 800); // Ligne droite Gare Basse Voie 3 de gauche à droite
  Track ZoneGB10 = new Track(ZoneGB7, 1, 100, -25); // Ligne courbe à droite vers Gare Basse Voie 4
  Track ZoneGB11 = new Track(ZoneGB10, 1, 800); // Ligne droite Gare Basse Voie 4 de gauche à droite

  // Voie B
  Track ZoneB1 = new Track(layout, TrackX+37.5, TrackY, 312.5, -90, 90); // Ligne courbe quart haut ouest : rayon, orientation
  Track ZoneB2 = new Track(ZoneB1, 1, 50); // Ligne droite de gauche à droite
  Track ZoneB3 = new Track(ZoneB2, 1, 70); // Aiguillage direct ligne droite de Voie B vers Voie B
  Track ZoneB4 = new Track(ZoneB3, 1, 1060); // Ligne droite quai de gauche à droite
  Track ZoneB5 = new Track(ZoneB4, 1, 50); // Aiguillage direct ligne droite de Voie B vers Voie B
  Track ZoneB6 = new Track(ZoneB4, 1, 100, 35.5); // Aiguillage dévié ligne courbe à gauche de Voie B vers Voie A
  Track ZoneB7 = new Track(ZoneB6, 1, 100, -35.5); // Aiguillage dévié ligne courbe à droite de Voie B vers Voie A
  Track ZoneB8 = new Track(ZoneB5, 1, 20); // Ligne droite de gauche à droite
  Track ZoneB9 = new Track(ZoneB8, 1, 50); // Ligne droite de gauche à droite
  Track ZoneB10 = new Track(ZoneB9, 1, 312.5, -90); // Ligne courbe quart haut est
  Track ZoneB11 = new Track(ZoneB10, 1, 312.5, -90); // Ligne courbe à droite quart haut ouest
  Track ZoneB12 = new Track(ZoneB11, 1, 312.5, -180); // Ligne courbe à droite demi ouest
  Track ZoneB13 = new Track(ZoneB12, 1, 312.5, -90); // Ligne courbe à droite quart bas ouest
  Track ZoneB14 = new Track(ZoneB13, 1, 312.5, -90); // Ligne courbe quart bas est
  Track ZoneB15 = new Track(ZoneB14, 1, 440); // Ligne droite de droite à gauche
  Track ZoneB16 = new Track(ZoneB15, 1, 60); // Croisement ligne droite de Voie B vers Voie B
  Track ZoneB17 = new Track(ZoneB15, 1, 100, 35.5); // Croisement ligne courbe à gauche de Voie B vers Voie A
  Track ZoneB18 = new Track(ZoneB17, 1, 100, -35.5); // Croisement ligne courbe à droite de Voie B vers Voie A
  Track ZoneB19 = new Track(ZoneB18, 0, 65); // Croisement ligne droite de Voie A vers Voie C
  Track ZoneB20 = new Track(ZoneB16, 1, 580); // Ligne droite quai de droite à gauche
  Track ZoneB21 = new Track(ZoneB20, 1, 60); // Croisement ligne droite de Voie B vers Voie B
  Track ZoneB22 = new Track(ZoneA18, 1, 62); // Croisement ligne droite de Voie A vers Voie C
  Track ZoneB23 = new Track(ZoneB20, 1, 100, -35.5); // Croisement ligne courbe à droite de Voie B vers Voie C
  Track ZoneB24 = new Track(ZoneB23, 1, 100, 35.5); // Croisement ligne courbe à gauche de Voie B vers Voie C
  Track ZoneB25 = new Track(ZoneB21, 1, 160); // Ligne droite de droite à gauche
  Track ZoneB26 = new Track(ZoneB25, 1, 312.5, -90); // Ligne courbe à droite quart bas ouest
  Track ZoneB27 = new Track(ZoneB26, 1, 312.5, -90); // Ligne courbe à droite quart haut ouest
  Track ZoneB28 = new Track(ZoneB27, 1, 312.5, -180); // Ligne courbe à droite demi ouest
  Track ZoneB29 = new Track(ZoneB28, 1, 312.5, -90); // Ligne courbe à droite quart bas ouest

  // Voie C
  Track ZoneC1 = new Track(layout, TrackX+75, TrackY, 275, -90, 90); // Ligne courbe à droite quart haut ouest : rayon, orientation
  Track ZoneC2 = new Track(ZoneC1, 1, 1300); // Ligne droite de gauche à droite
  Track ZoneC3 = new Track(ZoneC2, 1, 275, -90); // Ligne courbe à droite quart haut est
  Track ZoneC4 = new Track(ZoneC3, 1, 275, -90); // Ligne courbe à droite quart bas est
  Track ZoneC5 = new Track(ZoneC4, 1, 390); // Ligne droite de droite à gauche
  Track ZoneC6 = new Track(ZoneC5, 1, 65); // Croisement ligne droite de voie C vers voie C
  Track ZoneC7 = new Track(ZoneC5, 1, 100, 35.5); // Croisement ligne courbe à gauche de voie C vers voie B
  Track ZoneC8 = new Track(ZoneC7, 1, 100, -35.5); // Croisement ligne courbe à droite de voie C vers voie B
  Track ZoneC9 = new Track(ZoneC8, 0, 65); // Croisement ligne droite de Voie B vers voie GH
  Track ZoneC10 = new Track(ZoneC6, 1, 675); // Ligne droite de droite à gauche
  Track ZoneC11 = new Track(ZoneC10, 1, 65); // Croisement ligne droite direct de voie C vers voie C
  Track ZoneC12 = new Track(ZoneB23, 1, 62); // Croisement Ligne droite de Voie B vers voie D
  Track ZoneC13 = new Track(ZoneC10, 1, 100, -35.5); // Croisement ligne courbe à droite vers Voie D
  Track ZoneC14 = new Track(ZoneC13, 1, 100, 35.5); // Ligne courbe à gauche vers Voie D
  Track ZoneC15 = new Track(ZoneC11, 1, 105); // Ligne droite de gauche à droite
  Track ZoneC16 = new Track(ZoneC15, 1, 275, -90); // Ligne courbe quart bas ouest

  // Voie D
  Track ZoneD1 = new Track(ZoneC14, 1, 50); // Ligne droite de droite à gauche
  Track ZoneD2 = new Track(ZoneD1, 1, 237.5, -90); // Ligne courbe quart bas ouest
  Track ZoneD3 = new Track(ZoneD2, 1, 237.5, -90); // Ligne courbe quart haut ouest : rayon, orientation
  Track ZoneD4 = new Track(ZoneD3, 1, 50); // Aiguillage entre voie D et D dévié troncon direct ligne droite de voie D vers voie D 
  Track ZoneD5 = new Track(ZoneD4, 1, 500); // Ligne droite de gauche à droite
  Track ZoneD6 = new Track(ZoneD3, 1, 100, -35.5); // Aiguillage entre voie D et D dévié ligne courbe à droite de voie A vers Voie B
  Track ZoneD7 = new Track(ZoneD6, 1, 100, 35.5); // Aiguillage entre voie D et D dévié ligne courbe à gauche de voie A vers Voie B
  Track ZoneD8 = new Track(ZoneD7, 1, 420); // Ligne droite de gauche à droite
  Track ZoneD9 = new Track(ZoneD8, 1, 210, -90); // Ligne courbe quart haut droit
  Track ZoneD10 = new Track(ZoneD9, 1, 150, 45); // Lignee courbe huitieme bas droit
  Track ZoneD11 = new Track(ZoneD10, 1, 150, 45); // Aiguillage courbe huitieme bas droit
  Track ZoneD12 = new Track(ZoneD5, 1, 237.5, -90); // Ligne courbe quart haut droit
  Track ZoneD13 = new Track(ZoneD12, 1, 47); // Ligne droite de haut en bas
  Track ZoneD14 = new Track(ZoneD13, 1, 110, 45); // Ligne courbe huitieme bas droit
  Track ZoneD15 = new Track(ZoneD14, 1, 110, 45); // Ligne courbe huitieme bas droit
  Track ZoneD16 = new Track(ZoneD15, 1, 110); // Ligne droite gauche vers droite
  Track ZoneD17 = new Track(ZoneD16, 1, 65); // Croisement ligne droite de voie D vers Voie Déchargement
  Track ZoneD18 = new Track(ZoneD16, 1, 100, 35.5); // Croisement ligne courbe à gauche vers Voie Maintenance

  // Voie Garage Gare Haute
  //Track ZoneGH1 = new Track(layout, TrackX+1200, TrackY+275, 100, 35.5, 0); // Aiguillage gauche de Voie D
  Track ZoneGH1 = new Track(ZoneC10, 0, 100, +35.5); // Croisement ligne courbe à gauche de voie C vers voie GH
  Track ZoneGH2 = new Track(ZoneGH1, 1, 10); // Ligne droite
  Track ZoneGH3 = new Track(ZoneGH2, 1, 100, -35.5); // Aiguillage dévié ligne courbe à droite vers Gare Haute Voie 1 - Lavage
  Track ZoneGH4 = new Track(ZoneGH3, 1, 300); // Ligne droite Gare Haute Voie 1 - Lavage
  Track ZoneGH5 = new Track(ZoneGH2, 1, 65); // Ligne droite
  Track ZoneGH6 = new Track(ZoneGH5, 1, 100, -35.5); // Aiguillage dévié ligne courbe à droite vers Gare Haute Voie 2 - Rotonde
  Track ZoneGH7 = new Track(ZoneGH6, 1, 300); // Ligne droite Gare Haute Voie 2 - Rotonde
  Track ZoneGH8 = new Track(ZoneGH5, 1, 65); // Ligne droite
  Track ZoneGH9 = new Track(ZoneGH8, 1, 100, -35.5); // Croisement ligne courbe à droite vers Gare Haute Voie 3 - Déchargement
  Track ZoneGH10 = new Track(ZoneGH9, 1, 300); // Ligne droite Gare Haute Voie 3 - Déchargement
  Track ZoneGH11 = new Track(ZoneGH8, 1, 65); // Croisement ligne droite vers voies de Maintenance
  Track ZoneGH12 = new Track(ZoneGH11, 1, 100, -35.5); // Aiguillage dévié ligne courbe à droite vers Gare Haute Voie 4 - Maintenance 1
  Track ZoneGH13 = new Track(ZoneGH12, 1, 300); // Ligne droite Gare Haute Voie 4 - Maintenance 1
  Track ZoneGH14 = new Track(ZoneGH11, 1, 65); // Ligne droite
  Track ZoneGH15 = new Track(ZoneGH14, 1, 100, -35.5); // Courbe droite vers Gare Haute Voie 5 - Maintenance 2
  Track ZoneGH16 = new Track(ZoneGH15, 1, 300); // Ligne droite Gare Haute Voie 5 - Maintenance 2

  // CREATE SECOND LAYOUT FOR SKY BRIDGE AND DEFINE TRACKS

  layout2=new Layout(325, 500, 400, 80*25.4, 36*25.4);
  layoutBridge=new Layout(layout2);


  // DEFINE SENSORS, MAP TO ARDUINO NUMBERS, AND INDICATE THEIR TRACK LOCATIONS
  //
  //  Avec pour définr la position du bouton associé au Sensor : 
  //    Segment de droite
  //      Zone : Track refTrack 
  //      Position : trackPoint (1 ==> fin de la zone 0 ==> début de la zone), 
  //      Distance par rapport à l'extémité sélectionnée : tLength
  //      Largeur, Hauteur du bouton associé : kWidth, kHeight
  //      Numero de pins Arduino reliée au Sensor: SensorNum 
  //      Etat du Sensor par defaut : SensorDefault
  //    Segment de courbe :
  //      Zone, 
  //      Position : trackPoint (1 ==> fin de la zone 0 ==> début de la zone), 
  //      Rayon et Angle par rapport à l'extémité sélectionnée : curveRadius, curveAngleDeg
  //      Largeur, Hauteur du bouton associé : kWidth, kHeight
  //      Numero de pins Arduino reliée au Sensor : SensorNum
  //      Etat du Sensor par defaut : SensorDefault
  //
  ////////////////////////////////////////////////////////////////////////
  //  Current sensor button definition
  //    TrackSensor(Track refTrack, trackPoint, tLength, kWidth, kHeight, SensorNum, SensorDefault, SensorValue)
  //    TrackSensor(Track refTrack, trackPoint, curveRadius, curveAngleDeg, kWidth, kHeight, SensorNum, SensorDefault, SensorValue)
  ////////////////////////////////////////////////////////////////////////

  Sensor1 = new TrackSensor(ZoneA1, 0, -30, 20, 20, 1, false, 0); // Canton Ouest Voie A
  Sensor2 = new TrackSensor(ZoneA7, 1, -560, 20, 20, 2, false, 0); // Canton Bas Voie A
  Sensor3 = new TrackSensor(ZoneA9, 1, -30, 20, 20, 3, false, 0); // Canton Est Voie A
  Sensor4 = new TrackSensor(ZoneA16, 0, -275, 20, 20, 4, false, 0); // Canton Haut Voie A
  Sensor5 = new TrackSensor(ZoneB1, 0, -30, 20, 20, 5, false, 0); // Canton Ouest Voie B
  Sensor6 = new TrackSensor(ZoneB4, 1, -550, 20, 20, 6, false, 0); // Canton Bas Voie B
  Sensor7 = new TrackSensor(ZoneB10, 1, -30, 20, 20, 7, false, 0); // Canton Est Voie B
  Sensor8 = new TrackSensor(ZoneB20, 0, -300, 20, 20, 8, false, 0); // Canton Haut Voie B
  Sensor9 = new TrackSensor(ZoneC1, 0, -30, 20, 20, 9, false, 0); // Canton Ouest Voie C
  Sensor10 = new TrackSensor(ZoneC2, 1, -725, 20, 20, 10, false, 0); // Canton Bas Voie C
  Sensor11 = new TrackSensor(ZoneC3, 1, -30, 20, 20, 11, false, 0); // Canton Est Voie C
  Sensor12 = new TrackSensor(ZoneC10, 0, -300, 20, 20, 12, false, 0); // Canton Haut Voie C
  Sensor13 = new TrackSensor(ZoneD3, 0, -30, 20, 20, 13, false, 0); // Canton Ouest Voie D
  Sensor14 = new TrackSensor(ZoneD5, 1, -30, 20, 20, 14, false, 0); // Canton Est Voie D segment nord
  Sensor15 = new TrackSensor(ZoneD8, 1, -55, 20, 20, 15, false, 0); // Canton Est Voie D segment sud
  Sensor16 = new TrackSensor(ZoneGH2, 1, -5, 20, 20, 16, false, 0); // Gare Haute Voie accès

  ////////////////////////////////////////////////////////////////////////
  //  Infrared sensor button definition
  ////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////
  // Turnout buttons definition and add track for each turnout
  //    addTrack(Track track, tPos) : tPos = specifies that this track should be considered part of a Tracks
  //      Init ==> ButtonStatus=0
  //      tPos = 0 ==> track.tStatus=1-buttonStatus;    aTracks.add(track); specifies that this track button should be set to A when route selected
  //      tPos = 1 ==> track.tStatus=buttonStatus;      bTracks.add(track); specifies that this track button should be set to B when route selected
  ////////////////////////////////////////////////////////////////////////

  // Aiguillage Voie A vers B Gare Basse : Component Name = T101
  tButton101 = new TrackButton(20, 20, 101); // Largeur, Hauteur, Identifiant
  tButton101.addTrack(ZoneA2, 0);  //  0 ==> Valid track
  tButton101.addTrack(ZoneA3, 1);  //  1 ==> invalid track
  tButton101.addTrack(ZoneA4, 1);
  tButton101.addTrack(ZoneB3, 0);

  // Aiguillage Voie B vers A Gare Basse : Component Name = T102
  tButton102 = new TrackButton(20, 20, 102);
  tButton102.addTrack(ZoneB5, 0);
  tButton102.addTrack(ZoneB6, 1);
  tButton102.addTrack(ZoneB7, 1);
  tButton102.addTrack(ZoneA8, 0); 

  // Aiguillage Voie A vers B Gare Haute : Component Name = T103
  tButton103 = new TrackButton(20, 20, 103);
  tButton103.addTrack(ZoneA15, 0);
  tButton103.addTrack(ZoneB18, 1);

  // Croisement Voie C direct et Voie B vers GH Gare Haute : Component Name = T104
  tButton104 = new TrackButton(20, 20, 104);
  tButton104.addTrack(ZoneC6, 0);
  tButton104.addTrack(ZoneC7, 1);
  tButton104.addTrack(ZoneC9, 0);
  tButton104.addTrack(ZoneGH1, 1);

  // Croisement Voie B direct et Voie A vers B Gare Haute : Component Name = T105
  tButton105 = new TrackButton(20, 20, 105);
  tButton105.addTrack(ZoneB16, 0);
  tButton105.addTrack(ZoneB17, 1);
  tButton105.addTrack(ZoneB19, 0);
  tButton105.addTrack(ZoneC8, 1);

  // Aiguillage Voie A vers B Gare Haute : Component Name = T106
  tButton106 = new TrackButton(20, 20, 106);
  tButton106.addTrack(ZoneA17, 0);
  tButton106.addTrack(ZoneA18, 1);

  // Croisement Voie B direct et Voie B vers C Gare Haute: Component Name = T107
  tButton107 = new TrackButton(20, 20, 107);
  tButton107.addTrack(ZoneB21, 0);
  tButton107.addTrack(ZoneB22, 0);
  tButton107.addTrack(ZoneB23, 1);
  tButton107.addTrack(ZoneA19, 1);

  // Croisement Voie C direct et Voie C vers D Gare Haute : Component Name = T108
  tButton108 = new TrackButton(20, 20, 108);
  tButton108.addTrack(ZoneC11, 0);
  tButton108.addTrack(ZoneC12, 0);
  tButton108.addTrack(ZoneC13, 1);
  tButton108.addTrack(ZoneB24, 1);

  // Aiguillage Voie A vers Gare Basse : Component Name = T109
  tButton109 = new TrackButton(20, 20, 109);
  tButton109.addTrack(ZoneA5, 0);
  tButton109.addTrack(ZoneA6, 1);

  // Aiguillage vers Gare Basse Voie 1 : Component Name = T110
  tButton110 = new TrackButton(20, 20, 110);
  tButton110.addTrack(ZoneGB1, 0);
  tButton110.addTrack(ZoneGB2, 1);

  // Aiguillage vers Gare Basse Voie 2 : Component Name = T111
  tButton111 = new TrackButton(20, 20, 111);
  tButton111.addTrack(ZoneGB4, 0);
  tButton111.addTrack(ZoneGB5, 1);

  // Aiguillage vers Gare Basse Voie 3 : Component Name = T112
  tButton112 = new TrackButton(20, 20, 112);
  tButton112.addTrack(ZoneGB7, 0);
  tButton112.addTrack(ZoneGB8, 1);

  // Aiguillage vers Gare Basse Voie 4 : Component Name = T113
  tButton113 = new TrackButton(20, 20, 113);
  //tButton113.addTrack(ZoneGB10, 1);

  // Aiguillage vers Gare Haute Voie 1 - Lavage : Component Name = T114
  tButton114 = new TrackButton(20, 20, 114);
  tButton114.addTrack(ZoneGH5, 0);
  tButton114.addTrack(ZoneGH3, 1);

  // Aiguillage vers Gare Haute Voie 2 - Rotonde : Component Name = T115
  tButton115 = new TrackButton(20, 20, 115);
  tButton115.addTrack(ZoneGH8, 0);
  tButton115.addTrack(ZoneGH6, 1);

  // Aiguillage vers Gare Haute Voie 3 - Déchargement : Component Name = T116
  tButton116 = new TrackButton(20, 20, 116);
  tButton116.addTrack(ZoneGH11, 0);
  tButton116.addTrack(ZoneGH9, 1);
  tButton116.addTrack(ZoneD17, 0);
  tButton116.addTrack(ZoneD18, 1);

  // Aiguillage vers Gare Haute Voie 4 - Maintenance 1 : Component Name = T117
  tButton117 = new TrackButton(20, 20, 117);
  tButton117.addTrack(ZoneGH14, 0);
  tButton117.addTrack(ZoneGH12, 1);

  // Aiguillage Ouest Voie D vers D : Component Name = T118
  tButton118 = new TrackButton(20, 20, 118);
  tButton118.addTrack(ZoneD4, 0);
  tButton118.addTrack(ZoneD6, 1);

  // Aiguillage Est Voie D vers D : Component Name = T119
  tButton119 = new TrackButton(20, 20, 119);
  tButton119.addTrack(ZoneD15, 0);
  tButton119.addTrack(ZoneD11, 1);

  ////////////////////////////////////////////////////////////////////////
  //  Signal button definition
  // Position x, y, Form largeur, hauteur, Init statut 1=green, 2=red, 3=yellow, identifiant
  ////////////////////////////////////////////////////////////////////////

  SButton1 = new SignalButton(TrackX+710, TrackY-433, 20, 20, 2, 1);      // Signal Gare Basse Voie 4 Ouest
  SButton2 = new SignalButton(TrackX+677, TrackY-417, 20, 20, 2, 2);      // Signal Gare Basse Voie 3 Ouest
  SButton3 = new SignalButton(TrackX+644, TrackY-401, 20, 20, 2, 3);      // Signal Gare Basse Voie 2 Ouest
  SButton4 = new SignalButton(TrackX+611, TrackY-385, 20, 20, 2, 4);      // Signal Gare Basse Voie 1 Ouest
  SButton5 = new SignalButton(TrackX+500, TrackY-383, 20, 20, 2, 5);      // Signal Voie A spirale Ouest 
  SButton6 = new SignalButton(TrackX+575, TrackY-370, 20, 20, 2, 6);      // Signal Voie A vers Gare Basse 
  SButton7 = new SignalButton(TrackX+1090, TrackY-383, 20, 20, 2, 7);     // Signal Voie A spirale Est
  SButton8 = new SignalButton(TrackX+1150, TrackY-383, 20, 20, 2, 8);     // Signal Voie A de Voie B
  SButton9 = new SignalButton(TrackX+500, TrackY-364, 20, 20, 2, 9);      // Signal Voie B spirale ouest
  SButton10 = new SignalButton(TrackX+575, TrackY-351, 20, 20, 2, 10);    // Signal Voie B
  SButton11 = new SignalButton(TrackX+1070, TrackY-364, 20, 20, 2, 11);   // Signal Voie B spirale est
  SButton12 = new SignalButton(TrackX+1150, TrackY-364, 20, 20, 2, 12);   // Signal Voie B spirale est
  SButton13 = new SignalButton(TrackX+500, TrackY-346, 20, 20, 2, 13);    // Signal Voie C
  SButton14 = new SignalButton(TrackX+1150, TrackY-346, 20, 20, 2, 14);   // Signal Voie C
  SButton15 = new SignalButton(TrackX+500, TrackY-328, 20, 20, 2, 15);    // Signal Voie D spirale ouest
  SButton16 = new SignalButton(TrackX+940, TrackY-135, 20, 20, 2, 16);    // Signal Voie D  
  SButton17 = new SignalButton(TrackX+1085, TrackY-156, 20, 20, 2, 17);   // Signal Gare Haute Voie 4 - Maintenance 1
  SButton18 = new SignalButton(TrackX+1065, TrackY-138, 20, 20, 2, 18);   // Signal Gare Haute Voie 4 - Maintenance 1
  SButton19 = new SignalButton(TrackX+1040, TrackY-119, 20, 20, 2, 19);   // Signal Gare Haute Voie 3 - Déchargement
  SButton20 = new SignalButton(TrackX+1015, TrackY-101, 20, 20, 2, 20);   // Signal Gare Haute Voie 2 - Rotonde
  SButton21 = new SignalButton(TrackX+990, TrackY-82, 20, 20, 2, 21);     // Signal Gare Haute Voie 1 - Lavage 
  SButton22 = new SignalButton(TrackX+500, TrackY-80, 20, 20, 2, 22);     // Signal Voie D spirale ouest
  SButton23 = new SignalButton(TrackX+500, TrackY-62, 20, 20, 2, 23);     // Signal Voie C spirale ouest
  SButton24 = new SignalButton(TrackX+630, TrackY-76, 20, 20, 2, 24);     // Signal Voie C
  SButton25 = new SignalButton(TrackX+900, TrackY-76, 20, 20, 2, 25);     // Signal Voie C
  SButton26 = new SignalButton(TrackX+1150, TrackY-62, 20, 20, 2, 26);    // Signal Voie C spirale est
  SButton27 = new SignalButton(TrackX+500, TrackY-44, 20, 20, 2, 27);     // Signal Voie B spirale ouest
  SButton28 = new SignalButton(TrackX+650, TrackY-58, 20, 20, 2, 28);     // Signal Voie B
  SButton29 = new SignalButton(TrackX+880, TrackY-58, 20, 20, 2, 29);     // Signal Voie B
  SButton30 = new SignalButton(TrackX+1150, TrackY-44, 20, 20, 2, 30);    // Signal Voie B spirale est
  SButton31 = new SignalButton(TrackX+500, TrackY-25, 20, 20, 2, 31);     // Signal Voie A spirale ouest
  SButton32 = new SignalButton(TrackX+670, TrackY-39, 20, 20, 2, 32);     // Signal Voie A
  SButton33 = new SignalButton(TrackX+860, TrackY-39, 20, 20, 2, 33);     // Signal Voie A
  SButton34 = new SignalButton(TrackX+1150, TrackY-25, 20, 20, 2, 34);    // Signal Voie A spirale est

  ////////////////////////////////////////////////////////////////////////
  // Route button definition and add tracks and turnout buttons
  ////////////////////////////////////////////////////////////////////////

  rButton20 = new RouteButton(rX+510, rY-65, 60, 30, "Voie A"); // Position X et Y, laugeur, Hauteur
  rButton20.addTrack(ZoneA1);
  rButton20.addTrack(ZoneA2);
  rButton20.addTrackButton(tButton101, 0);
  rButton20.addTrack(ZoneA5);
  rButton20.addTrackButton(tButton109, 0);
  rButton20.addTrack(ZoneA7);
  rButton20.addTrackButton(tButton102, 0);
  rButton20.addTrack(ZoneA8);
  rButton20.addTrack(ZoneA9);
  rButton20.addTrack(ZoneA10);
  rButton20.addTrack(ZoneA11);
  rButton20.addTrack(ZoneA12);
  rButton20.addTrack(ZoneA13);
  rButton20.addTrack(ZoneA14);
  rButton20.addTrackButton(tButton103, 0);
  rButton20.addTrack(ZoneA15);
  rButton20.addTrack(ZoneA16);
  rButton20.addTrackButton(tButton106, 0);
  rButton20.addTrack(ZoneA17);
  rButton20.addTrackButton(tButton107, 0);
  rButton20.addTrack(ZoneA20);
  rButton20.addTrack(ZoneA21);
  rButton20.addTrack(ZoneA22);
  rButton20.addTrack(ZoneA23);
  rButton20.addTrack(ZoneA24);

  Voie_A.put(0, ZoneA1);
  Voie_A.put(1, ZoneA2);
  Voie_A.put(2, ZoneA5);
  Voie_A.put(3, ZoneA7);
  Voie_A.put(4, ZoneA8);
  Voie_A.put(5, ZoneA9);
  Voie_A.put(6, ZoneA10);
  Voie_A.put(7, ZoneA11);
  Voie_A.put(8, ZoneA12);
  Voie_A.put(9, ZoneA13);
  Voie_A.put(10, ZoneA14);
  Voie_A.put(11, ZoneA15);
  Voie_A.put(12, ZoneA16);
  Voie_A.put(13, ZoneA17);
  Voie_A.put(14, ZoneA20);
  Voie_A.put(15, ZoneA21);
  Voie_A.put(16, ZoneA22);
  Voie_A.put(17, ZoneA23);
  Voie_A.put(18, ZoneA24);

  Canton_A.put(ZoneA1, 110);    //    Voie_A 0
  Canton_A.put(ZoneA2, 120);    //    Voie_A 1
  Canton_A.put(ZoneA5, 120);    //    Voie_A 2
  Canton_A.put(ZoneA7, 120);    //    Voie_A 3
  Canton_A.put(ZoneA8, 120);    //    Voie_A 4
  Canton_A.put(ZoneA9, 130);    //    Voie_A 5
  Canton_A.put(ZoneA10, 130);    //    Voie_A 5
  Canton_A.put(ZoneA11, 130);    //    Voie_A 5
  Canton_A.put(ZoneA12, 130);    //    Voie_A 5
  Canton_A.put(ZoneA13, 130);    //    Voie_A 6
  Canton_A.put(ZoneA14, 140);    //    Voie_A 7
  Canton_A.put(ZoneA15, 140);    //    Voie_A 8
  Canton_A.put(ZoneA16, 140);    //    Voie_A 9
  Canton_A.put(ZoneA17, 140);    //    Voie_A 10
  Canton_A.put(ZoneA20, 140);    //    Voie_A 11
  Canton_A.put(ZoneA21, 110);    //    Voie_A 12
  Canton_A.put(ZoneA22, 110);    //    Voie_A 13
  Canton_A.put(ZoneA23, 110);    //    Voie_A 16
  Canton_A.put(ZoneA24, 110);    //    Voie_A 17

  rButton21 = new RouteButton(rX+510, rY-30, 60, 30, "Voie B");
  rButton21.addTrack(ZoneB1);
  rButton21.addTrack(ZoneB2);
  rButton21.addTrackButton(tButton101, 0);
  rButton21.addTrack(ZoneB3);
  rButton21.addTrack(ZoneB4);
  rButton21.addTrack(ZoneB5);
  rButton21.addTrackButton(tButton102, 0);
  rButton21.addTrack(ZoneB8);
  rButton21.addTrack(ZoneB9);
  rButton21.addTrack(ZoneB10);
  rButton21.addTrack(ZoneB11);
  rButton21.addTrack(ZoneB12);
  rButton21.addTrack(ZoneB13);
  rButton21.addTrack(ZoneB14);
  rButton21.addTrack(ZoneB15);
  rButton21.addTrack(ZoneB16);
  rButton21.addTrackButton(tButton105, 0);
  rButton21.addTrackButton(tButton103, 0);
  rButton21.addTrack(ZoneB20);
  rButton21.addTrack(ZoneB21);
  rButton21.addTrackButton(tButton107, 0);
  rButton21.addTrackButton(tButton108, 0);
  rButton21.addTrack(ZoneB25);
  rButton21.addTrack(ZoneB26);
  rButton21.addTrack(ZoneB27);
  rButton21.addTrack(ZoneB28);
  rButton21.addTrack(ZoneB29);

  Voie_B.put(0, ZoneB1);
  Voie_B.put(1, ZoneB2);
  Voie_B.put(2, ZoneB3);
  Voie_B.put(3, ZoneB4);
  Voie_B.put(4, ZoneB5);
  Voie_B.put(5, ZoneB8);
  Voie_B.put(6, ZoneB9);
  Voie_B.put(7, ZoneB10);
  Voie_B.put(8, ZoneB11);
  Voie_B.put(9, ZoneB12);
  Voie_B.put(10, ZoneB13);
  Voie_B.put(11, ZoneB14);
  Voie_B.put(12, ZoneB15);
  Voie_B.put(13, ZoneB16);
  Voie_B.put(14, ZoneB20);
  Voie_B.put(15, ZoneB21);
  Voie_B.put(16, ZoneB25);
  Voie_B.put(17, ZoneB26);
  Voie_B.put(18, ZoneB27);
  Voie_B.put(19, ZoneB28);
  Voie_B.put(20, ZoneB29);

  Canton_B.put(ZoneB1, 210);    //    Voie_B 0
  Canton_B.put(ZoneB2, 220);
  Canton_B.put(ZoneB3, 220);
  Canton_B.put(ZoneB4, 220);
  Canton_B.put(ZoneB5, 220);
  Canton_B.put(ZoneB8, 220);
  Canton_B.put(ZoneB9, 220);
  Canton_B.put(ZoneB10, 230);
  Canton_B.put(ZoneB11, 230);
  Canton_B.put(ZoneB12, 230);
  Canton_B.put(ZoneB13, 230);
  Canton_B.put(ZoneB14, 230);
  Canton_B.put(ZoneB15, 240);
  Canton_B.put(ZoneB16, 240);
  Canton_B.put(ZoneB20, 240);
  Canton_B.put(ZoneB21, 240);
  Canton_B.put(ZoneB25, 240);
  Canton_B.put(ZoneB26, 210);
  Canton_B.put(ZoneB27, 210);
  Canton_B.put(ZoneB28, 210);
  Canton_B.put(ZoneB29, 210);

  rButton22 = new RouteButton(rX+510, rY+5, 60, 30, "Voie C");
  rButton22.addTrack(ZoneC1);
  rButton22.addTrack(ZoneC2);
  rButton22.addTrack(ZoneC3);
  rButton22.addTrack(ZoneC4);
  rButton22.addTrack(ZoneC5);
  rButton22.addTrackButton(tButton104, 0);
  rButton22.addTrack(ZoneC6);
  rButton22.addTrackButton(tButton105, 0);
  rButton22.addTrack(ZoneC10);
  rButton22.addTrack(ZoneC11);
  rButton22.addTrackButton(tButton108, 0);
  rButton22.addTrack(ZoneC15);
  rButton22.addTrack(ZoneC16);

  Voie_C.put(0, ZoneC1);
  Voie_C.put(1, ZoneC2);
  Voie_C.put(2, ZoneC3);
  Voie_C.put(3, ZoneC4);
  Voie_C.put(4, ZoneC5);
  Voie_C.put(5, ZoneC6);
  Voie_C.put(6, ZoneC10);
  Voie_C.put(7, ZoneC11);
  Voie_C.put(8, ZoneC15);
  Voie_C.put(9, ZoneC16);

  Canton_C.put(ZoneC1, 310);    //  Voie_C 0
  Canton_C.put(ZoneC2, 320);
  Canton_C.put(ZoneC3, 330);
  Canton_C.put(ZoneC4, 330);
  Canton_C.put(ZoneC5, 340);
  Canton_C.put(ZoneC6, 340);
  Canton_C.put(ZoneC10, 340);
  Canton_C.put(ZoneC11, 340);
  Canton_C.put(ZoneC15, 340);
  Canton_C.put(ZoneC16, 310);

  rButton23 = new RouteButton(rX+510, rY+40, 60, 30, "Voie D");
  rButton23.addTrack(ZoneD1);
  rButton23.addTrack(ZoneD2);
  rButton23.addTrack(ZoneD3);
  rButton23.addTrack(ZoneD4);
  rButton23.addTrack(ZoneD5);
  rButton23.addTrackButton(tButton118, 1);
  rButton23.addTrack(ZoneD6);
  rButton23.addTrack(ZoneD7); 
  rButton23.addTrack(ZoneD8);
  rButton23.addTrack(ZoneD9);
  rButton23.addTrack(ZoneD10);
  rButton23.addTrack(ZoneD11);
  rButton23.addTrackButton(tButton119, 1);
  rButton23.addTrack(ZoneD12);
  rButton23.addTrack(ZoneD13);
  rButton23.addTrack(ZoneD14);
  rButton23.addTrack(ZoneD15);
  rButton23.addTrack(ZoneD16);
  rButton23.addTrack(ZoneD17);
  rButton23.addTrack(ZoneD18);
  rButton23.addTrackButton(tButton116, 1);
  rButton23.addTrack(ZoneGH8);
  rButton23.addTrack(ZoneGH9);
  rButton23.addTrack(ZoneGH5);
  rButton23.addTrack(ZoneGH2);
  rButton23.addTrack(ZoneGH1);
  rButton23.addTrackButton(tButton104, 1);
  rButton23.addTrack(ZoneC10);
  rButton23.addTrackButton(tButton108, 1);
  rButton23.addTrack(ZoneC13);
  rButton23.addTrack(ZoneC14);

  Voie_D.put(0, ZoneD1);
  Voie_D.put(1, ZoneD2);
  Voie_D.put(2, ZoneD3);
  Voie_D.put(3, ZoneD4);
  Voie_D.put(4, ZoneD5);
  Voie_D.put(5, ZoneD6);
  Voie_D.put(6, ZoneD7);
  Voie_D.put(7, ZoneD8);
  Voie_D.put(8, ZoneD9);
  Voie_D.put(9, ZoneD10);
  Voie_D.put(10, ZoneD11);
  Voie_D.put(11, ZoneD12);
  Voie_D.put(12, ZoneD13);
  Voie_D.put(13, ZoneD13);
  Voie_D.put(14, ZoneD15);
  Voie_D.put(15, ZoneD16);
  Voie_D.put(16, ZoneD17);
  Voie_D.put(17, ZoneD18);
  Voie_D.put(18, ZoneGH8);
  Voie_D.put(19, ZoneGH9);
  Voie_D.put(20, ZoneGH5);
  Voie_D.put(21, ZoneGH2);
  Voie_D.put(22, ZoneGH1);
  Voie_D.put(23, ZoneC10);
  Voie_D.put(24, ZoneC13);
  Voie_D.put(25, ZoneC14);

  Canton_D.put(ZoneD1, 410);
  Canton_D.put(ZoneD2, 410);
  Canton_D.put(ZoneD3, 410);
  Canton_D.put(ZoneD4, 410);
  Canton_D.put(ZoneD5, 410);
  Canton_D.put(ZoneD6, 411);
  Canton_D.put(ZoneD7, 411);
  Canton_D.put(ZoneD8, 411);
  Canton_D.put(ZoneD9, 411);
  Canton_D.put(ZoneD10, 411);
  Canton_D.put(ZoneD11, 411);
  Canton_D.put(ZoneD12, 410);
  Canton_D.put(ZoneD13, 410);
  Canton_D.put(ZoneD14, 410);
  Canton_D.put(ZoneD15, 410);
  Canton_D.put(ZoneD16, 410);
  Canton_D.put(ZoneD17, 410);
  Canton_D.put(ZoneD18, 410);
  Canton_D.put(ZoneGH8, 420);
  Canton_D.put(ZoneGH9, 420);
  Canton_D.put(ZoneGH5, 420);
  Canton_D.put(ZoneGH2, 420);
  Canton_D.put(ZoneGH1, 420);
  Canton_D.put(ZoneC10, 340);
  Canton_D.put(ZoneC13, 340);
  Canton_D.put(ZoneC14, 340);

  rButton24 = new RouteButton(rX+440, rY-65, 60, 30, "Voie\nA-B");
  rButton24.addTrack(ZoneA1);
  rButton24.addTrack(ZoneA3);
  rButton24.addTrack(ZoneA4);
  rButton24.addTrackButton(tButton101, 1);
  rButton24.addTrack(ZoneB4);
  rButton24.addTrack(ZoneB6);
  rButton24.addTrackButton(tButton102, 1);
  rButton24.addTrack(ZoneB7);
  rButton24.addTrack(ZoneA9);
  rButton24.addTrack(ZoneA10);
  rButton24.addTrack(ZoneA11);
  rButton24.addTrack(ZoneA12);
  rButton24.addTrack(ZoneA13);
  rButton24.addTrack(ZoneA14);
  rButton24.addTrack(ZoneA15);
  rButton24.addTrack(ZoneA16);
  rButton24.addTrack(ZoneA17);
  rButton24.addTrackButton(tButton106, 0);
  rButton24.addTrack(ZoneA20);    
  rButton24.addTrack(ZoneA21);    
  rButton24.addTrack(ZoneA22);    
  rButton24.addTrack(ZoneA23);    
  rButton24.addTrack(ZoneA24);    

  Voie_A_B.put(0, ZoneA1);
  Voie_A_B.put(1, ZoneA3);
  Voie_A_B.put(2, ZoneA4);
  Voie_A_B.put(3, ZoneB4);
  Voie_A_B.put(4, ZoneB6);
  Voie_A_B.put(5, ZoneB7);
  Voie_A_B.put(6, ZoneA9);
  Voie_A_B.put(7, ZoneA10);
  Voie_A_B.put(10, ZoneA11);
  Voie_A_B.put(11, ZoneA12);
  Voie_A_B.put(12, ZoneA13);
  Voie_A_B.put(13, ZoneA14);
  Voie_A_B.put(14, ZoneA15);
  Voie_A_B.put(15, ZoneA16);
  Voie_A_B.put(16, ZoneA17);    
  Voie_A_B.put(17, ZoneA20); 
  Voie_A_B.put(18, ZoneA21);
  Voie_A_B.put(19, ZoneA22);
  Voie_A_B.put(22, ZoneA23);
  Voie_A_B.put(23, ZoneA24);

  Canton_A_B.put(ZoneA1, 110);
  Canton_A_B.put(ZoneA3, 120);
  Canton_A_B.put(ZoneA4, 120);
  Canton_A_B.put(ZoneB4, 220);
  Canton_A_B.put(ZoneB6, 220);
  Canton_A_B.put(ZoneB7, 220);
  Canton_A_B.put(ZoneA9, 130);
  Canton_A_B.put(ZoneA10, 130);
  Canton_A_B.put(ZoneA11, 130);
  Canton_A_B.put(ZoneA12, 130);
  Canton_A_B.put(ZoneA13, 130);
  Canton_A_B.put(ZoneA14, 140);
  Canton_A_B.put(ZoneA15, 140);
  Canton_A_B.put(ZoneA16, 140);
  Canton_A_B.put(ZoneA17, 140);    
  Canton_A_B.put(ZoneA20, 140); 
  Canton_A_B.put(ZoneA21, 110);
  Canton_A_B.put(ZoneA22, 110);
  Canton_A_B.put(ZoneA23, 110);
  Canton_A_B.put(ZoneA24, 110);

  rButton25 = new RouteButton(rX+440, rY-30, 60, 30, "Voie\nB-A");
  rButton25.addTrack(ZoneB1);
  rButton25.addTrack(ZoneB2);
  rButton25.addTrack(ZoneB3);
  rButton25.addTrack(ZoneB4);
  rButton25.addTrack(ZoneB5);
  rButton25.addTrackButton(tButton102, 0);
  rButton25.addTrack(ZoneB8);
  rButton25.addTrack(ZoneB9);
  rButton25.addTrack(ZoneB10);
  rButton25.addTrack(ZoneB11);
  rButton25.addTrack(ZoneB12);
  rButton25.addTrack(ZoneB13);
  rButton25.addTrack(ZoneB14);
  rButton25.addTrack(ZoneB15);
  rButton25.addTrack(ZoneB17);
  rButton25.addTrackButton(tButton105, 1);
  rButton25.addTrack(ZoneB18);
  rButton25.addTrackButton(tButton103, 1);
  rButton25.addTrack(ZoneA16);
  rButton25.addTrack(ZoneA18);
  rButton25.addTrackButton(tButton106, 1);
  rButton25.addTrack(ZoneA19);
  rButton25.addTrackButton(tButton107, 1);
  rButton25.addTrack(ZoneB25);
  rButton25.addTrack(ZoneB26);
  rButton25.addTrack(ZoneB27);
  rButton25.addTrack(ZoneB28);
  rButton25.addTrack(ZoneB29);

  Voie_B_A.put(0, ZoneB1);
  Voie_B_A.put(1, ZoneB2);
  Voie_B_A.put(2, ZoneB3);
  Voie_B_A.put(3, ZoneB4);
  Voie_B_A.put(4, ZoneB5);
  Voie_B_A.put(5, ZoneB8);
  Voie_B_A.put(6, ZoneB9);
  Voie_B_A.put(7, ZoneB10);
  Voie_B_A.put(8, ZoneB11);
  Voie_B_A.put(11, ZoneB12);
  Voie_B_A.put(12, ZoneB13);
  Voie_B_A.put(13, ZoneB14);
  Voie_B_A.put(14, ZoneB15);
  Voie_B_A.put(15, ZoneB17);
  Voie_B_A.put(16, ZoneB18);
  Voie_B_A.put(17, ZoneA16);
  Voie_B_A.put(18, ZoneA18);
  Voie_B_A.put(19, ZoneA19);
  Voie_B_A.put(20, ZoneB25);
  Voie_B_A.put(21, ZoneB26);
  Voie_B_A.put(22, ZoneB27);
  Voie_B_A.put(25, ZoneB28);
  Voie_B_A.put(26, ZoneB29);

  Canton_B_A.put(ZoneB1, 210);
  Canton_B_A.put(ZoneB2, 220);
  Canton_B_A.put(ZoneB3, 220);
  Canton_B_A.put(ZoneB4, 220);
  Canton_B_A.put(ZoneB5, 220);
  Canton_B_A.put(ZoneB8, 220);
  Canton_B_A.put(ZoneB9, 220);
  Canton_B_A.put(ZoneB10, 230);
  Canton_B_A.put(ZoneB11, 230);
  Canton_B_A.put(ZoneB12, 230);
  Canton_B_A.put(ZoneB13, 230);
  Canton_B_A.put(ZoneB14, 230);
  Canton_B_A.put(ZoneB15, 240);
  Canton_B_A.put(ZoneB17, 240);
  Canton_B_A.put(ZoneB18, 240);
  Canton_B_A.put(ZoneA16, 140);
  Canton_B_A.put(ZoneA18, 140);
  Canton_B_A.put(ZoneA19, 140);
  Canton_B_A.put(ZoneB25, 240);
  Canton_B_A.put(ZoneB26, 210);
  Canton_B_A.put(ZoneB27, 210);
  Canton_B_A.put(ZoneB28, 210);
  Canton_B_A.put(ZoneB29, 210);

  rButton26 = new RouteButton(rX+440, rY+5, 60, 30, "Voie\nB-C");
  rButton26.addTrack(ZoneC1);
  rButton26.addTrack(ZoneC2);
  rButton26.addTrack(ZoneC3);
  rButton26.addTrack(ZoneC4);
  rButton26.addTrack(ZoneC5);
  rButton26.addTrack(ZoneC7);
  rButton26.addTrackButton(tButton104, 1);
  rButton26.addTrack(ZoneC8);
  rButton26.addTrackButton(tButton105, 1);
  rButton26.addTrack(ZoneB20);
  rButton26.addTrack(ZoneB23);
  rButton26.addTrackButton(tButton107, 1);
  rButton26.addTrack(ZoneB24);
  rButton26.addTrackButton(tButton108, 1);
  rButton26.addTrack(ZoneC15);
  rButton26.addTrack(ZoneC16);

  Voie_B_C.put(0, ZoneC1);
  Voie_B_C.put(1, ZoneC2);
  Voie_B_C.put(2, ZoneC3);
  Voie_B_C.put(3, ZoneC4);
  Voie_B_C.put(4, ZoneC5);
  Voie_B_C.put(5, ZoneC7);
  Voie_B_C.put(6, ZoneC8);
  Voie_B_C.put(7, ZoneB20);
  Voie_B_C.put(8, ZoneB23);
  Voie_B_C.put(9, ZoneB24);
  Voie_B_C.put(10, ZoneC15);
  Voie_B_C.put(11, ZoneC16);

  Canton_B_C.put(ZoneC1, 310);
  Canton_B_C.put(ZoneC2, 320);
  Canton_B_C.put(ZoneC3, 330);
  Canton_B_C.put(ZoneC4, 330);
  Canton_B_C.put(ZoneC5, 340);
  Canton_B_C.put(ZoneC7, 340);
  Canton_B_C.put(ZoneC8, 340);
  Canton_B_C.put(ZoneB20, 240);
  Canton_B_C.put(ZoneB23, 240);
  Canton_B_C.put(ZoneB24, 240);
  Canton_B_C.put(ZoneC15, 340);
  Canton_B_C.put(ZoneC16, 310);

  rButton28 = new RouteButton(rX+510, rY+75, 60, 30, "Gare\nBasse");
  rButton28.addTrack(ZoneA6);
  rButton28.addTrackButton(tButton110, 1);
  rButton28.addTrack(ZoneGB1);
  rButton28.addTrack(ZoneGB2);
  rButton28.addTrack(ZoneGB3);
  rButton28.addTrackButton(tButton111, 1);
  rButton28.addTrack(ZoneGB4);
  rButton28.addTrack(ZoneGB5);
  rButton28.addTrack(ZoneGB6);
  rButton28.addTrack(ZoneGB7);
  rButton28.addTrackButton(tButton112, 1);
  rButton28.addTrack(ZoneGB8);
  rButton28.addTrack(ZoneGB9);
  rButton28.addTrack(ZoneGB10);
  rButton28.addTrackButton(tButton113, 1);
  rButton28.addTrack(ZoneGB11);

  Canton_GB.put(ZoneGB1, 510);
  Canton_GB.put(ZoneGB2, 510);
  Canton_GB.put(ZoneGB3, 511);
  Canton_GB.put(ZoneGB4, 510);
  Canton_GB.put(ZoneGB5, 510);
  Canton_GB.put(ZoneGB6, 512);
  Canton_GB.put(ZoneGB7, 510);
  Canton_GB.put(ZoneGB8, 510);
  Canton_GB.put(ZoneGB9, 513);
  Canton_GB.put(ZoneGB10, 510);
  Canton_GB.put(ZoneGB11, 514);

  rButton29 = new RouteButton(rX+510, rY+110, 60, 30, "Gare\nHaute");
  rButton29.addTrack(ZoneGH1);
  rButton29.addTrackButton(tButton116, 1);
  rButton29.addTrack(ZoneGH2);
  rButton29.addTrack(ZoneGH3);
  rButton29.addTrackButton(tButton114, 1);
  rButton29.addTrack(ZoneGH4);
  rButton29.addTrack(ZoneGH5);
  rButton29.addTrackButton(tButton115, 1);
  rButton29.addTrack(ZoneGH6);
  rButton29.addTrack(ZoneGH7);
  rButton29.addTrack(ZoneGH8);
  rButton29.addTrackButton(tButton116, 1);
  rButton29.addTrack(ZoneGH9);
  rButton29.addTrack(ZoneGH10);
  rButton29.addTrack(ZoneGH11);
  rButton29.addTrackButton(tButton117, 1);
  rButton29.addTrack(ZoneGH12);
  rButton29.addTrack(ZoneGH13);
  rButton29.addTrack(ZoneGH14);
  rButton29.addTrack(ZoneGH15);
  rButton29.addTrack(ZoneGH16);

  Canton_GH.put(ZoneGH1, 420);
  Canton_GH.put(ZoneGH2, 420);
  Canton_GH.put(ZoneGH3, 420);
  Canton_GH.put(ZoneGH4, 421);
  Canton_GH.put(ZoneGH5, 420);
  Canton_GH.put(ZoneGH6, 420);
  Canton_GH.put(ZoneGH7, 422);
  Canton_GH.put(ZoneGH8, 420);
  Canton_GH.put(ZoneGH9, 420);
  Canton_GH.put(ZoneGH10, 423);
  Canton_GH.put(ZoneGH11, 420);
  Canton_GH.put(ZoneGH12, 420);
  Canton_GH.put(ZoneGH13, 424);
  Canton_GH.put(ZoneGH14, 420);
  Canton_GH.put(ZoneGH15, 420);
  Canton_GH.put(ZoneGH16, 425);

  rButtonClean = new RouteButton(rX+440, rY+40, 60, 30, "Clean");
  rButtonClean.addTrack(ZoneGH16);
  rButtonClean.addTrack(ZoneGH15);
  rButtonClean.addTrack(ZoneGH14);
  rButtonClean.addTrack(ZoneGH11);
  rButtonClean.addTrack(ZoneGH8);
  rButtonClean.addTrack(ZoneGH5);
  rButtonClean.addTrack(ZoneGH2);
  rButtonClean.addTrack(ZoneGH1);
  rButtonClean.addTrack(ZoneC10);
  rButtonClean.addTrack(ZoneC11);
  rButtonClean.addTrack(ZoneC15);
  rButtonClean.addTrack(ZoneC16);
  rButtonClean.addTrack(ZoneC1);
  rButtonClean.addTrack(ZoneC2);
  rButtonClean.addTrack(ZoneC3);
  rButtonClean.addTrack(ZoneC4);
  rButtonClean.addTrack(ZoneC5);
  rButtonClean.addTrack(ZoneC7);
  rButtonClean.addTrackButton(tButton104, 1);
  rButtonClean.addTrack(ZoneC8);
  rButtonClean.addTrackButton(tButton105, 1);
  rButtonClean.addTrack(ZoneB20);
  rButtonClean.addTrack(ZoneB21);
  rButtonClean.addTrackButton(tButton107, 0);
  rButtonClean.addTrack(ZoneB25);
  rButtonClean.addTrack(ZoneB26);
  rButtonClean.addTrack(ZoneB27);
  rButtonClean.addTrack(ZoneB28);
  rButtonClean.addTrack(ZoneB29);
  rButtonClean.addTrack(ZoneB1);
  rButtonClean.addTrack(ZoneB2);
  rButtonClean.addTrack(ZoneB3);
  rButtonClean.addTrack(ZoneB4);
  rButtonClean.addTrack(ZoneB5);
  rButtonClean.addTrackButton(tButton102, 0);
  rButtonClean.addTrack(ZoneB8);
  rButtonClean.addTrack(ZoneB9);
  rButtonClean.addTrack(ZoneB10);
  rButtonClean.addTrack(ZoneB11);
  rButtonClean.addTrack(ZoneB12);
  rButtonClean.addTrack(ZoneB13);
  rButtonClean.addTrack(ZoneB14);
  rButtonClean.addTrack(ZoneB15);
  rButtonClean.addTrack(ZoneB17);
  rButtonClean.addTrackButton(tButton105, 1);
  rButtonClean.addTrack(ZoneB18);
  rButtonClean.addTrackButton(tButton103, 1);
  rButtonClean.addTrack(ZoneA16);
  rButtonClean.addTrack(ZoneA17);
  rButtonClean.addTrack(ZoneA20);
  rButtonClean.addTrack(ZoneA21);
  rButtonClean.addTrack(ZoneA22);
  rButtonClean.addTrack(ZoneA23);
  rButtonClean.addTrack(ZoneA24);
  rButtonClean.addTrack(ZoneA1);
  rButtonClean.addTrack(ZoneA2);
  rButtonClean.addTrackButton(tButton101, 0);
  rButtonClean.addTrack(ZoneA5);
  rButtonClean.addTrackButton(tButton109, 0);
  rButtonClean.addTrack(ZoneA7);
  rButtonClean.addTrack(ZoneA8);
  rButtonClean.addTrackButton(tButton102, 0);
  rButtonClean.addTrack(ZoneA9);
  rButtonClean.addTrack(ZoneA10);
  rButtonClean.addTrack(ZoneA11);
  rButtonClean.addTrack(ZoneA12);
  rButtonClean.addTrack(ZoneA13);
  rButtonClean.addTrack(ZoneA14);
  rButtonClean.addTrack(ZoneA15);
  rButtonClean.addTrackButton(tButton103, 0);
  rButtonClean.addTrack(ZoneA16);
  rButtonClean.addTrack(ZoneA18);
  rButtonClean.addTrackButton(tButton106, 1);
  rButtonClean.addTrack(ZoneB22);
  rButtonClean.addTrackButton(tButton107, 0);
  rButtonClean.addTrack(ZoneC12);
  rButtonClean.addTrackButton(tButton108, 0);
  rButtonClean.addTrack(ZoneC14);
  rButtonClean.addTrack(ZoneD1);
  rButtonClean.addTrack(ZoneD2);
  rButtonClean.addTrack(ZoneD3);
  rButtonClean.addTrack(ZoneD4);
  rButtonClean.addTrack(ZoneD5);
  rButtonClean.addTrack(ZoneD12);
  rButtonClean.addTrack(ZoneD13);
  rButtonClean.addTrack(ZoneD14);
  rButtonClean.addTrack(ZoneD15);
  rButtonClean.addTrackButton(tButton119, 0);
  rButtonClean.addTrack(ZoneD16);
  rButtonClean.addTrack(ZoneD17);
  rButtonClean.addTrack(ZoneD18);
  rButtonClean.addTrackButton(tButton116, 1);
  rButtonClean.addTrack(ZoneGH14);
  rButtonClean.addTrack(ZoneGH15);

  Voie_Clean.put(0, ZoneGH16);
  Voie_Clean.put(1, ZoneGH15);
  Voie_Clean.put(2, ZoneGH14);
  Voie_Clean.put(3, ZoneGH11);
  Voie_Clean.put(4, ZoneGH8);
  Voie_Clean.put(5, ZoneGH5);
  Voie_Clean.put(6, ZoneGH2);
  Voie_Clean.put(7, ZoneGH1);
  Voie_Clean.put(8, ZoneC10);
  Voie_Clean.put(9, ZoneC11);
  Voie_Clean.put(10, ZoneC15);
  Voie_Clean.put(11, ZoneC16);
  Voie_Clean.put(12, ZoneC1);
  Voie_Clean.put(13, ZoneC2);
  Voie_Clean.put(14, ZoneC3);
  Voie_Clean.put(15, ZoneC4);
  Voie_Clean.put(16, ZoneC5);
  Voie_Clean.put(17, ZoneC7);
  Voie_Clean.put(18, ZoneC8);
  Voie_Clean.put(19, ZoneB20);
  Voie_Clean.put(20, ZoneB21);
  Voie_Clean.put(21, ZoneB25);
  Voie_Clean.put(22, ZoneB26);
  Voie_Clean.put(23, ZoneB27);
  Voie_Clean.put(26, ZoneB28);
  Voie_Clean.put(27, ZoneB29);
  Voie_Clean.put(28, ZoneB1);
  Voie_Clean.put(29, ZoneB2);
  Voie_Clean.put(30, ZoneB3);
  Voie_Clean.put(31, ZoneB4);
  Voie_Clean.put(32, ZoneB5);
  Voie_Clean.put(33, ZoneB8);
  Voie_Clean.put(34, ZoneB9);
  Voie_Clean.put(35, ZoneB10);
  Voie_Clean.put(36, ZoneB11);
  Voie_Clean.put(39, ZoneB12);
  Voie_Clean.put(40, ZoneB13);
  Voie_Clean.put(41, ZoneB14);
  Voie_Clean.put(42, ZoneB15);
  Voie_Clean.put(43, ZoneB17);
  Voie_Clean.put(44, ZoneB18);
  Voie_Clean.put(45, ZoneA16);
  Voie_Clean.put(46, ZoneA17);
  Voie_Clean.put(47, ZoneA20);
  Voie_Clean.put(48, ZoneA21);
  Voie_Clean.put(49, ZoneA22);
  Voie_Clean.put(52, ZoneA23);
  Voie_Clean.put(53, ZoneA24);
  Voie_Clean.put(54, ZoneA1);
  Voie_Clean.put(55, ZoneA2);
  Voie_Clean.put(56, ZoneA5);
  Voie_Clean.put(57, ZoneA7);
  Voie_Clean.put(58, ZoneA8);
  Voie_Clean.put(59, ZoneA9);
  Voie_Clean.put(60, ZoneA10);
  Voie_Clean.put(63, ZoneA11);
  Voie_Clean.put(64, ZoneA12);
  Voie_Clean.put(65, ZoneA13);
  Voie_Clean.put(66, ZoneA14);
  Voie_Clean.put(67, ZoneA15);
  Voie_Clean.put(68, ZoneA16);
  Voie_Clean.put(69, ZoneA18);
  Voie_Clean.put(70, ZoneB22);
  Voie_Clean.put(71, ZoneC12);
  Voie_Clean.put(72, ZoneC14);
  Voie_Clean.put(73, ZoneD1);
  Voie_Clean.put(74, ZoneD2);
  Voie_Clean.put(75, ZoneD3);
  Voie_Clean.put(76, ZoneD4);
  Voie_Clean.put(77, ZoneD5);
  Voie_Clean.put(78, ZoneD12);
  Voie_Clean.put(79, ZoneD13);
  Voie_Clean.put(80, ZoneD14);
  Voie_Clean.put(81, ZoneD15);
  Voie_Clean.put(82, ZoneD16);
  Voie_Clean.put(83, ZoneD17);
  Voie_Clean.put(84, ZoneD18);
  Voie_Clean.put(85, ZoneGH14);
  Voie_Clean.put(86, ZoneGH15);

  Canton_Clean.put(ZoneGH16, 425);
  Canton_Clean.put(ZoneGH15, 420);
  Canton_Clean.put(ZoneGH14, 420);
  Canton_Clean.put(ZoneGH11, 420);
  Canton_Clean.put(ZoneGH8, 420);
  Canton_Clean.put(ZoneGH5, 420);
  Canton_Clean.put(ZoneGH2, 420);
  Canton_Clean.put(ZoneGH1, 420);
  Canton_Clean.put(ZoneC10, 340);
  Canton_Clean.put(ZoneC11, 340);
  Canton_Clean.put(ZoneC15, 340);
  Canton_Clean.put(ZoneC16, 310);
  Canton_Clean.put(ZoneC1, 310);
  Canton_Clean.put(ZoneC2, 320);
  Canton_Clean.put(ZoneC3, 330);
  Canton_Clean.put(ZoneC4, 330);
  Canton_Clean.put(ZoneC5, 340);
  Canton_Clean.put(ZoneC7, 340);
  Canton_Clean.put(ZoneC8, 340);
  Canton_Clean.put(ZoneB20, 240);
  Canton_Clean.put(ZoneB21, 240);
  Canton_Clean.put(ZoneB25, 240);
  Canton_Clean.put(ZoneB26, 210);
  Canton_Clean.put(ZoneB27, 210);
  Canton_Clean.put(ZoneB28, 210);
  Canton_Clean.put(ZoneB29, 210);
  Canton_Clean.put(ZoneB1, 210);
  Canton_Clean.put(ZoneB2, 220);
  Canton_Clean.put(ZoneB3, 220);
  Canton_Clean.put(ZoneB4, 220);
  Canton_Clean.put(ZoneB5, 220);
  Canton_Clean.put(ZoneB8, 220);
  Canton_Clean.put(ZoneB9, 220);
  Canton_Clean.put(ZoneB10, 230);
  Canton_Clean.put(ZoneB11, 230);
  Canton_Clean.put(ZoneB12, 230);
  Canton_Clean.put(ZoneB13, 230);
  Canton_Clean.put(ZoneB14, 230);
  Canton_Clean.put(ZoneB15, 240);
  Canton_Clean.put(ZoneB17, 240);
  Canton_Clean.put(ZoneB18, 240);
  Canton_Clean.put(ZoneA16, 140);
  Canton_Clean.put(ZoneA17, 140);
  Canton_Clean.put(ZoneA20, 140);
  Canton_Clean.put(ZoneA21, 110);
  Canton_Clean.put(ZoneA22, 110);
  Canton_Clean.put(ZoneA23, 110);
  Canton_Clean.put(ZoneA24, 110);
  Canton_Clean.put(ZoneA1, 110);
  Canton_Clean.put(ZoneA2, 120);
  Canton_Clean.put(ZoneA5, 120);
  Canton_Clean.put(ZoneA7, 120);
  Canton_Clean.put(ZoneA8, 120);
  Canton_Clean.put(ZoneA9, 130);
  Canton_Clean.put(ZoneA10, 130);
  Canton_Clean.put(ZoneA11, 130);
  Canton_Clean.put(ZoneA12, 130);
  Canton_Clean.put(ZoneA13, 130);
  Canton_Clean.put(ZoneA14, 140);
  Canton_Clean.put(ZoneA15, 140);
  Canton_Clean.put(ZoneA16, 140);
  Canton_Clean.put(ZoneA18, 140);
  Canton_Clean.put(ZoneB22, 240);
  Canton_Clean.put(ZoneC12, 340);
  Canton_Clean.put(ZoneC14, 340);
  Canton_Clean.put(ZoneD1, 410);
  Canton_Clean.put(ZoneD2, 410);
  Canton_Clean.put(ZoneD3, 410);
  Canton_Clean.put(ZoneD4, 410);
  Canton_Clean.put(ZoneD5, 410);
  Canton_Clean.put(ZoneD12, 412);
  Canton_Clean.put(ZoneD13, 412);
  Canton_Clean.put(ZoneD14, 412);
  Canton_Clean.put(ZoneD15, 412);
  Canton_Clean.put(ZoneD16, 412);
  Canton_Clean.put(ZoneD17, 412);
  Canton_Clean.put(ZoneD18, 412);
  Canton_Clean.put(ZoneGH14, 412);
  Canton_Clean.put(ZoneGH15, 412);

  rButtonReset = new RouteButton(rX+440, rY+110, 60, 30, "Reset");
  rButtonReset.addTrackButton(tButton101, 0);
  rButtonReset.addTrackButton(tButton102, 0);
  rButtonReset.addTrackButton(tButton103, 0);
  rButtonReset.addTrackButton(tButton104, 0);
  rButtonReset.addTrackButton(tButton105, 0);
  rButtonReset.addTrackButton(tButton106, 0);
  rButtonReset.addTrackButton(tButton107, 0);
  rButtonReset.addTrackButton(tButton108, 0);
  rButtonReset.addTrackButton(tButton109, 0);
  rButtonReset.addTrackButton(tButton110, 0);
  rButtonReset.addTrackButton(tButton111, 0);
  rButtonReset.addTrackButton(tButton112, 0);
  rButtonReset.addTrackButton(tButton113, 0);
  rButtonReset.addTrackButton(tButton114, 0);
  rButtonReset.addTrackButton(tButton115, 0);
  rButtonReset.addTrackButton(tButton116, 0);
  rButtonReset.addTrackButton(tButton117, 0);
  rButtonReset.addTrackButton(tButton118, 0);
  rButtonReset.addTrackButton(tButton119, 0);
  rButtonReset.addTrack(ZoneA2);  // Aiguillage Voie A vers B Gare Basse : Component Name = T101
  rButtonReset.addTrack(ZoneB3);  // Aiguillage Voie A vers B Gare Basse : Component Name = T101
  rButtonReset.addTrack(ZoneB5);  // Aiguillage Voie B vers A Gare Basse : Component Name = T102
  rButtonReset.addTrack(ZoneA8);  // Aiguillage Voie B vers A Gare Basse : Component Name = T102
  rButtonReset.addTrack(ZoneA15);  // Aiguillage Voie A vers B Gare Haute : Component Name = T103
  rButtonReset.addTrack(ZoneC6);  // Croisement Voie C direct et Voie B vers GH Gare Haute : Component Name = T104
  rButtonReset.addTrack(ZoneC9);  // Croisement Voie C direct et Voie B vers GH Gare Haute : Component Name = T104
  rButtonReset.addTrack(ZoneB16);  // Croisement Voie B direct et Voie A vers B Gare Haute : Component Name = T105
  rButtonReset.addTrack(ZoneB19);  // Croisement Voie B direct et Voie A vers B Gare Haute : Component Name = T105
  rButtonReset.addTrack(ZoneA17);  // Aiguillage Voie A vers B Gare Haute : Component Name = T106
  rButtonReset.addTrack(ZoneB21);  // Croisement Voie B direct et Voie B vers C Gare Haute: Component Name = T107
  rButtonReset.addTrack(ZoneB22);  // Croisement Voie B direct et Voie B vers C Gare Haute: Component Name = T107
  rButtonReset.addTrack(ZoneC11);  // Croisement Voie C direct et Voie C vers D Gare Haute : Component Name = T108
  rButtonReset.addTrack(ZoneC12);  // Croisement Voie C direct et Voie C vers D Gare Haute : Component Name = T108
  rButtonReset.addTrack(ZoneA5);  // Aiguillage Voie A vers Gare Basse : Component Name = T109
  rButtonReset.addTrack(ZoneGB1);  // Aiguillage vers Gare Basse Voie 1 : Component Name = T110
  rButtonReset.addTrack(ZoneGB4);  // Aiguillage vers Gare Basse Voie 2 : Component Name = T111
  rButtonReset.addTrack(ZoneGB7);  // Aiguillage vers Gare Basse Voie 3 : Component Name = T112
  rButtonReset.addTrack(ZoneGH5);  // Aiguillage vers Gare Haute Voie 1 - Lavage : Component Name = T114
  rButtonReset.addTrack(ZoneGH8);  // Aiguillage vers Gare Haute Voie 2 - Rotonde : Component Name = T115
  rButtonReset.addTrack(ZoneGH11);  // Aiguillage vers Gare Haute Voie 3 - Déchargement : Component Name = T116
  rButtonReset.addTrack(ZoneD17);  // Aiguillage vers Gare Haute Voie 3 - Déchargement : Component Name = T116
  rButtonReset.addTrack(ZoneGH14);  // Aiguillage vers Gare Haute Voie 4 - Maintenance 1 : Component Name = T117
  rButtonReset.addTrack(ZoneD4);  // Aiguillage Ouest Voie D vers D : Component Name = T118
  rButtonReset.addTrack(ZoneD15);  // Aiguillage Est Voie D vers D : Component Name = T119 

  ////////////////////////////////////////////////////////////////////////
  // Cab position initialization    
  //    LocoButton(Track refTrack, position (0 begin of segment , 1 end of segment), cab)
  //      ou
  //    LocoButton(Route, num track, position (0 begin of segment, 1 end of segment), cab, Canton)
  ////////////////////////////////////////////////////////////////////////

  Loco1 = new LocoButton(Voie_A, 1, 0, cab1, Canton_A, 16); // Track : voie A 
  Loco2 = new LocoButton(Voie_B, 1, 0, cab2, Canton_B, 15); // Track : voie B
  Loco3 = new LocoButton(Voie_C, 1, 0, cab3, Canton_C, 30); // Track : voie C
  Loco4 = new LocoButton(Voie_A_B, 1, 0, cab4, Canton_A_B, 18); // Circuit : voie A - B
  Loco5 = new LocoButton(Voie_B_A, 1, 0, cab5, Canton_B_A, 25); // Circuit : voie B - A
  Loco6 = new LocoButton(Voie_B_C, 1, 0, cab6, Canton_B_C, 22); // Circuit : voie B - C
  Loco7 = new LocoButton(Voie_Clean, 2, 1, cab7, Canton_Clean, 25); // Circuit : voie D

  //////////////////////////////////////////////////////////////////////////
  //   Array control to debug only
  //////////////////////////////////////////////////////////////////////////
  /*
  int Size_A_R = SizeClass_A_RouteButton();
   println ("Size_A_R:", Size_A_R);
   for (int IR_A=0; IR_A<Size_A_R; IR_A=IR_A+1) {
   RouteButton Ref_A_R = getClass_A_RouteButton(IR_A);
   println ("       Ref_A_R:", Ref_A_R);
   }
   
   int Size_B_R = SizeClass_B_RouteButton();
   println ("Size_B_R:", Size_B_R);
   for (int IR_B=0; IR_B<Size_B_R; IR_B=IR_B+1) {
   RouteButton Ref_B_R = getClass_B_RouteButton(IR_B);
   println ("       Ref_B_R:", Ref_B_R);
   }
   
   int Size_R_Track = SizeClass_R_Track();
   println ("Size_R_Track:", Size_R_Track);
   for (int IR_T=0; IR_T<Size_R_Track; IR_T=IR_T+1) {
   Track Ref_R_Track = getClass_R_Track(IR_T);
   println ("       Ref_R_Track:", Ref_R_Track);
   }
   */
} // Initialize

//////////////////////////////////////////////////////////////////////////

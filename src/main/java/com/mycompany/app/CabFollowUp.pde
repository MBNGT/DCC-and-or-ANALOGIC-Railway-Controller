////////////////////////////////////////////////////////////////////////// //<>// //<>//
//  PROCESSING RAILWAY CONTROLLER: Classes for Cabs follow up on track
//      Sheet : CabFollowUp
//
//  LocoButton  - Define Cab symbol on track
//    fields
//      input : 
//        reftrack (X0,Y0,X1,Y1,trackPoint,curveRadius,thetaR,thetaA,tStatus,hStatus) 
//        position (begining or end of track)
//        cabButton (speed, cab, baseHue)
//        speedFactor
//
//      output : 
//
//    methods
//      void display() : triangle position
//      void move() : from old position to new position
//
//
//////////////////////////////////////////////////////////////////////////
//    Class LocoButton
//////////////////////////////////////////////////////////////////////////

class LocoButton extends DccComponent {
  boolean LocoActive=false;
  int log;
  int lWidth=20;
  int lHeight=20;
  String LocoName;
  XML LocoButtonXML;
  Track refTrack;
  int trackPoint;
  float xPos, yPos;  //  Coordonnées position en X,Y et Theta du marqueur Loco
  float XPos, YPos;
  float curveAngleDeg;
  float thetaR, thetaA;
  float thetaStart, thetaEnd;
  float thetaPos;
  int curve;
  int position;
  int angle;
  float xR, yR;
  float Radius;
  int tStatus;         // specfies current track status (0=off/not visible, 1=on/visible)
  int hStatus;         // specifies if current track is highlighted (1) or normal (0)

  CabButton cabButton;
  int sidingSensor;
  int parkingSensor;
  int rayon=10;
  float speedFactor; // conversion factor between cab speed and symbol speed on the screen

  HashMap<Integer, Track> Route;
  int size_Route;
  int num_Track;
  boolean routeOn;
  int finish;  //  after movement on the track, this indicate the end (1)

  //  New for cantons management
  HashMap<Track, Integer> Canton;
  int size_Canton;
  int num_Canton;

  MessageBox msgBoxLoco;

  //////////////////////////////////////////////////////////////////////////
  //  Loco button definition for a track
  //////////////////////////////////////////////////////////////////////////

  LocoButton(Track refTrack, int position, CabButton cabButton, float speedFactor) {      
    locoButtons.add(this);
    log=locoButtons.size();
    this.refTrack=refTrack;
    this.position=position;
    this.cabButton=cabButton;
    this.trackPoint=refTrack.trackPoint;
    this.Radius=refTrack.r;
    this.thetaA=refTrack.thetaA;
    this.curveAngleDeg=refTrack.curveAngleDeg;
    this.thetaR=refTrack.thetaR;
    this.curve=(thetaR==0)?0:1;
    this.angle=(thetaR>0)?1:-1; // Angle : Clock =-1, Trigo=1 
    this.tStatus=refTrack.tStatus;
    this.hStatus=refTrack.hStatus;
    this.speedFactor=speedFactor;
    finish=0;

    //////////////////////////////////////////////////////////////////////////
    // Here it is possible to init the loco symbol at the middle of a rTrack
    //////////////////////////////////////////////////////////////////////////
    //    this.xPos=((refTrack.x[0]+refTrack.x[1])/2.0*refTrack.layout.sFactor+refTrack.layout.xCorner);
    //    this.yPos=((refTrack.y[0]+refTrack.y[1])/2.0*refTrack.layout.sFactor+refTrack.layout.yCorner);

    //////////////////////////////////////////////////////////////////////////
    // Init the loco symbol at the end of a rTrack
    //////////////////////////////////////////////////////////////////////////
    if (position==1) { 
      if (curve==0) {   // straight rtrack segment
        this.xPos=refTrack.x[1];
        this.yPos=refTrack.y[1];
      } else {               //  curve rtrack segment
        thetaPos=thetaA+thetaR;
        this.xPos=refTrack.xR+angle*Radius*sin(thetaPos);
        this.yPos=refTrack.yR+angle*Radius*cos(thetaPos);
      }
    }
    //////////////////////////////////////////////////////////////////////////
    // Init the loco symbol at the begining of a rTrack
    //////////////////////////////////////////////////////////////////////////
    if (position==0) { 
      if (curve==0) {    // straight rtrack segment
        this.xPos=refTrack.x[0];
        this.yPos=refTrack.y[0];
      } else {               //  curve rtrack segment
        thetaPos=thetaA;
        this.xPos=refTrack.xR+angle*Radius*sin(thetaPos);
        this.yPos=refTrack.yR+angle*Radius*cos(thetaPos);
      }
    }
    // println("Loco    DEF 1 - Loco ", cabButton.cab, " track definition");
    // println("cab:", cabButton.cab, "baseHue:", cabButton.baseHue, "speed:", cabButton.speed); 
    // println("reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
    // println("x[0]:", refTrack.x[0], "x[1]:", refTrack.x[1], "y[0]:", refTrack.y[0], "y[1]:", refTrack.y[1]);
    // println("sfactor:", refTrack.layout.sFactor, "xcorner:", refTrack.layout.xCorner, "ycorner:", refTrack.layout.yCorner);
    // println("refTrack.a[1]:", refTrack.a[1], "refTrack.a[0]:", refTrack.a[0], "curveAngleDeg:", refTrack.curveAngleDeg);
    // println("refTrack.xR:", refTrack.xR, "refTrack.yR:", refTrack.yR, "Radius:", Radius, "tStatus:", tStatus, "hStatus:", hStatus);
    // println("thetaPos:", thetaPos, "xPos:", xPos, "yPos:", yPos, "angle:", angle, "Radius:", Radius); 
    // println("sin(thetaPos):", sin(thetaPos), "cos(thetaPos):", cos(thetaPos), "finish:", finish);
    // println("thetaA:", thetaA, "thetaR:", thetaR, "thetaA+thetaR", thetaA+thetaR, "thetaA+thetaPos:", thetaA+thetaPos);
    LocoName="Loco"+cabButton.cab;
    componentName=LocoName;
    LocoButtonXML=LocoButtonsXML.getChild(LocoName);
    if (LocoButtonXML==null) {
      LocoButtonXML=LocoButtonsXML.addChild(LocoName);
      LocoButtonXML.setContent(str(LocoActive));
    } else {
      LocoActive=boolean(LocoButtonXML.getContent());
    }
    LocosHM.put(cabButton.cab, this);
    msgBoxLoco=new MessageBox(CabWindow, 10, cabButton.cab*22+22, -1, 0, color(175), 18, "Loco-"+nf(cabButton.cab, 2)+":", color(cabButton.baseHue, 255, 255));
    dccComponents.add(this);
  }  //  LocoButton

  //////////////////////////////////////////////////////////////////////////
  //  Loco button definition for a route
  //////////////////////////////////////////////////////////////////////////

  //  LocoButton(HashMap<Integer, Track>Route, int position, CabButton cabButton, int parkingSensor, int sidingSensor) {
  LocoButton(HashMap<Integer, Track> Route, int num_Track, int position, CabButton cabButton, float speedFactor) {      

    locoButtons.add(this);
    log=locoButtons.size();
    this.Route=Route;
    this.num_Track=num_Track;
    this.position=position;
    this.cabButton=cabButton;
    this.size_Route=Route.size();
    this.speedFactor=speedFactor;

    init_Route();

    LocoName="Loco"+cabButton.cab;
    componentName=LocoName;
    LocoButtonXML=LocoButtonsXML.getChild(LocoName);
    if (LocoButtonXML==null) {
      LocoButtonXML=LocoButtonsXML.addChild(LocoName);
      LocoButtonXML.setContent(str(LocoActive));
    } else {
      LocoActive=boolean(LocoButtonXML.getContent());
    }
    LocosHM.put(cabButton.cab, this);
    msgBoxLoco=new MessageBox(CabWindow, 10, cabButton.cab*22+22, -1, 0, color(175), 18, "Loco-"+nf(cabButton.cab, 2)+":", color(cabButton.baseHue, 255, 255));
    dccComponents.add(this);
  }  //  LocoButton

  //////////////////////////////////////////////////////////////////////////
  //  Loco button definition for a route with cantons management
  //////////////////////////////////////////////////////////////////////////

  LocoButton(HashMap<Integer, Track> Route, int num_Track, int position, CabButton cabButton, HashMap<Track, Integer> Canton, float speedFactor) {      

    locoButtons.add(this);
    log=locoButtons.size();
    this.Route=Route;
    this.num_Track=num_Track;
    this.position=position;
    this.cabButton=cabButton;
    this.size_Route=Route.size();
    this.Canton=Canton;
    this.speedFactor=speedFactor;
    //this.current_Canton = current_Canton;
    //this.current_Speed = current_Speed;

    init_Route_Canton();

    LocoName="Loco"+cabButton.cab;
    componentName=LocoName;
    LocoButtonXML=LocoButtonsXML.getChild(LocoName);
    if (LocoButtonXML==null) {
      LocoButtonXML=LocoButtonsXML.addChild(LocoName);
      LocoButtonXML.setContent(str(LocoActive));
    } else {
      LocoActive=boolean(LocoButtonXML.getContent());
    }
    LocosHM.put(cabButton.cab, this);
    msgBoxLoco=new MessageBox(CabWindow, 10, cabButton.cab*22+22, -1, 0, color(175), 18, "Loco-"+nf(cabButton.cab, 2)+":", color(cabButton.baseHue, 255, 255));
    dccComponents.add(this);
  }  //  LocoButton

  //////////////////////////////////////////////////////////////////////////
  //  Init the loco symbol at route num_track (in relation with Loco1 = new LocoButton(Voie_A, 0, cab1)
  //////////////////////////////////////////////////////////////////////////
  void init_Route() {    
    finish=0;
    Track refTrack = Route.get(num_Track);
    this.refTrack=refTrack;
    trackPoint=refTrack.trackPoint;
    Radius=refTrack.r;
    thetaA=refTrack.thetaA;
    curveAngleDeg=refTrack.curveAngleDeg;
    thetaR=refTrack.thetaR;
    curve=(thetaR==0)?0:1;
    angle=(thetaR>0)?1:-1; // Angle : Clock =-1, Trigo=1 
    tStatus=refTrack.tStatus;
    hStatus=refTrack.hStatus;

    //////////////////////////////////////////////////////////////////////////
    // Here it is possible to init the loco symbol at the middle of a rTrack
    //////////////////////////////////////////////////////////////////////////
    //    this.xPos=((refTrack.x[0]+refTrack.x[1])/2.0*refTrack.layout.sFactor+refTrack.layout.xCorner);
    //    this.yPos=((refTrack.y[0]+refTrack.y[1])/2.0*refTrack.layout.sFactor+refTrack.layout.yCorner);

    //////////////////////////////////////////////////////////////////////////
    // Init the loco symbol at the end of a rTrack
    //////////////////////////////////////////////////////////////////////////
    if (position==1) {   
      if (curve==0) {   // straight rtrack segment 
        this.xPos=refTrack.x[1];
        this.yPos=refTrack.y[1];
      } else {    //  curve rtrack segment 
        thetaPos=thetaA+thetaR;
        this.xPos=refTrack.xR+angle*Radius*sin(thetaPos);
        this.yPos=refTrack.yR+angle*Radius*cos(thetaPos);
      }
    }
    //////////////////////////////////////////////////////////////////////////
    // Init the loco symbol at the begining of a rTrack
    //////////////////////////////////////////////////////////////////////////
    if (position==0) { 
      if (curve==0) {  /// straight rtrack segment
        this.xPos=refTrack.x[0];
        this.yPos=refTrack.y[0];
      } else {  //  curve rtrack segment
        thetaPos=thetaA;
        this.xPos=refTrack.xR+angle*Radius*sin(thetaPos);
        this.yPos=refTrack.yR+angle*Radius*cos(thetaPos);
      }
    }
    // println("Loco    DEF 2 - Loco ", cabButton.cab, " route definition", Route, "  num track", num_Track);
    // println("cab:", cabButton.cab, "baseHue:", cabButton.baseHue, "speed:", cabButton.speed, "Route:", Route); 
    // println("reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
    // println("x[0]:", refTrack.x[0], "x[1]:", refTrack.x[1], "y[0]:", refTrack.y[0], "y[1]:", refTrack.y[1]);
    // println("sfactor:", refTrack.layout.sFactor, "xcorner:", refTrack.layout.xCorner, "ycorner:", refTrack.layout.yCorner);
    // println("refTrack.a[1]:", refTrack.a[1], "refTrack.a[0]:", refTrack.a[0], "curveAngleDeg:", refTrack.curveAngleDeg);
    // println("refTrack.xR:", refTrack.xR, "refTrack.yR:", refTrack.yR, "Radius:", Radius, "tStatus:", tStatus, "hStatus:", hStatus);
    // println("thetaPos:", thetaPos, "xPos:", xPos, "yPos:", yPos, "angle:", angle, "Radius:", Radius); 
    // println("sin(thetaPos):", sin(thetaPos), "cos(thetaPos):", cos(thetaPos), "finish:", finish);
    // println("thetaA:", thetaA, "thetaR:", thetaR, "thetaA+thetaR", thetaA+thetaR, "thetaA+thetaPos:", thetaA+thetaPos);
  }    //  LocoButton init_Route

  //////////////////////////////////////////////////////////////////////////
  //  Init the loco symbol at route num_track (in relation with Loco1 = new LocoButton(Voie_A, 0, cab1)
  //////////////////////////////////////////////////////////////////////////
  void init_Route_Canton() {    
    finish=0;
    Track refTrack = Route.get(num_Track);
    this.refTrack=refTrack;
    num_Canton = Canton.get(refTrack);    //  In case of cantons management
    //this.current_Canton = cabButton.current_Canton;
    //this.current_Speed = cabButton.current_Speed;
    trackPoint=refTrack.trackPoint;
    Radius=refTrack.r;
    thetaA=refTrack.thetaA;
    curveAngleDeg=refTrack.curveAngleDeg;
    thetaR=refTrack.thetaR;
    curve=(thetaR==0)?0:1;
    angle=(thetaR>0)?1:-1; // Angle : Clock =-1, Trigo=1 
    tStatus=refTrack.tStatus;
    hStatus=refTrack.hStatus;

    //////////////////////////////////////////////////////////////////////////
    // Here it is possible to init the loco symbol at the middle of a rTrack
    //////////////////////////////////////////////////////////////////////////
    //    this.xPos=((refTrack.x[0]+refTrack.x[1])/2.0*refTrack.layout.sFactor+refTrack.layout.xCorner);
    //    this.yPos=((refTrack.y[0]+refTrack.y[1])/2.0*refTrack.layout.sFactor+refTrack.layout.yCorner);

    //////////////////////////////////////////////////////////////////////////
    // Init the loco symbol at the end of a rTrack
    //////////////////////////////////////////////////////////////////////////
    if (position==1) {   
      if (curve==0) {   // straight rtrack segment 
        this.xPos=refTrack.x[1];
        this.yPos=refTrack.y[1];
      } else {    //  curve rtrack segment 
        thetaPos=thetaA+thetaR;
        this.xPos=refTrack.xR+angle*Radius*sin(thetaPos);
        this.yPos=refTrack.yR+angle*Radius*cos(thetaPos);
      }
    }
    //////////////////////////////////////////////////////////////////////////
    // Init the loco symbol at the begining of a rTrack
    //////////////////////////////////////////////////////////////////////////
    if (position==0) { 
      if (curve==0) {  /// straight rtrack segment
        this.xPos=refTrack.x[0];
        this.yPos=refTrack.y[0];
      } else {  //  curve rtrack segment
        thetaPos=thetaA;
        this.xPos=refTrack.xR+angle*Radius*sin(thetaPos);
        this.yPos=refTrack.yR+angle*Radius*cos(thetaPos);
      }
    }
    // println("Loco    DEF 2 - Loco ", cabButton.cab, " route definition", Route, "  num track", num_Track);
    // println("cab:", cabButton.cab, "baseHue:", cabButton.baseHue, "speed:", cabButton.speed, "Route:", Route); 
    // println("Num track", num_Track, "  Canton ", num_Canton, "  reftrack:", refTrack, "  trackPoint:", refTrack.trackPoint, "  position:", position, "angle:", angle, "curve:", curve); 
    // println("x[0]:", refTrack.x[0], "x[1]:", refTrack.x[1], "y[0]:", refTrack.y[0], "y[1]:", refTrack.y[1]);
    // println("sfactor:", refTrack.layout.sFactor, "xcorner:", refTrack.layout.xCorner, "ycorner:", refTrack.layout.yCorner);
    // println("refTrack.a[1]:", refTrack.a[1], "refTrack.a[0]:", refTrack.a[0], "curveAngleDeg:", refTrack.curveAngleDeg);
    // println("refTrack.xR:", refTrack.xR, "refTrack.yR:", refTrack.yR, "Radius:", Radius, "tStatus:", tStatus, "hStatus:", hStatus);
    // println("thetaPos:", thetaPos, "xPos:", xPos, "yPos:", yPos, "angle:", angle, "Radius:", Radius); 
    // println("sin(thetaPos):", sin(thetaPos), "cos(thetaPos):", cos(thetaPos), "finish:", finish);
    // println("thetaA:", thetaA, "thetaR:", thetaR, "thetaA+thetaR", thetaA+thetaR, "thetaA+thetaPos:", thetaA+thetaPos);
  }    //  LocoButton Init_Route_Canton

  //////////////////////////////////////////////////////////////////////////
  // Loco button move on Railway track
  //////////////////////////////////////////////////////////////////////////

  void move_Loco() {

    // println("Loco      MOVE 1 - cab:", cabButton.cab, "baseHue:", cabButton.baseHue, "speed:", cabButton.speed);
    /*
     if (cabButton.cab==5) {
     println("x[0]:", refTrack.x[0], "x[1]:", refTrack.x[1], "y[0]:", refTrack.y[0], "y[1]:", refTrack.y[1]);
     println("position:", position, "trackPoint:", refTrack.trackPoint, "angle:", angle, "curve:", curve);
     println("refTrack.a[1]:", refTrack.a[1], "refTrack.a[0]:", refTrack.a[0], "curveAngleDeg:", refTrack.curveAngleDeg);
     println("refTrack.xR:", refTrack.xR, "refTrack.yR:", refTrack.yR, "Radius:", Radius, "tStatus:", tStatus, "hStatus:", hStatus);
     println("thetaPos:", thetaPos, "xPos:", xPos, "yPos:", yPos, "angle:", angle, "Radius:", Radius); 
     println("sin(thetaPos):", sin(thetaPos), "cos(thetaPos):", cos(thetaPos), "finish:", finish);
     println("thetaA:", thetaA, "thetaR:", thetaR, "thetaA+thetaR", thetaA+thetaR, "thetaA+thetaPos:", thetaA+thetaPos);
     }
     */

    if (curve==0) { // segment de droite
      // segment de gauche à droite et vitesse négative
      if ((cabButton.speed<0)&&(refTrack.x[1]>refTrack.x[0])&&(xPos<=refTrack.x[0])) {  // début du segment ?
        finish =1;
        // println("Loco      MOVE 3 A - cab:", cabButton.cab, "x[0]:", refTrack.x[0], "x[1]:", refTrack.x[1], "xPos:", xPos);
        // println("Loco      MOVE 3 A - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        return;
      } 
      // segment de droite à gauche et vitesse négative
      if ((cabButton.speed<0)&&(refTrack.x[0]>refTrack.x[1])&&(xPos>=refTrack.x[0])) {  // début du segment ?
        finish =1;
        // println("Loco      MOVE 3 B - cab:", cabButton.cab, "x[0]:", refTrack.x[0], "x[1]:", refTrack.x[1], "xPos:", xPos);
        // println("Loco      MOVE 3 B - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        return;
      }
      // segment de gauche à droite et vitesse positive
      if ((cabButton.speed>0)&&(refTrack.x[1]>refTrack.x[0])&&(xPos>=refTrack.x[1])) {  //  Fin du segment ?
        finish =1;
        // println("Loco      MOVE 4 A - cab:", cabButton.cab, "x[0]:", refTrack.x[0], "x[1]:", refTrack.x[1], "xPos:", xPos);
        // println("Loco      MOVE 4 A - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        return;
      }
      // segment de droite à gauche et vitesse positive
      if ((cabButton.speed>0)&&(refTrack.x[0]>refTrack.x[1])&&(xPos<=refTrack.x[1])) {  //  Fin du segment ?
        finish =1;
        // println("Loco      MOVE 4 B - cab:", cabButton.cab, "x[0]:", refTrack.x[0], "x[1]:", refTrack.x[1], "xPos:", xPos);
        // println("Loco      MOVE 4 B - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        return;
      }
      // segment de haut en bas et vitesse négative
      if ((cabButton.speed<0)&&(refTrack.y[1]>refTrack.y[0])&&(yPos<=refTrack.y[0])) {  // début du segment ?
        finish =1;
        // println("Loco      MOVE 5 A - cab:", cabButton.cab, "y[0]:", refTrack.y[0], "y[1]:", refTrack.y[1], "yPos:", yPos);
        // println("Loco      MOVE 5 A - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        return;
      } 
      // segment de bas en haut  et vitesse négative
      if ((cabButton.speed<0)&&(refTrack.y[0]>refTrack.y[1])&&(yPos>=refTrack.y[0])) {  // début du segment ?
        finish =1;
        // println("Loco      MOVE 5 B - cab:", cabButton.cab, "y[0]:", refTrack.y[0], "y[1]:", refTrack.y[1], "yPos:", yPos);
        // println("Loco      MOVE 5 B - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        return;
      }
      // segment de haut en bas  et vitesse positive
      if ((cabButton.speed>0)&&(refTrack.y[1]>refTrack.y[0])&&(yPos>=refTrack.y[1])) {  //  Fin du segment ?
        finish =1;
        // println("Loco      MOVE 6 A - cab:", cabButton.cab, "y[0]:", refTrack.y[0], "y[1]:", refTrack.y[1], "yPos:", yPos);
        // println("Loco      MOVE 6 A - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        return;
      }
      // segment de bas en haut et vitesse positive
      if ((cabButton.speed>0)&&(refTrack.y[0]>refTrack.y[1])&&(yPos<=refTrack.y[1])) {  //  Fin du segment ?
        finish =1;
        // println("Loco      MOVE 6 B - cab:", cabButton.cab, "y[0]:", refTrack.y[0], "y[1]:", refTrack.y[1], "yPos:", yPos);
        // println("Loco      MOVE 6 B - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        return;
      }
    } else { // courbe 
      // Courbe sens inverse trigo et vitesse négative
      if ((cabButton.speed<0)&&(thetaPos>=thetaA)&&(angle==-1)) {  // Debut de la courbe ?
        finish =1;
        // println("Loco      MOVE 7 A - cab:", cabButton.cab, "finish:", finish,"thetaPos:", thetaPos, "thetaA:", thetaA, "thetaR:", thetaR);
        // println("sin(thetaPos):", sin(thetaPos), "cos(thetaPos):", cos(thetaPos));
        // println("Loco      MOVE 7 A - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        return;
      }
      //  Courbe sens trigo et vitesse négative
      if ((cabButton.speed<0)&&(thetaPos<=thetaA)&&(angle==1)) {  // Debut de la courbe ?
        finish =1;
        // println("Loco      MOVE 7 B - cab:", cabButton.cab, "finish:", finish,"thetaPos:", thetaPos, "thetaA:", thetaA, "thetaR:", thetaR);
        // println("sin(thetaPos):", sin(thetaPos), "cos(thetaPos):", cos(thetaPos));
        // println("Loco      MOVE 7 B - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        return;
      } 
      //  courbe sens inverse trigo et vitesse positive
      if ((cabButton.speed>0)&&(thetaPos<=(thetaA+thetaR))&&(angle==-1)) {  // fin de la courbe ?
        finish =1;
        // println("Loco      MOVE 8 A - cab:", cabButton.cab, "finish:", finish,"thetaPos:", thetaPos, "thetaA:", thetaA, "thetaR:", thetaR);
        // println("sin(thetaPos):", sin(thetaPos), "cos(thetaPos):", cos(thetaPos));
        // println("Loco      MOVE 8 A - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        return;
      }
      //  courbe sens trigo et vitesse positive
      if ((cabButton.speed>0)&&(thetaPos>=(thetaA+thetaR))&&(angle==1)) {  // fin de la courbe ?
        finish =1;
        // println("Loco      MOVE 8 B - cab:", cabButton.cab, "finish:", finish,"thetaPos:", thetaPos, "thetaA:", thetaA, "thetaR:", thetaR);
        // println("sin(thetaPos):", sin(thetaPos), "cos(thetaPos):", cos(thetaPos));
        // println("Loco      MOVE 8 B - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        return;
      }
    }
    if (tStatus==1) {
      if (curve==0) { // segment de droite
        xPos = xPos+cos(refTrack.a[1])*cabButton.speed/speedFactor;
        yPos = yPos-sin(refTrack.a[1])*cabButton.speed/speedFactor;
      } else { //  Courbe
        if (angle==-1) thetaPos=thetaPos-(cabButton.speed/Radius)/speedFactor; // sens inverse trigo
        if (angle==1) thetaPos=thetaPos+(cabButton.speed/Radius)/speedFactor;  // sens trigo
        xPos=refTrack.xR+angle*Radius*sin(thetaPos);
        yPos=refTrack.yR+angle*Radius*cos(thetaPos);
      }
      //  In cantons management, send cab, direction, speed, track and canton to Nano via Mega
      if (cabButton.speed!=cabButton.current_Speed||num_Canton!=cabButton.current_Canton) {
        cabButton.setThrottleCanton(cabButton.speed, num_Canton);    //  Cantons management : tPos = speed and current canton
        cabButton.current_Canton = num_Canton;
        cabButton.current_Speed = cabButton.speed;
        println("cab", cabButton.cab, "  cur speed", cabButton.current_Speed, "  speed", cabButton.speed, "  cur canton", cabButton.current_Canton, "  canton", num_Canton);
      }
      /*
      if (cabButton.cab==1) {
       println("Loco      MOVE 2 - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed); 
       println("reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
       // println("x[1]-x[0]:", refTrack.x[1]-refTrack.x[0], "x[1]-xPos:", refTrack.x[1]-xPos, "y[1]-y[0]:", refTrack.y[1]-refTrack.y[0], "y[1]-yPos:", refTrack.y[1]-yPos);
       // println("x[0]-x[1]:", refTrack.x[0]-refTrack.x[1], "x[0]-xPos:", refTrack.x[0]-xPos, "y[0]-y[1]:", refTrack.y[0]-refTrack.y[1], "y[0]-yPos:", refTrack.y[0]-yPos);
       // println("refTrack.a[1]:", refTrack.a[1], "refTrack.a[0]:", refTrack.a[0], "curveAngleDeg:", refTrack.curveAngleDeg);
       // println("refTrack.xR:", refTrack.xR, "refTrack.yR:", refTrack.yR, "Radius:", Radius, "tStatus:", tStatus, "hStatus:", hStatus);
       // println("thetaPos:", thetaPos, "xPos:", xPos, "yPos:", yPos, "angle:", angle, "Radius:", Radius); 
       // println("sin(thetaPos):", sin(thetaPos), "cos(thetaPos):", cos(thetaPos));
       // println("thetaA:", thetaA, "thetaR:", thetaR, "thetaA+thetaR", thetaA+thetaR, "thetaA+thetaPos:", thetaA+thetaPos);
       // println("speed:", cabButton.speed, "xPos:", xPos, "yPos:", yPos, "XPos:", XPos, "YPos:", YPos, "finish:", finish);
       }
       */
    } else {  //  do not move
      if (cabButton.cab==1) {
        // println("Loco      MOVE 9 - cab:", cabButton.cab, "tStatus:", tStatus, "hStatus:", hStatus, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
        // println("x[1]-x[0]:", refTrack.x[1]-refTrack.x[0], "x[1]-xPos:", refTrack.x[1]-xPos, "y[1]-y[0]:", refTrack.y[1]-refTrack.y[0], "y[1]-yPos:", refTrack.y[1]-yPos);
        // println("thetaPos:", thetaPos, "thetaA:", thetaA, "thetaR:", thetaR);
      }
    }
  }    //  LocoButton move_Loco

  //////////////////////////////////////////////////////////////////////////
  //  Display
  //////////////////////////////////////////////////////////////////////////

  void display() {
    rectMode(CENTER);
    float x1Pos, x2Pos, x3Pos;
    float y1Pos, y2Pos, y3Pos;
    float alpha, alpha120, alpha240;
    // print("Loco      DISPLAY 1 - ");
    // println("cab:",cabButton.cab,"baseHue:",cabButton.baseHue,"speed:",cabButton.speed,"reftrack:",refTrack,"position:",position); 
    // println("xPos:", xPos, "yPos:", yPos,"refTrack.layout.sFactor:",refTrack.layout.sFactor,"refTrack.layout.xCorner:",refTrack.layout.xCorner); 

    if (curve==0) {
      alpha = refTrack.a[1];
    } else {
      alpha=thetaPos;
    }
    alpha120=alpha+PI/3;
    alpha240=alpha+2*PI/3;
    if (alpha120>=TWO_PI) alpha120-=TWO_PI;
    if (alpha120<0) alpha120+=TWO_PI;
    if (alpha240>=TWO_PI) alpha240-=TWO_PI;
    if (alpha240<0) alpha240+=TWO_PI;
    //    print("Loco      DISPLAY 2 - ");
    // println("alpha:", alpha, "alpha120:", alpha120, "alpha240:", alpha240);

    XPos=xPos*refTrack.layout.sFactor+refTrack.layout.xCorner;
    YPos=yPos*refTrack.layout.sFactor+refTrack.layout.yCorner;
    x1Pos = XPos+(rayon*cos(alpha));
    y1Pos = YPos-(rayon*sin(alpha));
    x2Pos = XPos-((rayon)*cos(alpha120));
    y2Pos = YPos+((rayon)*sin(alpha120));
    x3Pos = XPos+(rayon*cos(alpha240));
    y3Pos = YPos-(rayon*sin(alpha240));

    colorMode(HSB, 255);
    strokeWeight(1);
    stroke(color(0, 0, 0));
    fill(color(cabButton.baseHue, 255, 255));
    // println("Loco      DISPLAY 3 - CabFollowUp      cab:",cabButton.cab,"baseHue:",cabButton.baseHue,"speed:",cabButton.speed,"reftrack:",refTrack,"position:",position); 
    triangle(x1Pos, y1Pos, x2Pos, y2Pos, x3Pos, y3Pos); // Sommet 1 : X,Y, sommet 2 : X,Y, sommet 3 : X,Y
    colorMode(RGB, 255);
  }    //  LocoButton display

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    LocoButtonXML.setContent(str(LocoActive));
    saveXMLFlag=true;
    if (LocoActive) {
      msgBoxLoco.setMessage("Loco-"+nf(cabButton.cab, 2)+": Pos:"+nfp(refTrack.x[0], 1, 1)+"/"+nfp(refTrack.y[0], 1, 1)+"-"+nfp(refTrack.x[1], 1, 1)+"/"+nfp(refTrack.y[1], 1, 1)+"; speed:"+cabButton.speed);
    }
    // println();
    // print("Loco      PRESSED - ");
    // println("cab:", cabButton.cab, "baseHue:", cabButton.baseHue, "speed:", cabButton.speed, "reftrack:", refTrack, "trackPoint:", trackPoint);
  }    //  LocoButton pressed

  //////////////////////////////////////////////////////////////////////////

  void reset() {
    pressed();
  }    //  LocoButton reset

  //////////////////////////////////////////////////////////////////////////

  void check() {
    if (selectedComponent==null && (mouseX-XPos)*(mouseX-XPos)/(lWidth*lWidth/4.0)+(mouseY-YPos)*(mouseY-YPos)/(lHeight*lHeight/4.0)<=1) {
      cursorType=HAND;
      selectedComponent=this;
    }
  }    //  LocoButton check

  //////////////////////////////////////////////////////////////////////////
  //    Route prédéfinie
  //////////////////////////////////////////////////////////////////////////

  void LocoRoutes() {

    // println("Loco    LocoRoute 1 ", "cab:", cabButton.cab, "speed:", cabButton.speed, "finish:", finish, "size_Route:", size_Route, "num_Track:", num_Track, "refTrack:", refTrack);
    if (finish ==1) { //  Track is finished
      if (cabButton.speed>0) { //  Positive Speed 
        // println("finished - positive speed", "num_Track 1 :", num_Track, "refTrack:", refTrack);
        if (num_Track==size_Route-1) {  //  Fin de la liste des tracks de la route
          num_Track=0;    //  Re initialisation de la route
          position=0;
        } else {
          num_Track=num_Track+1;    //  Sinon track suivant
          position=0;
        }
      } else { //  Negative speed
        // println("finished - negative speed", "num_Track 2 :", num_Track, "refTrack:", refTrack);
        if (num_Track==0) {    //  Debut de la liste des tracks de la route
          num_Track=size_Route-1;    //  Re initialisation au dernier track de la route
          position=1;
        } else {
          num_Track=num_Track-1;    //  Sinon track précédent
          position=1;
        }
      }

      finish=0;
      this.refTrack = Route.get(num_Track);
      this.trackPoint=refTrack.trackPoint;
      this.Radius=refTrack.r;
      this.thetaA=refTrack.thetaA;
      this.curveAngleDeg=refTrack.curveAngleDeg;
      this.thetaR=refTrack.thetaR;
      this.curve=(thetaR==0)?0:1;
      this.angle=(thetaR>0)?1:-1; // Angle : Clock =-1, Trigo=1 
      this.tStatus=refTrack.tStatus;
      this.hStatus=refTrack.hStatus;
      println("Route for cab", cabButton.cab, "  num_Track", num_Track, "  size_Route", size_Route, "  position", position);
      // println("Loco    LocoRoute 2 - ");
      // println("cab:", cabButton.cab, "finish:", finish, "speed:", cabButton.speed, "tStatus:", tStatus, "hStatus:", hStatus, "Route:", Route); 
      // println("reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
      // println("x[0]:", refTrack.x[0], "x[1]:", refTrack.x[1], "y[0]:", refTrack.y[0], "y[1]:", refTrack.y[1], "xPos:", xPos, "yPos:", yPos);
      // println("sfactor:", refTrack.layout.sFactor, "xcorner:", refTrack.layout.xCorner, "ycorner:", refTrack.layout.yCorner);
      // println("refTrack.a[1]:", refTrack.a[1], "refTrack.a[0]:", refTrack.a[0], "curveAngleDeg:", refTrack.curveAngleDeg);
      // println("refTrack.xR:", refTrack.xR, "refTrack.yR:", refTrack.yR, "Radius:", Radius, "tStatus:", tStatus, "hStatus:", hStatus);
      // println("thetaPos:", thetaPos, "thetaA:", thetaA, "thetaR:", thetaR, "thetaA+thetaR", thetaA+thetaR, "thetaA+thetaPos:", thetaA+thetaPos); 
      // println("sin(thetaPos):", sin(thetaPos), "cos(thetaPos):", cos(thetaPos));

      if (position==1) { // Positionnement à la fin du segment
        if (curve==0) {  // Segment de droite
          this.xPos=refTrack.x[1];
          this.yPos=refTrack.y[1];
        } else {  // Segment courbe
          thetaPos=thetaA+thetaR;
          this.xPos=refTrack.xR+angle*Radius*sin(thetaPos);
          this.yPos=refTrack.yR+angle*Radius*cos(thetaPos);
        }
      }
      if (position==0) { // Positionnement au début du segment
        if (curve==0) {  // Segment de droite
          this.xPos=refTrack.x[0];
          this.yPos=refTrack.y[0];
        } else {  // Segment courbe
          thetaPos=thetaA;
          this.xPos=refTrack.xR+angle*Radius*sin(thetaPos);
          this.yPos=refTrack.yR+angle*Radius*cos(thetaPos);
        }
      }
    }  //  Track is not finished

    move_Loco();
  }    //  LocoButton LocoRoutes

  //////////////////////////////////////////////////////////////////////////
  //    Route prédéfinie with cantons management
  //////////////////////////////////////////////////////////////////////////

  void LocoRoutes_Cantons() {

    if (finish ==1) { //  Track is finished
      if (cabButton.speed>0) { //  Positive Speed 
        // println("finished - positive speed", "num_Track 1 :", num_Track, "refTrack:", refTrack);
        if (num_Track==size_Route-1) {  //  Fin de la liste des tracks de la route
          num_Track=0;    //  Re initialisation de la route
          position=0;
        } else {
          num_Track=num_Track+1;    //  Sinon track suivant
          position=0;
        }
      } else { //  Negative speed
        // println("finished - negative speed", "num_Track 2 :", num_Track, "refTrack:", refTrack);
        if (num_Track==0) {    //  Debut de la liste des tracks de la route
          num_Track=size_Route-1;    //  Re initialisation au dernier track de la route
          position=1;
        } else {
          num_Track=num_Track-1;    //  Sinon track précédent
          position=1;
        }
      }

      //println("Finished track for cab", cabButton.cab, "  num_Track", num_Track, "  Canton", num_Canton, "  size_Route", size_Route, "  position", position);
      finish=0;
      this.refTrack = Route.get(num_Track);
      this.trackPoint=refTrack.trackPoint;
      this.num_Canton = Canton.get(refTrack);    //  In case of cantons management
      this.Radius=refTrack.r;
      this.thetaA=refTrack.thetaA;
      this.curveAngleDeg=refTrack.curveAngleDeg;
      this.thetaR=refTrack.thetaR;
      this.curve=(thetaR==0)?0:1;
      this.angle=(thetaR>0)?1:-1; // Angle : Clock =-1, Trigo=1 
      this.tStatus=refTrack.tStatus;
      this.hStatus=refTrack.hStatus;
      // if (cabButton.cab == 1) println("Canton for cab", cabButton.cab, "speed:", cabButton.speed, "finish:", finish, "  num_Track", num_Track, "  Canton", num_Canton, "  size_Route", size_Route, "  position", position);
      // println("Loco    LocoRoute 2 - ");
      // println("cab:", cabButton.cab, "finish:", finish, "speed:", cabButton.speed, "tStatus:", tStatus, "hStatus:", hStatus, "Route:", Route); 
      // println("reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
      // println("x[0]:", refTrack.x[0], "x[1]:", refTrack.x[1], "y[0]:", refTrack.y[0], "y[1]:", refTrack.y[1], "xPos:", xPos, "yPos:", yPos);
      // println("sfactor:", refTrack.layout.sFactor, "xcorner:", refTrack.layout.xCorner, "ycorner:", refTrack.layout.yCorner);
      // println("refTrack.a[1]:", refTrack.a[1], "refTrack.a[0]:", refTrack.a[0], "curveAngleDeg:", refTrack.curveAngleDeg);
      // println("refTrack.xR:", refTrack.xR, "refTrack.yR:", refTrack.yR, "Radius:", Radius, "tStatus:", tStatus, "hStatus:", hStatus);
      // println("thetaPos:", thetaPos, "thetaA:", thetaA, "thetaR:", thetaR, "thetaA+thetaR", thetaA+thetaR, "thetaA+thetaPos:", thetaA+thetaPos); 
      // println("sin(thetaPos):", sin(thetaPos), "cos(thetaPos):", cos(thetaPos));

      if (position==1) { // Positionnement à la fin du segment
        if (curve==0) {  // Segment de droite
          this.xPos=refTrack.x[1];
          this.yPos=refTrack.y[1];
        } else {  // Segment courbe
          thetaPos=thetaA+thetaR;
          this.xPos=refTrack.xR+angle*Radius*sin(thetaPos);
          this.yPos=refTrack.yR+angle*Radius*cos(thetaPos);
        }
      }
      if (position==0) { // Positionnement au début du segment
        if (curve==0) {  // Segment de droite
          this.xPos=refTrack.x[0];
          this.yPos=refTrack.y[0];
        } else {  // Segment courbe
          thetaPos=thetaA;
          this.xPos=refTrack.xR+angle*Radius*sin(thetaPos);
          this.yPos=refTrack.yR+angle*Radius*cos(thetaPos);
        }
      }
    }  //  Track is not finished

    move_Loco();
  }    //  LocoButton LocoRoutes_Cantons
} // LocoButton Class

//////////////////////////////////////////////////////////////////////////
//    Route non prédéfinie 
//      based upon tracks with :
//          tStatus; specfies current track status 1=on/visible
//          hStatus; specifies if current track is highlighted (1) or normal (0)
//////////////////////////////////////////////////////////////////////////
/*
void LocoCircuit() {
 
 // println("Loco    LocoCircuit 1 ", "cab:", cabButton.cab, "speed:", cabButton.speed, "finish:", finish, "size_Route:", size_Route, "num_Track:", num_Track, "refTrack:", refTrack);
 if (finish ==1) { //  Track is finished
 if (cabButton.speed>0) { //  Positive Speed 
 // println("finished - positive speed", "num_Track 1 :", num_Track, "refTrack:", refTrack);
 if (num_Track==size_Route-1) {  //  Fin de la liste des tracks de la route
 num_Track=0;    //  Re initialisation de la route
 position=0;
 } else {
 num_Track=num_Track+1;    //  Sinon track suivant
 position=0;
 }
 } else { //  Negative speed
 // println("finished - negative speed", "num_Track 2 :", num_Track, "refTrack:", refTrack);
 if (num_Track==0) {    //  Debut de la liste des tracks de la route
 num_Track=size_Route-1;    //  Re initialisation au dernier track de la route
 position=1;
 } else {
 num_Track=num_Track-1;    //  Sinon track précédent
 position=1;
 }
 }
 
 finish=0;
 this.refTrack = Route.get(num_Track);
 this.trackPoint=refTrack.trackPoint;
 this.Radius=refTrack.r;
 this.thetaA=refTrack.thetaA;
 this.curveAngleDeg=refTrack.curveAngleDeg;
 this.thetaR=refTrack.thetaR;
 this.curve=(thetaR==0)?0:1;
 this.angle=(thetaR>0)?1:-1; // Angle : Clock =-1, Trigo=1 
 this.tStatus=refTrack.tStatus;
 this.hStatus=refTrack.hStatus;
 // println("Loco    LocoCircuit 2 - ");
 // println("cab:", cabButton.cab, "finish:", finish, "speed:", cabButton.speed, "tStatus:", tStatus, "hStatus:", hStatus, "Route:", Route); 
 // println("reftrack:", refTrack, "trackPoint:", refTrack.trackPoint, "position:", position, "angle:", angle, "curve:", curve); 
 // println("x[0]:", refTrack.x[0], "x[1]:", refTrack.x[1], "y[0]:", refTrack.y[0], "y[1]:", refTrack.y[1], "xPos:", xPos, "yPos:", yPos);
 // println("sfactor:", refTrack.layout.sFactor, "xcorner:", refTrack.layout.xCorner, "ycorner:", refTrack.layout.yCorner);
 // println("refTrack.a[1]:", refTrack.a[1], "refTrack.a[0]:", refTrack.a[0], "curveAngleDeg:", refTrack.curveAngleDeg);
 // println("refTrack.xR:", refTrack.xR, "refTrack.yR:", refTrack.yR, "Radius:", Radius, "tStatus:", tStatus, "hStatus:", hStatus);
 // println("thetaPos:", thetaPos, "thetaA:", thetaA, "thetaR:", thetaR, "thetaA+thetaR", thetaA+thetaR, "thetaA+thetaPos:", thetaA+thetaPos); 
 // println("sin(thetaPos):", sin(thetaPos), "cos(thetaPos):", cos(thetaPos));
 
 // Positionnement à la moitié du segment
 //    this.xPos=((refTrack.x[0]+refTrack.x[1])/2.0*refTrack.layout.sFactor+refTrack.layout.xCorner);
 //    this.yPos=((refTrack.y[0]+refTrack.y[1])/2.0*refTrack.layout.sFactor+refTrack.layout.yCorner);
 if (tStatus == 1) {    //  tStatus == 1 track is visible
 if (hStatus == 1) {    //  hStatus == 1 track is highlighted
 if (position==1) { // Positionnement à la fin du segment
 if (curve==0) {  // Segment de droite
 this.xPos=refTrack.x[1];
 this.yPos=refTrack.y[1];
 } else {  // Segment courbe
 thetaPos=thetaA+thetaR;
 this.xPos=refTrack.xR+angle*Radius*sin(thetaPos);
 this.yPos=refTrack.yR+angle*Radius*cos(thetaPos);
 }
 }
 if (position==0) { // Positionnement au début du segment
 if (curve==0) {  // Segment de droite
 this.xPos=refTrack.x[0];
 this.yPos=refTrack.y[0];
 } else {  // Segment courbe
 thetaPos=thetaA;
 this.xPos=refTrack.xR+angle*Radius*sin(thetaPos);
 this.yPos=refTrack.yR+angle*Radius*cos(thetaPos);
 }
 }
 } else {    //  hStatus == 0 track is not highlighted
 }
 } else {    //  tStatus == 0 track is not visible
 if (hStatus == 1) {    //  hStatus == 1 track is highlighted
 } else {    // hStatus == 0 track is not highlighted
 }
 }  //  Track is not finished
 
 
 move_Loco();
 }    //  LocoCircuit
 */

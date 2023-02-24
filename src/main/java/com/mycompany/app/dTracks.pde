//////////////////////////////////////////////////////////////////////////
//  PROCESSING RAILWAY CONTROLLER: Classes for Layouts and Tracks
//      Sheet : dTracks
//
//  Layout - defines a scaled region on the screen into which tracks
//           will be place using scaled coordinates
//
//  Track  - defines a curved or straight piece of track.
//         - placement on layout can be in absolute scaled coordinates
//           or linked to one end of a previously-defined track.
//         - tracks can be linked even across separate layouts
//         - define multiple overlapping tracks to create any type
//           of turnout, crossover, or other complex track
//
// Signal  - define the traffic light
//  
// 
//////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
//    Class Layout
//////////////////////////////////////////////////////////////////////////

class Layout {
  int xCorner, yCorner;
  float sFactor;

  // Définition d'une partie de l'écran. Origine en haut à gauche : xcorner , ycorner, echelle, largeur fonction echelle, hauteur fonction echelle      

  Layout(int xCorner, int yCorner, int frameWidth, float layoutWidth, float layoutHeight) {
    this.xCorner=xCorner;
    this.yCorner=yCorner;
    sFactor=float(frameWidth)/layoutWidth;   // frameWidth in pixels, layoutWidth in mm, inches, cm, etc.
  } // Layout

  Layout(Layout layout) {
    this.xCorner=layout.xCorner;
    this.yCorner=layout.yCorner;
    this.sFactor=layout.sFactor;
  } // Layout

  void copy(Layout layout) {
    this.xCorner=layout.xCorner;
    this.yCorner=layout.yCorner;
    this.sFactor=layout.sFactor;
  } // copy

  boolean equals(Layout layout) {
    return((this.xCorner==layout.xCorner)&&(this.yCorner==layout.yCorner)&&(this.sFactor==layout.sFactor));
  } // equals
} // Layout Class

//////////////////////////////////////////////////////////////////////////
//    Class Track
//////////////////////////////////////////////////////////////////////////

class Track extends DccComponent {
  float[] x = new float[2];
  float[] y = new float[2];
  float[] a = new float[2];
  color tColor;
  float xR, yR;
  float r;
  float curveAngleDeg;
  float thetaR, thetaA;
  float aStart, aEnd;
  int trackPoint;        // specifies link with the previous track
  int tStatus=1;         // specifies current track status (0=off/not visible, 1=on/visible)
  int hStatus=0;         // specifies if current track is highlighted (1) or normal (0)
  Layout layout;

  //////////////////////////////////////////////////////////////////////////
  // Ligne droite absolue 
  //    à partir de coordonnnées : 
  //      Coordonnée en X
  //      Coordonnée en Y
  //    tLenght ==> longueur du nouveau segment
  //    Direction angle avec rotation antihoraire et 0 à droite
  //    avec layout spécifié
  //////////////////////////////////////////////////////////////////////////

  Track(Layout layout, float x, float y, float tLength, float angleDeg) {
    this.x[0]=x;
    this.y[0]=y;
    this.a[1]=angleDeg/360.0*TWO_PI;
    this.a[0]=this.a[1]+PI;
    if (this.a[0]>=TWO_PI)
      this.a[0]-=TWO_PI;
    this.x[1]=this.x[0]+cos(this.a[1])*tLength;
    this.y[1]=this.y[0]-sin(this.a[1])*tLength;
    this.layout=layout;
    this.tColor=color(255, 255, 0);
    dccComponents.add(this);
  } // Track - straight, absolute

  //////////////////////////////////////////////////////////////////////////
  // Ligne droite relative à partir de la zone précédente : 
  //    trackPoint = 1 ==> accroche à la fin du segment précédent, 
  //    trackPoint = 0 ==> accroche au début du segment précédent
  //    tLenght ==> longueur du nouveau segment
  //    avec layout spécifié
  //////////////////////////////////////////////////////////////////////////

  Track(Track track, int trackPoint, float tLength, Layout layout) {
    this.x[0]=track.x[trackPoint%2];
    this.y[0]=track.y[trackPoint%2];
    this.a[1]=track.a[trackPoint%2];
    this.a[0]=this.a[1]+PI;
    if (this.a[0]>=TWO_PI)
      this.a[0]-=TWO_PI;
    this.x[1]=this.x[0]+cos(this.a[1])*tLength;
    this.y[1]=this.y[0]-sin(this.a[1])*tLength;
    this.layout=layout;
    this.tColor=color(255, 255, 0);
    dccComponents.add(this);
  } // Track - straight, relative, Layout specified

  //////////////////////////////////////////////////////////////////////////
  // Ligne droite relative à partir de la zone précédente : 
  //    trackPoint = 1 ==> accroche à la fin du segment précédent, 
  //    trackPoint = 0 ==> accroche au début du segment précédent
  //    tLenght ==> longueur du nouveau segment
  //    sans layout spécifié
  //////////////////////////////////////////////////////////////////////////

  Track(Track track, int trackPoint, float tLength) {
    this.x[0]=track.x[trackPoint%2];
    this.y[0]=track.y[trackPoint%2];
    this.a[1]=track.a[trackPoint%2];
    this.a[0]=this.a[1]+PI;
    if (this.a[0]>=TWO_PI)
      this.a[0]-=TWO_PI;
    this.x[1]=this.x[0]+cos(this.a[1])*tLength;
    this.y[1]=this.y[0]-sin(this.a[1])*tLength;
    this.layout=track.layout;
    this.tColor=color(255, 255, 0);
    dccComponents.add(this);
  } // Track - straight, relative, no Layout specified

  //////////////////////////////////////////////////////////////////////////
  // Ligne courbe absolue : 
  //    x,y ==> Position de départ du segment horizontal (0 à gauche), vertical (0 en haut)
  //    curveRadius ==> Rayon de la courbe
  //    curveAngleDeg ==> longueur du segment en degré
  //    angleDeg ==> direction de propagation du segment (cercle trigo)
  //    avec layout spécifié
  //////////////////////////////////////////////////////////////////////////

  Track(Layout layout, float x, float y, float curveRadius, float curveAngleDeg, float angleDeg) {
    int d;
    thetaR=curveAngleDeg/360.0*TWO_PI;
    thetaA=angleDeg/360.0*TWO_PI;
    d=(thetaR>0)?1:-1;
    this.x[0]=x;
    this.y[0]=y;
    this.a[0]=thetaA+PI;
    if (this.a[0]>=TWO_PI)
      this.a[0]-=TWO_PI;
    this.a[1]=thetaA+thetaR;
    if (this.a[1]>=TWO_PI)
      this.a[1]-=TWO_PI;
    if (this.a[1]<0)
      this.a[1]+=TWO_PI;
    this.r=curveRadius;
    this.xR=this.x[0]-d*this.r*sin(thetaA);
    this.yR=this.y[0]-d*this.r*cos(thetaA);
    this.x[1]=this.xR+d*this.r*sin(thetaA+thetaR);
    this.y[1]=this.yR+d*this.r*cos(thetaA+thetaR);
    if (d==1) {
      this.aEnd=PI/2-thetaA;
      this.aStart=this.aEnd-thetaR;
    } else {
      this.aStart=1.5*PI-thetaA;
      this.aEnd=this.aStart-thetaR;
    }
    this.layout=layout;
    this.tColor=color(255, 255, 0);
    // println("Track 1 - curveRadius:",curveRadius," curveAngleDeg:",curveAngleDeg," angleDeg:",angleDeg);
    dccComponents.add(this);
  } // Track - curved, absolute

  //////////////////////////////////////////////////////////////////////////
  // Ligne courbe relative à partir de la zone précédente : 
  //    trackPoint = 1 ==> accroche à la fin du segment précédent, 
  //    trackPoint = 0 ==> accroche au début du segment précédent
  //    curveRadius ==> Rayon de la courbe
  //    curveAngleDeg ==> longueur du segment en degré
  //    avec layout spécifié
  //////////////////////////////////////////////////////////////////////////

  Track(Track track, int trackPoint, float curveRadius, float curveAngleDeg, Layout layout) {
    int d;
    thetaR=curveAngleDeg/360.0*TWO_PI;
    thetaA=track.a[trackPoint%2];
    d=(thetaR>0)?1:-1;
    this.x[0]=track.x[trackPoint%2];
    this.y[0]=track.y[trackPoint%2];
    this.a[0]=thetaA+PI;
    if (this.a[0]>=TWO_PI)
      this.a[0]-=TWO_PI;
    this.a[1]=thetaA+thetaR;
    if (this.a[1]>=TWO_PI)
      this.a[1]-=TWO_PI;
    if (this.a[1]<0)
      this.a[1]+=TWO_PI;
    this.r=curveRadius;
    this.xR=this.x[0]-d*this.r*sin(thetaA);
    this.yR=this.y[0]-d*this.r*cos(thetaA);
    this.x[1]=this.xR+d*this.r*sin(thetaA+thetaR);
    this.y[1]=this.yR+d*this.r*cos(thetaA+thetaR);
    if (d==1) {
      this.aEnd=PI/2-thetaA;
      this.aStart=this.aEnd-thetaR;
    } else {
      this.aStart=1.5*PI-thetaA;
      this.aEnd=this.aStart-thetaR;
    }
    this.layout=layout;
    this.tColor=color(255, 255, 0);
    // println("Track 2 - curveRadius:",curveRadius," curveAngleDeg:",curveAngleDeg);
    dccComponents.add(this);
  } // Track - curved, relative, Layout specified

  //////////////////////////////////////////////////////////////////////////
  // Ligne courbe relative à partir de la zone précédente : 
  //    trackPoint = 1 ==> accroche à la fin du segment précédent, 
  //    trackPoint = 0 ==> accroche au début du segment précédent
  //    curveRadius ==> Rayon de la courbe
  //    curveAngleDeg ==> longueur du segment en degré
  //    sans layout spécifié
  //////////////////////////////////////////////////////////////////////////

  Track(Track track, int trackPoint, float curveRadius, float curveAngleDeg) {
    int d;
    this.curveAngleDeg=curveAngleDeg;
    thetaR=curveAngleDeg/360.0*TWO_PI;
    thetaA=track.a[trackPoint%2];
    d=(thetaR>0)?1:-1;
    this.x[0]=track.x[trackPoint%2];
    this.y[0]=track.y[trackPoint%2];
    this.a[0]=thetaA+PI;
    if (this.a[0]>=TWO_PI)
      this.a[0]-=TWO_PI;
    this.a[1]=thetaA+thetaR;
    if (this.a[1]>=TWO_PI)
      this.a[1]-=TWO_PI;
    if (this.a[1]<0)
      this.a[1]+=TWO_PI;
    this.r=curveRadius;
    this.xR=this.x[0]-d*this.r*sin(thetaA);
    this.yR=this.y[0]-d*this.r*cos(thetaA);
    this.x[1]=this.xR+d*this.r*sin(thetaA+thetaR);
    this.y[1]=this.yR+d*this.r*cos(thetaA+thetaR);
    if (d==1) {
      this.aEnd=PI/2-thetaA;
      this.aStart=this.aEnd-thetaR;
    } else {
      this.aStart=1.5*PI-thetaA;
      this.aEnd=this.aStart-thetaR;
    }
    this.layout=track.layout;
    this.tColor=color(255, 255, 0);
    // println("Track 3 - curveRadius:",curveRadius," curveAngleDeg:",curveAngleDeg);
    dccComponents.add(this);
  } // Track - curved, relative, no Layout specified

  //////////////////////////////////////////////////////////////////////////

  void display() {

    if (tStatus==1) {                // track is visible
      if (hStatus==1)                // track is highlighted
        stroke(color(0, 255, 0));
      else
        stroke(color(255, 255, 0));
    } else {                          // track is not visible
      if (hStatus==1)                // track is highlighted
        stroke(color(255, 0, 0));
      else
        stroke(color(80, 80, 0));
    }

    strokeWeight(3);
    ellipseMode(RADIUS);
    noFill();
    if (r==0) {
      line(x[0]*layout.sFactor+layout.xCorner, y[0]*layout.sFactor+layout.yCorner, x[1]*layout.sFactor+layout.xCorner, y[1]*layout.sFactor+layout.yCorner);
      // println("TRACK DISPLAY - ", "x[0]:",x[0],"x[1]:",x[1],"y[0]:",y[0],"y[1]:",y[1]," tStatus:",tStatus,"  hStatus:",hStatus);
    } else {
      arc(xR*layout.sFactor+layout.xCorner, yR*layout.sFactor+layout.yCorner, r*layout.sFactor, r*layout.sFactor, aStart, aEnd);
      // println("TRACK DISPLAY - ", "xR:",xR,"yR:",yR," tStatus:",tStatus,"  hStatus:",hStatus);
    }
  } //  Track display()
} // Track Class


//////////////////////////////////////////////////////////////////////////

int SizeClass_R_Track() {
  int size_r_track = rTracks.size();
  return size_r_track;
}

//////////////////////////////////////////////////////////////////////////

Track getClass_R_Track(int i) {
  Track ref_r_track = rTracks.get(i);
  return ref_r_track;
}
//////////////////////////////////////////////////////////////////////////

void removeTrack(Track reftrack, int i) {
  rTracks.remove(i);
  int size = rTracks.size();
  // println ("size:", size);
}


//////////////////////////////////////////////////////////////////////////
//  Class SignalButton
//////////////////////////////////////////////////////////////////////////

class SignalButton extends DccComponent {
  boolean SignalActive=false;
  int xPos, yPos;
  int sTime;
  int kWidth, kHeight;
  int SignalStatus;
  String SignalName;
  int SignalNum;
  XML SignalButtonXML;
  MessageBox msgBoxSignal;

  SignalButton(int xPos, int yPos, int kWidth, int kHeight, int SignalStatus, int SignalNum) {
    this.xPos=xPos;
    this.yPos=yPos;
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    this.SignalStatus=SignalStatus;
    this.SignalNum=SignalNum;
    SignalName="Signal"+SignalNum;
    componentName=SignalName;    
    SignalButtonXML=SignalButtonsXML.getChild(SignalName);
    if (SignalButtonXML==null) {
      SignalButtonXML=SignalButtonsXML.addChild(SignalName);
      SignalButtonXML.setContent(str(SignalActive));
    } else {
      SignalActive=boolean(SignalButtonXML.getContent());
    }
    SignalsHM.put(SignalNum, this);
    if (SignalNum<20) {
      msgBoxSignal=new MessageBox(SignalWindow1, 10, SignalNum*22+20, -1, 0, color(175), 18, "Sig-"+nf(SignalNum, 2)+":", color(50, 50, 250));
    } else {
      msgBoxSignal=new MessageBox(SignalWindow2, 10, SignalNum*22-394, -1, 0, color(175), 18, "Sig-"+nf(SignalNum, 2)+":", color(50, 50, 250));
    }  
    dccComponents.add(this);
  } // SignalButton

  //////////////////////////////////////////////////////////////////////////

  void display() {

    ellipseMode(CENTER);
    if (SignalStatus==1) {                // Green Signal is visible
      fill(color(0, 255, 0));
    }
    if (SignalStatus==2) {        // Red Signal is visible
      fill(color(255, 0, 0));
    }
    if (SignalStatus==3) {        // Yellow Signal is visible
      fill(color(255, 255, 0));
    }
    noStroke();
    ellipse(xPos, yPos, kWidth/2, kHeight/2);
  } //  SignalButton display()

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    SignalStatus=SignalStatus+1;
    if (SignalStatus==4) {
      SignalStatus=1;
    } 
    autoPilot.process(SignalNum, SignalActive);
    SignalButtonXML.setContent(str(SignalActive));
    saveXMLFlag=true;
    if (SignalActive) {
      msgBoxSignal.setMessage("Sig-"+nf(SignalNum, 2)+": "+nf(hour(), 2)+":"+nf(minute(), 2)+":"+nf(second(), 2)+" - "+nf((millis()-sTime)/1000.0, 0, 1)+" sec"+" - Status:"+SignalStatus);
      sTime=millis();
    }
  } //  SignalButton pressed

  //////////////////////////////////////////////////////////////////////////

  void reset() {
    pressed();
    SignalStatus=2;
  } //  SignalButton reset

  //////////////////////////////////////////////////////////////////////////

  void check() {
    if (selectedComponent==null && (mouseX-xPos)*(mouseX-xPos)/(kWidth*kWidth/4.0)+(mouseY-yPos)*(mouseY-yPos)/(kHeight*kHeight/4.0)<=1) {
      cursorType=HAND;
      selectedComponent=this;
    }
  } //  SignalButton check
} // SignalButton Class

//////////////////////////////////////////////////////////////////////////

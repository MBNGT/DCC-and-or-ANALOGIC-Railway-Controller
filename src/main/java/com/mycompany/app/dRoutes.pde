////////////////////////////////////////////////////////////////////////// //<>// //<>// //<>//
//  PROCESSING RAILWAY CONTROLLER: Class for Route Button
//      Sheet : dRoutes
//
//  RouteButton  -  creates a button to activate one or more Track Buttons
//                  that in turn set one or more TURNOUTS or CROSSOVERS to either an
//                  open or closed position representing a specific track route
//               -  tracks may also be added to a route button so that they are highlighted
//                  on the screen when the route button is first selected
//               -  track highlights will be color-coded to indicate whether each
//                  turnout or crossover that in in the route is already set properly,
//                  or needs to be toggled if that route is activiated
//
//               -  two types of route buttons are supported:
//
//                  * large stand-alone button with a text label indicated the name of the route
//                  * small button placed on a track where the route is obvious and does
//                    not require a name (such as at the end of a siding)
//
//////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
//    Class RouteButton
//////////////////////////////////////////////////////////////////////////

class RouteButton extends DccComponent {
  int xPos, yPos;
  int kWidth, kHeight;
  String label="";
  boolean routeOn=false;
  ArrayList<TrackButton> aTrackButtons = new ArrayList<TrackButton>(); // dTurnouts list with tPos=0 ==> activ
  ArrayList<TrackButton> bTrackButtons = new ArrayList<TrackButton>(); // dTurnouts list with tPos=1 ==> non activ
  ArrayList<Track> rTracks = new ArrayList<Track>(); // Tracks list

  RouteButton(Track refTrack, int kWidth, int kHeight) {
    this.xPos=int((refTrack.x[0]+refTrack.x[1])/2.0*refTrack.layout.sFactor+refTrack.layout.xCorner);
    this.yPos=int((refTrack.y[0]+refTrack.y[1])/2.0*refTrack.layout.sFactor+refTrack.layout.yCorner);
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    //    this.locoButtons=locoButtons;
    //    this.finish=locoButtons.finish;
    dccComponents.add(this);
  }

  RouteButton(int xPos, int yPos, int kWidth, int kHeight, String label) {
    this.xPos=xPos;
    this.yPos=yPos;
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    this.label=label;
    dccComponents.add(this);
  } // RouteButton

  //////////////////////////////////////////////////////////////////////////
  //  addTrackButton needed to add right way and deviant way of turnout
  //////////////////////////////////////////////////////////////////////////
  
  void addTrackButton(TrackButton trackButton, int tPos) {
    if (tPos==0) {                       // specifies that this track button should be set to A when route selected
      aTrackButtons.add(trackButton);
      trackButton.aRouteButtons.add(this);
    } else if (tPos==1) {              // specifies that this track button should be set to B when route selected
      bTrackButtons.add(trackButton);
      trackButton.bRouteButtons.add(this);
    }
  }  //  RouteButton addTrackButton

  //////////////////////////////////////////////////////////////////////////
  
  void addTrack(Track track) {    //  Add track to a route
    rTracks.add(track);
  }  //  RouteButton addTrack

  //////////////////////////////////////////////////////////////////////////
  
  void display() {    
    if (label.equals("")) {
      ellipseMode(CENTER);
      if (routeOn)
        fill(color(0, 255, 0)); // Green color
      else
        fill(color(0, 150, 0)); // Green color
      noStroke();
      ellipse(xPos, yPos, kWidth/2, kHeight/2);
    } else {
      ellipseMode(CENTER);
      if (routeOn)
        fill(color(0, 200, 200)); // blue color
      else
        fill(color(0, 100, 100)); // blue color
      noStroke();
      ellipse(xPos, yPos, kWidth, kHeight);
      textFont(buttonFont, 12);
      textAlign(CENTER, CENTER);
      fill(color(0));             // black color
      text(label, xPos, yPos);
    }
  }  //  RouteButton display

  //////////////////////////////////////////////////////////////////////////
  
  void check() {
    if (selectedComponent==null && (mouseX-xPos)*(mouseX-xPos)/(kWidth*kWidth/4.0)+(mouseY-yPos)*(mouseY-yPos)/(kHeight*kHeight/4.0)<=1) {
      cursorType=HAND;
      selectedComponent=this;
      //println("RouteButton      CHECK 1 - ");
      //println("selectedComponent:", selectedComponent, " aTrackButtons:", aTrackButtons, " bTrackButtons:", bTrackButtons, " rTracks:", rTracks);
      for (Track track : rTracks) {
        track.hStatus=1;
      }
    } else if (previousComponent==this) {
      //println("RouteButton      CHECK 2 - ");
      //println("selectedComponent:", selectedComponent, " aTrackButtons:", aTrackButtons, " bTrackButtons:", bTrackButtons, " rTracks:", rTracks);
      for (Track track : rTracks) {
        track.hStatus=0;
      }
    }
  }  //  RouteButton check

  //////////////////////////////////////////////////////////////////////////
  
  void pressed() {
    for (TrackButton trackButton : aTrackButtons) {
      if (trackButton.rEnabled)
        trackButton.pressed(0);
      //println("RouteButton      PRESSED 1 - ");
      //println("routeOn:", routeOn, " aTrackButtons:", aTrackButtons, " bTrackButtons:", bTrackButtons, " rTracks:", rTracks, " rEnabled:", trackButton.rEnabled);
    }
    for (TrackButton trackButton : bTrackButtons) {
      if (trackButton.rEnabled)
        trackButton.pressed(1);
      //println("RouteButton      PRESSED 2 - ");
      //println("routeOn:", routeOn, " aTrackButtons:", aTrackButtons, " bTrackButtons:", bTrackButtons, " rTracks:", rTracks, " rEnabled:", trackButton.rEnabled);
    }
    routeOn=true;
    //println("routeOn:", routeOn, " aTrackButtons:", aTrackButtons, " bTrackButtons:", bTrackButtons, " rTracks:", rTracks);
  }  //  RouteButton pressed

  //////////////////////////////////////////////////////////////////////////
  
  void shiftPressed() {
    for (TrackButton trackButton : aTrackButtons) {
      if (trackButton.rEnabled)
        trackButton.pressed(1);
      //println("RouteButton      PRESSED 3 - ");
      //println("routeOn:", routeOn, " aTrackButtons:", aTrackButtons, " bTrackButtons:", bTrackButtons, " rTracks:", rTracks, " rEnabled:", trackButton.rEnabled);
    }
    for (TrackButton trackButton : bTrackButtons) {
      if (trackButton.rEnabled)
        trackButton.pressed(0);
      //println("RouteButton      PRESSED 4 - ");
      //println("routeOn:", routeOn, " aTrackButtons:", aTrackButtons, " bTrackButtons:", bTrackButtons, " rTracks:", rTracks, " rEnabled:", trackButton.rEnabled);
    }
    routeOn=false;
    println("routeOn:", routeOn, " aTrackButtons:", aTrackButtons, " bTrackButtons:", bTrackButtons, " rTracks:", rTracks);
  }  //  RouteButton shiftPressed
} // RouteButton Class

//////////////////////////////////////////////////////////////////////////

int SizeClass_A_RouteButton() {
  int size_a_routebutton = aRouteButtons.size();
  return size_a_routebutton;
}


//////////////////////////////////////////////////////////////////////////

int SizeClass_B_RouteButton() {
  int size_b_routebutton = bRouteButtons.size();
  return size_b_routebutton;
}

//////////////////////////////////////////////////////////////////////////

RouteButton getClass_A_RouteButton(int i) {
  RouteButton ref_a_routebutton = aRouteButtons.get(i);
  return ref_a_routebutton;
}

//////////////////////////////////////////////////////////////////////////

RouteButton getClass_B_RouteButton(int i) {
  RouteButton ref_b_routebutton = bRouteButtons.get(i);
  return ref_b_routebutton;
}

//////////////////////////////////////////////////////////////////////////

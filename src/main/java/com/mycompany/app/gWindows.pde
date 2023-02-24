//////////////////////////////////////////////////////////////////////////
//  PROCESSING RAILWAY CONTROLLER: Generic Windows
//      Sheet : gWindows
//
//  Window      -  creates a window box of a specified size, color, and
//                 initial position into which other components can be placed
//                 such as buttons, message boxes, and text boxes
//
//  DragBar     -  creates a drag bar on window to allow it to be dragged
//                 across screen
//
//  CloseButton -  creates close button on window that closes window box
//              -  windows are normally opened by other buttons or key commands
//                 defined elsewhere
//
//  ImageWindow -  extends Window to create a window bx into which
//                 a single cab image tied to a specified throttle will be displayed
//
//  JPGWindow   -  extends Window to create a generic window box for diplaying a single jpg image
//
//////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
//    Class Window
//////////////////////////////////////////////////////////////////////////

class Window extends DccComponent{
  int xPos, yPos;
  int kWidth, kHeight;
  color backgroundColor;
  color outlineColor;
  
  ArrayList<DccComponent> windowComponents = new ArrayList<DccComponent>();
  
  Window(int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color outlineColor){
    this.xPos=xPos;
    this.yPos=yPos;
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    this.backgroundColor=backgroundColor;
    this.outlineColor=outlineColor;
  } // Window

//////////////////////////////////////////////////////////////////////////

  void display(){

    rectMode(CORNER);
    fill(backgroundColor);
    strokeWeight(3);
    stroke(outlineColor);
    rect(xPos,yPos,kWidth,kHeight);    
  }  //  Window display

//////////////////////////////////////////////////////////////////////////

  void check(){
    if(selectedComponent==null && (mouseX>xPos)&&(mouseX<xPos+kWidth)&&(mouseY>yPos)&&(mouseY<yPos+kHeight)){
      selectedComponent=this;
    }
  }  //  Window check
  
//////////////////////////////////////////////////////////////////////////

  void pressed(){
    close();
    open();
  }  //  Window pressed
  
//////////////////////////////////////////////////////////////////////////

  void toggle(){
    if(dccComponents.contains(this))
      close();
    else
      open();      
  }  //  Window toggle
    
//////////////////////////////////////////////////////////////////////////

  void open(){
    if(dccComponents.contains(this))
      return;
      
    dccComponents.add(this);                                /// adds window and components to end of dccComponents --- will display last on top
    for(DccComponent windowComponent : windowComponents)
      dccComponents.add(windowComponent);      
  }  //  Window open
    
//////////////////////////////////////////////////////////////////////////

  void show(){
    if(dccComponents.contains(this))
      return;
      
    for(DccComponent windowComponent : windowComponents)
      dccComponents.add(0,windowComponent);      
    dccComponents.add(0,this);                               // adds window and components to start of dccComponents --- will display first on bottom
  }  //  Window show

//////////////////////////////////////////////////////////////////////////

  void close(){
    if(!dccComponents.contains(this))
      return;

    for(DccComponent windowComponent : windowComponents)
      dccComponents.remove(windowComponent);      
    dccComponents.remove(this);
  }  //  Window close
    
} // Window Class

//////////////////////////////////////////////////////////////////////////
//  Class DragBar
//////////////////////////////////////////////////////////////////////////

class DragBar extends DccComponent{
  int xPos, yPos;
  int kWidth, kHeight;
  color backgroundColor;
  Window window;
  int xDrag, yDrag;
  
  DragBar(Window window, int xPos, int yPos, int kWidth, int kHeight, color backgroundColor){
    this.window=window;
    this.xPos=xPos;
    this.yPos=yPos;
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    this.backgroundColor=backgroundColor;
    window.windowComponents.add(this);
  } // DragBar

//////////////////////////////////////////////////////////////////////////

  void display(){
    rectMode(CORNER);
    fill(backgroundColor);
    noStroke();
    rect(xPos+window.xPos,yPos+window.yPos,kWidth,kHeight);    
  }  //  DragBar display

//////////////////////////////////////////////////////////////////////////

  void check(){
    if(selectedComponent==null && (mouseX>xPos+window.xPos)&&(mouseX<xPos+window.xPos+kWidth)&&(mouseY>yPos+window.yPos)&&(mouseY<yPos+window.yPos+kHeight)){
      cursorType=MOVE;
      selectedComponent=this;
    }
  }  //  DragBar check
  
//////////////////////////////////////////////////////////////////////////

  void pressed(){
    window.close();
    window.open();
    xDrag=mouseX-window.xPos;
    yDrag=mouseY-window.yPos;
    cursor(ARROW);
  }  //  DragBar pressed
  
//////////////////////////////////////////////////////////////////////////

  void drag(){
    window.xPos=mouseX-xDrag;
    window.yPos=mouseY-yDrag;
  }  //  DragBar drag
  
} // DragBar Class

//////////////////////////////////////////////////////////////////////////
//  Class CloseButton
//////////////////////////////////////////////////////////////////////////

class CloseButton extends DccComponent{
  int xPos, yPos;
  int kWidth, kHeight;
  color backgroundColor;
  color lineColor;
  Window window;
  
  CloseButton(Window window, int xPos, int yPos, int kWidth, int kHeight, color backgroundColor, color lineColor){
    this.window=window;
    this.xPos=xPos;
    this.yPos=yPos;
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    this.backgroundColor=backgroundColor;
    this.lineColor=lineColor;
    window.windowComponents.add(this);
  } // CloseButton

//////////////////////////////////////////////////////////////////////////

  void display(){
    rectMode(CORNER);
    fill(backgroundColor);
    stroke(lineColor);    
    strokeWeight(1);
    rect(xPos+window.xPos,yPos+window.yPos,kWidth,kHeight);
    line(xPos+window.xPos,yPos+window.yPos,xPos+window.xPos+kWidth,yPos+window.yPos+kHeight);
    line(xPos+window.xPos,yPos+window.yPos+kHeight,xPos+window.xPos+kWidth,yPos+window.yPos);   
  }  //  CloseButton display

//////////////////////////////////////////////////////////////////////////

  void check(){
    if(selectedComponent==null && (mouseX>xPos+window.xPos)&&(mouseX<xPos+window.xPos+kWidth)&&(mouseY>yPos+window.yPos)&&(mouseY<yPos+window.yPos+kHeight)){
      cursorType=HAND;
      selectedComponent=this;
    }
  }  //  CloseButton check
  
//////////////////////////////////////////////////////////////////////////

  void pressed(){
    window.close();
  }  //  CloseButton pressed
  
} // CloseButton Class

//////////////////////////////////////////////////////////////////////////
//  Class ImageWindow
//////////////////////////////////////////////////////////////////////////

class ImageWindow extends Window{
  PImage img;
  Throttle throttle;
  int w,h;
    
  ImageWindow(Throttle throttle, int w, int h, int xPos, int yPos, color outlineColor){
    super(xPos, yPos, w, h, color(255), outlineColor);
    new DragBar(this,0,0,w,10,outlineColor);
    new CloseButton(this,w-12,0,10,10,outlineColor,color(255,255,255));
    this.throttle=throttle;
    this.w=w;
    this.h=h;    
  } // ImageWindow

//////////////////////////////////////////////////////////////////////////

  void display(){
    super.display();
    if(throttle.cabButton==null){
      textAlign(CENTER,CENTER);
      fill(color(200,0,0));
      textFont(messageFont,20);
      text("PLEASE SELECT CAB TO DISPLAY IMAGE",xPos+w/2,yPos+h/2);
    } else if(throttle.cabButton.cabImage==null){
      textAlign(CENTER,CENTER);
      fill(color(200,0,0));
      textFont(messageFont,20);
      text("NO IMAGE FILE FOUND FOR THIS CAB",xPos+w/2,yPos+h/2);
    } else{ 
      imageMode(CORNER);
      image(throttle.cabButton.cabImage,xPos,yPos,w,h);
    }
    
  }  // ImageWindow display
    
} // ImageWindow Class

//////////////////////////////////////////////////////////////////////////
//  Class JPGWindow
//////////////////////////////////////////////////////////////////////////

class JPGWindow extends Window{
  PImage img;
  int w,h;
    
  JPGWindow(String JPGFile, int w, int h, int xPos, int yPos, color outlineColor){
    super(xPos, yPos, w, h, color(255), outlineColor);
    new DragBar(this,0,0,w,10,outlineColor);
    new CloseButton(this,w-12,0,10,10,outlineColor,color(255,255,255));
    img=loadImage(JPGFile);
    this.w=w;
    this.h=h;    
  } // JPGWindow

//////////////////////////////////////////////////////////////////////////

  void display(){
    super.display();
    imageMode(CORNER);
    image(img,xPos,yPos,w,h);
  }  //  JPGWindow display
    
} // JPGWindow Class

//////////////////////////////////////////////////////////////////////////

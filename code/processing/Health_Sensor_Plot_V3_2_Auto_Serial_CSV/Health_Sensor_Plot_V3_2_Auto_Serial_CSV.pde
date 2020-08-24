// Base on ArduinoScope 
// ###################################################################################
// # Project: ECG Health Sensor Plots
// # Engineer:  Mic.Tsai
// # Date:  10 June 2020
// # Objective: Dev.board
// # Usage: ESP8266
// # Modified: Mode Select with filter and PPG
// ###################################################################################

import java.io.BufferedWriter;
import java.io.FileWriter;
String outFilename = "/Users/mic/Desktop/ECG+PPG_Data.csv";


import processing.serial.*;
Serial ArduinoPort;  // Create object from Serial class
 
int NumOfScopes,NumOfInput=2;
int data_span=10000;
Strage dfs = new Strage();
Scope[] sp;
 
int fontsize=16;
PFont myFont;
PFont myFont2;
PFont myFont3;
 
//============================= # ECG BPM calculate 
int LastTimeECG=0;
int ThisTimeECG; 
float inByteECG = 0;
int BPMECG = 0;
int beat_oldECG = 0;
float[] beatsECG = new float[500];  // Used to calculate average BPM
int averagebuffervalueecg=5;
int beatIndexECG;
boolean belowThresholdECG = true; 

int valssECG;
int timestampAllECG;
 
boolean BPMTimingECG=false;
boolean BeatCompleteECG=false;

float beatsPerMinuteECG;
int beatAvgECG;
int averageECG = 0;
 
//============================= # ECG BPM calculate 

//============================= # PPG BPM calculate 
int LastTime=0;
int ThisTime; 
float inByte = 0;
int BPM = 0;
int beat_old = 0;
float[] beats = new float[500];  // Used to calculate average BPM
int averagebuffervalueppg=5;
int beatIndex;
boolean belowThreshold = true; 

int valssPPG;
int timestampAll;
 
boolean BPMTiming=false;
boolean BeatComplete=false;

float beatsPerMinute;
int beatAvg;
int averageppg = 0;

//============================= # PPG BPM calculate 

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Set ECG Limit>>>>>>>
// # ECG limit
float UpperThresholdECG = 750  ;
float LowerThresholdECG = 0  ;
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Set ECG Limit>>>>>>>

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Set PPG Limit>>>>>>>
// # PPG limit
float UpperThreshold = 100  ;
float LowerThreshold = 0  ;
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Set PPG Limit>>>>>>>

void setup() 
{
 //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Set COM PORT Here>>>>>>>
  boolean portNr = activateSerialPort("tty.usbserial", 38400);  // Search Phrase and speed
  ArduinoPort.bufferUntil(10);
 //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Set COM PORT Here>>>>>>>

 //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Set Screen Here>>>>>>>
  // Screen
  size(800, 500);
  //size(700, 500);
 //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Set Screen Here>>>>>>>

  NumOfScopes=2;
  sp = new Scope[NumOfScopes];
  sp[0]= new Scope(0,50,10,width-100,height/2-35,1500,-1500,1000,10);
  sp[1]= new Scope(1,50,height/2+15,width-100,height/2-35,300,-300,1000,10);
 
  myFont = loadFont("Helvetica-Light-15.vlw");
  myFont2 = loadFont("Helvetica-LightOblique-20.vlw");
  myFont3 = loadFont("Helvetica-BoldOblique-72.vlw");
  textFont(myFont,fontsize);  
}



boolean activateSerialPort(String partOfPortName, int SerialSpeed) {
  boolean portIsActivated = false;
  int portIndex = -1;
  
  for(int i = 0; i < Serial.list().length; i++) {   // go thru all serial ports
    print(i);    
    
    if(Serial.list()[i].indexOf(partOfPortName) > 0) { // chech if name match
      portIndex = i;
      print("*");
    }
    println("\t" + Serial.list()[i]);
  }
  
  if(portIndex < 0 ) {
    println("Error: No serial port found - " + partOfPortName);
  }else{
    ArduinoPort = new Serial(this, Serial.list()[portIndex], SerialSpeed);
    println("Serial conection: " + Serial.list()[portIndex] + " speed: " + SerialSpeed);  // activate
  }
  return portIsActivated;  
}

 
class Scope{
  int input_id;    // corresponding input
  int posx,posy;   // screen position of the scope
  int sizex,sizey; // pixel size of the scope
  float yu,yl;     // range of y is [yl,yu]
  int tspan;       //
  int tspany;       //
  int ngx,ngy; // number of grids
  float maxposx,maxposy,minposx,minposy,maxx,minx,maxy,miny;
 
  Scope(int did,int px,int py,int sx,int sy,float syu,float syl,int ts,int ts2){
    input_id=did;
    posx=px; 
    posy=py;
    sizex=sx; 
    sizey=sy;
    yu=syu; 
    yl=syl;
    tspan=ts;
    tspany=ts2; //add x
    ngx=10; 
    ngy=4;
  }
 
  void grid(){
    pushStyle();
    fill(255,196);
    stroke(0,0,150);
    for(float gx=sizex; gx>=0; gx-= (float)sizex/ngx){
      line(posx+gx,posy,posx+gx,posy+sizey);
      textAlign(CENTER,TOP);
      text((int)map(gx,sizex,0,0,-tspan),posx+gx,posy+sizey+2);    
    }
    for(float gy=sizey; gy>=0; gy-= (float)sizey/ngy){
      line(posx,posy+gy,posx+sizex,posy+gy);
      textAlign(RIGHT,CENTER);
      text((int)map(gy,0,sizey,yu,yl),posx,posy+gy);    
    }
    popStyle(); 
  }
 
  int curx,cury;
 
  // draw cursor
  void cur()
  {
    // return if mouse cursor is not in this scope
    if(constrain(mouseX,posx,posx+sizex)!=mouseX 
      || constrain(mouseY,posy,posy+sizey)!=mouseY) return;
 
    pushStyle();
 
    // draw cross cursor
    stroke(255,0,0,196);
    fill(255,0,0,196);
    line(mouseX,posy,mouseX,posy+sizey);
    line(posx,mouseY,posx+sizex,mouseY);
 
    // draw measure if mouse is dragged
    if(mousePressed){
      line(curx,posy,curx,posy+sizey);
      line(posx,cury,posx+sizex,cury);
      textAlign(RIGHT,BOTTOM);
      text((int)map(curx,posx,posx+sizex,-tspan,0)+"ms, "+(int)map(cury,posy,posy+sizey,yu,yl),curx,cury);
      textAlign(LEFT,TOP); 
      text("("+nfp((int)map(mouseX-curx,0,sizex,0,tspan),1)+"ms, "+nfp((int)map(mouseY-cury,0,sizey,0,-(yu-yl)),1)+")\n"+nf(1000/map(mouseX-curx,0,sizex,0,tspan),1,2)+"Hz\n"+nf(TWO_PI*1000/map(mouseX-curx,0,sizex,0,tspan),1,2)+"rad/sec",mouseX,mouseY+2);
    }
    else{
      curx=mouseX;
      cury=mouseY;
      textAlign(RIGHT,BOTTOM);
      text((int)map(curx,posx,posx+sizex,-tspan,0)+"ms, "+(int)map(cury,posy,posy+sizey,yu,yl),curx,cury);
    }
    popStyle();
  }
 
  // draw min&max tick
  void minmax(){
    pushStyle();
    fill(255,128);
    stroke(0,0,100);
    textAlign(RIGHT,CENTER);
    line(posx,maxposy,posx+sizex,maxposy);
    text((int)maxy,posx,maxposy); 
    line(posx,minposy,posx+sizex,minposy);
    text((int)miny,posx,minposy); 
    textAlign(LEFT,CENTER);
    textAlign(CENTER,TOP);
    text("max",maxposx,maxposy); 
    textAlign(CENTER,BOTTOM);
    text("min",minposx,minposy+20); 
    popStyle();
  }
 
  // draw scope
  void Plot(){
    
    float sx,sy,ex,ey;
    int nof=0;
    DataFrame df_last = dfs.get(0);
 
    maxy=-1e10; // -inf
    miny=1e10;  // +inf
 
    // draw background (for transparency)
    pushStyle();
    noStroke();
    fill(0,0,64,64);
    rect(posx,posy,sizex,sizey);
    popStyle();
 
    // draw data plot
    pushStyle();
    stroke(0,255,0);
    smooth();
    strokeWeight(1);
    for(int idx=0;(dfs.get(idx).t>max(df_last.t-tspan,0)) && -idx<data_span;idx--){
      DataFrame df_new=dfs.get(idx);
      DataFrame df_old=dfs.get(idx-1);
      sx=(float) map(df_new.t, df_last.t, df_last.t - tspan, posx+sizex,posx);
      ex=(float) map(df_old.t, df_last.t, df_last.t - tspan, posx+sizex,posx);
//===================================================================================================================== tspan
      sy=(float) map((float)df_new.v[input_id],(float) yu,(float) yl,(float) posy- tspany,(float) posy+sizey+ tspany);
      ey=(float) map((float)df_old.v[input_id],(float) yu,(float) yl,(float) posy- tspany,(float) posy+sizey+ tspany);
      
 //     sy=(float) map((float)df_new.v[input_id],(float) yu,(float) yl,(float) posy,(float) posy+sizey );
 //     ey=(float) map((float)df_old.v[input_id],(float) yu,(float) yl,(float) posy,(float) posy+sizey );
//===================================================================================================================== tspan
      if(ex<posx){
        ey+=(sy-ey)*(posx-ex)/(sx-ex);
        ex=posx;
      }
      line(sx,sy,ex,ey);
      maxy=max(maxy,df_new.v[input_id]);
      if(maxy==df_new.v[input_id]){
        maxposx=sx;
        maxposy=sy;
      }
      miny=min(miny,df_new.v[input_id]);
      if(miny==df_new.v[input_id]){
        minposx=sx;
        minposy=sy;
      }
      nof++;
    }
    popStyle();
    //    minmax();    
    // draw current value of input
    pushStyle();
    textAlign(LEFT,CENTER);
    stroke(0,0,64);
    fill(0,255,0,196);
 //   text(df_last.v[input_id],posx+sizex,map(df_last.v[input_id], yu, yl, posy, posy+sizey ));
    text(df_last.v[input_id],posx+sizex,map(df_last.v[input_id], yu, yl, posy- tspany, posy+sizey+ tspany ));
    popStyle();   
 
    grid();
    cur();   
    
  }
}
 
void draw() 
{ 
  background(0);
 
  for(int i=0;i<NumOfScopes;i++){
    sp[i].Plot();
  }
  
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Draw Data View>>>>>>>

  textSize(14); 

/*
  //# Raw Data check
  text(beatsPerMinuteECG , width -600, 25);
  text(valssECG , width -600, 45);
  text(ThisTime , width -600, 65);
*/

  //# ECG Part
  text( "/" ,        width-46, 220);
  text( BPMECG ,        width-40, 220);
  
  textFont(myFont2,16);
  textSize(16); text( "Avg" , width-163, 200);
  textSize(20); text( "BPM:" , width-165, 220);
  textFont(myFont3,16);
  textSize(50); text( averageECG , width-110, 220);
  textSize(25); text("ECG" , width -430, 32);

  textFont(myFont,16);


  //# PPG Part
  text( "/" ,        width-46, 475);
  text( BPM ,        width-40, 475);
   
  textFont(myFont2,16);
  textSize(16); text( "Avg" , width-163, 455);
  textSize(20); text( "BPM:" , width-165, 475);
  textFont(myFont3,16);
  textSize(50); text( averageppg , width-110, 475);
  textSize(25); text("PPG" , width -430, 286);

  textFont(myFont,14);


  appendTextToFile(outFilename, "Time:" + "," + millis() + "," 
  
  + "ECG:" + "," + valssECG + "," + "ECG_BPM:" + "," + averageECG + ","
  
  + "PPG:" + "," + valssPPG + "," + "PPG_BPM:" + "," + averageppg + ","
  
  );

        
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Draw Data View>>>>>>>
}



 //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Save CSV>>>>>>>

 
 /**
 * Appends text to the end of a text file located in the data directory, 
 * creates the file if it does not exist.
 * Can be used for big files with lots of rows, 
 * existing lines will not be rewritten
 */
void appendTextToFile(String filename, String text){
  File f = new File(dataPath(filename));
  if(!f.exists()){
    createFile(f);
  }
  try {
    PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(f, true)));
    out.println(text);
    out.close();
  }catch (IOException e){
      e.printStackTrace();
  }
}
 
 /**
 * Creates a new file including all subfolders
 */
void createFile(File f){
  File parentDir = f.getParentFile();
  try{
    parentDir.mkdirs(); 
    f.createNewFile();
  }catch(Exception e){
    e.printStackTrace();
  }
} 
 
 //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Save CSV>>>>>>>

 
// input data buffer class
// (now using ring buffer)
class Strage{
  int cur;
  DataFrame[] DataFrames;
 
  Strage(){
    cur=0;
    DataFrames=new DataFrame[data_span];
    for(int idx=0;idx<data_span;idx++){
      int ret_v[] = new int[NumOfInput];
      DataFrames[idx] = new DataFrame(0,ret_v);
    }
  }
 
  void push(DataFrame d){
    cur = ((cur+1) %data_span);
    DataFrames[cur]=d;
  }
 
  DataFrame get(int idx)
  {
    int num=(cur+idx);
    for(; num<0; num+= data_span);
    return((DataFrame) DataFrames[num]);
  }
 
 /*
  void save()
  {
    String savePath = selectOutput();  // Opens file chooser
    if (savePath == null) {
      // If a file was not selected
      println("No output file was selected...");
    }else{
      PrintWriter output;
      output = createWriter(savePath); 
      DataFrame df_last = this.get(0);
      for(int idx=0;-idx<data_span;idx--){
        if(this.get(idx).t==0) break;
        output.print(this.get(idx).t-df_last.t);
        for(int k=0;k<NumOfInput;k++){
          output.print(","+this.get(idx).v[k]);
        } 
        output.println("");
      }
      output.flush();
      output.close();
    }
  }
  */
  
}
 
class DataFrame{
  int t;
  int[] v;
  DataFrame(int st, int[] sv){
    t=st;
    v=sv.clone();
  }
}
 
boolean isactive=true;
 
// buffering data from serial port
void serialEvent(Serial myPort)
{
  int[] vals=new int[NumOfInput];
  int timestamp;
  int[] splitdata;
  if( myPort.available() > 0) { 
    String datline=myPort.readString();
    splitdata=parseInt(datline.split(","));
    if((splitdata.length==NumOfInput+2)){
        timestamp=splitdata[0];
        for(int idx=0;idx<NumOfInput;idx++){
          vals[idx]=splitdata[idx+1];
        }

      valssECG = vals[0];
      valssPPG = vals[1];
      
      timestampAll = splitdata[0];
      timestampAllECG = splitdata[0];
      
      ThisTime=timestampAll;
      ThisTimeECG=timestampAllECG;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ECG BPM calculate
    // ECG BPM calculation check
    if(valssECG<LowerThresholdECG && isactive)
    {
      if(BeatCompleteECG)
      {
      int BPMBUFFECG =ThisTimeECG-LastTimeECG;
      BPMECG=  int(60/(float(BPMBUFFECG)/1000));
      BPMTimingECG=false;
      BeatCompleteECG=false;  
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Average ECG calculate

        float currentBPMECG = BPMECG;    // convert to beats per minute
        beatsECG[beatIndexECG] = currentBPMECG;  // store to array to convert the average
        float totalECG = 0.0;
        for (int i = 0; i < averagebuffervalueecg; i++){
          totalECG += beatsECG[i];
        }
        int averageppgbuffECG = int(totalECG / averagebuffervalueecg);
        beatIndexECG = (beatIndexECG + 1) % averagebuffervalueecg;  
        
        if (averageppgbuffECG < 120 && averageppgbuffECG >= 45)
          {
            averageECG = averageppgbuffECG;
          }     
          
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Average ECG calculate   
      }
      if(BPMTimingECG==false)
      {
        LastTimeECG=timestampAllECG;
        BPMTimingECG=true;
      }
    }
    if((valssECG>UpperThresholdECG)&(BPMTimingECG))
      BeatCompleteECG=true;

   // beatsPerMinuteECG = BPMECG;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ECG BPM calculate


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PPG BPM calculate
    // PPG BPM calculation check
    if(valssPPG<LowerThreshold && isactive)
    {
      if(BeatComplete)
      {
      int BPMBUFF =ThisTime-LastTime;
      BPM=  int(60/(float(BPMBUFF)/1000));
      BPMTiming=false;
      BeatComplete=false;  
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Average PPG calculate
        float currentBPM = BPM;    // convert to beats per minute
        beats[beatIndex] = currentBPM;  // store to array to convert the average
        float total = 0.0;
        for (int i = 0; i < averagebuffervalueppg; i++){
          total += beats[i];
        }
        int averageppgbuff = int(total / averagebuffervalueppg);
        beatIndex = (beatIndex + 1) % averagebuffervalueppg;  // cycle through the array instead of using FIFO queue
        
        if (averageppgbuff < 120 && averageppgbuff >= 45)
          {
            averageppg = averageppgbuff;
          }
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Average PPG calculate   
      }
      if(BPMTiming==false)
      {
        LastTime=timestampAll;
        BPMTiming=true;
      }
    }
    if((valssPPG>UpperThreshold)&(BPMTiming))
      BeatComplete=true;

    //beatsPerMinute = BPM;
    
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PPG BPM calculate

      if(isactive){
        if((timestamp-dfs.get(0).t)<0){
          dfs.cur--;
        }
        if((timestamp-dfs.get(0).t) > ((float)sp[0].tspan / sp[0].sizex/2.0) ){
          dfs.push( new DataFrame(timestamp,vals));
        }
      }

    }
  }
}
 
// keyboard user interface
void keyPressed(){
  switch(key){
    // activate/deactivate scope update
  case ' ':
    isactive=!isactive;
    break;
    // save record
  case 's':
 //   dfs.save();
    break;
  case CODED:
    switch(keyCode){
      // Increse time span
    case RIGHT:
      for(int i=0;i<NumOfScopes;i++){
        sp[i].tspan*=2;
      }
      break;
      // Decrease time span
    case LEFT:
      for(int i=0;i<NumOfScopes;i++){
        sp[i].tspan/=2;
      }
      break;
      
//========================================Add      
      // Increse V span
    case UP:
      for(int i=0;i<NumOfScopes;i++){
        sp[i].tspany*=2;
      }
      break;
      
      // Decrease time span
    case DOWN:
      for(int i=0;i<NumOfScopes;i++){
        sp[i].tspany/=2;
      }
      break;
//========================================Add            
      
    }
    break;
  }
}

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> END >>>>>>>

/* Arduino code
void setup()
{
  Serial.begin(38400);  
}
 
void loop()
{
  Serial.print(millis());
  Serial.print(",");
  Serial.print(analogRead(0));
  Serial.print(",");
  Serial.print(analogRead(1));
  Serial.println(",");
}
*/

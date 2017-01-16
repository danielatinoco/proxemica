/* --------------------------------------------------------------------------
 * SimpleOpenNI User3d Test
 * --------------------------------------------------------------------------
 * Processing Wrapper for the OpenNI/Kinect 2 library
 * http://code.google.com/p/simple-openni
 * --------------------------------------------------------------------------
 * prog:  Max Rheiner / Interaction Design / Zhdk / http://iad.zhdk.ch/
 * date:  12/12/2012 (m/d/y)
 * ----------------------------------------------------------------------------
 */
 
 // a biblioteca SimpleOpenNI está disponível apenas para o processing 2
 // o Kinect utilizado para o projeto é o v1

import SimpleOpenNI.*;
import netP5.*;
import oscP5.*;


SimpleOpenNI context;
OscP5 osc;
NetAddress supercollider;

int cols, rows;
int scl = 20;
int w = 2000;
int h = 1600;

float flying = 0;

float[][] terrain;

int MAX_USERS = 9;
int x=0;

// the data from openni comes upside down
float distancia;  // distancia entre pessoas 



boolean      autoCalib=true;

PVector[]    allDataBody = new PVector[MAX_USERS];
PVector[]    cmDataBody = new PVector[MAX_USERS];
PVector      bodyCenter = new PVector();
PVector      bodyDir = new PVector();
PVector      com = new PVector();                                   
PVector      com2d = new PVector();                                   


void setup()
{
  size(displayWidth, displayHeight, P3D);
  context = new SimpleOpenNI(this);

  if (context.isInit() == false)
  {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }

  println("antes da inicializacao");
  for (int i = 0; i < MAX_USERS; i++) {
    allDataBody[i] = new PVector(0, 0, 0);
  }
  for (int i = 0; i < MAX_USERS; i++) {
    cmDataBody[i] = new PVector(0, 0, 0);
  }

  // disable mirror
  context.setMirror(false);

  // enable depthMap generation 
  context.enableDepth();

  // enable skeleton generation for all joints
  context.enableUser();

  cols = w / scl;
  rows = h/ scl;
  terrain = new float[cols][rows];

  osc = new OscP5(this, 12000);
  supercollider = new NetAddress("127.0.0.1", 57120);
}



void draw()
{
  // update the cam
  context.update();

  background(-1);

  background(0, 0, 0);

  
  //desenha default

  flying -= 0.05;

  float yoff = flying;
  for (int y = 0; y < rows; y++) {
    float xoff = 0;
    
    for (int x = 0; x < cols; x++) {
      terrain[x][y] = map(noise(xoff, yoff), 0, 1, 10, -10);
      xoff += 0.2;
    }
    yoff += 0.2;
  }



  background(0);
  stroke(255,100,50);
  noFill();


  for (int y = 0; y < rows-1; y++) {
    beginShape(TRIANGLE_STRIP);
    for (int x = 0; x < cols; x++) {
      pushMatrix();
      vertex(x*scl, y*scl, terrain[x][y]);
      vertex(x*scl, (y)*scl, terrain[x][y+1]);
      popMatrix();
    }
    endShape();
  }
//  fim

    int[]   depthMap = context.depthMap();
    int[]   userMap = context.userMap();
    int     steps   = 3;  // to speed up the drawing, draw every third point
    int     index;
    PVector realWorldPoint;

  
    // inicializa vetor com as coordenadas de todos os usuarios
    for (int i = 0; i < MAX_USERS; i++) {
      allDataBody[i] = new PVector(0, 0, 0);
    }

    // inicializa vetor com as coordenadas do centro de massa de todos os usuarios
    for (int i = 0; i < MAX_USERS; i++) {
      cmDataBody[i] = new PVector(0, 0, 0);
    }

    // draw the skeleton if it's available
    int[] userList = context.getUsers();
    for (int i=0; i<userList.length; i++)
    {

      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_HEAD, allDataBody[userList[i] - 1]);

    
      if (context.isTrackingSkeleton(userList[i])) {
        //      drawSkeleton(userList[i]); //essa e a instrucao que desenha o esqueleto
      }
      // draw the center of mass
      if (context.getCoM(userList[i], com)) {
        stroke(100, 255, 0);
        strokeWeight(1);
        beginShape(LINES);
        vertex(com.x - 15, com.y, com.z);
        vertex(com.x + 15, com.y, com.z);

        vertex(com.x, com.y - 15, com.z);
        vertex(com.x, com.y + 15, com.z);

        vertex(com.x, com.y, com.z - 15);
        vertex(com.x, com.y, com.z + 15);
        endShape();

        fill(0, 255, 100);
        println("usuario e coordenadas COM = " + Integer.toString(userList[i]) + "    " + com.x  + "    " + com.y  + "    " +  com.z);
        cmDataBody[i].x = com.x;
        cmDataBody[i].y = com.y;
        cmDataBody[i].z = com.z;
      }
    }

    //imprime array com coordenadas de cabeca de cada usuario que foi pega acima 
    for (int i = 0; i < MAX_USERS; i++) {
      // println (i + "     " + allDataBody[i].x + "      " + allDataBody[i].y + "      " + allDataBody[i].z);
    } 
    distancia = 0;
    for (int i = 0; i < MAX_USERS; i++) {
      for (int j = i; j < MAX_USERS; j++) {
        if (i != j) {


          // próximas 4 linhas são para descobrir distância entre pessoas pelo centro de massa
          if (!((cmDataBody[i].x == 0.0 && cmDataBody[i].y == 0.0 && cmDataBody[i].z == 0.0) || (cmDataBody[j].x == 0.0 && cmDataBody[j].y == 0.0 && cmDataBody[j].z == 0.0 ))) {
            distancia = dist(cmDataBody[i].x, cmDataBody[i].y, cmDataBody[i].z, cmDataBody[j].x, cmDataBody[j].y, cmDataBody[j].z);
            println("distancia entre " + i + " e " + j + ": "+ distancia);
            String nomeMsg = "/dist" + i + j;


            OscMessage msg = new OscMessage("/dist" + i + j);
            println("---------------------------------------------------"+nomeMsg);
            msg.add(distancia);
            osc.send(msg, supercollider);
            println("dist"+i+j);
            toca();
            desenha();
          }
        }
      }
    } 

  }

  void toca() {


    if (distancia < 900) {
      OscMessage msg = new OscMessage("/starhit2");
      osc.send(msg, supercollider);
    }

    if (distancia < 3000 && distancia > 2050) {
      OscMessage msg = new OscMessage("/starhit4");
      osc.send(msg, supercollider);
    }

    if (distancia < 4000 && distancia > 3100) {
      OscMessage msg = new OscMessage("/starhit3");
      osc.send(msg, supercollider);
    }

    OscMessage msg = new OscMessage("/starhit");
    msg.add(map(distancia, 0, 5000, 2000, 20));
    msg.add(map(distancia, 0, 5000, 0.7, 0));
    osc.send(msg, supercollider);
  }

  void desenha() {
    flying -= map(distancia, 0, 5000, 0.1, 0.01);

    float yoff = flying;
    for (int y = 0; y < rows; y++) {
      float xoff = 0;
      for (int x = 0; x < cols; x++) {
        terrain[x][y] = map(noise(xoff, yoff), 0, 1, map(distancia, 0, 5000, 500, 0), map(distancia, 0, 5000, -500, 0));
        xoff += 0.2;
      }
      yoff += 0.2;
    }



    background(0);
    stroke(map(distancia, 5000, 0, 0, 255), map(distancia, 5000, 0, 50, 0), map(distancia, 5000, 0, 255, 0));
    noFill();

    for (int y = 0; y < rows-1; y++) {
      beginShape(TRIANGLE_STRIP);
      for (int x = 0; x < cols; x++) {
        pushMatrix();
        vertex(x*scl, y*scl, terrain[x][y]);
        vertex(x*scl, (y)*scl, terrain[x][y+1]);
        popMatrix();
      }
      endShape();
    }
  }

 
  // SimpleOpenNI user events

  void onNewUser(SimpleOpenNI curContext, int userId)
  {
    println("onNewUser - userId: " + userId);
    println("\tstart tracking skeleton");

    context.startTrackingSkeleton(userId);
  }

  void onLostUser(SimpleOpenNI curContext, int userId)
  {
    println("onLostUser - userId: " + userId);
  }

  void onVisibleUser(SimpleOpenNI curContext, int userId)
  {
    //println("onVisibleUser - userId: " + userId);
  }



  void getBodyDirection(int userId, PVector centerPoint, PVector dir)
  {
    PVector jointL = new PVector();
    PVector jointH = new PVector();
    PVector jointR = new PVector();
    float  confidence;

    // draw the joint position
    confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, jointL);
    confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, jointH);
    confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, jointR);

    // take the neck as the center point
    confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_NECK, centerPoint);


    PVector up = PVector.sub(jointH, centerPoint);
    PVector left = PVector.sub(jointR, centerPoint);

    dir.set(up.cross(left));
    dir.normalize();
  }


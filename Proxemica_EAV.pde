
import netP5.*;
import oscP5.*;


OscP5 osc;
NetAddress supercollider;

int cols, rows;
int scl = 20;
int w = 2000;
int h = 1600;

float flying = 0;

float[][] terrain;


void setup()
{
  
  size(1300, 930, P3D);  // strange, get drawing error in the cameraFrustum if i use P3D, in opengl there is no problem

  cols = w / scl;
  rows = h/ scl;
  terrain = new float[cols][rows];

  osc = new OscP5(this, 12000);
  supercollider = new NetAddress("127.0.0.1", 57120);
}



void draw()
{

    if (mouseX > 3*width/4) {
      OscMessage msg = new OscMessage("/starhit2");
      osc.send(msg, supercollider);
    }

    if (mouseX > width/5 && mouseX < width/3) {
      OscMessage msg = new OscMessage("/starhit4");
      osc.send(msg, supercollider);
    }

    if (mouseX > width/3 && mouseX < 2*width/3) {
      OscMessage msg = new OscMessage("/starhit3");
      osc.send(msg, supercollider);
    }

    OscMessage msg = new OscMessage("/starhit");
    msg.add(map(mouseX, 0, width, 20, 2000));
    msg.add(map(mouseX, 0, width, 0, 0.7));
    osc.send(msg, supercollider);


    flying -= map(mouseX, 0, width, 0.01, 0.1);

    float yoff = flying;
    for (int y = 0; y < rows; y++) {
      float xoff = 0;
      for (int x = 0; x < cols; x++) {
        terrain[x][y] = map(noise(xoff, yoff), 0, 1, map(mouseX, 0, width, 0, 500), map(mouseX, 0, width, 0, -500));
        xoff += 0.2;
      }
      yoff += 0.2;
    }



    background(0);
    stroke(map(mouseX, 0, width, 0, 255), map(mouseX, 0, width, 50, 0), map(mouseX, 0, width , 255, 0));
    noFill();

    //translate(width/2, height/2+50);
    //rotateX(PI/3);
    //translate(-w/2, -h/2);
    for (int y = 0; y < rows-1; y++) {
      beginShape(TRIANGLE_STRIP);
      for (int x = 0; x < cols; x++) {
      
        vertex(x*scl, y*scl, terrain[x][y]);
        vertex(x*scl, (y)*scl, terrain[x][y+1]);
        //rect(x*scl, y*scl, scl, scl);
       
      }
      endShape();
    }
  }
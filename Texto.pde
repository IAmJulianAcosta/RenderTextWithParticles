/* //<>//
 * All this work is based on work of Amnom Owed, I adapted his kinect example
 * (http://www.creativeapplications.net/processing/kinect-physics-tutorial-for-processing/)
 * to use with text. It uses ControlP5, and Syphon to send rendered text.
 */

import controlP5.*;
import codeanticode.syphon.*;
import processing.opengl.*; // opengl
import blobDetection.*; // blobs
import java.awt.Polygon;

PGraphics renderCanvas, textCanvas;
SyphonServer server;
ControlFrame cf;
PFont mono;

// declare BlobDetection object
BlobDetection theBlobDetection;

// PImage to hold incoming imagery and smaller one for blob detection
PImage blobs;

// background color
color bgColor;
// three color palettes (artifact from me storing many interesting color palettes as strings in an external data file ;-)
String[] palettes = {
  "-1117720,-13683658,-8410437,-9998215,-1849945,-5517090,-4250587,-14178341,-5804972,-3498634", 
  "-67879,-9633503,-8858441,-144382,-4996094,-16604779,-588031", 
  "-16711663,-13888933,-9029017,-5213092,-1787063,-11375744,-2167516,-15713402,-5389468,-2064585"
};

final int PARTICLE_AMOUNT = 500;
final int FONT_SIZE = 180;

ArrayList <Particle []> particles;
ArrayList <PolygonBlob> polygons;

// global variables to influence the movement of all particles
float globalX, globalY;

int canvasWidth = 200;
int canvasHeight = 200;

int renderCanvasWidth = 1200;
int renderCanvasHeight = 240;

void settings() {
  size(100, 100, OPENGL);
  PJOGL.profile=1;
}

void setup() {
  textCanvas = createGraphics(canvasWidth, canvasHeight, OPENGL);
  renderCanvas = createGraphics(renderCanvasWidth, renderCanvasHeight, OPENGL);

  // Create syhpon server to send frames out.
  server = new SyphonServer(this, "Processing Syphon");
  cf = new ControlFrame(this, 500, 100, "Controls");
  polygons = new ArrayList <PolygonBlob> ();

  mono = loadFont("sansserif.vlw");

  blobs = createImage(canvasWidth/2, canvasHeight/2, RGB);
  // initialize blob detection object to the blob image dimensions
  theBlobDetection = new BlobDetection(blobs.width, blobs.height);
  theBlobDetection.setThreshold(0.2);
}

String previousText  = "";
long delta;

void draw() {
  renderCanvas.beginDraw();
  renderCanvas.noStroke ();
  renderCanvas.fill(bgColor, 65);
  renderCanvas.rect(0, 0, renderCanvasWidth, renderCanvasHeight);
  String textToRender = cf.getText ();
  boolean changed = false;

  if (!previousText.equals (textToRender)) {
    changed = true;
    previousText = textToRender;
    particles = new ArrayList <Particle []> ();
    delta = millis();
    polygons.clear ();
  }

  /*for (int i = 0; i < polygons.size (); i++) {
   PolygonBlob poly = polygons.get (i);
   beginShape();
   for (int j = 0; j < poly.npoints; j++) {
   vertex (poly.xpoints [j], poly.ypoints [j]);
   }
   endShape ();
   }*/
   float traslateAmount = 0;
  for (int i = 0, polygonIndex = 0; i < textToRender.length (); i++) { 
    if (changed) {
      if (textToRender.charAt (i) == ' ') {
        particles.add (new Particle[0]);
      } else {
        drawText (i, textToRender);
        PolygonBlob poly = new PolygonBlob();
        polygons.add (poly);
        updateBlobs (poly);
        Particle [] particleGroup = new Particle[PARTICLE_AMOUNT];
        particles.add (particleGroup);
        setupFlowfield(particleGroup, poly);
      }
    }
    renderCanvas.pushMatrix ();
    traslate: 
    {
      if (polygonIndex > 0) {
        if (textToRender.charAt (i-1) != ' ') {
          traslateAmount += polygons.get (polygonIndex-1).width () + FONT_SIZE*0.05;
          //Avanzar en el index de poligonos solo si hay uno, si no, pues no.
          polygonIndex++;
        } else {
          traslateAmount += FONT_SIZE*0.5;
          //Si hay un espacio, que no avance en el index (se puede obviar pero quiero entender)
          polygonIndex+=0;
        }
      }
      else {
        //si el index es igual a cero, que igual lo avance
        polygonIndex++;
      }
    }
    renderCanvas.translate (traslateAmount, 0);
    if (textToRender.charAt (i) != ' ') {
      drawFlowfield(particles.get (i));
    }
    renderCanvas.popMatrix ();
  }

  renderCanvas.endDraw ();
  server.sendImage(renderCanvas);

  if (changed) {
    changed = false;
  }
}

void drawText (int index, String text) {
  textCanvas.beginDraw();
  textCanvas.background(0);
  textCanvas.textFont(mono);
  textCanvas.textSize (FONT_SIZE);
  textCanvas.pushMatrix ();
  textCanvas.text (text.charAt (index), 0, 160);
  textCanvas.popMatrix ();
  textCanvas.endDraw();
  //image(canvas, 0, 0);
}

void updateBlobs (PolygonBlob poly) {
  // copy the image into the smaller blob image
  blobs.copy(textCanvas, 0, 0, textCanvas.width, textCanvas.height, 0, 0, blobs.width, blobs.height);
  //image (blobs, 0, 0);

  blobs.filter (BLUR);

  if (textCanvas.pixels != null) {
    theBlobDetection.computeBlobs(blobs.pixels);
  }
  // create the polygon from the blobs (custom functionality, see class)
  poly.createPolygon();
}

void setupFlowfield(Particle [] flow, PolygonBlob poly) {
  // set stroke weight (for particle display) to 2.5
  strokeWeight(2.5);
  // initialize all particles in the flow
  for (int i=0; i<flow.length; i++) {
    flow[i] = new Particle(i/10000.0, poly);
  }

  if (firstTime) {
    setRandomColors(60, flow, firstTime);
    firstTime = false;
  }
}

boolean firstTime = true;

void drawFlowfield(Particle [] flow) {
  // set global variables that influence the particle flow's movement
  globalX = noise(frameCount * 0.01) * width/2 + width/4;
  globalY = noise(frameCount * 0.005 + 5) * height;
  // update and display all particles in the flow
  for (Particle p : flow) {
    p.updateAndDisplay();
  }
  setRandomColors(60, flow, false);
}

// sets the colors every nth frame
void setRandomColors(int nthFrame, Particle [] flow, boolean force) {
  if (frameCount % nthFrame == 0 || force) {
    // turn a palette into a series of strings
    String[] paletteStrings = split(palettes[int(random(palettes.length))], ",");
    // turn strings into colors
    color[] colorPalette = new color[paletteStrings.length];
    for (int i=0; i<paletteStrings.length; i++) {
      colorPalette[i] = int(paletteStrings[i]);
    }
    // set background color to first color from palette
    bgColor = colorPalette[0];
    // set all particle colors randomly to color from palette (excluding first aka background color)
    for (int i=0; i<flow.length; i++) {
      flow[i].col = colorPalette[int(random(1, colorPalette.length))];
    }
  }
}
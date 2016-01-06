// a basic noise-based moving particle
class Particle {
  // unique id, (previous) position, speed
  float id, x, y, xp, yp, s, d;
  color col; // color
  
  PolygonBlob poly;

  public Particle(float id, PolygonBlob poly) {
    this.id = id;
    s = random(2, 6); // speed
    this.poly = poly;
  }

  public void updateAndDisplay() {
    // let it flow, end with a new x and y position
    id += 0.01;
    d = (noise(id, x/globalY, y/globalY)-0.5)*globalX;
    x += cos(radians(d))*s;
    y += sin(radians(d))*s;

    // constrain to boundaries
    if (x<-10) {
      x=xp=canvasWidth+10;
    }
    if (x>canvasWidth+10) {
      x=xp=-10;
    }
    if (y<-10) { 
      y=yp=canvasHeight+10;
    }
    if (y>canvasHeight+10) {
      y=yp=-10;
    }
   
    // if there is a polygon (more than 0 points)
    if (poly.npoints > 0) {
      // if this particle is outside the polygon
      if (!poly.contains(x, y)) {
        // while it is outside the polygon
        while (!poly.contains(x, y)) {
          // randomize x and y
          x = random(canvasWidth);
          y = random(canvasHeight);
        }
        //println (x, y, id);
        // set previous x and y, to this x and y
        xp=x;
        yp=y;
      }
    }
    
    // individual particle color
    renderCanvas.stroke(col);
    // line from previous to current position
    renderCanvas.line(xp, yp, x, y);
   
    // set previous to current position
    xp=x;
    yp=y;
  }
}
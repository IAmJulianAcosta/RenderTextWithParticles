import java.util.Collections; //<>// //<>//
// an extended polygon class with my own customized createPolygon() method (feel free to improve!)
public class PolygonBlob extends Polygon {

  private final int MINIMUM_DISTANCE = 15;
  private final int BLOB_SIZE = 5;

  // took me some time to make this method fully self-sufficient
  // now it works quite well in creating a correct polygon from a person's blob
  // of course many thanks to v3ga, because the library already does a lot of the work

  private ArrayList<ArrayList> createContours () {
    ArrayList<ArrayList> contours = new ArrayList<ArrayList>();
    // create contours from blobs
    // go over all the detected blobs

    for (int n=0; n<theBlobDetection.getBlobNb(); n++) { 
      Blob b = theBlobDetection.getBlob(n); 

      // for each substantial blob... 
      if (b != null && b.getEdgeNb() > BLOB_SIZE) {
        // create a new contour arrayList of PVectors
        ArrayList contour = new ArrayList();
        // go over all the edges in the blob
        for (int m=0; m<b.getEdgeNb(); m++) { 
          // get the edgeVertices of the edge 
          EdgeVertex eA = b.getEdgeVertexA(m); 
          EdgeVertex eB = b.getEdgeVertexB(m); 
          // if both ain't null...
          if (eA != null && eB != null) { 
            if (contour.size() > 0) {
              // add final point
              contour.add(new PVector(eB.x*canvasWidth, eB.y*canvasHeight));
              // add current contour to the arrayList
              contours.add(contour);
              // start a new contour arrayList
              contour = new ArrayList();
              // if the current contour size is 0 (aka it's a new list)
            } else {
              // add the point to the list
              contour.add(new PVector(eA.x*canvasWidth, eA.y*canvasHeight));
            }
          }
        }
      }
    }
    return contours;
  }

  private void generatePolygonFromContours (ArrayList <ArrayList> contours) {
    // helpful variables to keep track of the selected contour and point (start/end point)
    int selectedContour = 0;
    int selectedPoint = 0;

    // at this point in the code we have a list of contours (aka an arrayList of arrayLists of PVectors)
    // now we need to sort those contours into a correct polygon. To do this we need two things:
    // 1. The correct order of contours
    // 2. The correct direction of each contour
    // as long as there are contours left...

    while (contours.size() > 0) {
      // find next contour
      float distance = 999999999;
      // if there are already points in the polygon
      if (npoints > 0) {
        // use the polygon's last point as a starting point
        PVector lastPoint = new PVector(xpoints[npoints-1], ypoints[npoints-1]);
        // go over all contours
        for (int i=0; i<contours.size(); i++) {
          ArrayList <PVector> c = contours.get(i);
          // get the contour's first point
          PVector fp = c.get(0);
          // get the contour's last point
          PVector lp = c.get(c.size()-1);
          // if the distance between the current contour's first point and the polygon's last point is smaller than distance
          if (fp.dist(lastPoint) < distance) {
            // set distance to this distance
            distance = fp.dist(lastPoint);
            // set this as the selected contour
            selectedContour = i;
            // set selectedPoint to 0 (which signals first point)
            selectedPoint = 0;
          }
          // if the distance between the current contour's last point and the polygon's last point is smaller than distance
          if (lp.dist(lastPoint) < distance) {
            // set distance to this distance
            distance = lp.dist(lastPoint);
            // set this as the selected contour
            selectedContour = i;
            // set selectedPoint to 1 (which signals last point)
            selectedPoint = 1;
          }
        }
        // if the polygon is still empty
      } else {
        // use a starting point in the lower-right
        PVector closestPoint = new PVector(0, 0);
        // go over all contours
        for (int i=0; i<contours.size(); i++) {

          ArrayList<PVector> c = contours.get(i);
          // get the contour's first point
          PVector fp = c.get(0);

          // get the contour's last point
          PVector lp = c.get(c.size()-1);
          // if the first point is the lowest and more to the left than the current closestPoint
          if (fp.y > closestPoint.y && fp.x > closestPoint.x) {
            // set closestPoint to first point
            closestPoint = fp;
            // set this as the selected contour
            selectedContour = i;
            // set selectedPoint to 0 (which signals first point)
            selectedPoint = 0;
          }
          // if the last point is the lowest and more to the left than the current closestPoint
          if (lp.y > closestPoint.y && lp.x > closestPoint.x) {
            // set closestPoint to last point
            closestPoint = lp;
            // set this as the selected contour
            selectedContour = i;
            // set selectedPoint to 1 (which signals last point)
            selectedPoint = 1;
          }
        }
      }

      // add contour to polygon
      ArrayList <PVector> contour = contours.get(selectedContour);
      // if selectedPoint is bigger than zero (aka last point) then reverse the arrayList of points
      if (selectedPoint > 0) { 
        Collections.reverse(contour);
      }

      // add all the points in the contour to the polygon
      for (PVector p : contour) {
        addPoint(int(p.x), int(p.y));
      }
      // remove this contour from the list of contours
      contours.remove(selectedContour);
      // the while loop above makes all of this code loop until the number of contours is zero
      // at that time all the points in all the contours have been added to the polygon... in the correct order (hopefully)
    }
  }

  public void createPolygon() {
    // an arrayList... of arrayLists... of PVectors
    ArrayList<ArrayList> contours = createContours ();
    generatePolygonFromContours (contours);
  }

  public int width () {
    return getBounds ().width;
  }

  public int height () {
    return getBounds ().height;
  }
}
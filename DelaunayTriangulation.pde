

class DelaunayTriangulation {
  // triangle components of triangulation
  ArrayList<Triangle> triangles = new ArrayList<Triangle>();
  
  // construct a Delaunay triangulation on a set of points
  DelaunayTriangulation(ArrayList<PVector> points) {
    // get the bounding super triangle for this point set
    Triangle superTriangle = this.getSuperTriangle(points);
    
    superTriangle.display();
  }
  
  // construct bounding triangle that contains all points in set
  Triangle getSuperTriangle(ArrayList<PVector> points) {
    int xMin = 0, xMax = 0, yMin = 0, yMax = 0;
    
    // loop through points
    for (int i = 0; i < points.size(); i++) {
      PVector p = points.get(i);
      
      if (i == 0 || p.x < xMin)
        xMin = (int) p.x;
      if (i == 0 || p.x > xMax)
        xMax = (int) p.x;
      if (i == 0 || p.y < yMin)
        yMin = (int) p.y;
      if (i == 0 || p.y > yMax)
        yMax = (int) p.y;
    }
    
    // add buffer to ensure all points are contained in super triangle
    xMin -= 1;
    yMin -= 1;
    xMax += 1;
    yMax += 1;
    
    // place vertices where they will encompass entire rectangular window of points
    PVector v1 = new PVector(((float) xMin + xMax) / 2.0f, 2 * yMin - yMax);
    PVector v2 = new PVector(xMin - (((float) xMax - xMin) / 2.0f), yMax);
    PVector v3 = new PVector(xMax + (((float) xMax - xMin) / 2.0f), yMax);
    
    return new Triangle(v1, v2, v3);
  }
  
  // debug: display the triangulation
  void display() {
    stroke(255);
    strokeWeight(2);
    noFill();
    
    for (Triangle t : this.triangles) {
      t.display();
    }
  }
  
}

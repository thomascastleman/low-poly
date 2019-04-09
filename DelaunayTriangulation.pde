

class DelaunayTriangulation {
  // triangle components of triangulation
  ArrayList<Triangle> triangles = new ArrayList<Triangle>();
  
  // construct a Delaunay triangulation on a set of points
  DelaunayTriangulation(ArrayList<PVector> points) {
    // debug: logs
    System.out.print("Constructing Delaunay Triangulation... ");
    
    // get the bounding super triangle for this point set
    Triangle superTriangle = this.getSuperTriangle(points);
    
    // add super triangle to triangulation
    this.triangles.add(superTriangle);
    
    ArrayList<Triangle> badTriangles = new ArrayList<Triangle>();
    ArrayList<Edge> polygon = new ArrayList<Edge>();
    
    // for each point
    for (int p = 0; p < points.size(); p++) {
      PVector point = points.get(p);
      
      // reset bad triangles to empty
      badTriangles.clear();
      
      // for each triangle in triangulation
      for (Triangle t : this.triangles) {
        // if point lies within triangle's circumcircle
        if (t.containsInCircumcircle(point)) {
          badTriangles.add(t);
          t.isBad = true;
        }
      }
      
      // reset polygon edges to empty
      polygon.clear();
      
      // add non-shared edges of bad triangles to polygonal hole
      for (int i = 0; i < badTriangles.size(); i++) {
        // TODO: add each non-shared edge to polygon (?)
        
        Triangle t = badTriangles.get(i);
        Edge edge;
        boolean shared;
        
        for (int e = 0; e < 3; e++) {
          // assume edge not shared
          shared = false;
          
          if (e < 2) {
            // construct edge from each pair of vertices
            edge = new Edge(t.vertices[e], t.vertices[e + 1]);
          } else {
            // wrap around from vertex 2 to vertex 0
            edge = new Edge(t.vertices[e], t.vertices[0]);
          }
          
          // for all the other bad triangles
          badTriangleLoop:
          for (int j = 0; j < badTriangles.size(); j++) {
            if (i != j) {
              Triangle b = badTriangles.get(j);
              Edge otherEdge;
              
              // check edges of other bad triangle
              for (int e2 = 0; e2 < 3; e2++) {
                if (e2 < 2) {
                  // construct edge from each pair of vertices
                  otherEdge = new Edge(b.vertices[e2], b.vertices[e2 + 1]);
                } else {
                  // wrap around from vertex 2 to vertex 0
                  otherEdge = new Edge(b.vertices[e2], b.vertices[0]);
                }
                
                // if edge is shared between bad triangles, break
                if (edge.edgeEquals(otherEdge)) {
                  shared = true;
                  break badTriangleLoop;
                }
              }
            }
          }
          
          // if non-shared edge, add to polygon
          if (!shared) {
            polygon.add(edge);
          }
        }
      }
      
      // iterate over triangles in current triangulation
      ListIterator<Triangle> iter = this.triangles.listIterator();
      while(iter.hasNext()) {
        Triangle t = iter.next();
        
        // remove if bad triangle
        if (t.isBad) {
          iter.remove();
        }
      }
      
      // for each edge in polygonal hole
      for (Edge e : polygon) {
        // add new triangle between this edge and point
        this.triangles.add(new Triangle(point, e.v1, e.v2));
      }
    }
    
    // remove any triangles connected to super triangle vertices
    ListIterator<Triangle> iter = this.triangles.listIterator();
    while(iter.hasNext()) {
      Triangle t = iter.next();
      
      // compare triangle vertices with super triangle vertices
      outer:
      for (int v = 0; v < t.vertices.length; v++) {
        for (int s = 0; s < superTriangle.vertices.length; s++) {
          // if share vertex, remove triangle
          if (t.vertices[v].x == superTriangle.vertices[s].x && t.vertices[v].y == superTriangle.vertices[s].y) {
            iter.remove();
            break outer;
          }
        }
      }
    }
    
    println("Done.");
  }
  
  // construct bounding triangle that contains all points in set
  Triangle getSuperTriangle(ArrayList<PVector> points) {
    int xMin = 0, xMax = 0, yMin = 0, yMax = 0;
    
    // loop through points
    for (int i = 0; i < points.size(); i++) {
      PVector p = points.get(i);
      
      // update mins and maxes accordingly
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

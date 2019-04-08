

class DelaunayTriangulation {
  // triangle components of triangulation
  ArrayList<Triangle> triangles = new ArrayList<Triangle>();
  
  // construct a Delaunay triangulation on a set of points
  DelaunayTriangulation(ArrayList<PVector> points) {
    
  }
  
  // debug: display the triangulation
  void display() {
    stroke(255);
    strokeWeight(2);
    noFill();
    
    for (Triangle t : this.triangles) {
      triangle(t.v1.x, t.v1.y, t.v2.x, t.v2.y, t.v3.x, t.v3.y);
    }
  }
  
}

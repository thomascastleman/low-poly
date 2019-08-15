
/*
    Edge.pde: Class to store information about a polygon edge
*/

class Edge {
  
  PVector v1, v2;  // vertices in edge
  
  // construct new Edge by copying vertex vectors
  Edge(PVector p1, PVector p2) {
    this.v1 = p1.copy();
    this.v2 = p2.copy();
  }
  
  // check if two edges describes the same pair of points
  boolean edgeEquals(Edge other) {
    return (vecEq(this.v1, other.v1) && vecEq(this.v2, other.v2)) || (vecEq(this.v1, other.v2) && vecEq(this.v2, other.v1));
  }

}


class Edge {
  
  PVector v1, v2;  // vertices in edge
  
  Edge(PVector p1, PVector p2) {
    this.v1 = p1.copy();
    this.v2 = p2.copy();
  }
  
  // check if two edges describes the same pair of points
  boolean edgeEquals(Edge other) {
    return (vecEq(this.v1, other.v1) && vecEq(this.v2, other.v2)) || (vecEq(this.v1, other.v2) && vecEq(this.v2, other.v1));
  }

}

// check if two vectors are equal
boolean vecEq(PVector v1, PVector v2) {
  return v1.x == v2.x && v1.y == v2.y;
}

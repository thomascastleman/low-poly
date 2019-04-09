
class Edge {
  
  PVector v1, v2;  // vertices in edge
  
  Edge(PVector p1, PVector p2) {
    this.v1 = p1.copy();
    this.v2 = p2.copy();
  }
}

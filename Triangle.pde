
class Triangle {
  PVector v1, v2, v3; // vertices of triangle
  PVector[] vertices;
  float r, g, b;      // average RGB values of pixels within this triangle
  int numPixels;      // number of pixels contained within this triangle
  boolean isBad;      // bad triangle flag for Delaunay triangulation
  
  Triangle(PVector p1, PVector p2, PVector p3) {
    this.vertices = new PVector[3];
    this.vertices[0] = this.v1 = p1.copy();
    this.vertices[1] = this.v2 = p2.copy();
    this.vertices[2] = this.v3 = p3.copy();
  }
  
  // check if point within circumcircle of this triangle
  boolean containsInCircumcircle(PVector p) {
    // TODO write the function
    return true;
  }
  
  // check if a point is inside this triangle (coloring)
  boolean contains(PVector p) {
    return true;
  }
  
  // update the average color of pixels within this triangle
  void updateAvgColor(int r, int g, int b) {
    // re-average each color value
    this.r = (this.r * this.numPixels + r) / (this.numPixels + 1);
    this.g = (this.g * this.numPixels + g) / (this.numPixels + 1);
    this.b = (this.b * this.numPixels + b) / (this.numPixels + 1);
    
    // increment the number of pixels contributing to this average
    this.numPixels++;
  }
  
  // debug: display a triangle
  void display() {
    stroke(255);
    noFill();
    triangle(this.v1.x, this.v1.y, this.v2.x, this.v2.y, this.v3.x, this.v3.y);
  }
}

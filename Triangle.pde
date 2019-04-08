

class Triangle {
  PVector v1, v2, v3; // vertices of triangle
  float r, g, b;      // average RGB values of pixels within this triangle
  int numPixels;      // number of pixels contained within this triangle
  
  Triangle(PVector p1, PVector p2, PVector p3) {
    this.v1 = p1.copy();
    this.v2 = p2.copy();
    this.v3 = p3.copy();
  }
  
  // check if a point p satisfies the Delaunay condition of no points lying within the circumcircle of this triangle
  boolean satisfiesDelaunay(PVector p) {
    // TODO write the function
    return true;
  }
  
  void flip(Triangle t) {
    PVector a, b;
    
  }
  
  // check if a point is inside this triangle
  boolean isInside(PVector p) {
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
}


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
      float ab = norm(this.v1);
      float cd = norm(this.v2);
      float ef = norm(this.v3);
      
      float circumX = (ab * (this.v3.y - this.v2.y) + cd * (this.v1.y - this.v3.y) + ef * (this.v2.y - this.v1.y)) / (this.v1.x * (this.v3.y - this.v2.y) + this.v2.x * (this.v1.y - this.v3.y) + this.v3.x * (this.v2.y - this.v1.y));
      float circumY = (ab * (this.v3.x - this.v2.x) + cd * (this.v1.x - this.v3.x) + ef * (this.v2.x - this.v1.x)) / (this.v1.y * (this.v3.x - this.v2.x) + this.v2.y * (this.v1.x - this.v3.x) + this.v3.y * (this.v2.x - this.v1.x));
    
      PVector circum = new PVector(0.5f * circumX, 0.5f * circumY);
      
      // calc radius of circumcircle and distance of point from circumcircle center
      float circumRadius = this.v1.dist(circum);
      float pointDist = p.dist(circum);
      
      // if point within circumcircle radius, return true
      return pointDist <= circumRadius;
  }
  
  // check if a point is inside this triangle (coloring)
  boolean contains(PVector p) {
    return sameSide(p, this.v1, this.v2, this.v3) && sameSide(p, this.v2, this.v1, this.v3) && sameSide(p, this.v3, this.v1, this.v2);    
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
    //stroke(255);
    //strokeWeight(1);
    noStroke();
    fill(this.r, this.g, this.b);
    triangle(this.v1.x, this.v1.y, this.v2.x, this.v2.y, this.v3.x, this.v3.y);
    
    
    // // show circumcircle
    //float ab = norm(this.v1);
    //float cd = norm(this.v2);
    //float ef = norm(this.v3);
    
    //float circumX = (ab * (this.v3.y - this.v2.y) + cd * (this.v1.y - this.v3.y) + ef * (this.v2.y - this.v1.y)) / (this.v1.x * (this.v3.y - this.v2.y) + this.v2.x * (this.v1.y - this.v3.y) + this.v3.x * (this.v2.y - this.v1.y));
    //float circumY = (ab * (this.v3.x - this.v2.x) + cd * (this.v1.x - this.v3.x) + ef * (this.v2.x - this.v1.x)) / (this.v1.y * (this.v3.x - this.v2.x) + this.v2.y * (this.v1.x - this.v3.x) + this.v3.y * (this.v2.x - this.v1.x));
  
    //PVector circum = new PVector(0.5f * circumX, 0.5f * circumY);
    
    //// calc radius of circumcircle and distance of point from circumcircle center
    //float circumRadius = this.v1.dist(circum);
    
    //strokeWeight(1);
    //stroke(0, 255, 0);
    //ellipse(circum.x, circum.y, circumRadius * 2, circumRadius * 2);
  }
}

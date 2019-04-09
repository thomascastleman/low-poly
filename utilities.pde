
// check if two vectors are equal
boolean vecEq(PVector v1, PVector v2) {
  return v1.x == v2.x && v1.y == v2.y;
}

// square components 
float norm(PVector v) {
  return v.x * v.x + v.y * v.y;
}

// check if two points p1 and p2 are on the same side of segment AB
boolean sameSide(PVector p1, PVector p2, PVector a, PVector b) {
  PVector cp1 = b.copy().sub(a).cross(p1.copy().sub(a));
  PVector cp2 = b.copy().sub(a).cross(p2.copy().sub(a));
  
  return cp1.dot(cp2) >= 0;
}

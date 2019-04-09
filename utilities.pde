
// check if two vectors are equal
boolean vecEq(PVector v1, PVector v2) {
  return v1.x == v2.x && v1.y == v2.y;
}

// square components 
float norm(PVector v) {
  return v.x * v.x + v.y * v.y;
}

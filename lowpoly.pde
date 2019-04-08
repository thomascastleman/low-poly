
PImage src, dest;
String url = "https://cdn.zmescience.com/wp-content/uploads/2014/03/poison-dart-frog.jpg"; //"https://ichef.bbci.co.uk/images/ic/720x405/p0517py6.jpg";

void setup() {
  size(1024, 605);
  src = loadImage(url);
  dest = loadImage(url);

  double maxEnergy = 0;
  double[][] energies = new double[src.width][src.height];

  // loop through all (x,y) positions in image
  for (int x = 1; x < src.width - 1; x++) {
    for (int y = 1; y < src.height - 1; y++) {
      // get the colors of the neighboring pixels      
      color above = src.get(x, y - 1);
      color below = src.get(x, y + 1);
      color left = src.get(x - 1, y);
      color right = src.get(x + 1, y);

      // calculate total energy of this pixel by summing horizontal and vertical gradients
      double energy = gradient(left, right) + gradient(above, below);

      // temporarily store the energy value in matrix
      energies[x][y] = energy;

      // maintain the max energy
      if (energy > maxEnergy) {
        maxEnergy = energy;
      }
    }
  }

  // list to keep track of all points placed on image
  ArrayList<PVector> points = new ArrayList<PVector>();
  
  int borderPointInterval = floor(dest.width / 10);

  // loop through all (x,y) positions in image
  for (int x = 0; x < dest.width; x++) {
    
    // every n pixels, add a border
    if (x % borderPointInterval == 0) {
      // add top and bottom of screen points
      points.add(new PVector(x, 0));
      points.add(new PVector(x, dest.height - 1));
    }
    
    for (int y = 0; y < dest.height; y++) {
      // calculate probability for this pixel to be a point based on energy
      float p = (float) (energies[x][y] / maxEnergy);
      
      // scale down P a bit so it's not so intense
      p *= 0.2;

      // debug: display the energy value in dest image
      dest.set(x, y, color((int) map((float) energies[x][y], 0, (float) maxEnergy, 0, (float) maxEnergy / 10)));
      
      // choose probabilistically to add a point here or not
      if (Math.random() < p) {
        points.add(new PVector(x, y));
      }
    }
  }

  image(dest, 0, 0);
  
  fill(0, 255, 0);
  for (PVector p : points) {
    // fill(src.get((int) p.x, (int) p.y));
    ellipse(p.x, p.y, 5, 5);
  }
  
  println(points.size());
}

// find squared difference between each color value of two adjacent pixels
double gradient(color a, color b) {
  return Math.pow(red(a) - red(b), 2) + Math.pow(green(a) - green(b), 2) + Math.pow(blue(a) - blue(b), 2);
}

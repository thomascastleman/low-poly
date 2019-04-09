
import java.util.*;
PImage src, dest;
String url = "https://i.kym-cdn.com/entries/icons/original/000/013/564/doge.jpg";

void setup() {
  fullScreen(); //size(1024, 605);
  
  //stroke(255);
  //background(50);

  //ArrayList<PVector> points = new ArrayList<PVector>();

  //for (int i = 0; i < 25; i++) {
  //  points.add(new PVector((float) Math.random() * (width * 0.7), (float) Math.random() * (height * 0.7)));
  //  ellipse(points.get(i).x, points.get(i).y, 6, 6);
  //}

  //DelaunayTriangulation t = new DelaunayTriangulation(points);

  //t.display();






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

  int borderPointInterval = floor(dest.width / 9);

  // loop through all (x,y) positions in image
  for (int x = 0; x < dest.width; x++) {

    // every n pixels, add a border
    if (x % borderPointInterval == 0) {
      // add top and bottom of screen points
      points.add(new PVector(x, 0));
      points.add(new PVector(x, dest.height - 1));
    }

    for (int y = 0; y < dest.height; y++) {
      // every n pixels, add a border
      if (y % borderPointInterval == 0 && x == 0) {
        // add top and bottom of screen points
        points.add(new PVector(0, y));
        points.add(new PVector(dest.width - 1, y));
      }

      // calculate probability for this pixel to be a point based on energy
      float p = (float) (energies[x][y] / maxEnergy);

      // scale down P a bit so it's not so intense
      p *= 0.3;

      // debug: display the energy value in dest image
      dest.set(x, y, color((int) map((float) energies[x][y], 0, (float) maxEnergy, 0, (float) maxEnergy / 10)));

      // choose probabilistically to add a point here or not
      if (Math.random() < p) {
        points.add(new PVector(x, y));
      }
    }
  }

  println(points.size());

  //image(dest, 0, 0);

  //fill(0, 255, 0);
  //for (PVector p : points) {
  //  // fill(src.get((int) p.x, (int) p.y));
  //  ellipse(p.x, p.y, 5, 5);
  //}

  // compute Delaunay triangulation on set of points placed on image
  DelaunayTriangulation delTri = new DelaunayTriangulation(points);


  print("Updating colors... ");
  // loop through all (x,y) positions in image
  for (int x = 0; x < src.width; x++) {    
    for (int y = 0; y < src.height; y++) {
      // for each triangle in triangulation
      for (Triangle t : delTri.triangles) {
        // if point within triangle
        if (t.contains(new PVector(x, y))) {
          // get color of this pixel
          color pixColor = src.get(x, y);

          // update color of this triangle to reflect average of pixels within it
          t.updateAvgColor((int) red(pixColor), (int) green(pixColor), (int) blue(pixColor));

          // break;
        }
      }
    }
  }

  println("Done.");

  // display colored triangulation
  delTri.display();
}

// find squared difference between each color value of two adjacent pixels
double gradient(color a, color b) {
  return Math.pow(red(a) - red(b), 2) + Math.pow(green(a) - green(b), 2) + Math.pow(blue(a) - blue(b), 2);
}

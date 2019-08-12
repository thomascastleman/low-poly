
import java.util.*;
PImage src, dest;
String url = "https://i.ytimg.com/vi/a_KqZdF4iNQ/maxresdefault.jpg"; //  "https://i.kym-cdn.com/entries/icons/original/000/013/564/doge.jpg";

void setup() {
  size(1280, 720);
  
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
  
  println(dest.width - 1);
  println(dest.height - 1);

  // list to keep track of all points placed on image
  ArrayList<PVector> points = new ArrayList<PVector>();

  int borderPointInterval = floor(dest.width / 9);
  println("interval: " + borderPointInterval);
  
  for (int y = 0; y < dest.height; y++) {
    if (y % borderPointInterval == 0 && y != 0 && y != dest.height - 1) {
      points.add(new PVector(0, y));
      points.add(new PVector(dest.width - 1, y));
    }
  }

  // loop through all (x,y) positions in image
  for (int x = 0; x < dest.width; x++) {

    // every n pixels, add a border
    if (x % borderPointInterval == 0) {
      // add top and bottom of screen points
      points.add(new PVector(x, 0));
      points.add(new PVector(x, dest.height - 1));
    }

    for (int y = 0; y < dest.height; y++) {
      //// every n pixels, add a border
      //if (y % borderPointInterval == 0 && (x == 0 || x == dest.width - 1) && (y != 0 && y != dest.height - 1)) {
      //  // add top and bottom of screen points
      //  points.add(new PVector(0, y));
      //  points.add(new PVector(dest.width - 1, y));
      //}

      // calculate probability for this pixel to be a point based on energy
      float p = (float) (energies[x][y] / maxEnergy);

      // scale down P a bit so it's not so intense
      p *= 0.1;

      // debug: display the energy value in dest image
      dest.set(x, y, color((int) map((float) energies[x][y], 0, (float) maxEnergy, 0, (float) maxEnergy / 10)));

      // choose probabilistically to add a point here or not
      if (Math.random() < p && x % borderPointInterval != 0 && y % borderPointInterval != 0) {
        points.add(new PVector(x, y));
      }
    }
  }

  println(points.size() + " points.");

  //image(src, 0, 0);

  //fill(0, 255, 0);
  //for (PVector p : points) {
  //  // fill(src.get((int) p.x, (int) p.y));
  //  ellipse(p.x, p.y, 5, 5);
  //}
  
  for (int i = 0; i < points.size(); i++) {
    for (int j = 0; j < points.size(); j++) {
      PVector p1 = points.get(i), p2 = points.get(j);
      if (i != j && p1.x == p2.x && p1.y == p2.y) {
        println("Duplicate @ " + p1.x + ", " + p1.y);
      }
    }
  }

  // compute Delaunay triangulation on set of points placed on image
  DelaunayTriangulation delTri = new DelaunayTriangulation(points);
  
  ArrayList<Triangle> legitBois = new ArrayList<Triangle>();
  
  for (Triangle t : delTri.triangles) {
    if (t.area() > 0) {
      legitBois.add(t);
      
      //t.r = 0;
      //t.g = 0;
      //t.b = 255;
      
      //t.display();
      
    } else {
      println("area 0: (" + t.v1.x + ", " + t.v1.y + ") (" + t.v2.x + ", " + t.v2.y + ") (" + t.v3.x + ", " + t.v3.y + ")");
      
      //t.r = 255;
      //t.g = 0;
      //t.b = 0;
      
      //t.display();
    }
  }
  
  println(delTri.triangles.size() + " bois.");
  println(legitBois.size() + " legit bois.");
  
  delTri.triangles = legitBois;

  // initialize previous container triangle randomly to start
  Triangle last = delTri.triangles.size() > 0 ? delTri.triangles.get(0) : null;
  
  println("(" + last.v1.x + ", " + last.v1.y + ") (" + last.v2.x + ", " + last.v2.y + ") (" + last.v3.x + ", " + last.v3.y + ")");

  print("Updating colors... ");
  // loop through every OTHER (x,y) position in image
  for (int x = 0; x < src.width; x += 1) {
    for (int y = 0; y < src.height; y += 1) {
      PVector p = new PVector(x, y);  // construct PVector at this point
      color pixColor = src.get(x, y);  // get color of this pixel
      
      // if this point shares same container triangle as the previous point, don't search
      if (last != null && last.contains(p)) {
        // update color of this triangle to reflect average of pixels within it
        last.updateAvgColor((int) red(pixColor), (int) green(pixColor), (int) blue(pixColor));
        
      } else {
        // linear search to find which triangle contains p
        for (Triangle t : delTri.triangles) {
          // if point within triangle
          if (t.contains(p)) {
            // update color of this triangle to reflect average of pixels within it
            t.updateAvgColor((int) red(pixColor), (int) green(pixColor), (int) blue(pixColor));

            // preserve reference to the container triangle of this point
            last = t;
            
            //print("Changing ");
  
            break;
          }
        }
      }
    }
  }

  println("Done.");

  // display colored triangulation
  delTri.display();
   
  //for (PVector p : points) {
  //  if (p.x == 0 || p.x == dest.width - 1) {
  //    println(p.x, p.y);
  //    fill(0, 255,0);
  //    ellipse(p.x, p.y, 10, 10);
  //  }
  //}
  
}

// find squared difference between each color value of two adjacent pixels
double gradient(color a, color b) {
  return Math.pow(red(a) - red(b), 2) + Math.pow(green(a) - green(b), 2) + Math.pow(blue(a) - blue(b), 2);
}

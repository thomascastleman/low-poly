
import java.util.*;

PImage src;
final String IMG_URL = "https://i.ytimg.com/vi/a_KqZdF4iNQ/maxresdefault.jpg"; //  "https://i.kym-cdn.com/entries/icons/original/000/013/564/doge.jpg";
final float ENERGY_SCALAR = 0.1;    // factor to scale down calculated energy of image (reduces number of points placed in point set)

void setup() {
  fullScreen();

  // load requested image
  src = loadImage(IMG_URL);

  // create a point set reflecting the energy of the src image
  ArrayList<PVector> points = generatePointSet(src);

  println(points.size() + " points in point set.");

  // compute Delaunay triangulation on set of points placed on image
  DelaunayTriangulation delTri = new DelaunayTriangulation(points);
  
  ArrayList<Triangle> legitBois = new ArrayList<Triangle>();
  
  for (Triangle t : delTri.triangles) {
    if (t.area() > 0) {
      legitBois.add(t);
    } else {
      println("area 0: (" + t.v1.x + ", " + t.v1.y + ") (" + t.v2.x + ", " + t.v2.y + ") (" + t.v3.x + ", " + t.v3.y + ")");
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
  for (int x = 0; x < src.width; x += 2) {
    for (int y = 0; y < src.height; y += 2) {
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
  
            break;
          }
        }
      }
    }
  }

  println("Done.");

  // display colored triangulation
  delTri.display();
}

/*  Generate a set of points on an image based on dual gradient energy, 
    where more points are placed in areas of greater energy,
    and fewer in areas with less energy */
ArrayList<PVector> generatePointSet(PImage img) {
  double maxEnergy = 0;                                       // maximum energy value for later relativization
  double[][] energies = new double[img.width][img.height];    // array for storing energy of each pixel

  // loop through all fully surrounded (x,y) positions in image
  for (int x = 1; x < img.width - 1; x++) {
    for (int y = 1; y < img.height - 1; y++) {
      // get colors of neighboring pixels      
      color above = img.get(x, y - 1);
      color below = img.get(x, y + 1);
      color left = img.get(x - 1, y);
      color right = img.get(x + 1, y);

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

  // point set for triangulation
  ArrayList<PVector> points = new ArrayList<PVector>();

  /*  interval (in px) at which points will be added to point set 
      around the border of the image. This forces the triangulation to
      (mostly) cover the entirety of the dimensions of the image */
  int borderPointInterval = floor(img.width / 9);

  // for each X position in image
  for (int x = 0; x < img.width; x++) {
    // at specified interval, add points on top & bottom borders of image
    if (x % borderPointInterval == 0) {
      points.add(new PVector(x, 0));
      points.add(new PVector(x, img.height - 1));
    }

    // for each Y position in image
    for (int y = 0; y < img.height; y++) {
      // at specified interval, add points on left & right borders of image
      if (y % borderPointInterval == 0 && x == 0 && y != 0 && y != img.height - 1) {
        points.add(new PVector(0, y));
        points.add(new PVector(img.width - 1, y));
      }

      /*  calculate probability for a point to be placed at this 
          pixel's position based on the energy at this pixel */
      float p = (float) (energies[x][y] / maxEnergy) * ENERGY_SCALAR;

      /*  choose probabilistically to add a point at this position or not,
          and don't ever place them at the border positions (could already exist there) */
      if (Math.random() < p && x % borderPointInterval != 0 && y % borderPointInterval != 0) {
        points.add(new PVector(x, y));
      }
    }
  }
  
  return points;
}

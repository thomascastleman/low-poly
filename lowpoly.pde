
/*
    lowpoly.pde: Main file with full logic of low poly process
*/

import java.util.*;

PImage src;
final boolean LOGGING = true;  // allow logs to console
final String IMG_URL =  "https://yatra8exe7uvportalprd.blob.core.windows.net/images/products/HighStDonated/Zoom/HD_101153233_01.jpg"; // "/home/tcastleman/Downloads/christmas.jpeg"; // "https://ichef.bbci.co.uk/images/ic/720x405/p0517py6.jpg"; // "https://i.ytimg.com/vi/a_KqZdF4iNQ/maxresdefault.jpg"; // "http://www.kolumnmagazine.com/wp-content/uploads/2019/02/John-Coltrane__10a.jpg"; //  "https://i.kym-cdn.com/entries/icons/original/000/013/564/doge.jpg";
final float ENERGY_SCALAR = 0.15;    // factor to scale down calculated energy of image (reduces number of points placed in point set)

void setup() {
  fullScreen();

  // load requested image
  src = loadImage(IMG_URL);
  
  // array for storing relative energy of each pixel
  double[][] energies = new double[src.width][src.height];
  
  // get blur kernel
  double[][] kernel = getKernel(9);
  
  // compute blurred image
  PImage blur = modifiedGaussianBlur(src, energies, kernel);
  
  
  // create a point set reflecting the energy of the src image
  ArrayList<PVector> points = generatePointSet(energies, src);

  println(points.size() + " points in point set.");

  // compute Delaunay triangulation on set of points placed on image
  DelaunayTriangulation dt = new DelaunayTriangulation(points);
  
  // remove any triangles with zero area
  // removeZeroAreaTriangles(dt);

  // add color to triangulation based on blurred image
  blurColorizeTriangulation(blur, dt);
  
  scale(0.9);  // scale down so we can see the full image
  
  // display blurred image under low poly form to fill in any gaps
  image(blur, 0, 0);

  // display colored triangulation
  dt.display();
}

/*  Generate a set of points on an image based on dual gradient energy, 
    where more points are placed in areas of greater energy,
    and fewer in areas with less energy.
    Cache the relativized energy value of each pixel in an energies matrix. */
ArrayList<PVector> generatePointSet(double[][] energies, PImage img) {
  if (LOGGING) print("Generating point set... ");
  
  double maxEnergy = 0;  // maximum energy value for later relativization

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
      
      // cache relative energy in energies matrix
      energies[x][y] /= maxEnergy;

      /*  choose probabilistically to add a point at this position or not,
          and don't ever place them at the border positions (could already exist there) */
      if (Math.random() < p && x % borderPointInterval != 0 && y % borderPointInterval != 0) {
        points.add(new PVector(x, y));
      }
    }
  }
  
  if (LOGGING) println("Done.");
  
  return points;
}

/*  Remove triangles with 0 area from the triangulation, as they cause 
    the contains() function to believe that every point is inside the triangle. */
void removeZeroAreaTriangles(DelaunayTriangulation dt) {
  ArrayList<Triangle> nonZero = new ArrayList<Triangle>();
  
  // for each triangle in triangulation
  for (Triangle t : dt.triangles) {
    if (t.area() > 0.0) {
      nonZero.add(t);
    } else {
      // -------- debug: print triangles with zero area ------------
      println("area 0: (" + t.v1.x + ", " + t.v1.y + ") (" + t.v2.x + ", " + t.v2.y + ") (" + t.v3.x + ", " + t.v3.y + ")");
    }
  }
  
  // ------- debug: see how many were removed ---------------
  println(dt.triangles.size() + " bois.");
  println(nonZero.size() + " legit bois.");
  
  // overwrite original set of triangles with new set
  dt.triangles = nonZero;
}

/*  Update the R, G, and B values of each triangle in a 
    triangulation to reflect the underlying pixels */
void colorizeTriangulation(PImage img, DelaunayTriangulation dt) {
  if (LOGGING) print("Colorizing triangulation (avg method)... ");
  
  // initialize previous container triangle randomly to start
  Triangle last = dt.triangles.size() > 0 ? dt.triangles.get(0) : null;
  
  // loop through every OTHER (x,y) position in image
  for (int x = 0; x < img.width; x += 2) {
    for (int y = 0; y < img.height; y += 2) {
      PVector p = new PVector(x, y);  // construct PVector at this point
      color pixColor = img.get(x, y);  // get color of this pixel

      // if this point shares same container triangle as the previous point, don't search
      if (last != null && last.contains(p)) {
        // update color of this triangle to reflect average of pixels within it
        last.updateAvgColor((int) red(pixColor), (int) green(pixColor), (int) blue(pixColor));

      } else {
        // linear search to find which triangle contains p
        for (Triangle t : dt.triangles) {
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

  if (LOGGING) println("Done.");
}

/*  Use the blur of the source image to colorize each triangle by taking
    the color of the pixel located at the centroid of each triangle. 
    (Credit to Johnny Lindbergh) */
void blurColorizeTriangulation(PImage blur, DelaunayTriangulation dt) {
  if (LOGGING) print("Colorizing triangulation (blur method)... ");
  
  // for each triangle in triangulation
  for (Triangle t : dt.triangles) {
    // compute centroid
    int cx = floor((t.v1.x + t.v2.x + t.v3.x) / 3.0);
    int cy = floor((t.v1.y + t.v2.y + t.v3.y) / 3.0);
    
    // get color of pixel at centroid
    color c = blur.get(cx, cy);
    
    // set triangle color
    t.r = red(c);
    t.g = green(c);
    t.b = blue(c);
  }
  
  if (LOGGING) println("Done.");
}

/*  Get an n x n kernel */
double[][] getKernel(int n) {
  double[][] k = new double[n][n];
  float sq = n * n;
  
  // build n x n kernel with values 1 / (n^2)
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      k[i][j] = 1 / sq;
    }
  }
  
  return k;
}

//{
//  { 0.00000067,  0.00002292,  0.00019117,  0.00038771,  0.00019117,  0.00002292,  0.00000067 },
//  { 0.00002292,  0.00078633,  0.00655965,  0.01330373,  0.00655965,  0.00078633,  0.00002292 },
//  { 0.00019117,  0.00655965,  0.05472157,  0.11098164,  0.05472157,  0.00655965,  0.00019117 },
//  { 0.00038771,  0.01330373,  0.11098164,  0.22508352,  0.11098164,  0.01330373,  0.00038771 },
//  { 0.00019117,  0.00655965,  0.05472157,  0.11098164,  0.05472157,  0.00655965,  0.00019117 },
//  { 0.00002292,  0.00078633,  0.00655965,  0.01330373,  0.00655965,  0.00078633,  0.00002292 },
//  { 0.00000067,  0.00002292,  0.00019117,  0.00038771,  0.00019117,  0.00002292,  0.00000067 }
//};

/*  Compute a variant of the Gaussian blur of an image, 
    with less blurring in detailed areas and more blurring in less important areas. */
PImage modifiedGaussianBlur(PImage img, double[][] energies, double[][] kernel) {
  if (LOGGING) print("Computing blur of source image... ");
  
  img.loadPixels();
  PImage blur = createImage(img.width, img.height, RGB);
  
  // compute half size of kernel for indexing
  int halfK = floor(kernel.length / 2);
  
  // iterate over pixels
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      float sumR = 0, sumG = 0, sumB = 0;
      
      // for each position in the kernel
      for (int ky = -halfK; ky <= halfK; ky++) {
        for (int kx = -halfK; kx <= halfK; kx++) {
          // if position valid (not outside image)
          if (y + ky >= 0 && x + kx >= 0 && y + ky < img.height && x + kx < img.width) {          
            // calculate position of actual pixel in pixels array
            int pos = (y + ky) * img.width + (x + kx);
            
            // add kernel-scaled color values to their respective sums
            sumR += kernel[ky + halfK][kx + halfK] * red(img.pixels[pos]);
            sumG += kernel[ky + halfK][kx + halfK] * green(img.pixels[pos]);
            sumB += kernel[ky + halfK][kx + halfK] * blue(img.pixels[pos]);
          }
        }
      }
      
      // in blurred image, set pixel color based on kernel sums
      blur.pixels[y * img.width + x] = color(sumR, sumG, sumB);
    }
  }
  
  // apply changes to pixels in blurred image
  blur.updatePixels();
  
  if (LOGGING) println("Done.");
  
  return blur;
}


/*
    lowpoly.pde: Main file with full logic of low poly process
*/

import java.util.*;

PImage src;
final boolean LOGGING = true;  // allow logs to console
final String IMG_URL = "https://i.ytimg.com/vi/a_KqZdF4iNQ/maxresdefault.jpg"; //  "https://ichef.bbci.co.uk/images/ic/720x405/p0517py6.jpg"; // "http://www.kolumnmagazine.com/wp-content/uploads/2019/02/John-Coltrane__10a.jpg"; //  "https://i.kym-cdn.com/entries/icons/original/000/013/564/doge.jpg";
final float ENERGY_SCALAR = 0.13;    // factor to scale down calculated energy of image (reduces number of points placed in point set)
final int MAX_KERNEL_DIM = 21;  // dimensions of largest kernel possible used to blur image

void setup() {
  fullScreen();

  // load requested image
  src = loadImage(IMG_URL);
  
  // array for storing relative energy of each pixel
  double[][] energies = new double[src.width][src.height];
  
  // create a point set reflecting the energy of the src image
  ArrayList<PVector> points = generatePointSet(energies, src);

  println(points.size() + " points in point set.");
  
  //double[][] kernel = getKernel(11);
  //energies = blurEnergyMatrix(energies, kernel);
  
  // compute blurred image
  double[][] kernel = getKernel(21);
  PImage blur = boxBlur(src, kernel); //energyDependentBoxBlur(src, energies);

  // compute Delaunay triangulation on set of points placed on image
  DelaunayTriangulation dt = new DelaunayTriangulation(points);

  // add color to triangulation based on blurred image
  blurColorizeTriangulation(blur, dt);
  
  scale(1);  // scale down so we can see the full image
  
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

/*  Compute a variant of the Gaussian blur of an image, 
    with less blurring in detailed areas and more blurring in less important areas. */
PImage boxBlur(PImage img, double[][] kernel) {
  if (LOGGING) print("Computing box blur of source image... ");
  
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

/*  Perform simple box blur on energy matrix */
double[][] blurEnergyMatrix(double[][] energies, double[][] kernel) {
  if (LOGGING) print("Computing box blur of energy matrix... ");
  
  // initialize blur matrix of same dimensions
  double[][] blur = new double[energies.length][energies[0].length];
  
  // compute half size of kernel for indexing
  int halfK = floor(kernel.length / 2);
  double max = 0;
  
  // iterate over pixels
  for (int x = 0; x < energies.length; x++) {
    for (int y = 0; y < energies[x].length; y++) {
      float sum = 0;
      
      // for each position in the kernel
      for (int ky = -halfK; ky <= halfK; ky++) {
        for (int kx = -halfK; kx <= halfK; kx++) {
          // if position valid
          if (y + ky >= 0 && x + kx >= 0 && y + ky < energies[x].length && x + kx < energies.length) {          
            // add kernel-scaled color values to their respective sums
            sum += kernel[ky + halfK][kx + halfK] * energies[x + kx][y + ky];
          }
        }
      }
      
      // in blurred image, set pixel color based on kernel sums
      blur[x][y] = sum;
      
      // record max energy value
      if (sum > max) {
        max = sum;
      }
    }
  }
  
  // iterate over pixels, relativize again
  for (int x = 0; x < blur.length; x++) {
    for (int y = 0; y < blur[x].length; y++) {
      blur[x][y] /= max;
    }
  }
  
  if (LOGGING) println("Done.");
  
  return blur;
}

/*  Compute a variant of a box blur of an image, 
    with less blurring in detailed areas and more blurring in less important areas. */
PImage energyDependentBoxBlur(PImage img, double[][] energies) {
  if (LOGGING) print("Computing energy-dependent box blur of source image... ");
  
  img.loadPixels();
  PImage blur = createImage(img.width, img.height, RGB);
  
  /*  Compute number of required kernels.
      Every kernel from 1x1 to NxN will be constructed to provide
      variation in blurring */
  double[][][] kernels = new double[ceil(MAX_KERNEL_DIM / 2.0)][][];
  double[][] kernel;
  
  // calculate values of each kernel
  for (int i = 0; i < kernels.length; i++) {
    kernels[i] = getKernel(2 * i + 1);
  }
  
  // iterate over pixels
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      float sumR = 0, sumG = 0, sumB = 0;
      
      /*  Choose which kernel to use for this pixel based on energy at this location
          Higher energy --> smaller kernel --> less blur
          Lower energy --> larger kernel --> more blur */
      kernel = kernels[(int) Math.floor((1 - energies[x][y]) * (kernels.length - 1))];
      
      // compute half size of kernel for indexing
      int halfK = floor(kernel.length / 2);
      
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

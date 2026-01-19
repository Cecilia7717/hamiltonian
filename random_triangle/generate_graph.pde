/**
 * Random T-shaped “triangular-hole” inside an m×n rectangle (grid-style coordinates).
 *
 * Variables:
 *  - m: rectangle width  (in cells)
 *  - n: rectangle height (in cells)
 *  - a: distance from top edge of rectangle to apex (top) of the hole
 *  - b: distance from base of the hole to bottom edge of rectangle
 *  - w0: width of the vertical middle column (same meaning across all T-shapes)
 *  - h0: height of the vertical column (topmost T-shape height)
 *  - h1,h2,h3: heights of the three lower “step” segments
 *  - d0..d3: left gaps from rectangle’s left edge to hole boundary at each level
 *  - c0..c3: right gaps from rectangle’s right edge to hole boundary at each level
 *
 * Restrictions enforced:
 *  - a,b,c3,d3 are nonzero (>= 1)
 *  - d0 > d1 > d2 > d3 >= 1
 *  - c0 > c1 > c2 > c3 >= 1
 *  - At every level i: d_i + c_i < m  (so the hole is strictly inside the rectangle)
 *  - Vertical fit: a + (h0+h1+h2+h3) + b = n, with all heights >= 1
 *
 * Output:
 *  - Visualization on canvas
 *  - Printed variable assignments in the Processing console
 *  - Also drawn as text on the canvas
 */

int cell = 28;     // pixels per “cell”
int pad  = 40;     // margin around drawing

// primary variables
int m, n;
int a, b;
int w0;
int h0, h1, h2, h3;
int d0, d1, d2, d3;
int c0, c1, c2, c3;

// derived y-levels
int yTop, y1, y2, y3, yBase;

void settings() {
  // generate a valid instance BEFORE size()
  boolean ok = false;
  for (int tries = 0; tries < 5000 && !ok; tries++) {
    ok = randomizeInstance();
  }

  if (!ok) {
    // fallback size to avoid crash
    size(800, 800);
  } else {
    size(pad*2 + m*cell + 220, pad*2 + n*cell);
  }
}

void setup() {
  noLoop();
  printAssignments();
}


void draw() {
  background(255);

  // draw outer rectangle
  stroke(0);
  strokeWeight(3);
  noFill();
  rect(pad, pad, m*cell, n*cell);

  drawHole();
  drawGrid(1);
  drawTextBlock();

  // ---- SAVE IMAGE ----
  saveFrame("triangular_hole_m" + m + "_n" + n + "_####.png");

  // stop after saving one frame
  noLoop();
}


boolean randomizeInstance() {
  // pick m,n first
  // keep them reasonably sized so the shape has room
  m = (int)random(14, 31);  // width in cells
  n = (int)random(14, 31);  // height in cells

  // choose vertical decomposition:
  // enforce: a >= 1, b >= 1, h0..h3 >= 1, and sum fits exactly to n
  a  = (int)random(1, max(2, n/3)); // keep a not too huge

  // choose heights with a guaranteed minimum
  // remaining after reserving a and b will be allocated to h0..h3
  int minB = 1;
  int minHeights = 4; // h0,h1,h2,h3 each >=1
  int remaining = n - a - minB - minHeights;
  if (remaining < 0) return false;

  // distribute remaining among h0..h3 and b
  // b gets at least 1 as minB, and can take extra too.
  int extraTotal = remaining;

  // random split into 5 buckets: (h0,h1,h2,h3,bExtra)
  int e0 = (int)random(0, extraTotal + 1);
  int e1 = (int)random(0, extraTotal - e0 + 1);
  int e2 = (int)random(0, extraTotal - e0 - e1 + 1);
  int e3 = (int)random(0, extraTotal - e0 - e1 - e2 + 1);
  int e4 = extraTotal - e0 - e1 - e2 - e3;

  h0 = 1 + e0;
  h1 = 1 + e1;
  h2 = 1 + e2;
  h3 = 1 + e3;
  b  = 1 + e4;

  // now choose widths/gaps with strict inside constraints
  // pick w0 first (must allow at least c0,d0 >=1)
  int maxW0 = m - 2; // leaves at least 1 gap each side if symmetric; but we allow asymmetry via d0,c0
  if (maxW0 < 1) return false;
  w0 = (int)random(1, maxW0 + 1);

  // choose d0 and c0 such that d0 + w0 + c0 = m with d0,c0 >=1
  // so d0 can range 1..(m - w0 - 1)
  int d0max = m - w0 - 1;
  if (d0max < 1) return false;
  d0 = (int)random(1, d0max + 1);
  c0 = m - w0 - d0;
  if (c0 < 1) return false;

  // choose d3 and c3 first (both nonzero), ensuring level 3 width positive
  // also must satisfy d3 < d2 < d1 < d0 and c3 < c2 < c1 < c0
  // We'll pick strictly increasing “inner” values by choosing a decreasing chain.

  // pick d3 in [1, d0-3]
  if (d0 - 3 < 1) return false;
  d3 = (int)random(1, (d0 - 3) + 1);

  // pick d2 in [d3+1, d0-2], d1 in [d2+1, d0-1]
  int d2min = d3 + 1;
  int d2max = d0 - 2;
  if (d2min > d2max) return false;
  d2 = (int)random(d2min, d2max + 1);

  int d1min = d2 + 1;
  int d1max = d0 - 1;
  if (d1min > d1max) return false;
  d1 = (int)random(d1min, d1max + 1);

  // similarly for c's
  if (c0 - 3 < 1) return false;
  c3 = (int)random(1, (c0 - 3) + 1);

  int c2min = c3 + 1;
  int c2max = c0 - 2;
  if (c2min > c2max) return false;
  c2 = (int)random(c2min, c2max + 1);

  int c1min = c2 + 1;
  int c1max = c0 - 1;
  if (c1min > c1max) return false;
  c1 = (int)random(c1min, c1max + 1);

  // enforce inside condition at every level: d_i + c_i < m
  if (!(d0 + c0 < m)) return false; // should always be true since d0+w0+c0=m and w0>=1
  if (!(d1 + c1 < m)) return false;
  if (!(d2 + c2 < m)) return false;
  if (!(d3 + c3 < m)) return false;

  // also ensure the “steps” are valid: each lower level is wider than above in the sense:
  // d0 > d1 > d2 > d3 and c0 > c1 > c2 > c3 already enforced.
  // And ensure base y is strictly inside rectangle (b>=1 already ensures).
  computeYLevels();

  // sanity check: hole fits vertically strictly inside rectangle
  if (a < 1 || b < 1) return false;
  if (yBase >= n) return false; // yBase is measured in cells from top; must be <= n-1 actually
  // yBase should be at n-b; b>=1 => yBase <= n-1, ok

  return true;
}

void computeYLevels() {
  yTop  = a;                 // apex/top of hole
  y1    = a + h0;            // after column
  y2    = a + h0 + h1;       // after step 1
  y3    = a + h0 + h1 + h2;  // after step 2
  yBase = a + h0 + h1 + h2 + h3; // base of hole
}

void drawHole() {
  computeYLevels();

  // convert cell coords -> pixel coords
  // hole polygon traced clockwise
  float xL0 = pad + d0 * cell;
  float xR0 = pad + (m - c0) * cell;

  float xL1 = pad + d1 * cell;
  float xR1 = pad + (m - c1) * cell;

  float xL2 = pad + d2 * cell;
  float xR2 = pad + (m - c2) * cell;

  float xL3 = pad + d3 * cell;
  float xR3 = pad + (m - c3) * cell;

  float YTop  = pad + yTop  * cell;
  float Y1    = pad + y1    * cell;
  float Y2    = pad + y2    * cell;
  float Y3    = pad + y3    * cell;
  float YBase = pad + yBase * cell;

  // draw filled white to “cut out” visually + thick border
  // (if you want transparent hole, remove fill)
  fill(255);
  stroke(0);
  strokeWeight(4);

  beginShape();
  vertex(xL0, YTop);
  vertex(xR0, YTop);
  vertex(xR0, Y1);

  vertex(xR1, Y1);
  vertex(xR1, Y2);

  vertex(xR2, Y2);
  vertex(xR2, Y3);

  vertex(xR3, Y3);
  vertex(xR3, YBase);

  vertex(xL3, YBase);
  vertex(xL3, Y3);

  vertex(xL2, Y3);
  vertex(xL2, Y2);

  vertex(xL1, Y2);
  vertex(xL1, Y1);

  vertex(xL0, Y1);
  endShape(CLOSE);
}

void drawGrid(int weight) {
  stroke(0, 35);
  strokeWeight(weight);

  // vertical
  for (int x = 0; x <= m; x++) {
    float px = pad + x * cell;
    line(px, pad, px, pad + n * cell);
  }
  // horizontal
  for (int y = 0; y <= n; y++) {
    float py = pad + y * cell;
    line(pad, py, pad + m * cell, py);
  }
}

void printAssignments() {
  println("===== Random Instance =====");
  println("m=" + m + ", n=" + n);
  println("a=" + a + ", b=" + b);
  println("w0=" + w0);
  println("h0=" + h0 + ", h1=" + h1 + ", h2=" + h2 + ", h3=" + h3);
  println("d0=" + d0 + ", d1=" + d1 + ", d2=" + d2 + ", d3=" + d3 + "   (d0>d1>d2>d3)");
  println("c0=" + c0 + ", c1=" + c1 + ", c2=" + c2 + ", c3=" + c3 + "   (c0>c1>c2>c3)");
  println("Check: a+(h0+h1+h2+h3)+b = " + (a + h0 + h1 + h2 + h3 + b) + " (should equal n=" + n + ")");
  println("===========================");
}

void drawTextBlock() {
  fill(0);
  textSize(14);
  textAlign(LEFT, TOP);

  String s = ""
    + "m=" + m + ", n=" + n + "   "
    + "a=" + a + ", b=" + b + "   "
    + "w0=" + w0 + "   "
    + "h0=" + h0 + ", h1=" + h1 + ", h2=" + h2 + ", h3=" + h3 + "   "
    + "d: (" + d0 + "," + d1 + "," + d2 + "," + d3 + ")   "
    + "c: (" + c0 + "," + c1 + "," + c2 + "," + c3 + ")";

  // above rectangle
  float textX = pad;
  float textY = 5;

  text(s, textX, textY);
}

void keyPressed() {
  exit();
}

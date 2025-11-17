// ============ PARAMETERS ============
int m = 5;      // width  (columns)
int n = 4;      // height (rows)
int cellSize = 30;
int margin = 20;

// store paths
ArrayList<ArrayList<PVector>> allPaths = new ArrayList<ArrayList<PVector>>();

// user control: save after drawing
boolean savedImage = false;


// ============ SETUP ============
void setup() {
  size(1800, 1400); 
  dfsEnumeratePaths();
  println("Total Hamilton paths = " + allPaths.size());
  noLoop();
}


// =======================================================
// ============   ENUMERATE HAMILTON PATHS   =============
// =======================================================

void dfsEnumeratePaths() {
  ArrayList<PVector> startPath = new ArrayList<PVector>();
  explore(startPath, new PVector(0,0));   // s = (0,0)
}

void explore(ArrayList<PVector> path, PVector cur) {

  ArrayList<PVector> newPath = new ArrayList<PVector>(path);
  newPath.add(cur);

  // t = (m-1, n-1)
  if (cur.x == m-1 && cur.y == n-1) {
    if (newPath.size() == m * n) {
      allPaths.add(newPath);
    }
    return;
  }

  // directions: RIGHT, DOWN, LEFT, UP
  int[][] dirs = {
    {1,0},
    {0,1},
    {-1,0},
    {0,-1}
  };

  for (int[] d : dirs) {
    int nx = (int)cur.x + d[0];
    int ny = (int)cur.y + d[1];

    if (valid(nx, ny, newPath)) {
      explore(newPath, new PVector(nx, ny));
    }
  }
}

boolean valid(int x, int y, ArrayList<PVector> path) {
  if (x < 0 || x >= m || y < 0 || y >= n) return false;

  for (PVector p : path)
    if (p.x == x && p.y == y)
      return false;

  return true;
}



// ===========================================
// ============ DRAW ALL PATHS ===============
// ===========================================

void draw() {
  background(255);

  if (allPaths.size() == 0) {
    text("No Hamiltonian paths", 20, 20);
    return;
  }

  int cols = ceil(sqrt(allPaths.size()));
  int rows = ceil(allPaths.size() / (float)cols);

  int tileW = m * cellSize + margin;
  int tileH = n * cellSize + margin;

  for (int i = 0; i < allPaths.size(); i++) {
    int cx = i % cols;
    int cy = i / cols;
    pushMatrix();
    translate(cx * tileW + margin, cy * tileH + margin);
    drawGrid();
    drawPath(allPaths.get(i));
    popMatrix();
  }

  // save once
  if (!savedImage) {
    saveAllPathsAsOneImage(cols, rows, tileW, tileH);
    savedImage = true;
  }
}



// =======================================================
// ============ SAVE TILE IMAGE TO DIRECTORY ============
// =======================================================

void saveAllPathsAsOneImage(int cols, int rows, int tileW, int tileH) {

  int W = cols * tileW + margin;
  int H = rows * tileH + margin;

  PGraphics pg = createGraphics(W, H);
  pg.beginDraw();
  pg.background(255);

  for (int i = 0; i < allPaths.size(); i++) {
    int cx = i % cols;
    int cy = i / cols;
    pg.pushMatrix();
    pg.translate(cx * tileW + margin, cy * tileH + margin);
    drawGrid(pg);
    drawPath(pg, allPaths.get(i));
    pg.popMatrix();
  }

  pg.endDraw();

  // save to sketch folder with correct naming
  String filename = "paths_m" + m + "_n" + n + "_diff.png";
  pg.save(filename);

  println("Saved image: " + filename);
}



// ================================================
// ============ DRAW HELPERS FOR PGRAPHICS ========
// ================================================

void drawGrid() {
  drawGrid(g);
}
void drawPath(ArrayList<PVector> path) {
  drawPath(g, path);
}

void drawGrid(PGraphics pg) {
  pg.stroke(150);
  for (int i = 0; i <= m; i++) {
    pg.line(i * cellSize, 0, i * cellSize, n * cellSize);
  }
  for (int j = 0; j <= n; j++) {
    pg.line(0, j * cellSize, m * cellSize, j * cellSize);
  }
}

void drawPath(PGraphics pg, ArrayList<PVector> path) {
  pg.strokeWeight(3);
  pg.stroke(0);

  for (int i = 0; i < path.size() - 1; i++) {
    PVector a = path.get(i);
    PVector b = path.get(i + 1);

    float ax = a.x * cellSize + cellSize/2;
    float ay = a.y * cellSize + cellSize/2;
    float bx = b.x * cellSize + cellSize/2;
    float by = b.y * cellSize + cellSize/2;

    pg.line(ax, ay, bx, by);
  }

  // start = (0,0)
  pg.fill(0,150,0);
  pg.ellipse(cellSize/2, cellSize/2, cellSize*0.4, cellSize*0.4);

  // end = (m-1,n-1)
  pg.fill(200,0,0);
  pg.ellipse(
    (m-1)*cellSize + cellSize/2,
    (n-1)*cellSize + cellSize/2,
    cellSize*0.4, cellSize*0.4
  );
}

import java.util.HashSet;

int m;
int n;

int cellSize = 30;
int margin = 20;

ArrayList<ArrayList<PVector>> allPaths = new ArrayList<ArrayList<PVector>>();

boolean savedImage = false;

String inputFile;

void setup() {
  inputFile = "/Users/chenzhuo/Desktop/hamiltonian/all_paths/paths_m2_n2.txt";  
  loadPathsFromFile(inputFile);

  // create image directly (see next section)
  renderAndSave();

  exit();   // close immediately
}

void renderAndSave() {
  int cols = ceil(sqrt(allPaths.size()));
  int rows = ceil(allPaths.size() / (float)cols);

  int tileW = m * cellSize + margin;
  int tileH = n * cellSize + margin;

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
    ArrayList<PVector> path = allPaths.get(i);

    //HashSet<String> redCells  = horizontalRunsOfLengthM(path);
    //HashSet<String> blueCells = verticalRunsOfLengthN(path);
    //ArrayList<EdgePoint> greenEdgePoints = new ArrayList<EdgePoint>();
    //if (redCells.isEmpty() && blueCells.isEmpty()){
    //  greenEdgePoints = findGreenEdgePoints(path);
    //}
  
    //HashSet<String> greenCells = new HashSet<String>();
    //for (EdgePoint a : greenEdgePoints) {
    //  greenCells.add(a.x + "," + a.y);
    //}

    drawGrid(pg);

    // ===================== PDF ALGORITHM START =====================
    VHUsage vh = computeVHUsage(path);
    HashSet<Integer> boldCols = columnsWithSingleVertical(vh);
    HashSet<Integer> boldRows = rowsWithSingleHorizontal(vh);
    
    // color vertical cut regions FIRST (background layer)
    colorAllVerticalCuts(pg, boldCols);
    colorAllHorizontalCuts(pg, boldRows);
    // draw bold x / y lines
    drawBoldLines(pg, boldCols, boldRows);
    // ====================== PDF ALGORITHM END ======================


    //drawColoredCells(pg, redCells, greenCells, blueCells);
    //for (EdgePoint a : greenEdgePoints) {
    //  float yLine = (a.y + 1) * cellSize;
    //  pg.stroke(0, 180);
    //  pg.strokeWeight(5);
    //  pg.line(0, yLine, m * cellSize, yLine);
    //}
    //pg.strokeWeight(1);

    drawPath(pg, path);

    pg.popMatrix();
  }

  pg.endDraw();

  String out = outputImagePath(inputFile);
  pg.save(out);
  println("Saved image to: " + out);
}

class EdgePoint {
  int x, y;
  EdgePoint(int x, int y) {
    this.x = x;
    this.y = y;
  }
}

/* ======================= PDF DATA STRUCTURES ======================= */

class VHUsage {
  int[][] vertical;    // [m-1][n]
  int[][] horizontal;  // [m][n-1]

  VHUsage(int[][] v, int[][] h) {
    vertical = v;
    horizontal = h;
  }
}

/* ======================= PDF CORE LOGIC ======================= */

VHUsage computeVHUsage(ArrayList<PVector> path) {
  int[][] vertical = new int[m-1][n];
  int[][] horizontal = new int[m][n-1];

  for (int i = 0; i < path.size() - 1; i++) {
    PVector a = path.get(i);
    PVector b = path.get(i + 1);

    int x = int(a.x);
    int y = int(a.y);
    int xn = int(b.x);
    int yn = int(b.y);

    // right
    if (xn == x + 1) {
      vertical[x][y] += 1;
    }
    // left
    else if (xn == x - 1) {
      vertical[xn][y] += 1;
    }
    // down
    else if (yn == y + 1) {
      horizontal[x][y] += 1;
    }
    // up
    else if (yn == y - 1) {
      horizontal[x][yn] += 1;
    }
  }

  return new VHUsage(vertical, horizontal);
}

HashSet<Integer> columnsWithSingleVertical(VHUsage vh) {
  HashSet<Integer> result = new HashSet<Integer>();

  for (int x = 0; x < m - 1; x++) {
    int count = 0;
    for (int y = 0; y < n; y++) {
      if (vh.vertical[x][y] == 1) {
        count++;
      }
    }
    if (count == 1) {
      result.add(x);
    }
  }
  return result;
}

HashSet<Integer> rowsWithSingleHorizontal(VHUsage vh) {
  HashSet<Integer> result = new HashSet<Integer>();

  for (int y = 0; y < n - 1; y++) {
    int count = 0;
    for (int x = 0; x < m; x++) {
      if (vh.horizontal[x][y] == 1) {
        count++;
      }
    }
    if (count == 1) {
      result.add(y);
    }
  }
  return result;
}

void drawBoldLines(PGraphics pg,
                   HashSet<Integer> boldCols,
                   HashSet<Integer> boldRows) {

  pg.stroke(0);
  pg.strokeWeight(4);

  // bold x (vertical cuts)
  for (int x : boldCols) {
    float X = (x + 1) * cellSize;
    pg.line(X, 0, X, n * cellSize);
  }

  // bold y (horizontal cuts)
  for (int y : boldRows) {
    float Y = (y + 1) * cellSize;
    pg.line(0, Y, m * cellSize, Y);
  }

  pg.strokeWeight(1);
}

/* ======================= EXISTING DRAW CODE ======================= */

void draw() {
  background(255);

  if (allPaths.size() == 0) {
    text("No paths loaded", 20, 20);
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
}

void loadPathsFromFile(String filename) {
  String[] lines = loadStrings(filename);
  if (lines == null) {
    println("ERROR: File not found: " + filename);
    exit();
  }

  int i = 0;

  // read m
  if (lines[i].startsWith("m=")) {
    m = int(lines[i].substring(2));
    i++;
  } else {
    println("ERROR: Missing m in file");
    exit();
  }

  // read n
  if (lines[i].startsWith("n=")) {
    n = int(lines[i].substring(2));
    i++;
  } else {
    println("ERROR: Missing n in file");
    exit();
  }

  // separator
  if (lines[i].equals("---")) {
    i++;
  } else {
    println("ERROR: Missing separator ---");
    exit();
  }

  // read paths
  for (; i < lines.length; i++) {
    String line = lines[i];
    int idx = line.indexOf("path=");
    if (idx < 0) continue;

    String pathStr = line.substring(idx + 5);
    String[] nodes = split(pathStr, "->");

    ArrayList<PVector> path = new ArrayList<PVector>();
    for (String node : nodes) {
      node = node.replace("(", "").replace(")", "");
      String[] xy = split(node, ",");
      int x = int(xy[0]);
      int y = int(xy[1]);
      path.add(new PVector(x, y));
    }
    allPaths.add(path);
  }
}

String outputImagePath(String inputPath) {
  // normalize separators
  inputPath = inputPath.replace("\\", "/");

  int slash = inputPath.lastIndexOf("/");
  int dot = inputPath.lastIndexOf(".");

  String base = (dot >= 0) ? inputPath.substring(slash + 1, dot)
                          : inputPath.substring(slash + 1);

  return base + "_color.png";
}

void drawGrid() {
  drawGrid(g);
}

void drawGrid(PGraphics pg) {
  pg.stroke(150);
  for (int i = 0; i <= m; i++)
    pg.line(i * cellSize, 0, i * cellSize, n * cellSize);
  for (int j = 0; j <= n; j++)
    pg.line(0, j * cellSize, m * cellSize, j * cellSize);
}

void drawPath(ArrayList<PVector> path) {
  drawPath(g, path);
}

void drawPath(PGraphics pg, ArrayList<PVector> path) {
  pg.strokeWeight(3);
  pg.stroke(0);

  for (int i = 0; i < path.size() - 1; i++) {
    PVector a = path.get(i);
    PVector b = path.get(i + 1);

    float ax = a.x * cellSize + cellSize / 2;
    float ay = a.y * cellSize + cellSize / 2;
    float bx = b.x * cellSize + cellSize / 2;
    float by = b.y * cellSize + cellSize / 2;

    pg.line(ax, ay, bx, by);
  }

  // start
  pg.fill(0, 150, 0);
  pg.ellipse(cellSize / 2, cellSize / 2,
             cellSize * 0.4, cellSize * 0.4);

  // end (0, n-1)
  pg.fill(200, 0, 0);
  pg.ellipse(
    cellSize / 2,
    (n - 1) * cellSize + cellSize / 2,
    cellSize * 0.4,
    cellSize * 0.4
  );
  
  //// end = (m-1,n-1)
  //pg.fill(200,0,0);
  //pg.ellipse(
  //  (m-1)*cellSize + cellSize/2,
  //  (n-1)*cellSize + cellSize/2,
  //  cellSize*0.4, cellSize*0.4
  //);
}

void colorVerticalCutSides(PGraphics pg, int x,
                           color leftColor,
                           color rightColor) {
  float cutX = (x + 1) * cellSize;
  float H = n * cellSize;
  float W = m * cellSize;

  pg.noStroke();

  // left side
  pg.fill(leftColor);
  pg.rect(0, 0, cutX, H);

  // right side
  pg.fill(rightColor);
  pg.rect(cutX, 0, W - cutX, H);
}

void colorHorizontalCutSides(PGraphics pg, int y,
                             color topColor,
                             color bottomColor) {
  float cutY = (y + 1) * cellSize;
  float W = m * cellSize;
  float H = n * cellSize;

  pg.noStroke();

  // top side
  pg.fill(topColor);
  pg.rect(0, 0, W, cutY);

  // bottom side
  pg.fill(bottomColor);
  pg.rect(0, cutY, W, H - cutY);
}

void colorAllVerticalCuts(PGraphics pg, HashSet<Integer> boldCols) {
  colorMode(HSB, 360, 100, 100, 100);

  int idx = 0;
  for (int x : boldCols) {
    // choose two contrasting colors deterministically
    color leftC  = color((idx * 90) % 360, 60, 95, 25);
    color rightC = color((idx * 90 + 180) % 360, 60, 95, 25);

    colorVerticalCutSides(pg, x, leftC, rightC);
    idx++;
  }

  colorMode(RGB, 255);
}

void colorAllHorizontalCuts(PGraphics pg, HashSet<Integer> boldRows) {
  colorMode(HSB, 360, 100, 100, 100);

  int idx = 0;
  for (int y : boldRows) {
    color topC    = color((idx * 90 + 45) % 360, 60, 95, 25);
    color bottomC = color((idx * 90 + 225) % 360, 60, 95, 25);

    colorHorizontalCutSides(pg, y, topC, bottomC);
    idx++;
  }

  colorMode(RGB, 255);
}

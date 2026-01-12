import java.util.HashSet;
import java.io.File;

int m;
int n;

int cellSize = 30;
int margin = 20;

ArrayList<ArrayList<PVector>> allPaths = new ArrayList<ArrayList<PVector>>();

boolean savedImage = false;

String inputFile;

// ===== USER CONFIG =====
String inputDir;
String outputRoot;
// =======================

void setup() {

  // ===== USER CONFIG =====
  String inputBaseName;
  String inputDir   = "/Users/chenzhuo/Desktop/hamiltonian/s_t_all_possible/paths_m8_n2";
  String outputRoot = "/Users/chenzhuo/Desktop/hamiltonian/draw_all_possible";
  // =======================

  File dir = new File(inputDir);
  if (!dir.exists() || !dir.isDirectory()) {
    println("ERROR: Input directory not found: " + inputDir);
    exit();
  }

  String folderName = dir.getName();

  File outDir = new File(outputRoot + "/" + folderName);
  if (!outDir.exists()) outDir.mkdirs();

  File[] files = dir.listFiles();
  if (files == null) exit();

  for (File f : files) {
    if (!f.getName().endsWith(".txt")) continue;

    allPaths.clear();
    inputFile = f.getAbsolutePath();
    inputBaseName = f.getName();
    loadPathsFromFile(inputFile);
    renderAndSave(outDir.getAbsolutePath(), inputBaseName);

  }

  exit();
}


// =======================================================
// ==================   RENDER & SAVE   ==================
// =======================================================

void renderAndSave(String outDir, String inputBaseName){

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

    HashSet<String> redCells  = horizontalRunsOfLengthM(path);
    HashSet<String> blueCells = verticalRunsOfLengthN(path);

    ArrayList<EdgePoint> greenEdgePoints = new ArrayList<EdgePoint>();
    if (redCells.isEmpty() && blueCells.isEmpty()) {
      greenEdgePoints = findGreenEdgePoints(path);
    }

    HashSet<String> greenCells = new HashSet<String>();
    for (EdgePoint a : greenEdgePoints) {
      greenCells.add(a.x + "," + a.y);
    }

    drawGrid(pg);
    drawColoredCells(pg, redCells, greenCells, blueCells);

    for (EdgePoint a : greenEdgePoints) {
      float yLine = (a.y + 1) * cellSize;
      pg.stroke(0, 180);
      pg.strokeWeight(5);
      pg.line(0, yLine, m * cellSize, yLine);
    }
    pg.strokeWeight(1);

    drawPath(pg, path);

    pg.popMatrix();
  }

  pg.endDraw();

  String out = outDir + "/" + outputImagePath(inputBaseName);

  pg.save(out);
  println("Saved image to: " + out);
}

String outputImagePath(String name) {
  int dot = name.lastIndexOf(".");
  String base = (dot >= 0) ? name.substring(0, dot) : name;
  return base + "_color.png";
}



// =======================================================
// =====================   CLASSES   =====================
// =======================================================

class EdgePoint {
  int x, y;
  EdgePoint(int x, int y) {
    this.x = x;
    this.y = y;
  }
}


// =======================================================
// ====================   LOADING   ======================
// =======================================================

void loadPathsFromFile(String filename) {
  String[] lines = loadStrings(filename);
  if (lines == null) exit();

  int i = 0;

  if (lines[i].startsWith("m=")) m = int(lines[i++].substring(2));
  if (lines[i].startsWith("n=")) n = int(lines[i++].substring(2));
  if (lines[i].equals("---")) i++;

  for (; i < lines.length; i++) {
    int idx = lines[i].indexOf("path=");
    if (idx < 0) continue;

    String[] nodes = split(lines[i].substring(idx + 5), "->");
    ArrayList<PVector> path = new ArrayList<PVector>();

    for (String node : nodes) {
      node = node.replace("(", "").replace(")", "");
      String[] xy = split(node, ",");
      path.add(new PVector(int(xy[0]), int(xy[1])));
    }

    allPaths.add(path);
  }
}


// =======================================================
// ====================   DRAWING   ======================
// =======================================================

void drawGrid(PGraphics pg) {
  pg.stroke(150);
  for (int i = 0; i <= m; i++)
    pg.line(i * cellSize, 0, i * cellSize, n * cellSize);
  for (int j = 0; j <= n; j++)
    pg.line(0, j * cellSize, m * cellSize, j * cellSize);
}


// ===== ONLY NECESSARY CHANGE IS HERE =====

void drawPath(PGraphics pg, ArrayList<PVector> path) {
  pg.strokeWeight(3);
  pg.stroke(0);

  for (int i = 0; i < path.size() - 1; i++) {
    PVector a = path.get(i);
    PVector b = path.get(i + 1);
    pg.line(
      a.x * cellSize + cellSize / 2,
      a.y * cellSize + cellSize / 2,
      b.x * cellSize + cellSize / 2,
      b.y * cellSize + cellSize / 2
    );
  }

  // 🟢 START = S
  PVector S = path.get(0);
  pg.fill(0, 150, 0);
  pg.ellipse(
    S.x * cellSize + cellSize / 2,
    S.y * cellSize + cellSize / 2,
    cellSize * 0.4,
    cellSize * 0.4
  );

  // 🔴 END = T
  PVector T = path.get(path.size() - 1);
  pg.fill(200, 0, 0);
  pg.ellipse(
    T.x * cellSize + cellSize / 2,
    T.y * cellSize + cellSize / 2,
    cellSize * 0.4,
    cellSize * 0.4
  );
}


// =======================================================
// ==============   ANALYSIS FUNCTIONS   =================
// =======================================================

HashSet<String> verticalRunsOfLengthN(ArrayList<PVector> path) {
  HashSet<String> blueCells = new HashSet<String>();

  // Step 1: detect which columns are fully vertical
  HashSet<Integer> fullColumns = new HashSet<Integer>();

  int i = 0;
  while (i < path.size()) {
    int start = i++;
    while (i < path.size()) {
      PVector a = path.get(i - 1), b = path.get(i);
      if (a.x == b.x && abs(a.y - b.y) == 1) i++;
      else break;
    }

    if (i - start == n) {
      int col = (int) path.get(start).x;
      fullColumns.add(col);
    }
  }

  // Step 2: decide direction based on endpoints
  boolean fromLeft =
    path.get(0).x == 0 && path.get(0).y == 0;

  boolean fromRight =
    path.get(path.size() - 1).x == m - 1 &&
    path.get(path.size() - 1).y == n - 1;

  // Step 3: scan columns and stop at first failure
  if (fromLeft) {
    for (int x = 0; x < m; x++) {
      if (!fullColumns.contains(x)) break;
      for (int y = 0; y < n; y++) {
        blueCells.add(x + "," + y);
      }
    }
  }

  if (fromRight) {
    for (int x = m - 1; x >= 0; x--) {
      if (!fullColumns.contains(x)) break;
      for (int y = 0; y < n; y++) {
        blueCells.add(x + "," + y);
      }
    }
  }

  return blueCells;
}



HashSet<String> horizontalRunsOfLengthM(ArrayList<PVector> path) {
  HashSet<String> redCells = new HashSet<String>();
  int i = 0;
  while (i < path.size()) {
    int start = i++;
    while (i < path.size()) {
      PVector a = path.get(i - 1), b = path.get(i);
      if (a.y == b.y && abs(a.x - b.x) == 1) i++;
      else break;
    }
    if (i - start == m)
      for (int k = start; k < i; k++)
        redCells.add((int)path.get(k).x + "," + (int)path.get(k).y);
  }
  return redCells;
}

ArrayList<EdgePoint> findGreenEdgePoints(ArrayList<PVector> path) {
  ArrayList<EdgePoint> result = new ArrayList<EdgePoint>();
  HashSet<String> edgeSet = new HashSet<String>();

  for (int y = 0; y < n; y++) {
    edgeSet.add("0," + y);
    edgeSet.add((m - 1) + "," + y);
  }

  for (int i = 1; i <= path.size() - 2; i++) {
    PVector p = path.get(i);
    String key = (int)p.x + "," + (int)p.y;
    if (!edgeSet.contains(key)) continue;

    boolean prefixOK = true, suffixOK = true;
    for (int j = 0; j < i; j++) if (path.get(j).y > p.y) prefixOK = false;
    for (int j = i + 1; j < path.size(); j++) if (path.get(j).y <= p.y) suffixOK = false;

    if (prefixOK && suffixOK)
      result.add(new EdgePoint((int)p.x, (int)p.y));
  }
  return result;
}

void drawColoredCells(PGraphics pg,
                      HashSet<String> redCells,
                      HashSet<String> greenCells,
                      HashSet<String> blueCells) {

  pg.noStroke();

  pg.fill(255, 150, 150, 120);
  for (String s : redCells) {
    String[] xy = split(s, ",");
    pg.rect(int(xy[0]) * cellSize, int(xy[1]) * cellSize, cellSize, cellSize);
  }

  pg.fill(150, 255, 150, 120);
  for (String s : greenCells) {
    if (redCells.contains(s)) continue;
    String[] xy = split(s, ",");
    pg.rect(int(xy[0]) * cellSize, int(xy[1]) * cellSize, cellSize, cellSize);
  }

  pg.fill(150, 150, 255, 150);
  for (String s : blueCells) {
    String[] xy = split(s, ",");
    pg.rect(int(xy[0]) * cellSize, int(xy[1]) * cellSize, cellSize, cellSize);
  }
}

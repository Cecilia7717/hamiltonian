import java.util.HashSet;

int m;
int n;

int cellSize = 30;
int margin = 20;

ArrayList<ArrayList<PVector>> allPaths = new ArrayList<ArrayList<PVector>>();

boolean savedImage = false;

String inputFile;

void setup() {
  inputFile = "/Users/chenzhuo/Desktop/hamiltonian/all_paths/paths_m2_n2_diff.txt";  
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

    HashSet<String> redCells  = horizontalRunsOfLengthM(path);
    HashSet<String> blueCells = verticalRunsOfLengthN(path);
    ArrayList<EdgePoint> greenEdgePoints = new ArrayList<EdgePoint>();
    if (redCells.isEmpty() && blueCells.isEmpty()){
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

  //String dir = (slash >= 0) ? inputPath.substring(0, slash + 1) : "";
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

  //// end (0, n-1)
  //pg.fill(200, 0, 0);
  //pg.ellipse(
  //  cellSize / 2,
  //  (n - 1) * cellSize + cellSize / 2,
  //  cellSize * 0.4,
  //  cellSize * 0.4
  //);
  
  // end = (m-1,n-1)
  pg.fill(200,0,0);
  pg.ellipse(
    (m-1)*cellSize + cellSize/2,
    (n-1)*cellSize + cellSize/2,
    cellSize*0.4, cellSize*0.4
  );
}

HashSet<String> verticalRunsOfLengthN(ArrayList<PVector> path) {
  HashSet<String> blueCells = new HashSet<String>();

  int i = 0;
  while (i < path.size()) {
    int start = i;

    i++;
    while (i < path.size()) {
      PVector prev = path.get(i - 1);
      PVector cur  = path.get(i);

      // vertical move = same x
      if (cur.x == prev.x && abs(cur.y - prev.y) == 1) {
        i++;
      } else {
        break;
      }
    }

    int length = i - start;
    if (length == n) {
      for (int k = start; k < i; k++) {
        PVector p = path.get(k);
        blueCells.add((int)p.x + "," + (int)p.y);
      }
    }
  }

  return blueCells;
}

ArrayList<EdgePoint> findGreenEdgePoints(ArrayList<PVector> path) {
  ArrayList<EdgePoint> result = new ArrayList<EdgePoint>();

  // 1) Build edgeSet = all points on left or right edge
  HashSet<String> edgeSet = new HashSet<String>();
  for (int y = 0; y < n; y++) {
    edgeSet.add("0," + y);
    edgeSet.add((m - 1) + "," + y);
  }

  int L = path.size();

  // 2) Traverse path in order (skip start and end)
  for (int i = 1; i <= L - 2; i++) {
    PVector p = path.get(i);
    int x0 = (int)p.x;
    int y0 = (int)p.y;
    String key = x0 + "," + y0;

    // must be an edge point
    if (!edgeSet.contains(key)) continue;
    println("the current edge point:"+key);
    //println(path);
    // ---------- Condition A: prefix ----------
    boolean prefixOK = true;
    for (int j = 0; j < i; j++) {
      
      if ((int)path.get(j).y > y0) {
        prefixOK = false;
        break;
      }
    }
    if (!prefixOK) continue;

    // ---------- Condition B: suffix ----------
    boolean suffixOK = true;
    for (int j = i + 1; j < L; j++) {
      println(path.get(j));
      println(y0);
      if ((int)path.get(j).y <= y0) {
        suffixOK = false;
        break;
      }
    }
    if (!suffixOK) continue;
    println("success"+x0+","+y0);
    // Both conditions satisfied
    result.add(new EdgePoint(x0, y0));
  }

  return result;
}


HashSet<String> horizontalRunsOfLengthM(ArrayList<PVector> path) {
  HashSet<String> redCells = new HashSet<String>();

  int i = 0;
  while (i < path.size()) {
    int start = i;

    PVector a = path.get(i);

    // advance while horizontal
    i++;
    while (i < path.size()) {
      PVector prev = path.get(i - 1);
      PVector cur  = path.get(i);

      // horizontal move = same y
      if (cur.y == prev.y && abs(cur.x - prev.x) == 1) {
        i++;
      } else {
        break;
      }
    }

    int length = i - start;
    if (length == m) {
      for (int k = start; k < i; k++) {
        PVector p = path.get(k);
        redCells.add((int)p.x + "," + (int)p.y);
      }
    }
  }

  return redCells;
}


HashSet<String> greenFromForwardRightEdge(ArrayList<PVector> path,
                                         HashSet<String> redCells) {
  HashSet<String> greenCells = new HashSet<String>();

  boolean[][] visited = new boolean[m][n];

  for (int t = 0; t < path.size(); t++) {
    PVector cur = path.get(t);
    int x = (int)cur.x;
    int y0 = (int)cur.y;

    visited[x][y0] = true;

    // Only when we are on right edge x = m-1
    if (x != m - 1) continue;

    // Condition 1: all cells with y <= y0 are visited
    boolean topComplete = true;
    for (int yy = 0; yy <= y0 && topComplete; yy++) {
      for (int xx = 0; xx < m; xx++) {
        if (!visited[xx][yy]) {
          topComplete = false;
          break;
        }
      }
    }

    if (!topComplete) continue;

    // Condition 2: exists a cell with y > y0 that is NOT visited
    boolean bottomIncomplete = false;
    for (int yy = y0 + 1; yy < n && !bottomIncomplete; yy++) {
      for (int xx = 0; xx < m; xx++) {
        if (!visited[xx][yy]) {
          bottomIncomplete = true;
          break;
        }
      }
    }

    if (!bottomIncomplete) continue;

    String key = (m - 1) + "," + y0;

    // Exception: if already red, do NOT color green
    if (!redCells.contains(key)) {
      greenCells.add(key);
    }
  }

  return greenCells;
}

HashSet<String> greenFromBackwardEdge(ArrayList<PVector> path,
                                      HashSet<String> redCells,
                                      int edgeX) {
  HashSet<String> greenCells = new HashSet<String>();

  boolean[][] visited = new boolean[m][n];

  for (int t = path.size() - 1; t >= 0; t--) {
    PVector cur = path.get(t);
    int x = (int)cur.x;
    int y0 = (int)cur.y;

    visited[x][y0] = true;

    // Only check when we are on the chosen edge
    if (x != edgeX) continue;

    // Condition 1: all cells with y >= y0 are visited (bottom complete)
    boolean bottomComplete = true;
    for (int yy = y0; yy < n && bottomComplete; yy++) {
      for (int xx = 0; xx < m; xx++) {
        if (!visited[xx][yy]) {
          bottomComplete = false;
          break;
        }
      }
    }

    if (!bottomComplete) continue;

    // Condition 2: exists a cell with y < y0 that is NOT visited (top incomplete)
    boolean topIncomplete = false;
    for (int yy = 0; yy < y0 && !topIncomplete; yy++) {
      for (int xx = 0; xx < m; xx++) {
        if (!visited[xx][yy]) {
          topIncomplete = true;
          break;
        }
      }
    }

    if (!topIncomplete) continue;

    String key = edgeX + "," + y0;

    // Exception: if already red, do NOT color green
    if (!redCells.contains(key)) {
      greenCells.add(key);
    }
  }

  return greenCells;
}


void drawColoredCells(PGraphics pg,
                      HashSet<String> redCells,
                      HashSet<String> greenCells,
                      HashSet<String> blueCells) {

  pg.noStroke();

  // 1) RED (horizontal m-runs)
  pg.fill(255, 150, 150, 120);
  for (String s : redCells) {
    String[] xy = split(s, ",");
    int x = int(xy[0]);
    int y = int(xy[1]);
    pg.rect(x * cellSize, y * cellSize, cellSize, cellSize);
  }

  // 2) GREEN (boundary cut condition), but DO NOT overwrite red
  pg.fill(150, 255, 150, 120);
  for (String s : greenCells) {
    if (redCells.contains(s)) continue;  // your exception
    String[] xy = split(s, ",");
    int x = int(xy[0]);
    int y = int(xy[1]);
    pg.rect(x * cellSize, y * cellSize, cellSize, cellSize);
  }

  // 3) BLUE (vertical n-runs)
  pg.fill(150, 150, 255, 150);
  for (String s : blueCells) {
    String[] xy = split(s, ",");
    int x = int(xy[0]);
    int y = int(xy[1]);
    pg.rect(x * cellSize, y * cellSize, cellSize, cellSize);
  }
}

int m;
int n;

int cellSize = 30;
int margin = 20;

ArrayList<ArrayList<PVector>> allPaths = new ArrayList<ArrayList<PVector>>();

boolean savedImage = false;

String inputFile;

void setup() {
  inputFile = "/Users/chenzhuo/Desktop/hamiltonian/all_paths/paths_m6_n4.txt";  
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
    drawGrid(pg);
    drawPath(pg, allPaths.get(i));
    pg.popMatrix();
  }

  pg.endDraw();

  String out = outputImagePath(inputFile);
  pg.save(out);
  println("Saved image to: " + out);
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

  return base + ".png";
}


void drawGrid() {
  stroke(150);
  for (int i = 0; i <= m; i++)
    line(i * cellSize, 0, i * cellSize, n * cellSize);
  for (int j = 0; j <= n; j++)
    line(0, j * cellSize, m * cellSize, j * cellSize);
}

void drawPath(ArrayList<PVector> path) {
  strokeWeight(3);
  stroke(0);

  for (int i = 0; i < path.size() - 1; i++) {
    PVector a = path.get(i);
    PVector b = path.get(i + 1);

    float ax = a.x * cellSize + cellSize / 2;
    float ay = a.y * cellSize + cellSize / 2;
    float bx = b.x * cellSize + cellSize / 2;
    float by = b.y * cellSize + cellSize / 2;

    line(ax, ay, bx, by);
  }

  // start
  fill(0, 150, 0);
  ellipse(cellSize / 2, cellSize / 2, cellSize * 0.4, cellSize * 0.4);

  // end (0, n-1)
  fill(200, 0, 0);
  ellipse(
    cellSize / 2,
    (n - 1) * cellSize + cellSize / 2,
    cellSize * 0.4,
    cellSize * 0.4
  );
}

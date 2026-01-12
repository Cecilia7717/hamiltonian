// ============ PARAMETERS ============
int m = 8;      // width  (columns)
int n = 6;      // height (rows)
int cellSize = 30;
int margin = 20;

// store paths for ONE (S, T) pair at a time
ArrayList<ArrayList<PVector>> allPaths = new ArrayList<ArrayList<PVector>>();

// current start and end
PVector S;
PVector T;


// ============ SETUP ============
void setup() {
  size(1800, 1400);

  // Loop over all S on top row (y = 0)
  for (int sx = 0; sx < m; sx++) {
    S = new PVector(sx, 0);

    // Loop over all T on bottom row (y = n - 1)
    for (int tx = 0; tx < m; tx++) {
      T = new PVector(tx, n - 1);

      allPaths.clear();
      dfsEnumeratePaths();

      println("S=" + S + " T=" + T + " paths=" + allPaths.size());

      savePathsToFile();
    }
  }

  exit();
}


// =======================================================
// ============   ENUMERATE HAMILTON PATHS   =============
// =======================================================

void dfsEnumeratePaths() {
  ArrayList<PVector> startPath = new ArrayList<PVector>();
  explore(startPath, S);
}

void explore(ArrayList<PVector> path, PVector cur) {

  ArrayList<PVector> newPath = new ArrayList<PVector>(path);
  newPath.add(cur);

  // reached T
  if (cur.x == T.x && cur.y == T.y) {
    if (newPath.size() == m * n) {
      allPaths.add(newPath);
    }
    return;
  }

  // directions: RIGHT, DOWN, LEFT, UP
  int[][] dirs = {
    {1, 0},
    {0, 1},
    {-1, 0},
    {0, -1}
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

void ensureOutputDirectory(String dirName) {
  File dir = new File(sketchPath(dirName));
  if (!dir.exists()) {
    dir.mkdirs();
  }
}


// =======================================================
// ============        SAVE TO FILE        ===============
// =======================================================

void savePathsToFile() {
  ArrayList<String> lines = new ArrayList<String>();

  // header
  lines.add("m=" + m);
  lines.add("n=" + n);
  lines.add("S=(" + (int)S.x + "," + (int)S.y + ")");
  lines.add("T=(" + (int)T.x + "," + (int)T.y + ")");
  lines.add("count=" + allPaths.size());
  lines.add("---");

  // paths
  for (ArrayList<PVector> path : allPaths) {
    StringBuilder sb = new StringBuilder();
    sb.append("path=");

    for (int i = 0; i < path.size(); i++) {
      PVector p = path.get(i);
      sb.append("(").append((int)p.x).append(",").append((int)p.y).append(")");
      if (i < path.size() - 1) sb.append("->");
    }

    lines.add(sb.toString());
  }

 // directory name based on m and n
  String dirName = "paths_m" + m + "_n" + n;
  ensureOutputDirectory(dirName);
  
  // full path including directory
  String filename =
    dirName + "/" +
    "paths_m" + m +
    "_n" + n +
    "_S(" + (int)S.x + "," + (int)S.y + ")" +
    "_T(" + (int)T.x + "," + (int)T.y + ").txt";
  
  saveStrings(filename, lines.toArray(new String[0]));

}

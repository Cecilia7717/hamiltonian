int m;      // width
int n;      // height
int cellSize = 30;
int margin = 20;

ArrayList<PVector> foundPath = null;
boolean found = false;

PVector S;
PVector T;


void setup() {
  size(1800, 1400);

  for (int mm = 7; mm < 10; mm++) {
    for (int nn = 2; nn <= 6; nn++) {

      m = mm;
      n = nn;

      println("==== m=" + m + " n=" + n + " ====");

      // Loop over all S on top row
      for (int sx = 0; sx < m; sx++) {
        S = new PVector(sx, 0);

        // Loop over all T on bottom row
        for (int tx = 0; tx < m; tx++) {
          T = new PVector(tx, n - 1);

          found = false;
          foundPath = null;

          dfsEnumeratePaths();

          if (found) {
            println("FOUND  S=" + S + " T=" + T);
          } else {
            println("NONE   S=" + S + " T=" + T);
          }
          
          savePathToFile();   // <-- always save

        }
      }
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
  if (found) return;   // ⬅️ stop immediately if already found

  ArrayList<PVector> newPath = new ArrayList<PVector>(path);
  newPath.add(cur);

  // reached T
  if (cur.x == T.x && cur.y == T.y) {
    if (newPath.size() == m * n) {
      foundPath = newPath;
      found = true;
    }
    return;
  }

  int[][] dirs = {
    {1, 0},
    {0, 1},
    {-1, 0},
    {0, -1}
  };

  for (int[] d : dirs) {
    if (found) return;   // ⬅️ stop exploring siblings

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

void savePathToFile() {
  ArrayList<String> lines = new ArrayList<String>();

  // header (always written)
  lines.add("m=" + m);
  lines.add("n=" + n);
  lines.add("S=(" + (int)S.x + "," + (int)S.y + ")");
  lines.add("T=(" + (int)T.x + "," + (int)T.y + ")");
  lines.add("count=" + (found ? 1 : 0));
  lines.add("---");

  // only write path if it exists
  if (found && foundPath != null) {
    StringBuilder sb = new StringBuilder();
    sb.append("path=");

    for (int i = 0; i < foundPath.size(); i++) {
      PVector p = foundPath.get(i);
      sb.append("(").append((int)p.x).append(",").append((int)p.y).append(")");
      if (i < foundPath.size() - 1) sb.append("->");
    }

    lines.add(sb.toString());
  }

  // directory name based on m,n
  String dirName = "paths_m" + m + "_n" + n;
  ensureOutputDirectory(dirName);

  // filename includes S,T
  String filename =
    dirName + "/" +
    "paths_m" + m +
    "_n" + n +
    "_S(" + (int)S.x + "," + (int)S.y + ")" +
    "_T(" + (int)T.x + "," + (int)T.y + ").txt";

  saveStrings(filename, lines.toArray(new String[0]));
}

import frames.timing.*;
import frames.primitives.*;
import frames.processing.*;

// 1. Frames' objects
Scene scene;
Frame frame;
Vector v1, v2, v3;
// timing
TimingTask spinningTask;
boolean yDirection;
// scaling is a power of 2
int n = 4;

// 2. Hints
boolean triangleHint = true;
boolean gridHint = true;
boolean debug = true;

// 3. Use FX2D, JAVA2D, P2D or P3D
String renderer = P3D;

void setup() {
  //use 2^n to change the dimensions
  size(1024, 1024, renderer);
  scene = new Scene(this);
  if (scene.is3D())
    scene.setType(Scene.Type.ORTHOGRAPHIC);
  scene.setRadius(width/2);
  scene.fitBallInterpolation();

  // not really needed here but create a spinning task
  // just to illustrate some frames.timing features. For
  // example, to see how 3D spinning from the horizon
  // (no bias from above nor from below) induces movement
  // on the frame instance (the one used to represent
  // onscreen pixels): upwards or backwards (or to the left
  // vs to the right)?
  // Press ' ' to play it :)
  // Press 'y' to change the spinning axes defined in the
  // world system.
  spinningTask = new TimingTask() {
    public void execute() {
      spin();
    }
  };
  scene.registerTask(spinningTask);

  frame = new Frame();
  frame.setScaling(width/pow(2, n));

  // init the triangle that's gonna be rasterized
  randomizeTriangle();
}

void draw() {
  background(0);
  stroke(0, 255, 0);
  if (gridHint)
    scene.drawGrid(scene.radius(), (int)pow( 2, n));
  if (triangleHint)
    drawTriangleHint();
  pushMatrix();
  pushStyle();
  scene.applyTransformation(frame);
  triangleRaster();
  popStyle();
  popMatrix();
}

float orient2d(Vector a, Vector b, Vector c) {
  return ((frame.coordinatesOf(b).x() - frame.coordinatesOf(a).x()) *  (frame.coordinatesOf(c).y() - frame.coordinatesOf(a).y())) -
    ((frame.coordinatesOf(b).y() - frame.coordinatesOf(a).y()) *  (frame.coordinatesOf(c).x() - frame.coordinatesOf(a).x()));
}

float orient2d2(Vector a, Vector b, Vector c) {
  return ((frame.coordinatesOf(b).x() - frame.coordinatesOf(a).x()) *  (c.y() - frame.coordinatesOf(a).y())) -
    ((frame.coordinatesOf(b).y() - frame.coordinatesOf(a).y()) *  (c.x() - frame.coordinatesOf(a).x()));
}

// Implement this function to rasterize the triangle.
// Coordinates are given in the frame system which has a dimension of 2^n
void triangleRaster() {
  // frame.coordinatesOf converts from world to frame
  // here we convert v1 to illustrate the idea
  if (debug) {
    pushStyle();
    stroke(255, 255, 0, 125);
    stroke(#FF0000);
    point(round(frame.coordinatesOf(v1).x()), round(frame.coordinatesOf(v1).y()));
    stroke(#00FF00);
    point(round(frame.coordinatesOf(v2).x()), round(frame.coordinatesOf(v2).y()));
    stroke(#0000FF);
    point(round(frame.coordinatesOf(v3).x()), round(frame.coordinatesOf(v3).y()));
    popStyle();
  }
  int maxX = round(max(frame.coordinatesOf(v1).x(), frame.coordinatesOf(v2).x(), frame.coordinatesOf(v3).x()));
  int maxY = round(max(frame.coordinatesOf(v1).y(), frame.coordinatesOf(v2).y(), frame.coordinatesOf(v3).y()));
  int minX = round(min(frame.coordinatesOf(v1).x(), frame.coordinatesOf(v2).x(), frame.coordinatesOf(v3).x()));
  int minY = round(min(frame.coordinatesOf(v1).y(), frame.coordinatesOf(v2).y(), frame.coordinatesOf(v3).y()));
  strokeWeight(0);
  if (orient2d(v1, v2, v3)<0)
  {
    Vector tmp = v1;
    v1 = v2;
    v2 = tmp;
  }

  int antialiasing_subdiv = 4;

  for (int x = minX; x<=maxX; x++)
    for (int y = minY; y<=maxY; y++) {
      float avgCols[] = {0, 0, 0};
      for (float i = 0; i<1; i+=(float)1/antialiasing_subdiv)
        for (float j = 0; j<1; j+=(float)1/antialiasing_subdiv) {
          Vector p = new Vector(x+i+1/antialiasing_subdiv/2, y+i+1/antialiasing_subdiv/2);
          float w1 = orient2d2(v1, v2, p);
          float w2 = orient2d2(v2, v3, p);
          float w3 = orient2d2(v3, v1, p);
          if (w1 >= 0 && w2>=0 && w3>=0) {
            avgCols[0]+=w1*255/(w1+w2+w3)/(antialiasing_subdiv*antialiasing_subdiv);
            avgCols[1]+=w2*255/(w1+w2+w3)/(antialiasing_subdiv*antialiasing_subdiv);
            avgCols[2]+=w3*255/(w1+w2+w3)/(antialiasing_subdiv*antialiasing_subdiv);
          }
        }
      fill(color(round(avgCols[0]), round(avgCols[1]), round(avgCols[2])));
      Vector p = new Vector(x, y);
      rect(p.x(), p.y(), 1, 1);
    }
}

void randomizeTriangle() {
  int low = -width/2;
  int high = width/2;
  v1 = new Vector(random(low, high), random(low, high));
  v2 = new Vector(random(low, high), random(low, high));
  v3 = new Vector(random(low, high), random(low, high));
}

void drawTriangleHint() {
  pushStyle();
  noFill();
  strokeWeight(2);
  stroke(255, 0, 0);
  triangle(v1.x(), v1.y(), v2.x(), v2.y(), v3.x(), v3.y());
  strokeWeight(5);
  stroke(0, 255, 255);
  point(v1.x(), v1.y());
  point(v2.x(), v2.y());
  point(v3.x(), v3.y());
  popStyle();
}

void spin() {
  if (scene.is2D())
    scene.eye().rotate(new Quaternion(new Vector(0, 0, 1), PI / 100), scene.anchor());
  else
    scene.eye().rotate(new Quaternion(yDirection ? new Vector(0, 1, 0) : new Vector(1, 0, 0), PI / 100), scene.anchor());
}

void keyPressed() {
  if (key == 'g')
    gridHint = !gridHint;
  if (key == 't')
    triangleHint = !triangleHint;
  if (key == 'd')
    debug = !debug;
  if (key == '+') {
    n = n < 7 ? n+1 : 2;
    frame.setScaling(width/pow( 2, n));
  }
  if (key == '-') {
    n = n >2 ? n-1 : 7;
    frame.setScaling(width/pow( 2, n));
  }
  if (key == 'r')
    randomizeTriangle();
  if (key == ' ')
    if (spinningTask.isActive())
      spinningTask.stop();
    else
      spinningTask.run(20);
  if (key == 'y')
    yDirection = !yDirection;
}
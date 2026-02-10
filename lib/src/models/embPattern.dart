// TODO: Placeholder class model needs to be created to properly work with
class EmbPattern {
  void metadata(String key, String value) {
    print("Metadata: $key = $value");
  }

  void addThread(Map<String, String> thread) {
    print("Thread: $thread");
  }

  void colorChange(int dx, int dy) {
    print("Color change: dx=$dx, dy=$dy");
  }

  void sequinMode(int dx, int dy) {
    print("Sequin mode: dx=$dx, dy=$dy");
  }

  void sequinEject(int dx, int dy) {
    print("Sequin eject: dx=$dx, dy=$dy");
  }

  void move(int dx, int dy) {
    print("Move: dx=$dx, dy=$dy");
  }

  void stitch(int dx, int dy) {
    print("Stitch: dx=$dx, dy=$dy");
  }

  void end() {
    print("End of pattern");
  }

  void interpolateTrims(int countMax, double? trimDistance, bool clipping) {
    print(
      "Interpolate trims: countMax=$countMax, trimDistance=$trimDistance, clipping=$clipping",
    );
  }
}

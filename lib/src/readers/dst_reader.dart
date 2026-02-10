import 'dart:typed_data';

import 'package:dtembroidery/src/models/embPattern.dart';

/// Extract a single bit from a byte at the specified position
int getBit(int b, int pos) {
  return (b >> pos) & 1;
}

/// Decode the X displacement from three bytes
int decodeDx(int b0, int b1, int b2) {
  int x = 0;
  x += getBit(b2, 2) * 81;
  x += getBit(b2, 3) * (-81);
  x += getBit(b1, 2) * 27;
  x += getBit(b1, 3) * (-27);
  x += getBit(b0, 2) * 9;
  x += getBit(b0, 3) * (-9);
  x += getBit(b1, 0) * 3;
  x += getBit(b1, 1) * (-3);
  x += getBit(b0, 0) * 1;
  x += getBit(b0, 1) * (-1);
  return x;
}

/// Decode the Y displacement from three bytes
int decodeDy(int b0, int b1, int b2) {
  int y = 0;
  y += getBit(b2, 5) * 81;
  y += getBit(b2, 4) * (-81);
  y += getBit(b1, 5) * 27;
  y += getBit(b1, 4) * (-27);
  y += getBit(b0, 5) * 9;
  y += getBit(b0, 4) * (-9);
  y += getBit(b1, 7) * 3;
  y += getBit(b1, 6) * (-3);
  y += getBit(b0, 7) * 1;
  y += getBit(b0, 6) * (-1);
  return -y;
}

/// Process metadata from DST header
void processHeaderInfo(EmbPattern out, String prefix, String value) {
  switch (prefix) {
    case "LA":
      out.metadata("name", value);
      break;
    case "AU":
      out.metadata("author", value);
      break;
    case "CP":
      out.metadata("copyright", value);
      break;
    case "TC":
      List<String> values = value.split(",").map((x) => x.trim()).toList();
      if (values.length >= 3) {
        out.addThread({
          "hex": values[0],
          "description": values[1],
          "catalog": values[2],
        });
      }
      break;
    default:
      out.metadata(prefix, value);
  }
}

/// Read the DST file header (512 bytes)
void dstReadHeader(Uint8List header, EmbPattern out) {
  int start = 0;
  for (int i = 0; i < header.length; i++) {
    int element = header[i];
    if (element == 13 || element == 10) {
      // 13 == '\r', 10 == '\n'
      int end = i;
      Uint8List data = header.sublist(start, end);
      start = end;
      try {
        String line = String.fromCharCodes(data).trim();
        if (line.length > 3) {
          String prefix = line.substring(0, 2).trim();
          String value = line.substring(3).trim();
          processHeaderInfo(out, prefix, value);
        }
      } catch (e) {
        // Non-UTF8 information. See #83
        continue;
      }
    }
  }
}

/// Read DST stitch data
void dstReadStitches(
  Uint8List stitchData,
  EmbPattern out, [
  Map<String, dynamic>? settings,
]) {
  bool sequinMode = false;
  int offset = 0;

  while (offset + 3 <= stitchData.length) {
    int b0 = stitchData[offset];
    int b1 = stitchData[offset + 1];
    int b2 = stitchData[offset + 2];
    offset += 3;

    int dx = decodeDx(b0, b1, b2);
    int dy = decodeDy(b0, b1, b2);

    if ((b2 & 0xF3) == 0xF3) {
      break;
    } else if ((b2 & 0xC3) == 0xC3) {
      out.colorChange(dx, dy);
    } else if ((b2 & 0x43) == 0x43) {
      out.sequinMode(dx, dy);
      sequinMode = !sequinMode;
    } else if ((b2 & 0x83) == 0x83) {
      if (sequinMode) {
        out.sequinEject(dx, dy);
      } else {
        out.move(dx, dy);
      }
    } else {
      out.stitch(dx, dy);
    }
  }

  out.end();

  int countMax = 3;
  bool clipping = true;
  double? trimDistance;

  if (settings != null) {
    countMax = settings["trim_at"] ?? countMax;
    trimDistance = settings["trim_distance"] ?? trimDistance;
    clipping = settings["clipping"] ?? clipping;
  }

  if (trimDistance != null) {
    trimDistance *= 10; // Pixels per mm. Native units are 1/10 mm.
  }

  out.interpolateTrims(countMax, trimDistance, clipping);
}

/// Main read function for DST files
void read(
  Uint8List fileData,
  EmbPattern out, [
  Map<String, dynamic>? settings,
]) {
  // Read header (first 512 bytes)
  Uint8List header = fileData.sublist(0, 512.clamp(0, fileData.length));
  dstReadHeader(header, out);

  // Read stitch data (remaining bytes)
  Uint8List stitchData = fileData.length > 512
      ? fileData.sublist(512)
      : Uint8List(0);
  dstReadStitches(stitchData, out, settings);
}

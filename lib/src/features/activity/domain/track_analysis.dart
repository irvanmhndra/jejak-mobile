import 'activity.dart';

class Split {
  const Split(this.km, this.seconds);
  final int km;
  final double seconds;

  String get pace {
    final total = seconds.round();
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }
}

/// Per-full-kilometer splits, interpolated at each 1 km mark of the track.
List<Split> computeSplits(List<TrackPoint> points) {
  if (points.length < 2) return const [];
  final splits = <Split>[];
  var nextMark = 1000.0;
  var prevMarkTime = points.first.t.millisecondsSinceEpoch.toDouble();
  var km = 1;
  for (var i = 1; i < points.length; i++) {
    final prev = points[i - 1];
    final cur = points[i];
    while (cur.dist >= nextMark) {
      final span = (cur.dist - prev.dist) == 0 ? 1.0 : (cur.dist - prev.dist);
      final frac = (nextMark - prev.dist) / span;
      final markTime = prev.t.millisecondsSinceEpoch +
          frac * (cur.t.millisecondsSinceEpoch - prev.t.millisecondsSinceEpoch);
      splits.add(Split(km, (markTime - prevMarkTime) / 1000));
      prevMarkTime = markTime;
      nextMark += 1000;
      km++;
    }
  }
  return splits;
}

class ElevationPoint {
  const ElevationPoint(this.km, this.ele);
  final double km;
  final double ele;
}

/// Elevation vs. distance (km); empty when the track has no elevation data.
List<ElevationPoint> elevationSeries(List<TrackPoint> points) {
  final withEle = points.where((p) => p.ele != null).toList();
  if (withEle.length < 2) return const [];
  return [for (final p in withEle) ElevationPoint(p.dist / 1000, p.ele!)];
}

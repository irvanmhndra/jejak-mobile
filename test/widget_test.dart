import 'package:flutter_test/flutter_test.dart';

import 'package:jejak_mobile/src/core/utils/format.dart';

void main() {
  test('formatDuration formats h:mm:ss and mm:ss', () {
    expect(formatDuration(65), '01:05');
    expect(formatDuration(3661), '1:01:01');
  });

  test('formatDistance switches to km at 1000m', () {
    expect(formatDistance(820), '820 m');
    expect(formatDistance(5200), '5.20 km');
  });
}

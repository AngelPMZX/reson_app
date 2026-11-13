import 'package:flutter_test/flutter_test.dart';
import 'package:reson/features/network/network_service.dart';

void main() {
  group('What a scanned code is allowed to open', () {
    const id = 'a356218794b4266ff1a7fd434a61ee9d';

    test('a Reson card link resolves, in either of its shapes', () {
      // The QR the app draws, and the in-app route the public page links to.
      expect(publicIdFromScan('https://reson-app.web.app/c/$id'), id);
      expect(publicIdFromScan('https://reson-app.web.app/c/$id/'), id);
      expect(publicIdFromScan('https://reson-app.web.app/c/$id?lang=en'), id);
      expect(publicIdFromScan('https://reson-app.firebaseapp.com/c/$id'), id);
      expect(publicIdFromScan('https://reson-app.web.app/#/receive/$id'), id);
      expect(publicIdFromScan('  https://reson-app.web.app/c/$id  '), id);
      // A bare id is what some generators leave after stripping the scheme.
      expect(publicIdFromScan(id), id);
    });

    test('a code from anywhere else opens nothing', () {
      // A camera reads whatever is in front of it, so this is the gate: a
      // look-alike host must not become a navigation inside the app.
      for (final bad in [
        null,
        '',
        '   ',
        'hello world',
        'https://evil.com/c/$id',
        'https://reson-app.web.app.evil.com/c/$id',
        'javascript:alert(1)',
        'file:///c/$id',
        'https://reson-app.web.app/c/notavalidid',
        'https://reson-app.web.app/c/${id.toUpperCase()}',
        'https://reson-app.web.app/other/$id',
        id.substring(0, 31),
        '${id}f',
      ]) {
        expect(
          publicIdFromScan(bad),
          isNull,
          reason: 'should refuse ${bad ?? 'null'}',
        );
      }
    });

    test('a wifi or contact code is simply not a card', () {
      // The everyday codes somebody might point the camera at by mistake.
      expect(publicIdFromScan('WIFI:S:MyNet;T:WPA;P:secret;;'), isNull);
      expect(
        publicIdFromScan('BEGIN:VCARD\nVERSION:3.0\nFN:Alex\nEND:VCARD'),
        isNull,
      );
      expect(publicIdFromScan('tel:+525512345678'), isNull);
    });
  });
}

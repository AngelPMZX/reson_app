import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/firebase_options.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test(
    'Android registration and Dart options match the actual application ID',
    () {
      final native =
          jsonDecode(
                File('android/app/google-services.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final client = (native['client'] as List).single as Map<String, dynamic>;
      expect(
        client['client_info']['android_client_info']['package_name'],
        'com.thedarkingstudios.reson',
      );
      expect(
        client['client_info']['mobilesdk_app_id'],
        DefaultFirebaseOptions.android.appId,
      );
      expect(
        client['api_key'][0]['current_key'],
        DefaultFirebaseOptions.android.apiKey,
      );
      expect(
        native['project_info']['project_id'],
        DefaultFirebaseOptions.android.projectId,
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        DefaultFirebaseOptions.currentPlatform,
        DefaultFirebaseOptions.android,
      );
    },
  );

  test('iOS registration is bundled and matches Dart options', () {
    final plist = File(
      'ios/Runner/GoogleService-Info.plist',
    ).readAsStringSync();
    String value(String key) => RegExp(
      '<key>$key</key>\\s*<string>([^<]+)</string>',
    ).firstMatch(plist)!.group(1)!;
    expect(value('BUNDLE_ID'), DefaultFirebaseOptions.ios.iosBundleId);
    expect(value('GOOGLE_APP_ID'), DefaultFirebaseOptions.ios.appId);
    expect(value('API_KEY'), DefaultFirebaseOptions.ios.apiKey);
    expect(value('PROJECT_ID'), DefaultFirebaseOptions.ios.projectId);
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(
      'GoogleService-Info.plist in Resources'.allMatches(project).length,
      2,
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(DefaultFirebaseOptions.currentPlatform, DefaultFirebaseOptions.ios);
  });

  test('Platforms share project and use distinct app registrations', () {
    final options = [
      DefaultFirebaseOptions.android,
      DefaultFirebaseOptions.ios,
      DefaultFirebaseOptions.web,
    ];
    expect(options.map((value) => value.projectId).toSet(), {'reson-app'});
    expect(options.map((value) => value.appId).toSet().length, 3);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(
      () => DefaultFirebaseOptions.currentPlatform,
      throwsUnsupportedError,
    );
  });
}

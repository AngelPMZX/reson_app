import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Hands the account export to the person it belongs to.
///
/// A download on the web, where the browser already knows what to do with a
/// file, and the system share sheet elsewhere, which is the only place on a
/// phone where a file can actually go somewhere the owner chooses.
Future<void> saveExport(String json) async {
  final name =
      'reson-${DateTime.now().toIso8601String().split('T').first}.json';
  final file = XFile.fromData(
    utf8.encode(json),
    mimeType: 'application/json',
    name: name,
  );
  if (kIsWeb) {
    // The web implementation turns this into a download rather than a share.
    await SharePlus.instance.share(
      ShareParams(files: [file], fileNameOverrides: [name]),
    );
    return;
  }
  await SharePlus.instance.share(ShareParams(files: [file]));
}

/// Where an export goes. Behind a provider because the share sheet is a
/// platform plugin, and a test has no platform to hand it to.
final exportSinkProvider = Provider<Future<void> Function(String)>(
  (ref) => saveExport,
);

import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_bootstrap.dart';

// Enable only after the target Firebase project has a bucket and private rules.
const photoUploadsEnabled = bool.fromEnvironment(
  'RESON_PHOTO_UPLOADS_ENABLED',
  defaultValue: true,
);

class PhotoUploadsUnavailable implements Exception {
  const PhotoUploadsUnavailable();
}

const maxPhotoBytes = 3 * 1024 * 1024;
String photoContentType(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > maxPhotoBytes) {
    throw const FormatException('Photo size');
  }
  if (bytes.length > 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255) {
    return 'image/jpeg';
  }
  if (bytes.length > 8 &&
      bytes.take(8).join(',') == '137,80,78,71,13,10,26,10') {
    return 'image/png';
  }
  if (bytes.length > 12 &&
      String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
      String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP') {
    return 'image/webp';
  }
  throw const FormatException('Unsupported photo');
}

class CardMediaRepository {
  CardMediaRepository(this.uid, {this.uploadsEnabled = photoUploadsEnabled});
  final bool uploadsEnabled;
  final String uid;
  void _check() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid != uid || user?.emailVerified != true) {
      throw StateError('Verified owner required');
    }
  }

  Future<String> upload(String cardId, Uint8List bytes) async {
    if (!uploadsEnabled) throw const PhotoUploadsUnavailable();
    _check();
    final type = photoContentType(bytes);
    final path =
        'users/$uid/cards/$cardId/${DateTime.now().microsecondsSinceEpoch}';
    final task = FirebaseStorage.instance
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: type));
    await awaitPhotoUpload(task, () => task.cancel());
    _check();
    return path;
  }

  Future<String> uploadProfile(Uint8List bytes) async {
    if (!uploadsEnabled) throw const PhotoUploadsUnavailable();
    _check();
    final type = photoContentType(bytes);
    final path = 'users/$uid/profile/${DateTime.now().microsecondsSinceEpoch}';
    final task = FirebaseStorage.instance
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: type));
    await awaitPhotoUpload(task, () => task.cancel());
    _check();
    return path;
  }

  Future<Uint8List> download(String path) async {
    _check();
    if (!path.startsWith('users/$uid/cards/') &&
        !path.startsWith('users/$uid/profile/')) {
      throw StateError('Invalid photo owner');
    }
    final bytes = await FirebaseStorage.instance
        .ref(path)
        .getData(maxPhotoBytes)
        .timeout(const Duration(seconds: 15));
    _check();
    if (bytes == null) throw StateError('Missing photo');
    return bytes;
  }
}

final cardMediaProvider = Provider<CardMediaRepository>((ref) {
  final user = ref.watch(authSessionProvider).asData?.value;
  if (user == null || !user.emailVerified) {
    throw StateError('Verified owner required');
  }
  return CardMediaRepository(user.uid);
});
final cardPhotoProvider = FutureProvider.autoDispose.family<Uint8List, String>((
  ref,
  path,
) {
  return ref.watch(cardMediaProvider).download(path);
});

Future<T> awaitPhotoUpload<T>(
  Future<T> upload,
  Future<bool> Function() cancel, {
  Duration timeout = const Duration(seconds: 25),
}) async {
  try {
    return await upload.timeout(timeout);
  } on TimeoutException {
    try {
      await cancel().timeout(const Duration(seconds: 2));
    } catch (_) {}
    rethrow;
  }
}

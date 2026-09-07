import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_bootstrap.dart';

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
  CardMediaRepository(this.uid);
  final String uid;
  void _check() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid != uid || user?.emailVerified != true) {
      throw StateError('Verified owner required');
    }
  }

  Future<String> upload(String cardId, Uint8List bytes) async {
    _check();
    final type = photoContentType(bytes);
    final path =
        'users/$uid/cards/$cardId/${DateTime.now().microsecondsSinceEpoch}';
    await FirebaseStorage.instance
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: type));
    _check();
    return path;
  }

  Future<Uint8List> download(String path) async {
    _check();
    if (!path.startsWith('users/$uid/cards/')) {
      throw StateError('Invalid photo owner');
    }
    final bytes = await FirebaseStorage.instance
        .ref(path)
        .getData(maxPhotoBytes);
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

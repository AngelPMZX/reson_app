import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../cards/data/card_media_repository.dart';

/// Picks one picture to send. Behind a provider because the gallery is a
/// platform plugin and a test has no gallery to open.
typedef ChatImagePicker = Future<Uint8List?> Function();

Future<Uint8List?> pickChatImage() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    // A conversation does not need print resolution, and the ceiling in the
    // Storage rules is 3MB: shrinking here is what keeps a photo from being
    // refused after the person already chose it.
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  // Throws on anything that is not a JPEG, PNG or WebP within the ceiling,
  // which is exactly what Storage would refuse anyway.
  photoContentType(bytes);
  return bytes;
}

final chatImagePickerProvider = Provider<ChatImagePicker>(
  (ref) => pickChatImage,
);

/// Pictures sent inside a conversation.
///
/// They live at `connections/<connectionId>/<messageId>`, beside the thread
/// rather than under one account: both members have to keep reading them,
/// and the backend accepts an attachment only at the path of the very
/// message that names it.
class ChatMedia {
  const ChatMedia();

  String path(String connectionId, String messageId) =>
      'connections/$connectionId/$messageId';

  Future<void> upload(
    String connectionId,
    String messageId,
    Uint8List bytes,
  ) async {
    final type = photoContentType(bytes);
    final task = FirebaseStorage.instance
        .ref(path(connectionId, messageId))
        .putData(bytes, SettableMetadata(contentType: type));
    await awaitPhotoUpload(task, () => task.cancel());
  }

  Future<Uint8List> download(String storagePath) async {
    if (!storagePath.startsWith('connections/')) {
      throw StateError('Invalid attachment path');
    }
    final bytes = await FirebaseStorage.instance
        .ref(storagePath)
        .getData(maxPhotoBytes)
        .timeout(const Duration(seconds: 20));
    if (bytes == null) throw StateError('Missing attachment');
    return bytes;
  }
}

final chatMediaProvider = Provider<ChatMedia>((ref) => const ChatMedia());

/// The bytes behind one attachment. Kept alive only while a bubble is on
/// screen, so scrolling a long thread does not hold every picture in memory.
final chatImageProvider = FutureProvider.autoDispose.family<Uint8List, String>(
  (ref, path) => ref.watch(chatMediaProvider).download(path),
);

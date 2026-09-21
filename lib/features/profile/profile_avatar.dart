import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cards/data/card_media_repository.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.path = '',
    this.googleUrl,
    this.source = 'google',
    this.bytes,
    this.size = 88,
  });
  final String name, path, source;
  final String? googleUrl;
  final Uint8List? bytes;
  final double size;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Center(
      child: Text(
        name.trim().isEmpty ? 'R' : name.trim().characters.first.toUpperCase(),
        style: TextStyle(
          fontSize: size * .36,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
    Widget content = fallback;
    if (bytes != null) {
      content = Image.memory(
        bytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, e, st) => fallback,
      );
    } else if (source == 'upload' && path.isNotEmpty) {
      content = ref
          .watch(cardPhotoProvider(path))
          .when(
            loading: () => const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, st) => fallback,
            data: (data) => Image.memory(
              data,
              fit: BoxFit.cover,
              errorBuilder: (_, e, st) => fallback,
            ),
          );
    } else if (source == 'google' &&
        googleUrl != null &&
        Uri.tryParse(googleUrl!)?.scheme == 'https') {
      content = Image.network(
        googleUrl!,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, e, st) => fallback,
      );
    }
    return Semantics(
      image: true,
      label: name,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primaryContainer, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: ColoredBox(color: scheme.primaryContainer, child: content),
        ),
      ),
    );
  }
}

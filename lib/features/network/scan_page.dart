import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/reson_chrome.dart';
import '../../core/theme/reson_motion.dart';
import '../../core/theme/reson_surfaces.dart';
import '../../l10n/generated/app_localizations.dart';
import 'network_service.dart';

/// Reading somebody else's card instead of being read.
///
/// The app could draw a QR but never read one, so the natural gesture — being
/// shown a code and pointing at it — meant leaving for the system camera and
/// landing in a browser. Everything this screen decides lives in
/// [publicIdFromScan]; the camera only supplies strings.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});
  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  // One code opens one screen: a camera keeps reading while the route changes.
  bool _handled = false;
  String? _rejected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final code in capture.barcodes) {
      final id = publicIdFromScan(code.rawValue);
      if (id == null) continue;
      _handled = true;
      context.go('/receive/$id');
      return;
    }
    final seen = capture.barcodes.any((b) => (b.rawValue ?? '').isNotEmpty);
    if (seen && mounted && _rejected == null) {
      setState(() => _rejected = AppLocalizations.of(context)!.scanNotReson);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ResonSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: ResonSpace.xl),
                  ResonHeader(
                    leading: TextButton.icon(
                      onPressed: () => context.go('/network'),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(s.navNetwork),
                    ),
                  ),
                  const SizedBox(height: ResonSpace.xl),
                  Text(
                    s.scanTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(letterSpacing: -1),
                  ),
                  const SizedBox(height: ResonSpace.sm),
                  Text(
                    s.scanSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: ResonSpace.xl),
                  Expanded(child: _viewfinder(context, s)),
                  if (_rejected != null)
                    Padding(
                      padding: const EdgeInsets.only(top: ResonSpace.md),
                      child: Text(
                        _rejected!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: ResonSpace.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewfinder(BuildContext context, AppLocalizations s) => ClipRRect(
    borderRadius: BorderRadius.circular(ResonRadius.lg),
    child: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          // A camera can be absent, refused, or simply busy. None of those is
          // a crash, and each one needs its own sentence.
          errorBuilder: (context, error) => ResonPanel(
            child: ResonNotice(
              icon: switch (error.errorCode) {
                MobileScannerErrorCode.permissionDenied =>
                  Icons.no_photography_outlined,
                _ => Icons.videocam_off_outlined,
              },
              text: switch (error.errorCode) {
                MobileScannerErrorCode.permissionDenied => s.scanNoPermission,
                _ => s.scanNoCamera,
              },
              action: FilledButton(
                onPressed: () => _controller.start(),
                child: Text(s.scanRetry),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(ResonRadius.lg),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(ResonSpace.lg),
            child: Text(
              s.scanAim,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}

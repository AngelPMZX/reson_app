import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/reson_motion.dart';
import '../auth/presentation/brand_widgets.dart';

String tr(BuildContext context, String es, String en) =>
    Localizations.localeOf(context).languageCode == 'es' ? es : en;

class NetworkShell extends StatelessWidget {
  const NetworkShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResonLogo(
                  dark: Theme.of(context).brightness == Brightness.dark,
                ),
                const SizedBox(height: 30),
                TextButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(tr(context, 'Mis tarjetas', 'My cards')),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                ResonReveal(child: child),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class NetworkPanel extends StatelessWidget {
  const NetworkPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: child,
  );
}

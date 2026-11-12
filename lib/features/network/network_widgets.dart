import '../../core/theme/reson_chrome.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/reson_motion.dart';
import '../../core/theme/reson_surfaces.dart';
import 'network_service.dart';

String tr(BuildContext context, String es, String en) =>
    Localizations.localeOf(context).languageCode == 'es' ? es : en;

/// How long ago, in as few characters as a list row can spare.
///
/// Days are kept relative for a week, which is the span where "3 d" means
/// more than a date does; past that a date says it better.
String shortMoment(BuildContext context, DateTime at) {
  final gap = DateTime.now().difference(at);
  if (gap.inMinutes < 1) return AppLocalizations.of(context)!.timeNow;
  if (gap.inHours < 1) return '${gap.inMinutes} min';
  if (gap.inDays < 1) return '${gap.inHours} h';
  if (gap.inDays < 7) return '${gap.inDays} d';
  return '${at.day}/${at.month}';
}

/// Resolves a backend failure into the reader's language.
///
/// Always prefer this over calling [networkError] with a literal flag: passing
/// a hardcoded `true` pinned eight call sites to Spanish for every reader.
String networkErrorText(BuildContext context, Object error) =>
    networkError(error, Localizations.localeOf(context).languageCode == 'es');

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
        padding: ResonSpace.screen,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ResonHeader(),
                const SizedBox(height: ResonSpace.xxl),
                TextButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(tr(context, 'Mis tarjetas', 'My cards')),
                ),
                const SizedBox(height: ResonSpace.md),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(letterSpacing: -1),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: ResonSpace.md,
                      bottom: ResonSpace.xl,
                    ),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                const SizedBox(height: ResonSpace.md),
                ResonReveal(child: child),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Offers the next page of a bounded list.
///
/// The network lists ask Firestore for one page at a time, so a page that comes
/// back full means there may be more behind it. Without this the cap would hide
/// older connections instead of merely deferring them.
class NetworkMore extends StatelessWidget {
  const NetworkMore({
    super.key,
    required this.visible,
    required this.onPressed,
  });
  final bool visible;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => visible
      ? Padding(
          padding: const EdgeInsets.only(top: ResonSpace.sm),
          child: TextButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.expand_more),
            label: Text(tr(context, 'Ver más', 'Load more')),
          ),
        )
      : const SizedBox.shrink();
}

class NetworkPanel extends StatelessWidget {
  const NetworkPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: ResonSpace.lg),
    child: SizedBox(
      width: double.infinity,
      child: ResonPanel(
        padding: const EdgeInsets.all(ResonSpace.xl - 4),
        child: child,
      ),
    ),
  );
}

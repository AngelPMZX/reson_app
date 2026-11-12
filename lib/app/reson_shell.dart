import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/reson_surfaces.dart';
import '../features/network/network_service.dart';
import '../l10n/generated/app_localizations.dart';

/// The four places the app lives in.
///
/// Connections, conversations and saved cards used to share one scrolling
/// screen, so none of them had a home of its own and a chat was three levels
/// deep. Each is a destination now, always one tap away.
class ResonShell extends ConsumerWidget {
  const ResonShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  /// Above this a bottom bar is the wrong shape and a rail is the right one.
  static const _railWidth = 760.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final unread = ref.watch(unreadCountProvider);
    final items = <_Destination>[
      _Destination(Icons.style_outlined, Icons.style, s.navHome),
      _Destination(Icons.hub_outlined, Icons.hub, s.navNetwork),
      _Destination(
        Icons.forum_outlined,
        Icons.forum,
        s.navMessages,
        badge: unread,
      ),
      _Destination(Icons.person_outline, Icons.person, s.navProfile),
    ];
    final rail = MediaQuery.sizeOf(context).width >= _railWidth;
    return Scaffold(
      body: rail
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: _go,
                  labelType: NavigationRailLabelType.all,
                  destinations: [for (final i in items) i.rail(context)],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: shell),
              ],
            )
          : shell,
      bottomNavigationBar: rail
          ? null
          : NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              destinations: [for (final i in items) i.bar(context)],
            ),
    );
  }

  /// Tapping the destination you are already on returns it to its first page,
  /// which is what every app with a bar like this does.
  void _go(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);
}

class _Destination {
  const _Destination(this.icon, this.selected, this.label, {this.badge = 0});
  final IconData icon;
  final IconData selected;
  final String label;
  final int badge;

  Widget _icon(BuildContext context, IconData data) =>
      badge > 0 ? Badge.count(count: badge, child: Icon(data)) : Icon(data);

  NavigationDestination bar(BuildContext context) => NavigationDestination(
    icon: _icon(context, icon),
    selectedIcon: _icon(context, selected),
    label: label,
  );

  NavigationRailDestination rail(BuildContext context) =>
      NavigationRailDestination(
        icon: _icon(context, icon),
        selectedIcon: _icon(context, selected),
        label: Padding(
          padding: const EdgeInsets.only(bottom: ResonSpace.sm),
          child: Text(label),
        ),
      );
}

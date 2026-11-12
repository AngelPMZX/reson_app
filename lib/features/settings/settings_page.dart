import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/reson_chrome.dart';
import '../../core/theme/reson_motion.dart';
import '../../core/theme/reson_surfaces.dart';
import '../../core/theme/reson_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/firebase/firebase_bootstrap.dart';

/// Everything that is a preference rather than a piece of identity.
///
/// These were scattered: the connection chime sat at the top of the network
/// screen, above other people's requests, and signing out hid at the bottom of
/// a profile form. Both also offer something the header toggles cannot — going
/// back to following the device — because a two-state toggle has no way to say
/// "whichever my phone is".
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool sound = false, busy = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() => sound = p.getBool('connectionSound') ?? false);
      }
    });
  }

  Future<void> _setSound(bool value) async {
    setState(() => sound = value);
    try {
      await (await SharedPreferences.getInstance()).setBool(
        'connectionSound',
        value,
      );
    } catch (_) {
      /* Device preferences are optional. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final mode = ref.watch(appearanceProvider);
    final locale = ref.watch(localeProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResonSpace.screen,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ResonHeader(
                    leading: TextButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(s.backCards),
                    ),
                  ),
                  const SizedBox(height: ResonSpace.xl),
                  Text(
                    s.settings,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(letterSpacing: -1),
                  ),
                  const SizedBox(height: ResonSpace.sm),
                  Text(
                    s.settingsSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: ResonSpace.xl),
                  _Section(
                    title: s.settingsAppearance,
                    note: s.settingsAppearanceNote,
                    child: _Choice<ThemeMode>(
                      group: 'appearance',
                      value: mode,
                      options: {
                        ThemeMode.system: s.settingsFollowSystem,
                        ThemeMode.light: s.settingsLight,
                        ThemeMode.dark: s.settingsDark,
                      },
                      onChanged: (v) =>
                          ref.read(appearanceProvider.notifier).set(v),
                    ),
                  ),
                  _Section(
                    title: s.settingsLanguage,
                    note: s.settingsLanguageNote,
                    child: _Choice<String?>(
                      group: 'language',
                      value: locale?.languageCode,
                      options: {
                        null: s.settingsFollowSystem,
                        'es': 'Español',
                        'en': 'English',
                      },
                      onChanged: (v) => v == null
                          ? ref.read(localeProvider.notifier).follow()
                          : ref.read(localeProvider.notifier).set(Locale(v)),
                    ),
                  ),
                  _Section(
                    title: s.settingsSound,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.connectionSound),
                      subtitle: Text(s.connectionSoundNote),
                      value: sound,
                      onChanged: _setSound,
                    ),
                  ),
                  _Section(
                    title: s.settingsAccount,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: busy
                            ? null
                            : () async {
                                setState(() => busy = true);
                                try {
                                  await (await ref.read(
                                    authRepositoryProvider.future,
                                  ))?.signOut();
                                } catch (_) {
                                  if (mounted) setState(() => busy = false);
                                }
                              },
                        icon: const Icon(Icons.logout),
                        label: Text(s.logout),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.note});
  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: ResonSpace.lg),
    child: ResonPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (note != null) ...[
            const SizedBox(height: ResonSpace.xs),
            Text(
              note!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: ResonSpace.md),
          child,
        ],
      ),
    ),
  );
}

/// A row of mutually exclusive choices that wraps instead of overflowing.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.group,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  /// Names the row, because "System" is an option in more than one of them and
  /// a label alone cannot say which row it belongs to.
  final String group;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  /// A stable id for an option, so an enum does not key itself as
  /// `ThemeMode.dark` and no option is keyed by its translated label.
  static String _id(Object? value) => switch (value) {
    null => 'system',
    Enum e => e.name,
    _ => '$value',
  };

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: ResonSpace.sm,
    runSpacing: ResonSpace.sm,
    children: [
      for (final entry in options.entries)
        ChoiceChip(
          key: Key('$group-${_id(entry.key)}'),
          label: Text(entry.value),
          selected: entry.key == value,
          onSelected: (_) => onChanged(entry.key),
        ),
    ],
  );
}

import '../../core/theme/reson_chrome.dart';
import '../../core/theme/reson_palette.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import '../cards/data/card_media_repository.dart';
import 'profile_avatar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/reson_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/theme/reson_motion.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/presentation/brand_widgets.dart';
import '../cards/domain/professional_profile.dart';
import '../cards/presentation/professional_editor.dart';
import '../cards/domain/digital_card.dart';
import 'personal_profile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    return ref
        .watch(personalProfileProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, st) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.cardLoadError),
                  TextButton(
                    onPressed: () => ref.invalidate(personalProfileProvider),
                    child: Text(s.retry),
                  ),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(s.backCards),
                  ),
                ],
              ),
            ),
          ),
          data: (profile) => _ProfileForm(initial: profile),
        );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({this.initial});
  final PersonalProfile? initial;
  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late Map<String, TextEditingController> _fields;
  late ProfessionalProfile _professional;
  bool _busy = false, _dirty = false;
  bool _pending = false;
  int _revision = 0;
  Uint8List? _photoBytes;
  String _photoPath = '', _photoSource = 'google', _availability = 'private';
  String? _uploadedPath;
  String? _message;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    final user = ref.read(authSessionProvider).asData?.value;
    final data =
        widget.initial ??
        PersonalProfile(
          fields: {'name': user?.name ?? '', 'email': user?.email ?? ''},
        );
    _professional = data.professional;
    _photoPath = data.photoPath;
    _photoSource = data.photoSource;
    _availability = data.availability;
    _fields = {
      for (final key in PersonalProfile.limits.keys)
        key: TextEditingController(text: data.value(key)),
    };
    for (final c in _fields.values) {
      c.addListener(() {
        _revision++;
        if (mounted) setState(() => _dirty = true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _confirmLeave() async {
    final s = AppLocalizations.of(context)!;
    if (_dirty) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.profileDiscard),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.profileStay),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.profileLeave),
            ),
          ],
        ),
      );
      if (leave != true) return false;
    }
    return true;
  }

  Future<void> _back() async {
    if (await _confirmLeave() && mounted) context.go('/home');
  }

  Future<void> _pickPhoto() async {
    if (_busy || _pending) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) return;
      if (await file.length() > maxPhotoBytes) {
        throw const FormatException('size');
      }
      final bytes = await file.readAsBytes();
      photoContentType(bytes);
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1024);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
      if (mounted) {
        setState(() {
          _photoBytes = bytes;
          _uploadedPath = null;
          _photoSource = 'upload';
          _dirty = true;
          _revision++;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _message = AppLocalizations.of(context)!.designChooseAJPGPNGOrWebP;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _choosePhotoSource(String source) {
    setState(() {
      _photoSource = source;
      _photoBytes = null;
      _uploadedPath = null;
      _photoPath = '';
      _dirty = true;
      _revision++;
    });
  }

  Future<void> _save() async {
    if (_busy || _pending || !_form.currentState!.validate()) return;
    final repo = ref.read(personalProfileRepositoryProvider);
    if (repo == null) return;
    final revision = _revision;
    setState(() {
      _busy = true;
      _pending = true;
      _message = null;
    });
    final draft = PersonalProfile(
      fields: _fields.map((k, v) => MapEntry(k, v.text.trim())),
      professional: _professional,
      photoPath: _photoPath,
      photoSource: _photoSource,
      availability: _availability,
    );
    final bytes = _photoBytes;
    final operation = Future<void>.sync(() async {
      var path = draft.photoPath;
      if (bytes != null && draft.photoSource == 'upload') {
        path =
            _uploadedPath ??
            await ref.read(cardMediaProvider).uploadProfile(bytes);
        if (mounted && revision == _revision) _uploadedPath = path;
      }
      await repo.save(
        PersonalProfile(
          fields: draft.fields,
          professional: draft.professional,
          photoPath: path,
          photoSource: draft.photoSource,
          availability: draft.availability,
        ),
      );
    });
    unawaited(
      operation.then(
        (_) {
          if (mounted) {
            setState(() {
              _pending = false;
              if (_revision == revision) _dirty = false;
              _message = AppLocalizations.of(context)!.profileSaved;
              _failed = false;
            });
          }
        },
        onError: (Object error, StackTrace stack) {
          if (mounted) {
            setState(() {
              _pending = false;
              _message = AppLocalizations.of(context)!.cardSaveError;
              _failed = true;
            });
          }
        },
      ),
    );
    try {
      await operation.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _message = AppLocalizations.of(context)!.saveUnconfirmed;
          _failed = true;
        });
      }
    } catch (_) {
      /* The completion listener reports the original failure. */
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authSessionProvider).asData?.value;
    final labels = {
      'name': s.name,
      'role': s.jobTitle,
      'company': s.company,
      'bio': s.designAboutYou,
      'email': s.email,
      'phone': s.phone,
      'website': s.website,
      'languages': s.profileLanguages,
      'services': s.profileServices,
    };
    return PopScope(
      canPop: !_dirty && !_busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_busy) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              ResonSpace.xl,
              ResonSpace.xl,
              ResonSpace.xl,
              ResonSpace.huge,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ResonHeader(),
                    const SizedBox(height: ResonSpace.lg),
                    TextButton.icon(
                      onPressed: _busy ? null : _back,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(s.backCards),
                    ),
                    ResonReveal(
                      child: ResonPanel(
                        padding: EdgeInsets.zero,
                        raised: true,
                        clip: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 78,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    ResonPalette.wine,
                                    ResonPalette.deepWine,
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(ResonSpace.xl),
                              child: Text(
                                s.profileStudio,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(ResonSpace.xl),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ProfileAvatar(
                                        name: _fields['name']!.text,
                                        path: _uploadedPath ?? _photoPath,
                                        source: _photoSource,
                                        googleUrl: user?.googlePhotoUrl,
                                        bytes: _photoBytes,
                                      ),
                                      const SizedBox(width: ResonSpace.lg),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _fields['name']!.text
                                                      .trim()
                                                      .isEmpty
                                                  ? s.profileTitle
                                                  : _fields['name']!.text,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    letterSpacing: -.7,
                                                  ),
                                            ),
                                            const SizedBox(
                                              height: ResonSpace.xs,
                                            ),
                                            Text(
                                              _fields['role']!.text
                                                      .trim()
                                                      .isEmpty
                                                  ? s.profileTagline
                                                  : _fields['role']!.text,
                                              style: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: ResonSpace.lg),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      OutlinedButton.icon(
                                        key: const Key('profilePickPhoto'),
                                        onPressed: _busy || _pending
                                            ? null
                                            : _pickPhoto,
                                        icon: const Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 18,
                                        ),
                                        label: Text(s.designChoosePhoto),
                                      ),
                                      if (user?.googlePhotoUrl != null)
                                        TextButton(
                                          onPressed: _busy || _pending
                                              ? null
                                              : () => _choosePhotoSource(
                                                  'google',
                                                ),
                                          child: Text(s.profileUseGoogle),
                                        ),
                                      if (_photoSource == 'upload' ||
                                          (_photoSource == 'google' &&
                                              user?.googlePhotoUrl != null))
                                        TextButton(
                                          onPressed: _busy || _pending
                                              ? null
                                              : () =>
                                                    _choosePhotoSource('none'),
                                          child: Text(s.designRemovePhoto),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    s.profilePhotoHint,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          height: 1.5,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: ResonSpace.xl),
                    Text(
                      s.profileAvailability,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: ResonSpace.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final item in {
                          'private': s.profileStatusPrivate,
                          'projects': s.profileStatusProjects,
                          'employment': s.profileStatusEmployment,
                          'unavailable': s.profileStatusUnavailable,
                        }.entries)
                          ChoiceChip(
                            label: Text(item.value),
                            selected: _availability == item.key,
                            showCheckmark: false,
                            onSelected: _busy || _pending
                                ? null
                                : (_) => setState(() {
                                    _availability = item.key;
                                    _dirty = true;
                                    _revision++;
                                  }),
                          ),
                      ],
                    ),
                    const SizedBox(height: ResonSpace.xxl),
                    Text(
                      s.profileDetails,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: ResonSpace.sm),
                    Text(
                      s.profileIntro,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: ResonSpace.xl),
                    Form(
                      key: _form,
                      child: Column(
                        children: [
                          for (final entry in labels.entries)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: ResonSpace.lg,
                              ),
                              child: TextFormField(
                                key: ValueKey('profile_${entry.key}'),
                                controller: _fields[entry.key],
                                enabled: !_busy,
                                maxLength: PersonalProfile.limits[entry.key],
                                maxLines: entry.key == 'bio' ? 3 : 1,
                                keyboardType: entry.key == 'email'
                                    ? TextInputType.emailAddress
                                    : entry.key == 'phone'
                                    ? TextInputType.phone
                                    : entry.key == 'website'
                                    ? TextInputType.url
                                    : TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: entry.value,
                                  counterText: '',
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (entry.key == 'website' &&
                                      text.isNotEmpty) {
                                    final uri = Uri.tryParse(text);
                                    if (uri == null ||
                                        ![
                                          'http',
                                          'https',
                                        ].contains(uri.scheme) ||
                                        uri.host.isEmpty) {
                                      return s.profileUrlError;
                                    }
                                  }
                                  if (entry.key == 'email' &&
                                      text.isNotEmpty &&
                                      !RegExp(
                                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                      ).hasMatch(text)) {
                                    return s.profileEmailError;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ProfessionalEditor(
                            initial: _professional,
                            enabled: !_busy,
                            visible: DigitalCard.defaultFields.toSet(),
                            onChanged: (p) {
                              _professional = p;
                              _revision++;
                              _dirty = true;
                            },
                            onVisibility: (_, show) {},
                            showVisibility: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: ResonSpace.xl),
                    if (_message != null)
                      FeedbackMessage(text: _message!, error: _failed),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy || _pending ? null : _save,
                        child: Text(_busy ? s.savingCard : s.profileSave),
                      ),
                    ),
                    const SizedBox(height: ResonSpace.xxl),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.verified_user_outlined,
                        color: scheme.primary,
                      ),
                      title: Text(s.profileVerified),
                      subtitle: Text(user?.email ?? ''),
                    ),
                    Text(
                      s.profileEmailNote,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: ResonSpace.lg),
                    // Signing out moved to Settings: it is a preference about
                    // the app, not a field of your identity, and here it was
                    // tangled with the unsaved-changes guard of this form.
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              if (_dirty) {
                                await _back();
                                return;
                              }
                              if (mounted) context.go('/settings');
                            },
                      icon: const Icon(Icons.tune),
                      label: Text(s.openSettings),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

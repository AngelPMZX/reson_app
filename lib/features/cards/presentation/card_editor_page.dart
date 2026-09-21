import '../../profile/personal_profile.dart';
import '../../../core/theme/reson_motion.dart';
import '../domain/professional_profile.dart';
import 'professional_editor.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import '../data/card_media_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/theme/reson_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/brand_widgets.dart';
import '../application/cards_providers.dart';
import '../domain/digital_card.dart';
import 'card_preview.dart';

class CardEditorPage extends ConsumerWidget {
  const CardEditorPage({super.key, this.cardId});
  final String? cardId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final user = ref.watch(authSessionProvider).asData?.value;
    if (user == null || !user.emailVerified) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (cardId == null) {
      return ref
          .watch(personalProfileProvider)
          .when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, stack) => Scaffold(
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
            data: (profile) => _Editor(
              initial: (profile ?? PersonalProfile()).newCard(
                fallbackName: user.name ?? '',
                fallbackEmail: user.email,
              ),
            ),
          );
    }
    return ref
        .watch(cardsProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.cardLoadError),
                  TextButton(
                    onPressed: () => ref.invalidate(cardsProvider),
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
          data: (cards) {
            for (final card in cards) {
              if (card.id == cardId) {
                return _Editor(key: ValueKey(card.id), initial: card);
              }
            }
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.cardNotFound),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: Text(s.backCards),
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({super.key, required this.initial});
  final DigitalCard initial;
  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  bool _busy = false;
  bool _error = false;
  bool _dirty = false;
  String? _newId;
  late String _kind, _layout, _photoPath;
  late Set<String> _visible;
  Uint8List? _photo;
  String? _photoError;
  String? _uploadedPath;
  late ProfessionalProfile _professional;
  Future<void>? _pendingWrite;
  String? _saveMessage;
  bool _uploading = false;
  Future<void> _pickPhoto() async {
    setState(() {
      _busy = true;
      _photoError = null;
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
          _photo = bytes;
          _uploadedPath = null;
          _dirty = true;
          _visible.add('photo');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _photoError = AppLocalizations.of(
            context,
          )!.designChooseAJPGPNGOrWebP,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _professional = c.professional;
    _kind = c.kind;
    _layout = c.layout;
    _photoPath = c.photoPath;
    _visible = c.visibleFields.toSet();
    _fields = {
      'label': c.label,
      'bio': c.bio,
      'name': c.displayName,
      'role': c.role,
      'company': c.company,
      'email': c.email,
      'phone': c.phone,
      'website': c.website,
      'color': c.primaryHex,
    }.map((key, value) => MapEntry(key, TextEditingController(text: value)));
    for (final controller in _fields.values) {
      controller.addListener(_changed);
    }
  }

  void _changed() {
    setState(() => _dirty = true);
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  String _value(String key) => _fields[key]!.text.trim();
  DigitalCard get _draft => DigitalCard(
    id: widget.initial.id,
    label: _value('label'),
    displayName: _value('name'),
    role: _value('role'),
    company: _value('company'),
    email: _value('email'),
    phone: _value('phone'),
    website: _value('website'),
    primaryHex: _value('color').toUpperCase(),
    kind: _kind,
    layout: _layout,
    bio: _value('bio'),
    photoPath: _photoPath,
    visibleFields: _visible.toList(),
    professional: _professional,
  );

  Future<void> _back() async {
    if (_busy) return;
    final s = AppLocalizations.of(context)!;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.discardTitle),
          content: Text(s.discardBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.discard),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (mounted) context.go('/home');
  }

  Future<void> _save() async {
    if (_busy || _pendingWrite != null || !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = false;
      _saveMessage = null;
      _photoError = null;
    });
    try {
      final repo = await ref
          .read(cardsRepositoryProvider.future)
          .timeout(const Duration(seconds: 10));
      if (repo == null) throw StateError('Verified session required');
      final c = _draft;
      _newId ??= c.id.isEmpty ? repo.newId() : c.id;
      if (_photo != null && _uploadedPath == null) {
        if (mounted) setState(() => _uploading = true);
        try {
          _uploadedPath = await ref
              .read(cardMediaProvider)
              .upload(_newId!, _photo!);
        } catch (error) {
          if (mounted) {
            setState(
              () => _photoError = error is PhotoUploadsUnavailable
                  ? AppLocalizations.of(context)!.photoUploadsUnavailable
                  : AppLocalizations.of(context)!.photoUploadFailed,
            );
          }
          rethrow;
        }
      }
      if (!mounted) return;
      setState(() => _uploading = false);
      final pending = repo.save(
        c.withIdAndPhoto(_newId!, _uploadedPath ?? _photoPath),
      );
      _pendingWrite = pending;
      // A UI timeout does not cancel a server write. Do not allow overlapping saves.
      unawaited(
        pending.then(
          (_) {
            if (mounted) {
              final late = !_busy;
              setState(() {
                _pendingWrite = null;
                if (late) _error = false;
              });
              if (late) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.lateSaveConfirmed,
                    ),
                  ),
                );
              }
            }
          },
          onError: (Object error, StackTrace stack) {
            if (mounted) {
              setState(() {
                _pendingWrite = null;
                if (!_busy) {
                  _error = true;
                  _saveMessage = AppLocalizations.of(context)!.cardSaveError;
                }
              });
            }
          },
        ),
      );
      await pending.timeout(const Duration(seconds: 30));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.savedCard)),
        );
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = true;
          final strings = AppLocalizations.of(context)!;
          _saveMessage =
              _photoError ??
              (error is TimeoutException
                  ? (_pendingWrite != null
                        ? strings.saveUnconfirmed
                        : strings.saveTimeout)
                  : error is FirebaseException &&
                        error.code == 'permission-denied'
                  ? strings.savePermission
                  : strings.cardSaveError);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final draft = _draft;
    return PopScope(
      canPop: !_dirty && !_busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResonLogo(
                      dark: Theme.of(context).brightness == Brightness.dark,
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: _busy ? null : _back,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(s.backCards),
                    ),
                    const SizedBox(height: 16),
                    ResonReveal(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.auto_awesome_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.initial.id.isEmpty
                                  ? s.newCard
                                  : s.editCard,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.cardEditorBody,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    LayoutBuilder(
                      builder: (context, bounds) {
                        final form = Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _customization(),
                              const SizedBox(height: 24),
                              _field(
                                'label',
                                s.cardLabel,
                                max: 60,
                                required: true,
                                hint: s.cardLabelHint,
                              ),
                              _field('name', s.name, max: 80, required: true),
                              _field('role', s.jobTitle, max: 100),
                              _field('company', s.company, max: 100),
                              _field(
                                'bio',
                                AppLocalizations.of(context)!.designAboutYou,
                                max: 240,
                              ),
                              _field(
                                'email',
                                s.email,
                                max: 254,
                                type: TextInputType.emailAddress,
                              ),
                              _field(
                                'phone',
                                s.phone,
                                max: 32,
                                type: TextInputType.phone,
                              ),
                              _field(
                                'website',
                                s.website,
                                max: 500,
                                type: TextInputType.url,
                                hint: 'https://',
                              ),
                              ProfessionalEditor(
                                initial: _professional,
                                enabled: !_busy,
                                visible: _visible,
                                onChanged: (value) => setState(() {
                                  _professional = value;
                                  _dirty = true;
                                }),
                                onVisibility: (key, show) => setState(() {
                                  _dirty = true;
                                  show
                                      ? _visible.add(key)
                                      : _visible.remove(key);
                                }),
                              ),
                              _field(
                                'color',
                                s.brandColor,
                                max: 7,
                                required: true,
                              ),
                              Wrap(
                                spacing: 10,
                                children:
                                    [
                                          '#D32945',
                                          '#7860E9',
                                          '#A78BFA',
                                          '#5B21B6',
                                          '#C2415B',
                                          '#B45309',
                                          '#2563EB',
                                          '#0891B2',
                                          '#0D9488',
                                          '#15803D',
                                          '#BE185D',
                                          '#E11D48',
                                          '#EA580C',
                                          '#334155',
                                          '#111827',
                                          '#7C3AED',
                                          '#D97706',
                                        ]
                                        .map(
                                          (hex) => Semantics(
                                            label: hex,
                                            selected: draft.primaryHex == hex,
                                            child: IconButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () =>
                                                        _fields['color']!.text =
                                                            hex,
                                              icon: Icon(
                                                draft.primaryHex == hex
                                                    ? Icons.check_circle
                                                    : Icons.circle,
                                                color: cardColor(hex),
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                              const SizedBox(height: 24),
                              if (_error) ...[
                                FeedbackMessage(
                                  text: _saveMessage ?? s.cardSaveError,
                                  error: true,
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (_photoError != null && _photo != null)
                                TextButton(
                                  key: const Key('saveWithoutNewPhoto'),
                                  onPressed: _busy || _pendingWrite != null
                                      ? null
                                      : () {
                                          setState(() {
                                            _photo = null;
                                            _uploadedPath = null;
                                            _photoError = null;
                                          });
                                          _save();
                                        },
                                  child: Text(s.saveWithoutNewPhoto),
                                ),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  key: const Key('saveCard'),
                                  onPressed: _busy || _pendingWrite != null
                                      ? null
                                      : _save,
                                  child: Text(
                                    _busy
                                        ? (_uploading
                                              ? s.uploadingPhoto
                                              : s.savingCard)
                                        : _pendingWrite != null
                                        ? s.confirmingSave
                                        : s.saveCard,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        final preview = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.previewCard,
                              style: const TextStyle(
                                color: ResonTheme.muted,
                                letterSpacing: 2,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CardPreview(card: draft, photoBytes: _photo),
                            const SizedBox(height: 14),
                            Text(
                              s.privateCard,
                              style: const TextStyle(
                                color: ResonTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                        return bounds.maxWidth >= 760
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: form),
                                  const SizedBox(width: 40),
                                  Expanded(child: preview),
                                ],
                              )
                            : Column(
                                children: [
                                  preview,
                                  const SizedBox(height: 32),
                                  form,
                                ],
                              );
                      },
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

  Widget _customization() {
    final tip = _kind == 'work'
        ? AppLocalizations.of(context)!.designForWorkFeatureYourRoleCompany
        : _kind == 'freelance'
        ? AppLocalizations.of(context)!.designForFreelanceExplainYourServicesIn
        : AppLocalizations.of(context)!.designForPersonalUseShareOnlyWhat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.designYourStyle,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in {
              'work': AppLocalizations.of(context)!.designWork,
              'freelance': 'Freelance',
              'personal': 'Personal',
            }.entries)
              ChoiceChip(
                label: Text(item.value),
                selected: _kind == item.key,
                onSelected: _busy
                    ? null
                    : (_) => setState(() {
                        _kind = item.key;
                        _dirty = true;
                        _visible = DigitalCard.defaultFields.toSet();
                        if (_kind == 'freelance') _visible.remove('company');
                        if (_kind == 'personal') {
                          _visible.removeAll(['company', 'role', 'phone']);
                        }
                      }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: .4),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(tip, style: const TextStyle(height: 1.5))),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in {
              'signature': AppLocalizations.of(context)!.designSignature,
              'minimal': AppLocalizations.of(context)!.designMinimal,
              'bold': AppLocalizations.of(context)!.designBold,
              'aurora': AppLocalizations.of(context)!.styleAurora,
              'executive': AppLocalizations.of(context)!.styleExecutive,
              'editorial': AppLocalizations.of(context)!.styleEditorial,
              'noir': AppLocalizations.of(context)!.styleNoir,
              'studio': AppLocalizations.of(context)!.styleStudio,
            }.entries)
              ChoiceChip(
                label: Text(item.value),
                selected: _layout == item.key,
                onSelected: _busy
                    ? null
                    : (_) => setState(() {
                        _layout = item.key;
                        _dirty = true;
                      }),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          AppLocalizations.of(context)!.designPhotograph,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('choosePhoto'),
              onPressed: _busy || !photoUploadsEnabled ? null : _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(AppLocalizations.of(context)!.designChoosePhoto),
            ),
            if (_photo != null || _photoPath.isNotEmpty)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _photo = null;
                        _photoPath = '';
                        _uploadedPath = null;
                        _dirty = true;
                      }),
                child: Text(AppLocalizations.of(context)!.designRemovePhoto),
              ),
          ],
        ),
        if (!photoUploadsEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(AppLocalizations.of(context)!.photoUploadsUnavailable),
          ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(AppLocalizations.of(context)!.designShowPortrait),
          value: _visible.contains('photo'),
          onChanged: _busy
              ? null
              : (show) => setState(() {
                  _dirty = true;
                  show ? _visible.add('photo') : _visible.remove('photo');
                }),
        ),
        if (_photoError != null)
          FeedbackMessage(text: _photoError!, error: true),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.designYourInformation,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.designUseTheEyeIconToChoose,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _field(
    String key,
    String label, {
    required int max,
    bool required = false,
    String? hint,
    TextInputType? type,
  }) {
    final s = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        key: Key('card_$key'),
        controller: _fields[key],
        enabled: !_busy,
        keyboardType: type,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: DigitalCard.defaultFields.contains(key)
              ? IconButton(
                  tooltip: _visible.contains(key)
                      ? AppLocalizations.of(context)!.designHideOnCard
                      : AppLocalizations.of(context)!.designShowOnCard,
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _dirty = true;
                          _visible.contains(key)
                              ? _visible.remove(key)
                              : _visible.add(key);
                        }),
                  icon: Icon(
                    _visible.contains(key)
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                )
              : null,
        ),
        validator: (raw) {
          final value = (raw ?? '').trim();
          if (required && value.isEmpty) return s.required;
          if (value.length > max) return s.maxLength;
          if (key == 'email' &&
              value.isNotEmpty &&
              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
            return s.invalidEmail;
          }
          if (key == 'website' && value.isNotEmpty) {
            final uri = Uri.tryParse(value);
            if (uri == null ||
                !['https', 'http'].contains(uri.scheme) ||
                uri.host.isEmpty) {
              return s.invalidWebsite;
            }
          }
          if (key == 'color' && !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
            return s.invalidColor;
          }
          return null;
        },
      ),
    );
  }
}

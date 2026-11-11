import '../../../core/theme/reson_palette.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/reson_surfaces.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'brand_widgets.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final wide = bounds.maxWidth >= 900;
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 1240,
                      minHeight: bounds.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 64 : 24,
                        30,
                        wide ? 64 : 24,
                        28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ResonLogo(),
                          SizedBox(height: wide ? 70 : 44),
                          Flex(
                            direction: wide ? Axis.horizontal : Axis.vertical,
                            crossAxisAlignment: wide
                                ? CrossAxisAlignment.center
                                : CrossAxisAlignment.start,
                            children: [
                              if (wide)
                                Expanded(child: _IntroCopy(wide: wide))
                              else
                                _IntroCopy(wide: wide),
                              SizedBox(
                                width: wide ? 60 : 0,
                                height: wide ? 0 : 30,
                              ),
                              if (wide)
                                const Expanded(child: IdentityPreview())
                              else
                                const Center(
                                  child: IdentityPreview(compact: true),
                                ),
                            ],
                          ),
                          SizedBox(height: wide ? 72 : 44),
                          const Divider(color: ResonPalette.darkBorder),
                          const SizedBox(height: ResonSpace.xxl),
                          Wrap(
                            spacing: 26,
                            runSpacing: 26,
                            children:
                                [
                                      (
                                        Icons.layers_outlined,
                                        s.featureOne,
                                        s.featureOneBody,
                                      ),
                                      (
                                        Icons.palette_outlined,
                                        s.featureTwo,
                                        s.featureTwoBody,
                                      ),
                                      (
                                        Icons.qr_code_rounded,
                                        s.featureThree,
                                        s.featureThreeBody,
                                      ),
                                    ]
                                    .map(
                                      (item) => SizedBox(
                                        width: wide
                                            ? (bounds.maxWidth.clamp(0, 1240) -
                                                      180) /
                                                  3
                                            : double.infinity,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              item.$1,
                                              color: ResonPalette.white,
                                              size: 23,
                                            ),
                                            const SizedBox(width: 13),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.$2,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge
                                                        ?.copyWith(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                  const SizedBox(
                                                    height: ResonSpace.sm,
                                                  ),
                                                  Text(
                                                    item.$3,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color: ResonPalette
                                                              .paleGrey,
                                                          height: 1.6,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: ResonSpace.huge),
                          Text(
                            s.publisher,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: ResonPalette.paleGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IntroCopy extends StatelessWidget {
  const _IntroCopy({required this.wide});
  final bool wide;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.introEyebrow,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ResonPalette.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: ResonSpace.xl),
        Text(
          s.introTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 56 : 42,
            fontWeight: FontWeight.w600,
            height: 1.1,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: ResonSpace.xl),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 415),
          child: Text(
            s.introBody,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: ResonPalette.paleGrey,
              height: 1.8,
            ),
          ),
        ),
        const SizedBox(height: ResonSpace.xxl),
        FilledButton(
          onPressed: () => context.go('/register'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(s.start)),
                const SizedBox(width: ResonSpace.xl),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: ResonSpace.sm),
        TextButton(
          onPressed: () => context.go('/login'),
          style: TextButton.styleFrom(foregroundColor: ResonPalette.white),
          child: Text(s.haveAccount),
        ),
      ],
    );
  }
}

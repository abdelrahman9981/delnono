import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand_images.dart';
import '../../../app/l10n/app_localizations.dart';
import '../data/clinics_repository.dart';

/// The picture of [clinic] (docs/design/README.md "Splash and brand"): the Moqattam waiting room
/// for the main clinic, the illustration for the second until its real photo arrives.
class ClinicPhoto extends ConsumerWidget {
  const ClinicPhoto({super.key, required this.clinic, this.height = 150});

  final Clinic clinic;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final main = ref.watch(mainClinicProvider)?.id == clinic.id;
    return Image.asset(
      main ? BrandImages.waitingRoom : BrandImages.clinic2Illustration,
      key: Key('clinic-photo-${clinic.id}'),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      semanticLabel: '${AppLocalizations.of(context).clinicWaitingRoom} · ${clinic.name}',
    );
  }
}

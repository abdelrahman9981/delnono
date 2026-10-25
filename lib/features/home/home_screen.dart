import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand_images.dart';
import '../../app/l10n/app_localizations.dart';
import '../../app/route_guard.dart';
import '../../app/theme.dart';
import '../../core/launch/external_links.dart';
import '../account/presentation/account_button.dart';
import '../clinics/data/clinics_repository.dart';
import '../clinics/domain/hours_summary.dart';
import '../registration/data/guardian_repository.dart';

/// Home (`/`, design `figma/home.jpg`; 004 FR-013): the doctor's card and one card per active clinic
/// with its address, hours, call and WhatsApp, and "احجزي هنا". Public: no sign-in needed (D-09).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final firstName = ref.watch(guardianProvider).value?.fullName.split(' ').first;
    final clinics = ref.watch(clinicsProvider);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, actions: const [AccountButton()]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
          children: [
            Text(l10n.appTitle, style: text.labelLarge?.copyWith(color: c.blue)),
            const SizedBox(height: 2),
            Text(
              firstName == null || firstName.isEmpty ? l10n.homeWelcome : l10n.homeGreeting(firstName),
              style: text.headlineMedium,
            ),
            const SizedBox(height: 16),
            const _DoctorCard(),
            const SizedBox(height: 22),
            Text(l10n.homeClinics, style: text.titleLarge),
            const SizedBox(height: 10),
            ...clinics.when(
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (_, _) => [Text(l10n.errGeneric)],
              data: (list) => [
                if (list.isEmpty) Text(l10n.noClinics, style: text.bodyMedium?.copyWith(color: c.muted)),
                for (final clinic in list) ...[_ClinicCard(clinic: clinic), const SizedBox(height: 12)],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The doctor's photo under a dark gradient, so the white text stays readable; the tagline sits
/// alone in the top corner over the wall, away from his face and from the name.
class _DoctorCard extends StatelessWidget {
  const _DoctorCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      key: const Key('doctor-card'),
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: const Color(0xFF2C3E50)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            BrandImages.doctorHero,
            key: const Key('doctor-photo'),
            fit: BoxFit.cover,
            alignment: BrandImages.doctorHeroFocus,
            semanticLabel: l10n.doctorName,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00081D2B), Color(0x33081D2B), Color(0xE6081D2B)],
                stops: [0, .4, 1],
              ),
            ),
          ),
          PositionedDirectional(
            top: 14,
            end: 14,
            child: Container(
              key: const Key('doctor-tagline'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: const Color(0x99081D2B), borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: Color(0xFF4FBF9F), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(l10n.doctorTagline, style: text.bodySmall?.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            start: 20,
            end: 20,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.doctorName, style: text.headlineMedium?.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(l10n.doctorTitle, style: text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: .92))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicCard extends ConsumerWidget {
  const _ClinicCard({required this.clinic});

  final Clinic clinic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final links = ref.read(externalLinksProvider);
    final hours = hoursSummary(l10n, clinic.workingHours);

    // The waiting-room photo is of the main clinic, so only its card shows it.
    final isMain = ref.watch(mainClinicProvider)?.id == clinic.id;

    return Card(
      key: Key('clinic-card-${clinic.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMain)
            Image.asset(
              BrandImages.waitingRoom,
              key: Key('clinic-photo-${clinic.id}'),
              height: 150,
              fit: BoxFit.cover,
              semanticLabel: l10n.clinicWaitingRoom,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(radius: 22, backgroundImage: AssetImage(BrandImages.doctorAvatar)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clinic.name, style: text.titleMedium),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: c.blue),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(clinic.address, style: text.bodySmall?.copyWith(color: c.muted)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final line in hours)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.schedule, size: 16, color: c.muted),
                        const SizedBox(width: 6),
                        Expanded(child: Text(line, style: text.bodySmall)),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: Key('book-at-${clinic.id}'),
                  onPressed: () =>
                      context.go(Uri(path: Routes.booking, queryParameters: {'clinic': clinic.id}).toString()),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(l10n.bookHere),
                ),
                if (clinic.phone != null || clinic.whatsapp != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (clinic.phone != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            key: Key('call-${clinic.id}'),
                            onPressed: () => links.callNumber(clinic.phone!),
                            icon: const Icon(Icons.call_outlined),
                            label: Text(l10n.callClinicShort),
                          ),
                        ),
                      if (clinic.phone != null && clinic.whatsapp != null) const SizedBox(width: 8),
                      if (clinic.whatsapp != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            key: Key('whatsapp-${clinic.id}'),
                            onPressed: () => links.openWhatsApp(clinic.whatsapp!),
                            icon: const Icon(Icons.chat_outlined),
                            label: Text(l10n.whatsapp),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

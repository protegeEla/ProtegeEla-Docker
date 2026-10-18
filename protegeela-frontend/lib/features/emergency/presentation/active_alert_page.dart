import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/emergency_call_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/phone_number_formatter.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../authentication/data/demo_session_repository.dart';
import '../../notifications/data/notification_center_repository.dart';
import '../../trusted_contacts/data/trusted_contacts_repository.dart';
import '../../../shared/models/trusted_contact.dart';
import '../data/emergency_controller.dart';
import '../data/emergency_repository.dart';
import '../data/emergency_services_repository.dart';
import 'widgets/active_alert_overview.dart';

class ActiveAlertPage extends ConsumerStatefulWidget {
  const ActiveAlertPage({super.key});
  @override
  ConsumerState<ActiveAlertPage> createState() => _ActiveAlertPageState();
}

class _ActiveAlertPageState extends ConsumerState<ActiveAlertPage> {
  bool _busy = false;

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Não foi possível confirmar a ação. Confira o status e tente novamente.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emergencyControllerProvider);
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Alerta ativo'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AppStateView(
          title: 'Alerta não carregado',
          message: 'Tente novamente ou volte para o início.',
          actionLabel: 'Início',
          onAction: () => context.go('/home'),
        ),
        data: (value) {
          final alert = value.activeAlert;
          if (alert == null) {
            return AppStateView(
              title: 'Nenhum alerta ativo',
              message: 'Quando um alerta for confirmado, ele aparecerá aqui.',
              actionLabel: 'Voltar ao início',
              onAction: () => context.go('/home'),
            );
          }
          final locationState =
              ref.watch(latestAlertLocationProvider(alert.id));
          final location = locationState.valueOrNull;
          final preciseLocation = location != null &&
                  location.accuracy <=
                      LocationService.maximumAcceptedAccuracyMeters
              ? location
              : null;
          final demo = alert.id.startsWith('demo-alert-') ||
              ref.watch(demoSessionProvider).valueOrNull == true;
          final contactsState = ref.watch(trustedContactsProvider);
          final notificationState = demo
              ? const AsyncData<AlertNotificationSummary>(
                  AlertNotificationSummary(status: 'demo', sent: false),
                )
              : ref.watch(alertNotificationSummaryProvider(alert.id));
          final center = LatLng(
            preciseLocation?.latitude ??
                location?.latitude ??
                config.defaultLatitude,
            preciseLocation?.longitude ??
                location?.longitude ??
                config.defaultLongitude,
          );
          return ActiveAlertOverview(
            alert: alert,
            location: location,
            center: center,
            demo: demo,
            busy: _busy,
            locationLoading: locationState.isLoading,
            locationError: locationState.hasError,
            contacts: contactsState.valueOrNull ?? const [],
            contactsLoading: contactsState.isLoading,
            contactsError: contactsState.hasError,
            notification: notificationState.valueOrNull,
            notificationLoading: notificationState.isLoading,
            notificationError: notificationState.hasError,
            onRefreshStatus: () {
              ref.invalidate(alertNotificationSummaryProvider(alert.id));
              ref.invalidate(trustedContactsProvider);
              ref.invalidate(latestAlertLocationProvider(alert.id));
            },
            onCall: () => _perform(() => _confirmCall(context, ref)),
            onUpdate: () =>
                _perform(() => _updateLocation(context, ref, alert.id)),
            onShareLocation: demo
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Demonstração: nenhum WhatsApp será aberto.')),
                    )
                : () => _perform(() => _shareLocation(
                    context,
                    ref,
                    alert.id,
                    contactsState.valueOrNull ?? const <TrustedContact>[])),
            onSafe: () => _perform(() => _close(context, ref, safe: true)),
            onClose: () => _perform(() => _close(context, ref)),
            onSupport: () => context.go('/mapa'),
          );
        },
      ),
    );
  }

  Future<void> _confirmCall(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar ligação'),
        content: const Text(
            'Seu dispositivo tentará abrir o aplicativo de chamadas. A ligação depende do suporte do dispositivo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ligar')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      if (await ref.read(demoSessionProvider.future)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Demonstração: nenhuma ligação real foi iniciada.'),
        ));
        return;
      }
      if (!context.mounted) return;
      final service =
          await ref.read(emergencyServicesRepositoryProvider).firstActive();
      if (!context.mounted) return;
      if (service == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Nenhum serviço de emergência ativo foi configurado.')));
        return;
      }
      final launched =
          await ref.read(emergencyCallServiceProvider).call(service.phone);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Não foi possível iniciar a ligação neste dispositivo.')));
      }
    }
  }

  Future<void> _updateLocation(
      BuildContext context, WidgetRef ref, String alertId) async {
    try {
      final demoActive = await ref.read(demoSessionProvider.future);
      if (demoActive) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Localização de demonstração. Nenhum dado foi enviado.')));
        return;
      }
      final location = await ref.read(locationServiceProvider).captureCurrent();
      await ref
          .read(emergencyRepositoryProvider)
          .updateLocation(alertId: alertId, location: location);
      ref.invalidate(latestAlertLocationProvider(alertId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Localização atualizada.')));
      }
    } catch (error) {
      if (context.mounted) {
        final message = error is AppException
            ? error.message
            : 'Não foi possível obter a localização. Confira as permissões e tente novamente.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _shareLocation(BuildContext context, WidgetRef ref,
      String alertId, List<TrustedContact> contacts) async {
    final contactsWithWhatsApp = contacts
        .where((contact) => contact.preferredChannel == 'whatsapp')
        .toList();
    if (contactsWithWhatsApp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Adicione um contato com WhatsApp na sua rede de apoio.'),
      ));
      return;
    }

    final selected = await showDialog<TrustedContact>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Enviar localização pelo WhatsApp'),
        children: [
          for (final contact in contactsWithWhatsApp)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, contact),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(contact.name),
                subtitle: Text(contact.phone),
              ),
            ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;

    try {
      final location = await ref.read(locationServiceProvider).captureCurrent();
      await ref.read(emergencyRepositoryProvider).updateLocation(
            alertId: alertId,
            location: location,
          );
      ref.invalidate(latestAlertLocationProvider(alertId));

      final number = PhoneNumberFormatter.digitsOnly(selected.phone);
      if (number.length < 10 || number.length > 13) {
        throw const FormatException('Invalid contact phone number');
      }
      final mapUrl = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '${location.latitude},${location.longitude}',
      });
      final message = 'Estou precisando de ajuda. Minha localização atual '
          '(precisão aproximada de ${location.accuracy.round()} m): $mapUrl';
      final internationalNumber = number.startsWith('55') ? number : '55$number';
      final whatsapp =
          Uri.https('wa.me', '/$internationalNumber', {'text': message});
      final opened = await launchUrl(
        whatsapp,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw const FormatException('WhatsApp could not be opened');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Não foi possível abrir o WhatsApp. Verifique a localização, o telefone do contato e tente novamente.'),
        ));
      }
    }
  }

  Future<void> _close(BuildContext context, WidgetRef ref,
      {bool safe = false}) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(safe ? 'Você está em local seguro?' : 'Encerrar alerta?'),
        content: const Text(
            'Ao confirmar, o acompanhamento deste alerta será encerrado.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, 'safe'),
              child: const Text('Estou segura')),
          if (!safe)
            OutlinedButton(
                onPressed: () => Navigator.pop(context, 'help_received'),
                child: const Text('Recebi ajuda')),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;
    await ref
        .read(emergencyControllerProvider.notifier)
        .closeAlert(reason: reason);
    if (context.mounted) context.go('/home');
  }
}

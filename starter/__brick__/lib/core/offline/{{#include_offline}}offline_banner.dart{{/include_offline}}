import 'package:flutter/material.dart';
{{#is_riverpod}}import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_providers.dart';
import 'offline_service.dart';
{{/is_riverpod}}{{#is_bloc}}import 'package:flutter_bloc/flutter_bloc.dart';

import 'offline_service.dart';
{{/is_bloc}}

{{#is_riverpod}}class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(offlineStatusProvider).valueOrNull;
    return _OfflineBannerContent(status: status);
  }
}
{{/is_riverpod}}{{#is_bloc}}class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = context.read<ConnectivityService>();

    return StreamBuilder<OfflineStatus>(
      stream: connectivityService.watchStatus(),
      builder: (context, snapshot) {
        return _OfflineBannerContent(status: snapshot.data);
      },
    );
  }
}
{{/is_bloc}}

class _OfflineBannerContent extends StatelessWidget {
  const _OfflineBannerContent({
    required this.status,
  });

  final OfflineStatus? status;

  @override
  Widget build(BuildContext context) {
    if (status != OfflineStatus.offline) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are offline. Cached data may be shown.',
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

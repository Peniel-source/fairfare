//this shows the cahin proof on the coridor screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'corridor_providers.dart';

class ChainProof extends ConsumerWidget {
  const ChainProof({super.key});

  Future<void> openProof(String link) async {
    await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //sho
    final receipt = ref.watch(latestNotarizationProvider).valueOrNull;
    if (receipt == null) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => openProof(receipt.explorerUrl),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_outlined, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Prices checked on chain, ${receipt.date}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
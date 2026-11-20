// How to pay: plain steps, the mobile money code with a copy button, and on
// Android a button that opens the dialer with the code filled in.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';

/// tel: link for a USSD code. `#` must be encoded as %23, otherwise the
/// dialer treats everything after it as a URL fragment and drops it.
Uri dialUri(String code) =>
    Uri.parse('tel:${code.replaceAll('#', Uri.encodeComponent('#'))}');

class DialPromptCard extends StatelessWidget {
  const DialPromptCard({
    super.key,
    required this.dialCode,
    required this.merchantCode,
    required this.priceRwf,
  });

  final String dialCode;
  final String merchantCode;
  final int priceRwf;

  bool get _canDial =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final steps = [
      'Dial the code below${_canDial ? ' (or tap Dial)' : ''}.',
      'Check MoMo shows merchant $merchantCode and '
          '${Formatters.price(priceRwf)}, then confirm with your PIN.',
      'Copy the reference from the payment SMS.',
      'Enter it below and tap Submit.',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to pay', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'MoMo Pay merchant $merchantCode',
              style: text.bodyMedium,
              semanticsLabel: 'Pay to MoMo merchant $merchantCode',
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs / 2,
                ),
                child: Text('${i + 1}. ${steps[i]}', style: text.bodyMedium),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    dialCode,
                    style: text.titleLarge,
                    semanticsLabel: 'Payment code $dialCode',
                  ),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copy(context),
                ),
              ],
            ),
            if (_canDial) ...[
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => _dial(context),
                icon: const Icon(Icons.phone),
                label: const Text('Dial'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: dialCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Code copied')));
  }

  Future<void> _dial(BuildContext context) async {
    final opened = await launchUrl(dialUri(dialCode));
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the dialer. Copy the code instead'),
      ),
    );
  }
}

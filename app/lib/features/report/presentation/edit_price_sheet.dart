import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/price_stepper.dart';
import '../domain/entities/report.dart';
import '../domain/price_sanity.dart';
import 'report_banners.dart';
import 'report_providers.dart';

/// Returns true when the price was saved
Future<bool?> showEditPriceSheet(
  BuildContext context, {
  required Report report,
  required String routeName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => EditPriceSheet(report: report, routeName: routeName),
  );
}

class EditPriceSheet extends ConsumerStatefulWidget {
  const EditPriceSheet({
    super.key,
    required this.report,
    required this.routeName,
  });

  final Report report;
  final String routeName;

  @override
  ConsumerState<EditPriceSheet> createState() => _EditPriceSheetState();
}

class _EditPriceSheetState extends ConsumerState<EditPriceSheet> {
  late int? _price = widget.report.price;
  String? _error;
  bool _isSaving = false;

  Future<void> _save() async {
    final error = priceSanityError(_price);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_price == widget.report.price) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });
    try {
      await ref
          .read(updatePendingReportProvider)
          .call(widget.report.id, _price!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = reportErrorMessage(e);
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit price', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(widget.routeName, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            PriceStepper(
              value: _price,
              onChanged: (price) => setState(() => _price = price),
              max: AppConstants.maxReportPrice,
              errorText: _error,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Save price',
              icon: Icons.check,
              expand: true,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

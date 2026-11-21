import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/entities/saved_route.dart';
import 'saved_route_providers.dart';
import 'saved_route_sheet.dart';

class SavedRoutesScreen extends ConsumerStatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  ConsumerState<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends ConsumerState<SavedRoutesScreen> {
  String? _deleting;

  Future<void> _edit([SavedRoute? route]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SavedRouteSheet(route: route),
    );
    if (mounted && saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(route == null ? 'Route saved' : 'Route updated'),
        ),
      );
    }
  }

  Future<void> _delete(SavedRoute route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete saved route?'),
        content: Text(
          'Remove ${route.label ?? 'this route'} from your saved routes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _deleting = route.id);
    try {
      await ref.read(deleteSavedRouteProvider).call(route.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Route deleted')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(savedRouteErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _deleting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routes = ref.watch(savedRoutesProvider);
    final text = Theme.of(context).textTheme;
    final busy = _deleting != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved routes')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: ListView(
              padding: AppSpacing.screen,
              children: [
                Text('Your usual trips', style: text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Save a route to find it again quickly.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Add route',
                  icon: Icons.add,
                  onPressed: busy ? null : () => _edit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                routes.when(
                  loading: () =>
                      const LoadingView(message: 'Loading saved routes…'),
                  error: (error, _) => ErrorView(
                    compact: true,
                    message: savedRouteErrorMessage(error),
                    onRetry: () => ref.invalidate(savedRoutesProvider),
                  ),
                  data: (routes) => routes.isEmpty
                      ? const EmptyView(
                          compact: true,
                          icon: Icons.bookmarks_outlined,
                          title: 'No saved routes yet',
                          message: 'Add the trips you take often.',
                        )
                      : Column(
                          children: [
                            for (final route in routes) ...[
                              AppCard(
                                key: ValueKey(route.id),
                                onTap: busy
                                    ? null
                                    : () => context.goNamed(
                                        'corridors',
                                        queryParameters: {
                                          'from': route.fromArea,
                                          'to': route.toArea,
                                        },
                                      ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            route.label ?? 'Saved route',
                                            style: text.titleMedium,
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            '${route.fromArea} → ${route.toArea}',
                                            style: text.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    IconButton(
                                      tooltip: 'Edit ${route.label ?? 'route'}',
                                      onPressed: busy
                                          ? null
                                          : () => _edit(route),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip:
                                          'Delete ${route.label ?? 'route'}',
                                      onPressed: busy
                                          ? null
                                          : () => _delete(route),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

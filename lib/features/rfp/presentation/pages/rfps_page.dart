import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osp_broker_admin/features/rfp/application/rfp_notifier.dart';

class RfpsPage extends ConsumerStatefulWidget {
  const RfpsPage({super.key});

  static const String routeName = 'rfps';
  static const String routePath = '/rfps';

  @override
  ConsumerState<RfpsPage> createState() => _RfpsPageState();
}

class _RfpsPageState extends ConsumerState<RfpsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rfpNotifierProvider.notifier).loadRfps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rfpNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'RFPs',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () =>
                    ref.read(rfpNotifierProvider.notifier).loadRfps(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null) {
                return Center(child: Text(state.error!));
              }

              if (state.rfps.isEmpty) {
                return const Center(child: Text('No RFPs found'));
              }

              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: state.rfps.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final rfp = state.rfps[index];
                  return ListTile(
                    title: Text(rfp.projectTitle.isNotEmpty
                        ? rfp.projectTitle
                        : 'Untitled RFP'),
                    subtitle: Text(
                      rfp.email.isNotEmpty ? rfp.email : rfp.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/rfps/${rfp.id}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

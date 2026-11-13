import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/feedback.dart';
import '../widgets/scope.dart';
import 'device_screen.dart';

class DevicesView extends StatelessWidget {
  const DevicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final store = context.store;
    if (!store.isConnected) return const NotConnectedView();
    if (store.instances.isEmpty) {
      return loadStateView(context, loading: store.loading, error: store.error, retry: store.refresh) ??
          MessageView(icon: Icons.lightbulb_outline, title: s.noDevicesTitle, message: s.noDevicesMessage);
    }

    return RefreshIndicator(
      onRefresh: store.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: store.instances.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _DeviceCard(instance: store.instances[index]),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.instance});

  final Instance instance;

  Future<void> _setPower(BuildContext context, bool on) async {
    try {
      await context.store.setPower(instance.id, on);
    } on ApiException catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final store = context.store;
    final loaded = store.states.containsKey(instance.id);
    final state = store.states[instance.id];

    return Card(
      child: ListTile(
        leading: Icon(state?.on ?? false ? Icons.lightbulb : Icons.lightbulb_outline),
        title: Text(instance.label),
        subtitle: Text(loaded && state == null ? s.notReachable(instance.ip) : instance.ip),
        trailing: switch ((loaded, state)) {
          (false, _) => const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          (_, null) => Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          (_, final state?) => Switch(value: state.on, onChanged: (on) => _setPower(context, on)),
        },
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => DeviceScreen(instance: instance))),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import '../l10n/app_localizations.dart';

String errorText(S s, ApiException error) => switch (error.error) {
  ApiError.network => s.errorNetwork,
  ApiError.unauthorized => s.errorUnauthorized,
  ApiError.notFound => s.errorNotFound,
  ApiError.conflict => s.errorConflict,
  ApiError.invalid => s.errorInvalid,
  ApiError.device => s.errorDevice,
  ApiError.server => s.errorServer,
};

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showError(BuildContext context, ApiException error) => showMessage(context, errorText(S.of(context), error));

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final s = S.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
      ],
    ),
  );
  return confirmed ?? false;
}

/// A centered icon with a title, an explanation and optionally a button: for empty lists and failed loads.
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action case final action?) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }
}

/// What a list screen shows instead of its list: a spinner while the first load runs, the error when it failed.
Widget? loadStateView(
  BuildContext context, {
  required bool loading,
  required ApiException? error,
  required VoidCallback retry,
}) {
  final s = S.of(context);
  if (loading) return const Center(child: CircularProgressIndicator());
  if (error == null) return null;
  return MessageView(
    icon: Icons.cloud_off,
    title: s.loadFailed,
    message: errorText(s, error),
    action: FilledButton.tonal(onPressed: retry, child: Text(s.retry)),
  );
}

class NotConnectedView extends StatelessWidget {
  const NotConnectedView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MessageView(icon: Icons.link_off, title: s.notConnectedTitle, message: s.notConnectedMessage);
  }
}

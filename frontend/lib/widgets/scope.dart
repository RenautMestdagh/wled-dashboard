import 'package:flutter/widgets.dart';

import '../data/settings.dart';
import '../data/store.dart';

class Scope<T extends Listenable> extends InheritedNotifier<T> {
  const Scope({super.key, required T value, required super.child}) : super(notifier: value);

  static T of<T extends Listenable>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Scope<T>>()!.notifier!;

  /// Without rebuilding on changes, so also usable in initState.
  static T read<T extends Listenable>(BuildContext context) =>
      context.getInheritedWidgetOfExactType<Scope<T>>()!.notifier!;
}

extension ScopeContext on BuildContext {
  Store get store => Scope.of<Store>(this);
  Settings get settings => Scope.of<Settings>(this);
}

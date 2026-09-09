import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/shared/widgets/mmm_dialog.dart';

void main() {
  testWidgets('actionsBuilder closes the dialog with its route context', (
    tester,
  ) async {
    Object? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await MmmDialog.show<String>(
                context: context,
                actionsBuilder: (dialogContext) => [
                  TextButton(
                    key: const Key('dialog-action'),
                    onPressed: () => Navigator.of(dialogContext).pop('done'),
                    child: const Text('Done'),
                  ),
                ],
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dialog-action')));
    await tester.pumpAndSettle();

    expect(result, 'done');
    expect(find.byType(MmmDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialog action remains usable after its launcher is removed', (
    tester,
  ) async {
    final hostKey = GlobalKey<_DialogHostState>();
    await tester.pumpWidget(MaterialApp(home: _DialogHost(key: hostKey)));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    hostKey.currentState!.removeLauncher();
    await tester.pump();
    await tester.tap(find.byKey(const Key('dialog-action')));
    await tester.pumpAndSettle();

    expect(find.byType(MmmDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _DialogHost extends StatefulWidget {
  const _DialogHost({super.key});

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  bool showLauncher = true;

  void removeLauncher() => setState(() => showLauncher = false);

  @override
  Widget build(BuildContext context) {
    if (!showLauncher) return const SizedBox.shrink();
    return ElevatedButton(
      onPressed: () => MmmDialog.show<void>(
        context: context,
        actionsBuilder: (dialogContext) => [
          TextButton(
            key: const Key('dialog-action'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
      child: const Text('Open'),
    );
  }
}

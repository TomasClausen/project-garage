import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lancer_restoration/screens/onboarding_screen.dart';

class _Harness extends StatefulWidget {
  const _Harness({required this.save, this.refresh, this.onCompleted});

  final Future<void> Function() save;
  final Future<void> Function()? refresh;
  final VoidCallback? onCompleted;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  bool completed = false;

  @override
  Widget build(BuildContext context) {
    if (completed) return const Scaffold(body: Text('MainNavigation'));
    return OnboardingScreen(
      saveOverride: widget.save,
      onRefresh: widget.refresh,
      onCompleted: () {
        widget.onCompleted?.call();
        setState(() => completed = true);
      },
    );
  }
}

Finder get _continueButton => find.widgetWithText(FilledButton, 'Continuar');
Finder get _startButton => find.widgetWithText(FilledButton, 'Empezar');

Future<void> _next(WidgetTester tester) async {
  await tester.tap(_continueButton);
  await tester.pumpAndSettle();
}

Future<void> _reachLastStep(WidgetTester tester) async {
  await _next(tester);
  await tester.enterText(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Nombre del proyecto *',
    ),
    'Mi proyecto',
  );
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await _next(tester);
  await _next(tester);
  await _next(tester);
  await _next(tester);
  expect(_startButton, findsOneWidget);
}

void main() {
  testWidgets('completes every step and enters main navigation', (
    tester,
  ) async {
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(home: _Harness(save: () async => saves++)),
    );

    await _reachLastStep(tester);
    await tester.tap(_startButton);
    await tester.pumpAndSettle();

    expect(find.text('MainNavigation'), findsOneWidget);
    expect(saves, 1);
  });

  testWidgets('last step back and forward remains usable', (tester) async {
    await tester.pumpWidget(MaterialApp(home: _Harness(save: () async {})));
    await _reachLastStep(tester);

    await tester.tap(find.text('Atrás'));
    await tester.pumpAndSettle();
    expect(_continueButton, findsOneWidget);
    await _next(tester);
    await tester.tap(_startButton);
    await tester.pumpAndSettle();

    expect(find.text('MainNavigation'), findsOneWidget);
  });

  testWidgets('multiple backward and forward transitions keep buttons active', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _Harness(save: () async {})));
    await _next(tester);
    await tester.enterText(find.byType(TextField), 'Mi proyecto');
    await _next(tester);
    await _next(tester);

    await tester.tap(find.text('Atrás'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atrás'));
    await tester.pumpAndSettle();
    expect(_continueButton, findsOneWidget);
    await _next(tester);
    await _next(tester);
    expect(_continueButton, findsOneWidget);
  });

  testWidgets('rapid continue taps cannot skip a step or its validation', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _Harness(save: () async {})));

    await tester.tap(_continueButton);
    await tester.tap(_continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Creá tu proyecto'), findsOneWidget);
    expect(tester.widget<FilledButton>(_continueButton).onPressed, isNull);
    expect(find.text('Vehículo (opcional)'), findsNothing);
  });

  testWidgets('failed completion unlocks the button and retry succeeds', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: _Harness(
          save: () async {
            if (attempts++ == 0) throw StateError('write failed');
          },
        ),
      ),
    );
    await _reachLastStep(tester);

    await tester.tap(_startButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('No pudimos guardar'), findsOneWidget);
    expect(tester.widget<FilledButton>(_startButton).onPressed, isNotNull);

    ScaffoldMessenger.of(tester.element(_startButton)).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(_startButton);
    await tester.pumpAndSettle();
    expect(find.text('MainNavigation'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('rapid double tap persists and navigates only once', (
    tester,
  ) async {
    final pending = Completer<void>();
    var saves = 0;
    var navigations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: _Harness(
          save: () {
            saves++;
            return pending.future;
          },
          onCompleted: () => navigations++,
        ),
      ),
    );
    await _reachLastStep(tester);

    await tester.tap(_startButton);
    await tester.tap(_startButton);
    await tester.pump();
    expect(saves, 1);
    expect(navigations, 0);

    pending.complete();
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(navigations, 1);
    expect(find.text('MainNavigation'), findsOneWidget);
  });

  testWidgets('refresh failure after persistence still enters main', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: _Harness(
          save: () async {},
          refresh: () async => throw StateError('refresh failed'),
        ),
      ),
    );
    await _reachLastStep(tester);

    await tester.tap(_startButton);
    await tester.pumpAndSettle();

    expect(find.text('MainNavigation'), findsOneWidget);
    expect(find.textContaining('No pudimos guardar'), findsNothing);
  });

  testWidgets('optional fields do not block completion', (tester) async {
    await tester.pumpWidget(MaterialApp(home: _Harness(save: () async {})));
    await _reachLastStep(tester);
    await tester.tap(_startButton);
    await tester.pumpAndSettle();
    expect(find.text('MainNavigation'), findsOneWidget);
  });

  testWidgets('controls remain usable at 2x text on a 320x568 viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(home: _Harness(save: () async {})),
      ),
    );
    expect(_continueButton, findsOneWidget);
    expect(tester.getRect(_continueButton).bottom, lessThanOrEqualTo(568));
    await _next(tester);
    expect(find.text('Atrás'), findsOneWidget);
    expect(_continueButton, findsOneWidget);
  });
}

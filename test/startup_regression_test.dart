import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lancer_restoration/main.dart';
import 'package:lancer_restoration/services/first_run_coordinator.dart';
import 'package:lancer_restoration/widgets/common/project_garage_logo.dart';

void main() {
  testWidgets('initialization exception shows an error instead of loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      StartupGate(initializer: () async => throw StateError('hive failed')),
    );
    await tester.pump();
    expect(find.text('No pudimos abrir tus datos'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('retry runs initialization again and reaches ready UI', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      StartupGate(
        initializer: () async {
          if (attempts++ == 0) throw StateError('first attempt');
        },
        readyBuilder: (_) => const Scaffold(body: Text('ready')),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('ready'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('missing or corrupt profile resolution cannot load forever', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LancerApp(
          resolver: () async => throw StateError('corrupt profile'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('No pudimos abrir tus datos'), findsOneWidget);
  });

  testWidgets('clean-install decision reaches onboarding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LancerApp(
          resolver: () async =>
              const FirstRunDecision(FirstRunState.newInstallation, true),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Bienvenido a Project Garage'), findsOneWidget);
  });

  testWidgets('update decision reaches main navigation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LancerApp(
          resolver: () async =>
              const FirstRunDecision(FirstRunState.update, false),
          navigationBuilder: (_) => const Text('main navigation'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('main navigation'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('startup timeout shows error', (tester) async {
    await tester.pumpWidget(
      StartupGate(
        initializer: () => Completer<void>().future,
        timeout: const Duration(milliseconds: 20),
      ),
    );
    await tester.pump(const Duration(milliseconds: 21));
    expect(find.text('No pudimos abrir tus datos'), findsOneWidget);
  });

  testWidgets('reduceMotion does not block logo rendering', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: ProjectGarageLogo(animate: true)),
      ),
    );
    expect(find.byType(ProjectGarageLogo), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });

  testWidgets('logo animation does not gate navigation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            const ProjectGarageLogo(animate: true),
            Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const Text('next')),
                ),
                child: const Text('continue'),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('continue'));
    await tester.pumpAndSettle();
    expect(find.text('next'), findsOneWidget);
  });
}

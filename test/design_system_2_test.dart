import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lancer_restoration/theme/app_colors.dart';
import 'package:lancer_restoration/models/dashboard_summary.dart';
import 'package:lancer_restoration/theme/app_icons.dart';
import 'package:lancer_restoration/theme/app_theme.dart';
import 'package:lancer_restoration/widgets/common/app_card.dart';
import 'package:lancer_restoration/widgets/common/app_animated_entry.dart';
import 'package:lancer_restoration/widgets/common/project_garage_logo.dart';
import 'package:lancer_restoration/widgets/common/project_progress_module.dart';
import 'package:lancer_restoration/widgets/finance_summary_card.dart';
import 'package:lancer_restoration/widgets/repair_summary_card.dart';

void main() {
  test('official Project Garage logo asset is present', () {
    expect(File(ProjectGarageLogo.assetPath).existsSync(), isTrue);
  });

  test('Design System palette keeps semantic colors distinct', () {
    expect(AppColors.primary, const Color(0xFF9F2436));
    expect(AppColors.success, isNot(AppColors.primary));
    expect(AppColors.warning, isNot(AppColors.danger));
    expect(AppColors.background, isNot(Colors.black));
  });

  testWidgets('ProjectProgressModule clamps and exposes semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: ProjectProgressModule(title: 'Restauración', value: 1.5),
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp(r'100 por ciento')), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('progress and logo respect reduced motion and large text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          disableAnimations: true,
          textScaler: TextScaler.linear(2),
          size: Size(320, 640),
        ),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ProjectGarageLogo(animate: true),
                  ProjectProgressModule(
                    title: 'Progreso general',
                    value: .42,
                    secondaryText: 'Documentación actualizada',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(ProjectGarageLogo), findsOneWidget);
  });

  testWidgets('all AppCard variants render on a compact screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ListView(
            children: AppCardVariant.values
                .map(
                  (variant) => AppCard(
                    variant: variant,
                    technical: variant == AppCardVariant.progress,
                    child: Text(variant.name),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    expect(find.byType(AppCard), findsNWidgets(AppCardVariant.values.length));
    expect(tester.takeException(), isNull);
  });

  test('icon mappers return stable linear concepts', () {
    expect(NavigationIconMapper.icons, hasLength(5));
    expect(RepairCategoryIconMapper.from('motor'), Icons.engineering_rounded);
    expect(
      FinanceCategoryIconMapper.from('repuesto'),
      Icons.inventory_2_outlined,
    );
    expect(
      MaintenanceCategoryIconMapper.from('aceite'),
      Icons.oil_barrel_outlined,
    );
    expect(TimelineEventIconMapper.from('foto'), Icons.photo_outlined);
  });

  test('navigation keeps five ordered destinations', () {
    final source = File('lib/main_navigation.dart').readAsStringSync();
    expect('NavigationDestination('.allMatches(source), hasLength(5));
    var cursor = -1;
    for (final label in [
      'Inicio',
      'Vehículo',
      'Taller',
      'Finanzas',
      'Bitácora',
    ]) {
      final next = source.indexOf("label: '$label'");
      expect(next, greaterThan(cursor));
      cursor = next;
    }
  });

  testWidgets('dense summary cards do not overflow compact or landscape', (
    tester,
  ) async {
    const summary = DashboardSummary(
      pendingRepairs: 12,
      inProgressRepairs: 7,
      completedRepairs: 24,
      estimatedTotal: 2500000,
      actualTotal: 1750000,
      remainingEstimated: 750000,
    );
    for (final size in const [Size(320, 568), Size(568, 320)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(2),
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    RepairSummaryCard(summary: summary),
                    FinanceSummaryCard(summary: summary),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('entry animation becomes immediate with reduce motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppAnimatedEntry(child: Text('Contenido técnico')),
        ),
      ),
    );
    await tester.pump();
    final fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(AppAnimatedEntry),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}

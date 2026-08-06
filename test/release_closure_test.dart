import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lancer_restoration/models/project_report.dart';
import 'package:lancer_restoration/services/pdf_font_loader.dart';
import 'package:lancer_restoration/services/pdf_image_optimizer.dart';
import 'package:lancer_restoration/widgets/common/app_image.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('embedded Roboto generates PDF with required Unicode text', () async {
    final fonts = await PdfFontLoader.load();
    final document = pw.Document()
      ..addPage(
        pw.Page(
          theme: fonts.theme,
          build: (_) => pw.Text(
            r'Restauración Suspensión Vehículo Tomás $ 1.250.000 Reparación completada Ñ Á É Í Ó Ú ü €',
          ),
        ),
      );
    expect(await document.save(), isNotEmpty);
  });

  test(
    'report options reject empty sections, bad dates and invalid states',
    () {
      expect(
        const ProjectReportOptions(sections: {}).validate(),
        contains('sección'),
      );
      expect(
        ProjectReportOptions(
          startDate: DateTime(2026, 2),
          endDate: DateTime(2026, 1),
        ).validate(),
        contains('fecha'),
      );
      expect(
        const ProjectReportOptions(
          includePending: false,
          includeCompleted: false,
        ).validate(),
        isNotNull,
      );
      expect(const ProjectReportOptions().validate(), isNull);
    },
  );

  test(
    'image profiles control resolution, JPEG quality and memory guidance',
    () {
      final low = PdfImageOptimizer.profile(ReportImageQuality.low);
      final medium = PdfImageOptimizer.profile(ReportImageQuality.medium);
      final high = PdfImageOptimizer.profile(ReportImageQuality.high);
      expect(low.maxDimension, lessThan(medium.maxDimension));
      expect(medium.maxDimension, lessThan(high.maxDimension));
      expect(low.jpegQuality, lessThan(high.jpegQuality));
      expect(low.recommendedMaxImages, greaterThan(high.recommendedMaxImages));
      expect(low.estimatedBytesPerImage, lessThan(high.estimatedBytesPerImage));
    },
  );

  test(
    'optimizer handles large, corrupt and missing images for all qualities',
    () async {
      final root = await Directory.systemTemp.createTemp('pdf_optimizer_');
      addTearDown(() => root.delete(recursive: true));
      final large = File('${root.path}/large.png');
      final original = img.encodePng(
        img.Image(width: 3000, height: 2000)..clear(img.ColorRgb8(120, 30, 20)),
      );
      await large.writeAsBytes(original);
      final optimizer = PdfImageOptimizer();
      for (final quality in ReportImageQuality.values) {
        final bytes = await optimizer.optimize(large.path, quality);
        expect(bytes, isNotNull);
        final decoded = img.decodeImage(bytes!);
        expect(
          decoded!.width,
          lessThanOrEqualTo(PdfImageOptimizer.profile(quality).maxDimension),
        );
      }
      expect(
        (await optimizer.optimize(large.path, ReportImageQuality.low))!.length,
        lessThan(original.length),
      );
      final corrupt = File('${root.path}/corrupt.jpg')
        ..writeAsStringSync('broken');
      expect(
        await optimizer.optimize(corrupt.path, ReportImageQuality.medium),
        isNull,
      );
      expect(
        await optimizer.optimize(
          '${root.path}/missing.jpg',
          ReportImageQuality.high,
        ),
        isNull,
      );
    },
  );

  testWidgets('AppImage contains failures for missing and corrupt files', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppImage(path: null)));
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    final context = tester.element(find.byType(AppImage));
    await tester.pumpWidget(
      MaterialApp(
        home: AppImage.errorPlaceholder(
          context,
          StateError('corrupt image'),
          StackTrace.empty,
        ),
      ),
    );
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });
}

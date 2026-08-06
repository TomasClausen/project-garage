// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'dart:io';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/formatters/money_formatter.dart';
import '../core/errors/app_error.dart';
import '../models/app_preferences.dart';
import '../models/finance_transaction.dart';
import '../models/maintenance.dart';
import '../models/project_budget.dart';
import '../models/project_report.dart';
import '../models/repair.dart';
import '../models/timeline_event.dart';
import '../models/vehicle.dart';
import 'finance_analytics_service.dart';
import 'hive_service.dart';
import 'app_logger.dart';
import 'pdf_font_loader.dart';
import 'pdf_image_optimizer.dart';

class ProjectReportService {
  Future<ProjectReportResult> generate(
    ProjectReportOptions options, {
    Directory? outputDirectory,
  }) async {
    final validation = options.validate();
    if (validation != null) {
      throw AppError(AppErrorCode.validation, validation);
    }
    try {
      return await _generate(options, outputDirectory: outputDirectory);
    } catch (cause) {
      if (cause is AppError) rethrow;
      final error = AppError(
        AppErrorCode.report,
        'report generation failed',
        cause: cause,
      );
      await AppLogger.record('project_report', error, context: 'generate');
      throw error;
    }
  }

  Future<ProjectReportResult> _generate(
    ProjectReportOptions options, {
    Directory? outputDirectory,
  }) async {
    final repairs = Hive.box<Repair>(HiveService.repairBox).values.toList();
    final maintenance = Hive.box<Maintenance>(
      HiveService.maintenanceBox,
    ).values.toList();
    final transactions = Hive.box<FinanceTransaction>(
      HiveService.financeTransactionBox,
    ).values.toList();
    final events =
        Hive.box<TimelineEvent>(
            HiveService.timelineBox,
          ).values.where((e) => _inside(e.date, options)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final vehicle = Hive.box<Vehicle>(
      HiveService.vehicleBox,
    ).values.firstOrNull;
    final budget = Hive.box<ProjectBudget>(
      HiveService.projectBudgetBox,
    ).values.firstOrNull;
    final preferences =
        Hive.box<AppPreferences>(
          HiveService.preferencesBox,
        ).get(AppPreferences.defaultId) ??
        const AppPreferences();
    final document = pw.Document(compress: true);
    final fonts = await PdfFontLoader.load();
    final pageFormat = options.orientation == ReportOrientation.landscape
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;
    final warnings = <String>[];
    document.addPage(
      pw.MultiPage(
        theme: fonts.theme,
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          if (options.sections.contains(ProjectReportSection.cover)) ...[
            pw.Header(level: 0, text: options.title),
            pw.Text(
              preferences.projectName,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              vehicle == null
                  ? 'Sin vehículo'
                  : '${vehicle.brand} ${vehicle.model} · ${vehicle.year}',
            ),
            pw.Text('Generado: ${DateTime.now().toLocal()}'),
            pw.SizedBox(height: 24),
          ],
          if (options.sections.contains(
            ProjectReportSection.executiveSummary,
          )) ...[
            pw.Header(level: 1, text: 'Resumen ejecutivo'),
            pw.Bullet(
              text:
                  '${repairs.where((r) => r.progress >= 1).length} de ${repairs.length} reparaciones completadas',
            ),
            if (options.includeCosts)
              pw.Bullet(
                text:
                    'Inversión neta: ${MoneyFormatter.format(FinanceAnalyticsService.netInvestment(transactions))}',
              ),
          ],
          if (options.sections.contains(ProjectReportSection.vehicle) &&
              vehicle != null) ...[
            pw.Header(level: 1, text: 'Vehículo'),
            pw.Table.fromTextArray(
              data: [
                ['Marca', vehicle.brand],
                ['Modelo', vehicle.model],
                ['Año', '${vehicle.year}'],
                ['Motor', vehicle.engine],
                ['Kilometraje almacenado', '${vehicle.kilometers} km'],
                ['VIN', vehicle.vin],
              ],
            ),
          ],
          if (options.sections.contains(ProjectReportSection.repairs)) ...[
            pw.Header(level: 1, text: 'Reparaciones'),
            ...repairs
                .where(
                  (r) =>
                      (options.includeCompleted || r.progress < 1) &&
                      (options.includePending || r.progress >= 1),
                )
                .map(
                  (r) => pw.Bullet(
                    text:
                        '${r.name} · ${(r.progress * 100).round()}%${options.includeCosts ? ' · ${MoneyFormatter.format(r.estimatedCost)} estimado' : ''}',
                  ),
                ),
          ],
          if (options.sections.contains(ProjectReportSection.maintenance)) ...[
            pw.Header(level: 1, text: 'Mantenimiento'),
            ...maintenance.map(
              (m) => pw.Bullet(
                text: '${m.name} · cada ${m.intervalKm} km · ${m.lastDate}',
              ),
            ),
          ],
          if (options.sections.contains(ProjectReportSection.finance) &&
              options.includeCosts) ...[
            pw.Header(level: 1, text: 'Finanzas'),
            pw.Table.fromTextArray(
              data: [
                [
                  'Inversión',
                  MoneyFormatter.format(
                    FinanceAnalyticsService.netInvestment(transactions),
                  ),
                ],
                [
                  'Pagado',
                  MoneyFormatter.format(
                    FinanceAnalyticsService.totalPaid(transactions),
                  ),
                ],
                [
                  'Pendiente',
                  MoneyFormatter.format(
                    FinanceAnalyticsService.totalPending(transactions),
                  ),
                ],
                if (budget != null)
                  [
                    'Presupuesto ampliado',
                    MoneyFormatter.format(budget.expandedBudget),
                  ],
                if (budget != null)
                  [
                    'Sobrecosto',
                    MoneyFormatter.format(
                      FinanceAnalyticsService.budgetOverrun(
                        transactions,
                        budget,
                      ),
                    ),
                  ],
              ],
            ),
            pw.SizedBox(height: 10),
            ...FinanceAnalyticsService.expensesByCategory(
              transactions,
            ).entries.map(
              (e) => pw.Bullet(
                text: '${e.key}: ${MoneyFormatter.format(e.value)}',
              ),
            ),
          ],
          if (options.sections.contains(ProjectReportSection.timeline)) ...[
            pw.Header(level: 1, text: 'Bitácora'),
            ...events.map(
              (e) => pw.Bullet(
                text:
                    '${e.createdAt.split('T').first} · ${e.title} · ${e.description}',
              ),
            ),
          ],
        ],
      ),
    );
    if (options.includePhotos && options.maxPhotos > 0) {
      final paths = <String>[
        if (vehicle?.imagePath != null) vehicle!.imagePath!,
        ...events.map((e) => e.imagePath),
        if (options.includeReceipts)
          ...transactions.map((e) => e.receiptImagePath),
      ].where((p) => p.isNotEmpty).take(options.maxPhotos).toList();
      if (paths.length == options.maxPhotos)
        warnings.add('Las fotos fueron limitadas a ${options.maxPhotos}.');
      if (paths.isNotEmpty &&
          options.sections.contains(ProjectReportSection.photos)) {
        final optimizer = PdfImageOptimizer();
        final images = <pw.Widget>[];
        for (final path in paths) {
          final bytes = await optimizer.optimize(path, options.imageQuality);
          if (bytes == null) {
            warnings.add('Una imagen no pudo procesarse.');
            continue;
          }
          images.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Image(
                pw.MemoryImage(bytes),
                height: 220,
                fit: pw.BoxFit.contain,
              ),
            ),
          );
        }
        final profile = PdfImageOptimizer.profile(options.imageQuality);
        if (paths.length > profile.recommendedMaxImages) {
          warnings.add(
            'La cantidad de fotos supera la recomendada para esta calidad.',
          );
        }
        document.addPage(
          pw.MultiPage(
            theme: fonts.theme,
            pageFormat: pageFormat,
            build: (_) => [pw.Header(level: 1, text: 'Fotos'), ...images],
          ),
        );
      }
    }
    final bytes = await document.save();
    if (bytes.length > 50 * 1024 * 1024)
      warnings.add('El PDF supera 50 MB; reducí fotos o calidad.');
    final root = outputDirectory ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/reports');
    await dir.create(recursive: true);
    final file = File(
      '${dir.path}/project_garage_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    return ProjectReportResult(
      filePath: file.path,
      sizeBytes: bytes.length,
      pageEstimate: (document.document.pdfPageList.pages.length),
      warnings: warnings,
    );
  }

  bool _inside(DateTime value, ProjectReportOptions options) =>
      (options.startDate == null || !value.isBefore(options.startDate!)) &&
      (options.endDate == null || !value.isAfter(options.endDate!));
}

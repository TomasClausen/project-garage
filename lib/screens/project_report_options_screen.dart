import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_report.dart';
import '../services/project_report_service.dart';
import '../widgets/common/app_snackbar.dart';

class ProjectReportOptionsScreen extends StatefulWidget {
  const ProjectReportOptionsScreen({super.key});
  @override
  State<ProjectReportOptionsScreen> createState() =>
      _ProjectReportOptionsScreenState();
}

class _ProjectReportOptionsScreenState
    extends State<ProjectReportOptionsScreen> {
  static ProjectReportOptions _session = const ProjectReportOptions(
    title: 'Informe de restauración',
  );
  late final TextEditingController title = TextEditingController(
    text: _session.title,
  );
  late Set<ProjectReportSection> sections = {..._session.sections};
  late bool costs = _session.includeCosts;
  late bool photos = _session.includePhotos;
  late bool receipts = _session.includeReceipts;
  late bool pending = _session.includePending;
  late bool completed = _session.includeCompleted;
  late int maxPhotos = _session.maxPhotos;
  late ReportOrientation orientation = _session.orientation;
  late ReportImageQuality quality = _session.imageQuality;
  late DateTime? startDate = _session.startDate;
  late DateTime? endDate = _session.endDate;
  bool generating = false;

  ProjectReportOptions get options => ProjectReportOptions(
    title: title.text.trim(),
    startDate: startDate,
    endDate: endDate,
    includeCosts: costs,
    includeReceipts: receipts,
    includePhotos: photos,
    maxPhotos: maxPhotos,
    includePending: pending,
    includeCompleted: completed,
    orientation: orientation,
    imageQuality: quality,
    sections: sections,
  );

  void _changed(VoidCallback change) {
    setState(change);
    _session = options;
  }

  Future<void> _date(bool start) async {
    final value = await showDatePicker(
      context: context,
      initialDate: (start ? startDate : endDate) ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (value != null) {
      _changed(() => start ? startDate = value : endDate = value);
    }
  }

  Future<void> _generate() async {
    final error = options.validate();
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    _session = options;
    setState(() => generating = true);
    try {
      final result = await ProjectReportService().generate(options);
      if (!mounted) return;
      AppSnackbar.success(
        context,
        'PDF generado · ${(result.sizeBytes / 1024).round()} KB',
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(File(result.filePath).path)],
          title: title.text,
        ),
      );
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'No se pudo generar el PDF. Revisá el diagnóstico.',
        );
      }
    } finally {
      if (mounted) setState(() => generating = false);
    }
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validation = options.validate();
    final estimateMb =
        (maxPhotos *
        switch (quality) {
          ReportImageQuality.low => .18,
          ReportImageQuality.medium => .45,
          ReportImageQuality.high => 1.0,
        });
    return Scaffold(
      appBar: AppBar(title: const Text('Informe PDF')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: title,
            onChanged: (_) => _changed(() {}),
            decoration: const InputDecoration(
              labelText: 'Título personalizado',
            ),
          ),
          ListTile(
            title: const Text('Desde'),
            subtitle: Text(
              startDate?.toIso8601String().split('T').first ?? 'Sin límite',
            ),
            onTap: () => _date(true),
            trailing: startDate == null
                ? null
                : IconButton(
                    onPressed: () => _changed(() => startDate = null),
                    icon: const Icon(Icons.clear),
                  ),
          ),
          ListTile(
            title: const Text('Hasta'),
            subtitle: Text(
              endDate?.toIso8601String().split('T').first ?? 'Sin límite',
            ),
            onTap: () => _date(false),
            trailing: endDate == null
                ? null
                : IconButton(
                    onPressed: () => _changed(() => endDate = null),
                    icon: const Icon(Icons.clear),
                  ),
          ),
          const Divider(),
          const Text(
            'Secciones',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...ProjectReportSection.values.map(
            (s) => CheckboxListTile(
              value: sections.contains(s),
              title: Text(_sectionName(s)),
              onChanged: (value) =>
                  _changed(() => value! ? sections.add(s) : sections.remove(s)),
            ),
          ),
          SwitchListTile(
            value: costs,
            onChanged: (v) => _changed(() => costs = v),
            title: const Text('Incluir costos'),
          ),
          SwitchListTile(
            value: photos,
            onChanged: (v) => _changed(() {
              photos = v;
              if (!v) receipts = false;
            }),
            title: const Text('Incluir fotos'),
          ),
          SwitchListTile(
            value: receipts,
            onChanged: photos ? (v) => _changed(() => receipts = v) : null,
            title: const Text('Incluir comprobantes'),
          ),
          SwitchListTile(
            value: pending,
            onChanged: (v) => _changed(() => pending = v),
            title: const Text('Incluir pendientes'),
          ),
          SwitchListTile(
            value: completed,
            onChanged: (v) => _changed(() => completed = v),
            title: const Text('Incluir completadas'),
          ),
          ListTile(
            title: Text('Máximo de fotos: $maxPhotos'),
            subtitle: Slider(
              value: maxPhotos.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: photos
                  ? (v) => _changed(() => maxPhotos = v.round())
                  : null,
            ),
          ),
          DropdownButtonFormField(
            initialValue: quality,
            decoration: const InputDecoration(labelText: 'Calidad de imágenes'),
            items: ReportImageQuality.values
                .map((q) => DropdownMenuItem(value: q, child: Text(q.name)))
                .toList(),
            onChanged: (q) => _changed(() => quality = q!),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ReportOrientation>(
            segments: const [
              ButtonSegment(
                value: ReportOrientation.portrait,
                label: Text('Vertical'),
              ),
              ButtonSegment(
                value: ReportOrientation.landscape,
                label: Text('Horizontal'),
              ),
            ],
            selected: {orientation},
            onSelectionChanged: (v) => _changed(() => orientation = v.first),
          ),
          const SizedBox(height: 16),
          Text(
            'Resumen: ${sections.length} secciones · hasta $maxPhotos fotos · estimado ${estimateMb.toStringAsFixed(1)} MB',
          ),
          if (estimateMb > 15)
            const Text(
              'Advertencia: el reporte puede ser grande y consumir más memoria.',
              style: TextStyle(color: Colors.orange),
            ),
          if (validation != null)
            Text(
              validation,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: generating || validation != null ? null : _generate,
            icon: generating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: const Text('Generar y compartir'),
          ),
        ],
      ),
    );
  }

  String _sectionName(ProjectReportSection value) => switch (value) {
    ProjectReportSection.cover => 'Portada',
    ProjectReportSection.vehicle => 'Vehículo',
    ProjectReportSection.progress => 'Progreso',
    ProjectReportSection.categories => 'Categorías',
    ProjectReportSection.repairs => 'Reparaciones',
    ProjectReportSection.maintenance => 'Mantenimiento',
    ProjectReportSection.finance => 'Finanzas',
    ProjectReportSection.budget => 'Presupuesto',
    ProjectReportSection.timeline => 'Bitácora',
    ProjectReportSection.photos => 'Fotos',
    ProjectReportSection.executiveSummary => 'Resumen ejecutivo',
  };
}

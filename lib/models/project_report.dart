enum ProjectReportSection {
  cover,
  vehicle,
  progress,
  categories,
  repairs,
  maintenance,
  finance,
  budget,
  timeline,
  photos,
  executiveSummary,
}

enum ReportOrientation { portrait, landscape }

enum ReportImageQuality { low, medium, high }

class ProjectReportOptions {
  const ProjectReportOptions({
    this.title = 'Project Garage',
    this.startDate,
    this.endDate,
    this.includeCosts = true,
    this.includeReceipts = false,
    this.includePhotos = true,
    this.maxPhotos = 20,
    this.includePending = true,
    this.includeCompleted = true,
    this.orientation = ReportOrientation.portrait,
    this.imageQuality = ReportImageQuality.medium,
    this.sections = const {
      ProjectReportSection.cover,
      ProjectReportSection.vehicle,
      ProjectReportSection.progress,
      ProjectReportSection.repairs,
      ProjectReportSection.maintenance,
      ProjectReportSection.finance,
      ProjectReportSection.timeline,
      ProjectReportSection.executiveSummary,
    },
  });
  final String title;
  final DateTime? startDate, endDate;
  final bool includeCosts,
      includeReceipts,
      includePhotos,
      includePending,
      includeCompleted;
  final int maxPhotos;
  final ReportOrientation orientation;
  final ReportImageQuality imageQuality;
  final Set<ProjectReportSection> sections;

  String? validate() {
    if (title.trim().isEmpty) return 'Ingresá un título.';
    if (sections.isEmpty) return 'Elegí al menos una sección.';
    if (maxPhotos < 0 || maxPhotos > 100) {
      return 'El máximo de fotos debe estar entre 0 y 100.';
    }
    if (startDate != null && endDate != null && startDate!.isAfter(endDate!)) {
      return 'La fecha desde no puede ser posterior a la fecha hasta.';
    }
    if (!includePending &&
        !includeCompleted &&
        (sections.contains(ProjectReportSection.repairs) ||
            sections.contains(ProjectReportSection.maintenance))) {
      return 'Incluí pendientes, completadas o desactivá esas secciones.';
    }
    return null;
  }
}

class ProjectReportResult {
  const ProjectReportResult({
    required this.filePath,
    required this.sizeBytes,
    required this.pageEstimate,
    this.warnings = const [],
  });
  final String filePath;
  final int sizeBytes, pageEstimate;
  final List<String> warnings;
}

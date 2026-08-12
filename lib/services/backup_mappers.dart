import '../models/app_preferences.dart';
import '../models/finance_transaction.dart';
import '../models/gallery_photo.dart';
import '../models/maintenance.dart';
import '../models/project_budget.dart';
import '../models/repair.dart';
import '../models/repair_media.dart';
import '../models/timeline_event.dart';
import '../models/vehicle.dart';
import '../models/project_profile.dart';

Map<String, dynamic> _entity(
  String type,
  String id,
  Map<String, dynamic> fields,
) => {'type': type, 'schemaVersion': 1, 'id': id, 'fields': fields};
Map<String, dynamic> _fields(Map<String, dynamic> json) =>
    Map<String, dynamic>.from(json['fields'] as Map);

class ProjectProfileBackupMapper {
  static Map<String, dynamic> toJson(ProjectProfile x) =>
      _entity('projectProfile', x.id, {
        'name': x.name,
        'startDate': x.startDate,
        'createdAt': x.createdAt,
        'updatedAt': x.updatedAt,
        'onboardingCompleted': x.onboardingCompleted,
        'activeVehicleId': x.activeVehicleId,
        'appDataVersion': x.appDataVersion,
        'identityColor': x.identityColor,
      });
  static ProjectProfile fromJson(Map<String, dynamic> j) {
    final f = _fields(j);
    return ProjectProfile(
      id: j['id'] as String? ?? ProjectProfile.defaultId,
      name: f['name'] as String? ?? 'Project Garage',
      startDate: f['startDate'] as String? ?? '',
      createdAt: f['createdAt'] as String? ?? '',
      updatedAt: f['updatedAt'] as String? ?? '',
      onboardingCompleted: f['onboardingCompleted'] as bool? ?? true,
      activeVehicleId: f['activeVehicleId'] as String? ?? '',
      appDataVersion: (f['appDataVersion'] as num?)?.toInt() ?? 1,
      identityColor: (f['identityColor'] as num?)?.toInt() ?? 0xFF9F2436,
    );
  }
}

class RepairBackupMapper {
  static Map<String, dynamic> toJson(Repair x) => _entity('repair', x.id, {
    'name': x.name,
    'category': x.category,
    'priority': x.priority,
    'progress': x.progress,
    'estimatedCost': x.estimatedCost,
    'status': x.status,
    'weight': x.weight,
    'actualCost': x.actualCost,
    'paid': x.paid,
    'projectId': x.projectId,
  });
  static Repair fromJson(Map<String, dynamic> j) {
    final f = _fields(j);
    return Repair(
      id: j['id'] as String,
      name: f['name'] as String,
      category: f['category'] as String,
      priority: f['priority'] as String,
      progress: (f['progress'] as num).toDouble(),
      estimatedCost: (f['estimatedCost'] as num).toInt(),
      status: f['status'] as String,
      weight: (f['weight'] as num).toDouble(),
      actualCost: (f['actualCost'] as num).toInt(),
      paid: f['paid'] as bool,
      projectId: f['projectId'] as String? ?? '',
    );
  }
}

class VehicleBackupMapper {
  static Map<String, dynamic> toJson(
    Vehicle x, {
    String id = 'lancer',
    String? imagePath,
  }) => _entity('vehicle', id, {
    'brand': x.brand,
    'model': x.model,
    'year': x.year,
    'engine': x.engine,
    'color': x.color,
    'kilometers': x.kilometers,
    'imagePath': imagePath ?? x.imagePath,
    'version': x.version,
    'licensePlate': x.licensePlate,
    'vin': x.vin,
    'transmission': x.transmission,
    'fuelType': x.fuelType,
    'driveType': x.driveType,
    'projectId': x.projectId,
  });
  static Vehicle fromJson(Map<String, dynamic> j, {String? imagePath}) {
    final f = _fields(j);
    return Vehicle(
      brand: f['brand'] as String,
      model: f['model'] as String,
      year: (f['year'] as num).toInt(),
      engine: f['engine'] as String,
      color: f['color'] as String,
      kilometers: (f['kilometers'] as num).toInt(),
      imagePath: imagePath ?? f['imagePath'] as String?,
      version: f['version'] as String? ?? '',
      licensePlate: f['licensePlate'] as String? ?? '',
      vin: f['vin'] as String? ?? '',
      transmission: f['transmission'] as String? ?? '',
      fuelType: f['fuelType'] as String? ?? '',
      driveType: f['driveType'] as String? ?? '',
      projectId: f['projectId'] as String? ?? '',
    );
  }
}

class MaintenanceBackupMapper {
  static Map<String, dynamic> toJson(Maintenance x) =>
      _entity('maintenance', x.id, {
        'name': x.name,
        'category': x.category,
        'lastKm': x.lastKm,
        'intervalKm': x.intervalKm,
        'lastDate': x.lastDate,
        'notes': x.notes,
        'projectId': x.projectId,
      });
  static Maintenance fromJson(Map<String, dynamic> j) {
    final f = _fields(j);
    return Maintenance(
      id: j['id'] as String,
      name: f['name'] as String,
      category: f['category'] as String,
      lastKm: (f['lastKm'] as num).toInt(),
      intervalKm: (f['intervalKm'] as num).toInt(),
      lastDate: f['lastDate'] as String,
      notes: f['notes'] as String,
      projectId: f['projectId'] as String? ?? '',
    );
  }
}

class GalleryPhotoBackupMapper {
  static Map<String, dynamic> toJson(GalleryPhoto x, {String? path}) => _entity(
    'galleryPhoto',
    x.id,
    {'path': path ?? x.path, 'projectId': x.projectId},
  );
  static GalleryPhoto fromJson(Map<String, dynamic> j, String path) =>
      GalleryPhoto(
        id: j['id'] as String,
        path: path,
        projectId: _fields(j)['projectId'] as String? ?? '',
      );
}

class RepairMediaBackupMapper {
  static Map<String, dynamic> toJson(RepairMedia x, {String? path}) =>
      _entity('repairMedia', x.id, {
        'repairId': x.repairId,
        'path': path ?? x.path,
        'stage': x.stage,
        'note': x.note,
        'createdAt': x.createdAt,
        'projectId': x.projectId,
      });
  static RepairMedia fromJson(
    Map<String, dynamic> j,
    String path, {
    String? id,
    String? repairId,
  }) {
    final f = _fields(j);
    return RepairMedia(
      id: id ?? j['id'] as String,
      repairId: repairId ?? f['repairId'] as String,
      path: path,
      stage: f['stage'] as String,
      note: f['note'] as String,
      createdAt: f['createdAt'] as String,
      projectId: f['projectId'] as String? ?? '',
    );
  }
}

class TimelineEventBackupMapper {
  static Map<String, dynamic> toJson(TimelineEvent x, {String? imagePath}) =>
      _entity('timelineEvent', x.id, {
        'eventType': x.type,
        'title': x.title,
        'description': x.description,
        'createdAt': x.createdAt,
        'relatedId': x.relatedId,
        'imagePath': imagePath ?? x.imagePath,
        'category': x.category,
        'tags': x.tags,
        'isFeatured': x.isFeatured,
        'repairId': x.repairId,
        'projectId': x.projectId,
      });
  static TimelineEvent fromJson(
    Map<String, dynamic> j, {
    String? id,
    String? imagePath,
    String? repairId,
    String? relatedId,
  }) {
    final f = _fields(j);
    return TimelineEvent(
      id: id ?? j['id'] as String,
      type: f['eventType'] as String,
      title: f['title'] as String,
      description: f['description'] as String,
      createdAt: f['createdAt'] as String,
      relatedId: relatedId ?? f['relatedId'] as String? ?? '',
      imagePath: imagePath ?? f['imagePath'] as String? ?? '',
      category: f['category'] as String? ?? '',
      tags: List<String>.from(f['tags'] as List? ?? const []),
      isFeatured: f['isFeatured'] as bool? ?? false,
      repairId: repairId ?? f['repairId'] as String? ?? '',
      projectId: f['projectId'] as String? ?? '',
    );
  }
}

class FinanceTransactionBackupMapper {
  static Map<String, dynamic> toJson(
    FinanceTransaction x, {
    String? receiptPath,
  }) => _entity('financeTransaction', x.id, {
    'title': x.title,
    'description': x.description,
    'amount': x.amount,
    'date': x.date,
    'transactionType': x.type,
    'category': x.category,
    'paymentStatus': x.paymentStatus,
    'paymentMethod': x.paymentMethod,
    'repairId': x.repairId,
    'maintenanceId': x.maintenanceId,
    'receiptImagePath': receiptPath ?? x.receiptImagePath,
    'vendor': x.vendor,
    'notes': x.notes,
    'createdAt': x.createdAt,
    'updatedAt': x.updatedAt,
    'paidAmount': x.paidAmount,
    'importedFromLegacy': x.importedFromLegacy,
    'projectId': x.projectId,
  });
  static FinanceTransaction fromJson(
    Map<String, dynamic> j, {
    String? id,
    String? receiptPath,
    String? repairId,
    String? maintenanceId,
  }) {
    final f = _fields(j);
    return FinanceTransaction(
      id: id ?? j['id'] as String,
      title: f['title'] as String,
      description: f['description'] as String? ?? '',
      amount: (f['amount'] as num).toInt(),
      date: f['date'] as String,
      type: f['transactionType'] as String,
      category: f['category'] as String,
      paymentStatus: f['paymentStatus'] as String,
      paymentMethod: f['paymentMethod'] as String? ?? '',
      repairId: repairId ?? f['repairId'] as String? ?? '',
      maintenanceId: maintenanceId ?? f['maintenanceId'] as String? ?? '',
      receiptImagePath: receiptPath ?? f['receiptImagePath'] as String? ?? '',
      vendor: f['vendor'] as String? ?? '',
      notes: f['notes'] as String? ?? '',
      createdAt: f['createdAt'] as String,
      updatedAt: f['updatedAt'] as String,
      paidAmount: (f['paidAmount'] as num?)?.toInt() ?? 0,
      importedFromLegacy: f['importedFromLegacy'] as bool? ?? false,
      projectId: f['projectId'] as String? ?? '',
    );
  }
}

class ProjectBudgetBackupMapper {
  static Map<String, dynamic> toJson(ProjectBudget x) =>
      _entity('projectBudget', x.id, {
        'name': x.name,
        'totalBudget': x.totalBudget,
        'contingencyPercentage': x.contingencyPercentage,
        'targetCompletionDate': x.targetCompletionDate,
        'notes': x.notes,
        'createdAt': x.createdAt,
        'updatedAt': x.updatedAt,
        'projectId': x.projectId,
      });
  static ProjectBudget fromJson(Map<String, dynamic> j) {
    final f = _fields(j);
    return ProjectBudget(
      id: j['id'] as String,
      name: f['name'] as String,
      totalBudget: (f['totalBudget'] as num).toInt(),
      contingencyPercentage: (f['contingencyPercentage'] as num).toDouble(),
      targetCompletionDate: f['targetCompletionDate'] as String? ?? '',
      notes: f['notes'] as String? ?? '',
      createdAt: f['createdAt'] as String,
      updatedAt: f['updatedAt'] as String,
      projectId: f['projectId'] as String? ?? '',
    );
  }
}

class AppPreferencesBackupMapper {
  static Map<String, dynamic> toJson(AppPreferences x) =>
      _entity('appPreferences', x.id, {
        'projectName': x.projectName,
        'projectStartDate': x.projectStartDate,
        'vehicleDisplayName': x.vehicleDisplayName,
        'currencyCode': x.currencyCode,
        'currencySymbol': x.currencySymbol,
        'locale': x.locale,
        'dateFormat': x.dateFormat,
        'distanceUnit': x.distanceUnit,
        'thousandsSeparator': x.thousandsSeparator,
        'firstRunInitialized': x.firstRunInitialized,
      });
  static AppPreferences fromJson(Map<String, dynamic> j) {
    final f = _fields(j);
    return AppPreferences(
      projectName: f['projectName'] as String? ?? 'Project Garage',
      projectStartDate: f['projectStartDate'] as String? ?? '',
      vehicleDisplayName: f['vehicleDisplayName'] as String? ?? '',
      currencyCode: f['currencyCode'] as String? ?? 'ARS',
      currencySymbol: f['currencySymbol'] as String? ?? r'$',
      locale: f['locale'] as String? ?? 'es_AR',
      dateFormat: f['dateFormat'] as String? ?? 'dd/MM/yyyy',
      distanceUnit: f['distanceUnit'] as String? ?? 'km',
      thousandsSeparator: f['thousandsSeparator'] as String? ?? '.',
      firstRunInitialized: f['firstRunInitialized'] as bool? ?? true,
    );
  }
}

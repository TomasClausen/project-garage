import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/backup_models.dart';
import '../services/app_logger.dart';
import '../services/backup_service.dart';

enum BackupOperationState {
  idle,
  calculating,
  exporting,
  validating,
  importing,
  success,
  error,
}

class BackupProvider extends ChangeNotifier {
  BackupProvider({BackupService? service})
    : _service = service ?? BackupService();
  final BackupService _service;
  BackupOperationState _state = BackupOperationState.idle;
  BackupOperationState get state => _state;
  File? _lastBackup;
  File? get lastBackup => _lastBackup;
  BackupValidationResult? _validation;
  BackupValidationResult? get validation => _validation;
  BackupImportResult? _importResult;
  BackupImportResult? get importResult => _importResult;
  String? _error;
  String? get error => _error;
  Future<File?> createBackup() async {
    _set(BackupOperationState.exporting);
    try {
      _lastBackup = await _service.exportBackup();
      _set(BackupOperationState.success);
      return _lastBackup;
    } catch (e) {
      _error = e.toString();
      await AppLogger.record('backup', e);
      _set(BackupOperationState.error);
      return null;
    }
  }

  Future<BackupValidationResult> validate(File file) async {
    _set(BackupOperationState.validating);
    _validation = await _service.validate(file);
    _set(
      _validation!.canImport
          ? BackupOperationState.idle
          : BackupOperationState.error,
    );
    return _validation!;
  }

  Future<BackupImportResult> import(File file, BackupImportMode mode) async {
    _set(BackupOperationState.importing);
    _importResult = await _service.importBackup(file, mode);
    _set(
      _importResult!.success
          ? BackupOperationState.success
          : BackupOperationState.error,
    );
    return _importResult!;
  }

  void reset() => _set(BackupOperationState.idle);
  void _set(BackupOperationState value) {
    _state = value;
    notifyListeners();
  }
}

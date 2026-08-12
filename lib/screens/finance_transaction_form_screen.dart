import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/finance_transaction.dart';
import '../models/project_profile.dart';
import '../core/errors/app_error.dart';
import '../providers/finance_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/repair_provider.dart';
import '../services/image_service.dart';
import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';
import '../theme/app_spacing.dart';
import '../theme/finance_mappers.dart';
import '../theme/garage_ds3.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_image.dart';
import '../widgets/common/app_snackbar.dart';
import '../widgets/common/app_unsaved_changes_guard.dart';

class FinanceTransactionFormScreen extends StatefulWidget {
  const FinanceTransactionFormScreen({
    super.key,
    this.transaction,
    this.repairId = '',
    this.maintenanceId = '',
  });
  final FinanceTransaction? transaction;
  final String repairId;
  final String maintenanceId;

  @override
  State<FinanceTransactionFormScreen> createState() =>
      _FinanceTransactionFormScreenState();
}

class _FinanceTransactionFormScreenState
    extends State<FinanceTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _paidAmount;
  late final TextEditingController _vendor;
  late final TextEditingController _method;
  late final TextEditingController _description;
  late final TextEditingController _notes;
  late String _type;
  late String _category;
  late String _status;
  late String _repairId;
  late String _maintenanceId;
  late String _receipt;
  late DateTime _date;
  bool _saving = false;

  bool get _editing => widget.transaction != null;
  bool get _hasChanges =>
      !_saving &&
      (_title.text.isNotEmpty || _amount.text.isNotEmpty || _editing);

  @override
  void initState() {
    super.initState();
    final item = widget.transaction;
    _title = TextEditingController(text: item?.title ?? '');
    _amount = TextEditingController(
      text: item == null ? '' : item.amount.toString(),
    );
    _paidAmount = TextEditingController(
      text: item == null || item.paidAmount == 0
          ? ''
          : item.paidAmount.toString(),
    );
    _vendor = TextEditingController(text: item?.vendor ?? '');
    _method = TextEditingController(text: item?.paymentMethod ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _notes = TextEditingController(text: item?.notes ?? '');
    _type = item?.type ?? FinanceTransactionType.expense;
    _category = item?.category ?? FinanceCategory.parts;
    _status = item?.paymentStatus ?? FinancePaymentStatus.pending;
    _repairId = item?.repairId ?? widget.repairId;
    _maintenanceId = item?.maintenanceId ?? widget.maintenanceId;
    _receipt = item?.receiptImagePath ?? '';
    _date = item?.transactionDate ?? DateTime.now();
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _amount,
      _paidAmount,
      _vendor,
      _method,
      _description,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
    final file = await ImageService.pickAndSaveImage(
      source: source,
      prefix: 'finance_receipt',
    );
    if (file != null && mounted) setState(() => _receipt = file.path);
  }

  Future<void> _selectDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_saving || !_formKey.currentState!.validate()) return;
    final amount = int.tryParse(_amount.text.trim());
    final partialPaidAmount = int.tryParse(_paidAmount.text.trim()) ?? 0;
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    final now = DateTime.now().toIso8601String();
    final old = widget.transaction;
    final transaction = FinanceTransaction(
      id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      description: _description.text.trim(),
      amount: amount,
      date: _date.toIso8601String(),
      type: _type,
      category: _category,
      paymentStatus: _status,
      paymentMethod: _method.text.trim(),
      repairId: _repairId,
      maintenanceId: _maintenanceId,
      receiptImagePath: _receipt,
      vendor: _vendor.text.trim(),
      notes: _notes.text.trim(),
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
      paidAmount: _status == FinancePaymentStatus.partial
          ? partialPaidAmount
          : (_status == FinancePaymentStatus.paid ? amount : 0),
      importedFromLegacy: old?.importedFromLegacy ?? false,
    );
    try {
      final provider = context.read<FinanceProvider>();
      if (_editing) {
        await provider.update(transaction);
      } else {
        await provider.add(transaction);
      }
      if (!mounted) return;
      AppSnackbar.success(
        context,
        _editing ? 'Movimiento actualizado' : 'Movimiento registrado',
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        final message = error is AppError
            ? AppFailure.fromError(error).userMessage
            : 'No se pudo guardar el movimiento.';
        AppSnackbar.error(context, message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repairs = context.watch<RepairProvider>().repairs;
    final maintenance = context.watch<MaintenanceProvider>().maintenances;
    ProjectProfile? profile;
    for (final item in Hive.box<ProjectProfile>(
      HiveService.projectProfileBox,
    ).values) {
      if (item.id == MultiGarageService.activeProjectId) {
        profile = item;
        break;
      }
    }
    final identity = GarageDs3.identity(profile?.identityColor ?? 0);
    final baseTheme = Theme.of(context);
    return AppUnsavedChangesGuard(
      hasChanges: _hasChanges,
      child: Theme(
        data: baseTheme.copyWith(
          colorScheme: baseTheme.colorScheme.copyWith(primary: identity),
          inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: identity, width: 1.5),
            ),
          ),
        ),
        child: Scaffold(
          backgroundColor: GarageDs3.foundation,
          appBar: AppBar(
            title: Text(_editing ? 'Editar movimiento' : 'Agregar movimiento'),
          ),
          body: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                TextFormField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresá un título'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: r'$ ',
                  ),
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                      ? 'Ingresá un monto mayor que cero'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: FinanceTransactionType.values
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text(FinancePresentation.typeLabel(v)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Estado'),
                        items: FinancePaymentStatus.values
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text(
                                  FinancePresentation.paymentLabel(v),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ),
                  ],
                ),
                if (_status == FinancePaymentStatus.partial) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _paidAmount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Monto pagado',
                      prefixText: r'$ ',
                    ),
                    validator: (value) {
                      final paid = int.tryParse(value ?? '') ?? 0;
                      final total = int.tryParse(_amount.text) ?? 0;
                      return paid <= 0 || paid >= total
                          ? 'Debe ser mayor a 0 y menor al monto'
                          : null;
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: FinanceCategory.values
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(FinancePresentation.categoryLabel(v)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: const Text('Fecha'),
                  subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
                  trailing: const Icon(Icons.edit_calendar_rounded),
                  onTap: _selectDate,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _repairId,
                  decoration: const InputDecoration(
                    labelText: 'Reparación asociada',
                  ),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Ninguna')),
                    ...repairs.map(
                      (r) => DropdownMenuItem(value: r.id, child: Text(r.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _repairId = v!),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _maintenanceId,
                  decoration: const InputDecoration(
                    labelText: 'Mantenimiento asociado',
                  ),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Ninguno')),
                    ...maintenance.map(
                      (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _maintenanceId = v!),
                ),
                for (final field in [
                  (_vendor, 'Proveedor', 1),
                  (_method, 'Método de pago', 1),
                  (_description, 'Descripción', 2),
                  (_notes, 'Notas', 3),
                ]) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: field.$1,
                    maxLines: field.$3,
                    decoration: InputDecoration(labelText: field.$2),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                if (_receipt.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 180,
                      child: AppImage(
                        path: _receipt,
                        fit: BoxFit.cover,
                        cacheWidth: 1200,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _receipt = ''),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Quitar comprobante'),
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickReceipt(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Cámara'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickReceipt(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galería'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: _editing ? 'Guardar cambios' : 'Registrar movimiento',
                  onPressed: _save,
                  isLoading: _saving,
                  icon: Icons.save_outlined,
                  backgroundColor: identity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

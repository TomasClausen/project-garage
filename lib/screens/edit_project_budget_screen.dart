import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_unsaved_changes_guard.dart';

class EditProjectBudgetScreen extends StatefulWidget {
  const EditProjectBudgetScreen({super.key});
  @override
  State<EditProjectBudgetScreen> createState() =>
      _EditProjectBudgetScreenState();
}

class _EditProjectBudgetScreenState extends State<EditProjectBudgetScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _total;
  late final TextEditingController _contingency;
  late final TextEditingController _notes;
  DateTime? _target;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final budget = context.read<FinanceProvider>().budget;
    _total = TextEditingController(
      text: budget.totalBudget == 0 ? '' : budget.totalBudget.toString(),
    );
    _contingency = TextEditingController(
      text: budget.contingencyPercentage.toString(),
    );
    _notes = TextEditingController(text: budget.notes);
    _target = DateTime.tryParse(budget.targetCompletionDate);
  }

  @override
  void dispose() {
    _total.dispose();
    _contingency.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    setState(() => _saving = true);
    final old = context.read<FinanceProvider>().budget;
    await context.read<FinanceProvider>().saveBudget(
      old.copyWith(
        totalBudget: int.tryParse(_total.text) ?? 0,
        contingencyPercentage:
            double.tryParse(_contingency.text.replaceAll(',', '.')) ?? 0,
        targetCompletionDate: _target?.toIso8601String() ?? '',
        notes: _notes.text.trim(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AppUnsavedChangesGuard(
    hasChanges: !_saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Presupuesto del proyecto')),
      body: Form(
        key: _key,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            TextFormField(
              controller: _total,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Presupuesto total',
                prefixText: r'$ ',
              ),
              validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0
                  ? 'Ingresá un valor válido'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _contingency,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Contingencia',
                suffixText: '%',
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.')) ?? -1;
                return n < 0 || n > 100
                    ? 'Usá un porcentaje entre 0 y 100'
                    : null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: const Text('Fecha objetivo'),
              subtitle: Text(
                _target == null
                    ? 'Sin fecha'
                    : '${_target!.day}/${_target!.month}/${_target!.year}',
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _target ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _target = d);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _notes,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notas'),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Guardar presupuesto',
              onPressed: _save,
              isLoading: _saving,
              icon: Icons.savings_outlined,
            ),
          ],
        ),
      ),
    ),
  );
}

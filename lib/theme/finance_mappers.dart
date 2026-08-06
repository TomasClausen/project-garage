import 'package:flutter/material.dart';

import '../models/finance_transaction.dart';
import 'app_colors.dart';

class FinancePresentation {
  FinancePresentation._();
  static String typeLabel(String value) => switch (value) {
    FinanceTransactionType.income => 'Ingreso',
    FinanceTransactionType.adjustment => 'Ajuste',
    _ => 'Gasto',
  };
  static String paymentLabel(String value) => switch (value) {
    FinancePaymentStatus.paid => 'Pagado',
    FinancePaymentStatus.partial => 'Parcial',
    _ => 'Pendiente',
  };
  static Color paymentColor(String value) => switch (value) {
    FinancePaymentStatus.paid => AppColors.success,
    FinancePaymentStatus.partial => AppColors.warning,
    _ => AppColors.danger,
  };
  static String categoryLabel(String value) => switch (value) {
    FinanceCategory.parts => 'Repuestos',
    FinanceCategory.labor => 'Mano de obra',
    FinanceCategory.tools => 'Herramientas',
    FinanceCategory.paint => 'Pintura',
    FinanceCategory.bodywork => 'Carrocería',
    FinanceCategory.mechanical => 'Mecánica',
    FinanceCategory.electrical => 'Electricidad',
    FinanceCategory.maintenance => 'Mantenimiento',
    FinanceCategory.paperwork => 'Papeles',
    FinanceCategory.insurance => 'Seguro',
    FinanceCategory.fuel => 'Combustible',
    FinanceCategory.transport => 'Transporte',
    FinanceCategory.detailing => 'Detailing',
    _ => 'Otros',
  };
  static IconData categoryIcon(String value) => switch (value) {
    FinanceCategory.parts => Icons.settings_rounded,
    FinanceCategory.labor => Icons.handyman_rounded,
    FinanceCategory.tools => Icons.build_rounded,
    FinanceCategory.paint => Icons.format_paint_rounded,
    FinanceCategory.bodywork => Icons.car_repair_rounded,
    FinanceCategory.mechanical => Icons.engineering_rounded,
    FinanceCategory.electrical => Icons.electrical_services_rounded,
    FinanceCategory.maintenance => Icons.fact_check_rounded,
    FinanceCategory.paperwork => Icons.description_rounded,
    FinanceCategory.insurance => Icons.verified_user_rounded,
    FinanceCategory.fuel => Icons.local_gas_station_rounded,
    FinanceCategory.transport => Icons.local_shipping_rounded,
    FinanceCategory.detailing => Icons.auto_awesome_rounded,
    _ => Icons.receipt_long_rounded,
  };
}

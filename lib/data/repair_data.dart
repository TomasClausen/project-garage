import '../models/repair.dart';

final List<Repair> repairs = [
  Repair(
    id: "tren_delantero",

    name: "Tren delantero",

    category: "Suspensión",

    priority: "Alta",

    progress: 0.2,

    estimatedCost: 400000,

    status: "Pendiente",

    weight: 0.30,

    actualCost: 0,

    paid: false,
  ),

  Repair(
    id: "amortiguadores_delanteros",

    name: "Amortiguadores delanteros",

    category: "Suspensión",

    priority: "Alta",

    progress: 0.1,

    estimatedCost: 80000,

    status: "Pendiente",

    weight: 0.15,

    actualCost: 0,

    paid: false,
  ),

  Repair(
    id: "aire_acondicionado",

    name: "Aire acondicionado",

    category: "Climatización",

    priority: "Media",

    progress: 0.0,

    estimatedCost: 150000,

    status: "Pendiente",

    weight: 0.15,

    actualCost: 0,

    paid: false,
  ),

  Repair(
    id: "junta_tapa_valvulas",

    name: "Junta tapa de válvulas",

    category: "Motor",

    priority: "Media",

    progress: 0.0,

    estimatedCost: 30000,

    status: "Pendiente",

    weight: 0.15,

    actualCost: 0,

    paid: false,
  ),

  Repair(
    id: "pintura_exterior",

    name: "Pintura exterior",

    category: "Exterior",

    priority: "Baja",

    progress: 0.0,

    estimatedCost: 800000,

    status: "Pendiente",

    weight: 0.25,

    actualCost: 0,

    paid: false,
  ),
];

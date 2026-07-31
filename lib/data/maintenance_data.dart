import '../models/maintenance.dart';



final List<Maintenance> maintenances = [



  Maintenance(

    id: "aceite",

    name: "Cambio de aceite",

    category: "Motor",

    lastKm: 161000,

    intervalKm: 10000,

    lastDate: "Sin registrar",

    notes: "Último cambio registrado a los 161.000 km",

  ),




  Maintenance(

    id: "refrigerante",

    name: "Cambio de refrigerante",

    category: "Refrigeración",

    lastKm: 0,

    intervalKm: 40000,

    lastDate: "Sin registrar",

    notes: "Todavía no cargado",

  ),




  Maintenance(

    id: "correa_distribucion",

    name: "Correa de distribución",

    category: "Motor",

    lastKm: 0,

    intervalKm: 80000,

    lastDate: "Sin registrar",

    notes: "Cambiar junto con tensor si corresponde",

  ),




  Maintenance(

    id: "bujias",

    name: "Cambio de bujías",

    category: "Motor",

    lastKm: 0,

    intervalKm: 20000,

    lastDate: "Sin registrar",

    notes: "Revisar desgaste y color de electrodos",

  ),




  Maintenance(

    id: "filtro_aire",

    name: "Filtro de aire",

    category: "Motor",

    lastKm: 0,

    intervalKm: 15000,

    lastDate: "Sin registrar",

    notes: "Revisar antes si circula en zonas con polvo",

  ),




  Maintenance(

    id: "filtro_combustible",

    name: "Filtro de combustible",

    category: "Motor",

    lastKm: 0,

    intervalKm: 40000,

    lastDate: "Sin registrar",

    notes: "Importante para cuidar bomba e inyectores",

  ),




  Maintenance(

    id: "liquido_frenos",

    name: "Líquido de frenos",

    category: "Frenos",

    lastKm: 0,

    intervalKm: 30000,

    lastDate: "Sin registrar",

    notes: "Cambiar también por tiempo aunque tenga pocos km",

  ),




  Maintenance(

    id: "aceite_caja",

    name: "Aceite de caja",

    category: "Transmisión",

    lastKm: 0,

    intervalKm: 50000,

    lastDate: "Sin registrar",

    notes: "Revisar nivel y estado del aceite",

  ),




  Maintenance(

    id: "alineacion",

    name: "Alineación y tren delantero",

    category: "Suspensión",

    lastKm: 0,

    intervalKm: 10000,

    lastDate: "Sin registrar",

    notes: "Revisar después de reparar tren delantero",

  ),




  Maintenance(

    id: "bateria",

    name: "Batería",

    category: "Eléctrico",

    lastKm: 0,

    intervalKm: 50000,

    lastDate: "Sin registrar",

    notes: "Controlar estado y carga",

  ),



];
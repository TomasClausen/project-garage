import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Política de privacidad')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Text(
          'Privacidad en Project Garage',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Text(
          'Los datos del proyecto, fotos, comprobantes y logs se almacenan localmente. La aplicación no incluye analytics, tracking ni sincronización en la nube.',
        ),
        SizedBox(height: 12),
        Text(
          'Cámara y fotos sólo se usan cuando elegís adjuntar una imagen. Los backups, diagnósticos y PDFs se crean y comparten únicamente por acción tuya.',
        ),
        SizedBox(height: 12),
        Text(
          'Podés exportar backups y eliminar datos desde las funciones disponibles en la aplicación. Los logs técnicos evitan rutas completas y datos personales innecesarios.',
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import '../core/app_metadata.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/project_garage_logo.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Acerca de')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const ProjectGarageLogo(size: 96),
        const Text(
          AppMetadata.name,
          textAlign: TextAlign.center,
          style: AppTextStyles.screenTitle,
        ),
        const Text(AppMetadata.subtitle, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xl),
        const AppCard(
          variant: AppCardVariant.highlight,
          technical: true,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Versión'),
            subtitle: Text('${AppMetadata.version}+${AppMetadata.build}'),
          ),
        ),
        ListTile(
          title: const Text('Política de privacidad'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          ),
        ),
        ListTile(
          title: const Text('Licencias de terceros'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(
            context: context,
            applicationName: AppMetadata.name,
            applicationVersion: '${AppMetadata.version}+${AppMetadata.build}',
          ),
        ),
        const ListTile(
          title: Text('Términos'),
          subtitle: Text(
            'Uso bajo responsabilidad del propietario del proyecto. Ver TERMS_OF_USE.md.',
          ),
        ),
        const ListTile(
          title: Text('Copyright'),
          subtitle: Text('© 2026 Project Garage'),
        ),
      ],
    ),
  );
}

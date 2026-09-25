import 'package:flutter/material.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../widgets/nest_icon.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.aboutNest,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo y Versión
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(51)),
                    ),
                    child: const NestIcon(size: 80),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nest',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versión 6.0.0 (Colibrí)',
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(127),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Enlaces Legales
            _buildSection(
              context,
              child: Column(
                children: [
                  _buildListAction(
                    context,
                    title: l10n.termsConditions,
                    onTap: () {},
                  ),
                  Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: colorScheme.outlineVariant.withAlpha(51),
                  ),
                  _buildListAction(
                    context,
                    title: l10n.privacyPolicy,
                    onTap: () {},
                    isLast: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            // Botón Aceptar (estilo Material 3)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  l10n.accept,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required Widget child, EdgeInsetsGeometry? padding}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(51)),
      ),
      child: child,
    );
  }

  Widget _buildChangelogItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListAction(BuildContext context, {required String title, required VoidCallback onTap, bool isLast = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.open_in_new_rounded, size: 16, color: colorScheme.primary.withAlpha(127)),
      onTap: onTap,
      shape: isLast 
        ? const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)))
        : null,
    );
  }
}

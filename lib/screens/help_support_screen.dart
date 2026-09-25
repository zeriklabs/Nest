import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/data_service.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
          l10n.helpSupport,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buscador
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withAlpha(51)),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.howCanWeHelp,
                  hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(100), fontSize: 14),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSectionTitle(context, l10n.popularTopics),
            const SizedBox(height: 16),
            _buildHelpCard(
              context,
              icon: Icons.auto_awesome_rounded,
              title: l10n.whatsNew,
              description: l10n.whatsNewDesc,
              onTap: () => _showWhatsNewDialog(context),
            ),
            const SizedBox(height: 12),
            _buildHelpCard(
              context,
              icon: Icons.sync_rounded,
              title: l10n.syncProblems,
              description: l10n.syncProblemsDesc,
            ),
            const SizedBox(height: 12),
            _buildHelpCard(
              context,
              icon: Icons.security_rounded,
              title: l10n.securityPrivacy,
              description: l10n.securityPrivacyDesc,
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle(context, l10n.directContact),
            const SizedBox(height: 16),
            _buildHelpCard(
              context,
              icon: Icons.email_outlined,
              title: l10n.sendEmail,
              description: 'support.nest.agenda@gmail.com',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildHelpCard(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              title: l10n.supportChat,
              description: l10n.supportChatDesc,
              onTap: () {},
            ),

            const SizedBox(height: 32),
            _buildSectionTitle(context, l10n.accountManagement),
            const SizedBox(height: 16),
            _buildHelpCard(
              context,
              icon: Icons.delete_forever_rounded,
              iconColor: Colors.red.shade400,
              title: l10n.deleteAccount,
              description: l10n.deleteAccountDesc,
              onTap: () => _showDeleteAccountModal(context),
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                l10n.weAreHereToHelp,
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(100),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final Color effectiveIconColor = iconColor ?? colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(51)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: effectiveIconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    description,
                    style: TextStyle(color: colorScheme.onSurface.withAlpha(127), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withAlpha(51)),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountModal(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dataService = Provider.of<DataService>(context, listen: false);

    String selectedReason = l10n.noLongerUseApp;
    final List<String> reasons = [
      l10n.noLongerUseApp,
      l10n.foundAlternative,
      l10n.technicalIssues,
      l10n.privacyConcerns,
      l10n.otherReason,
    ];

    bool wipeAllData = true;
    final TextEditingController feedbackController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              24, 24, 24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14151B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.requestAccountDeletion,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              l10n.gracePeriod30Days,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF221A1A) : const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              l10n.whatHappensOnDeletion,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.localeName == 'es'
                              ? '• Tu cuenta entrará en un periodo de gracia de 30 días.\n• Tus notas, horarios y grupos se eliminarán de forma permanente tras los 30 días.\n• Si cambias de opinión, simplemente vuelve a iniciar sesión antes de los 30 días para cancelar la eliminación.'
                              : '• Your account will enter a 30-day grace period.\n• Your notes, schedules, and groups will be permanently deleted after 30 days.\n• If you change your mind, simply log back in before 30 days to cancel the deletion.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    l10n.whyAreYouLeaving,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  ...reasons.map((reason) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(reason, style: const TextStyle(fontSize: 13)),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedReason = val);
                      }
                    },
                  )),

                  if (selectedReason == l10n.otherReason || selectedReason == 'Otro motivo') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: feedbackController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: l10n.writeFeedbackOptional,
                        hintStyle: const TextStyle(fontSize: 12),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: Colors.red,
                    title: Text(
                      l10n.requestTotalWipeCheck,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    value: wipeAllData,
                    onChanged: (val) {
                      setModalState(() => wipeAllData = val ?? true);
                    },
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(l10n.localeName == 'es' ? 'Cancelar' : 'Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            Navigator.pop(context);

                            await dataService.requestAccountDeletion(
                              reason: selectedReason,
                              wipeAllData: wipeAllData,
                              feedback: feedbackController.text,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.localeName == 'es'
                                      ? 'Solicitud registrada. Tu cuenta se eliminará en 30 días si no inicias sesión.'
                                      : 'Deletion requested. Your account will be deleted in 30 days if you do not log back in.'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(l10n.deleteAccount, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showWhatsNewDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(l10n.whatsNewTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChangelogItem(l10n.changelog1),
            _buildChangelogItem(l10n.changelog2),
            _buildChangelogItem(l10n.changelog3),
            _buildChangelogItem(l10n.changelog4),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.understood, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChangelogItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
    );
  }
}

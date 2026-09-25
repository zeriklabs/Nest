import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../services/firebase_service.dart';
import '../widgets/user_avatar.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final FirebaseService _fb = FirebaseService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _showCameraIcon = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    
    // Delay camera icon appearance until Hero animation finishes
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) {
        setState(() => _showCameraIcon = true);
      }
    });
  }

  Future<void> _loadProfile() async {
    if (_fb.userId != null) {
      final profile = await _fb.getUserProfile(_fb.userId!);
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editField(String field, String currentValue, String label) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentValue);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final newValue = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(l10n.editField(label), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.enterField(label), style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                inputFormatters: field == 'alias' ? [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_.]')),
                ] : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (newValue != null && newValue.isNotEmpty && newValue != currentValue) {
      setState(() => _isLoading = true);
      try {
        if (field == 'alias') {
          if (newValue.length < 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.aliasMinLength)),
            );
            setState(() => _isLoading = false);
            return;
          }

          final isAvailable = await _fb.isAliasAvailable(newValue, excludeUserId: _fb.userId);
          if (!isAvailable) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.aliasInUse)),
              );
              setState(() => _isLoading = false);
            }
            return;
          }
        }

        await _fb.saveUserProfile(_fb.userId!, {field: newValue});
        if (!mounted) return;
        if (field == 'username') {
          context.read<DataService>().setUserName(newValue);
        } else if (field == 'alias') {
          context.read<DataService>().setUserAlias(newValue);
        }
        await _loadProfile();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editBirthday() async {
    final DateTime? currentDob = _userProfile?['dob'] != null 
        ? DateTime.parse(_userProfile!['dob']) 
        : null;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDob ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _isLoading = true);
      try {
        await _fb.saveUserProfile(_fb.userId!, {'dob': picked.toIso8601String()});
        context.read<DataService>().setUserBirthday(picked);
        await _loadProfile();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<DataService>();
    final l10n = AppLocalizations.of(context)!;

    String name = _userProfile?['username'] ?? dataService.userName;
    String alias = _userProfile?['alias'] ?? dataService.userAlias;
    String email = _userProfile?['email'] ?? (dataService.userEmail.isNotEmpty ? dataService.userEmail : (FirebaseService().userEmail ?? 'No disponible'));
    String dob = 'No definida';
    if (_userProfile?['dob'] != null) {
      dob = DateFormat('d MMMM, yyyy', l10n.localeName).format(DateTime.parse(_userProfile!['dob']));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 720;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            decoration: BoxDecoration(
              gradient: isTablet ? LinearGradient(
                colors: isDark
                  ? [theme.scaffoldBackgroundColor, const Color(0xFF050505)]
                  : [theme.scaffoldBackgroundColor, Colors.grey.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ) : null,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 1200 : double.infinity),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(context, l10n, isDark),
                    if (isTablet)
                      _buildTabletContent(context, name, alias, email, dob, l10n)
                    else
                      ..._buildMobileContent(context, name, alias, email, dob, l10n),
                    if (_isLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: LinearProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AppLocalizations l10n, bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        l10n.accountSettings,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildMobileContent(BuildContext context, String name, String alias, String email, String dob, AppLocalizations l10n) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 40),
          child: _buildProfileImage(context),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildSectionTitle(context, l10n.personalInfo),
            const SizedBox(height: 8),
            _buildSettingsGroup(context, [
              _buildSettingsTile(
                context,
                icon: Icons.person_outline_rounded,
                title: l10n.name,
                value: name,
                onTap: () => _editField('username', name, l10n.name),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.alternate_email_rounded,
                title: 'Alias',
                value: alias.isEmpty ? 'Sin definir' : '@$alias',
                onTap: () => _editField('alias', alias, 'Alias'),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.email_outlined,
                title: l10n.email,
                value: email,
                isEditable: false,
              ),
              _buildSettingsTile(
                context,
                icon: Icons.cake_outlined,
                title: l10n.dob,
                value: dob,
                onTap: _editBirthday,
                isLast: true,
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionTitle(context, l10n.linkedAccounts),
            const SizedBox(height: 8),
            _buildSettingsGroup(context, [
              _buildLinkedAccountItem(
                context, 
                provider: 'Google', 
                status: l10n.connected, 
                isConnected: true,
                isLast: true,
              ),
            ]),
            const SizedBox(height: 48),
            _buildLogoutButtonMobile(context),
            const SizedBox(height: 60),
          ]),
        ),
      ),
    ];
  }

  Widget _buildTabletContent(BuildContext context, String name, String alias, String email, String dob, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final fb = FirebaseService();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT SIDEBAR (Profile Card)
                SizedBox(
                  width: 320,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(50) : colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildProfileImage(context, isTablet: true),
                        const SizedBox(height: 24),
                        Text(
                          name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$alias',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Nest ID Chip
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: fb.nestId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.nestIdCopiedToClipboard),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.primary.withAlpha(40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.badge_outlined, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  fb.nestId,
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.copy_rounded, size: 14, color: colorScheme.primary.withAlpha(180)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Divider(color: colorScheme.outlineVariant.withAlpha(40), height: 1),
                        const SizedBox(height: 24),
                        _buildLogoutButtonSmall(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 28),

                // RIGHT CONTENT (Editable Settings & Linked Accounts)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, l10n.personalInfo),
                      const SizedBox(height: 12),
                      _buildSettingsGroup(context, [
                        _buildSettingsTile(
                          context,
                          icon: Icons.person_outline_rounded,
                          title: l10n.name,
                          value: name,
                          onTap: () => _editField('username', name, l10n.name),
                        ),
                        _buildSettingsTile(
                          context,
                          icon: Icons.alternate_email_rounded,
                          title: 'Alias',
                          value: alias.isEmpty ? 'Sin definir' : '@$alias',
                          onTap: () => _editField('alias', alias, 'Alias'),
                        ),
                        _buildSettingsTile(
                          context,
                          icon: Icons.email_outlined,
                          title: l10n.email,
                          value: email,
                          isEditable: false,
                        ),
                        _buildSettingsTile(
                          context,
                          icon: Icons.cake_outlined,
                          title: l10n.dob,
                          value: dob,
                          onTap: _editBirthday,
                          isLast: true,
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildSectionTitle(context, l10n.linkedAccounts),
                      const SizedBox(height: 12),
                      _buildSettingsGroup(context, [
                        _buildLinkedAccountItem(
                          context,
                          provider: 'Google',
                          status: l10n.connected,
                          isConnected: true,
                          isLast: true,
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButtonMobile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        title: Text(
          l10n.logout,
          style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onTap: () => _handleLogout(context),
      ),
    );
  }

  Widget _buildLogoutButtonSmall(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: () => _handleLogout(context),
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: Text(l10n.logout.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      style: TextButton.styleFrom(
        foregroundColor: Colors.redAccent.withOpacity(0.8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.confirmLogoutMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(l10n.logout, style: const TextStyle(color: Color(0xFFFF4B4B))),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        await context.read<DataService>().logout();
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        }
      }
    }
  }

  Widget _buildProfileImage(BuildContext context, {bool isTablet = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = isTablet ? 160.0 : 130.0;
    final innerSize = isTablet ? 148.0 : 118.0;

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Hero(
            tag: 'profile_avatar_tag',
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary.withOpacity(0.1), width: 1),
                  ),
                ),
                Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withOpacity(0.1),
                    border: Border.all(color: colorScheme.primary, width: isTablet ? 4.5 : 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: UserAvatar(
                    name: context.read<DataService>().userName,
                    photoUrl: _fb.userPhotoUrl,
                    size: isTablet ? 130 : 90,
                  ),
                ),
              ],
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _showCameraIcon ? 1.0 : 0.0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(right: 6, bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: isTablet ? 22 : 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    bool isEditable = true,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailing: isEditable 
            ? Icon(Icons.edit_outlined, color: colorScheme.primary.withOpacity(0.5), size: 18)
            : Icon(Icons.lock_outline, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), size: 18),
          onTap: isEditable ? onTap : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        if (!isLast)
          Divider(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            height: 1,
            indent: 70,
            endIndent: 20,
          ),
      ],
    );
  }

  Widget _buildLinkedAccountItem(
    BuildContext context, {
    required String provider,
    required String status,
    required bool isConnected,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                )
              ],
            ),
            child: Image.network(
              'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.account_circle, color: colorScheme.onSurface, size: 20),
            ),
          ),
          title: Text(
            provider,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            status,
            style: TextStyle(
              color: isConnected ? Colors.green : (isDark ? Colors.white54 : Colors.black54),
              fontSize: 12,
            ),
          ),
          trailing: Icon(Icons.check_circle, color: isConnected ? Colors.green : Colors.grey, size: 20),
        ),
        if (!isLast)
          Divider(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            height: 1,
            indent: 70,
            endIndent: 20,
          ),
      ],
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: TextButton(
        onPressed: () {
          // Confirm deletion logic
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.red.withOpacity(0.7),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(
          l10n.deleteAccount,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

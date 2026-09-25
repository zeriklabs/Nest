import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../services/firebase_service.dart';
import '../models/group.dart';
import '../models/group_post.dart';
import 'group_details_screen.dart';
import 'complete_profile_screen.dart';
import 'login_screen.dart';
import 'contacts_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  // State for tablet Master-Detail
  String? _selectedItemId;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final size = MediaQuery.of(context).size;
    final bool isLandscape = size.width > size.height;
    final bool isTablet = size.width > 720;
    final bool isLargeTablet = size.width > 1100;
    final bool useSidebar = isTablet && isLandscape;

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (!useSidebar) _buildHeader(context, isDark, colorScheme),
              Consumer<DataService>(
                builder: (context, dataService, _) => _buildProfileCompletionBanner(context, dataService, l10n, colorScheme, isDark),
              ),
              Expanded(
                child: Consumer<DataService>(
                  builder: (context, dataService, child) {
                    if (dataService.isGuest) {
                      return _buildGuestRestriction(context);
                    }

                    if (useSidebar) {
                      return Row(
                        children: [
                          _buildTabletSubNav(context, dataService, colorScheme, isDark, isLandscape),
                          const VerticalDivider(width: 1, thickness: 1),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _buildCurrentTabContent(dataService, l10n, isTablet, isLargeTablet),
                            ),
                          ),
                        ],
                      );
                    }

                    return _buildGroupsTab(dataService, l10n);
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Consumer<DataService>(
          builder: (context, dataService, child) {
            if (dataService.isGuest) return const SizedBox();
            
            final size = MediaQuery.of(context).size;
            final bool isLandscape = size.width > size.height;
            final bool isTablet = size.width > 720;
            final bool useSidebar = isTablet && isLandscape;
            
            if (useSidebar) return const SizedBox();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: FloatingActionButton(
                heroTag: 'groups_fab',
                onPressed: () => _showUnifiedGroupSheet(context),
                backgroundColor: colorScheme.primary,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            );
          },
        ),
      );
  }

  Widget _buildProfileCompletionBanner(BuildContext context, DataService dataService, AppLocalizations l10n, ColorScheme colorScheme, bool isDark) {
    if (dataService.isGuest || dataService.profileCompleted) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.almostReady(dataService.userName.split(' ')[0]),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  l10n.missingDetails,
                  style: TextStyle(
                    fontSize: 12,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompleteProfileScreen(
                    initialName: FirebaseService().userName ?? dataService.userName,
                    initialEmail: FirebaseService().userEmail,
                  ),
                ),
              );
            },
            child: Text(
              l10n.finish.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTabContent(DataService dataService, AppLocalizations l10n, bool isTablet, bool isLargeTablet) {
    if (isTablet && _selectedItemId != null) {
      return GroupDetailsScreen(groupId: _selectedItemId!);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_rounded, 
              size: 80, 
              color: colorScheme.primary.withOpacity(0.1)
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.groups,
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Selecciona un grupo para ver su actividad",
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletSubNav(BuildContext context, DataService dataService, ColorScheme colorScheme, bool isDark, bool isLandscape) {
    final l10n = AppLocalizations.of(context)!;
    final photoUrl = FirebaseService().userPhotoUrl;
    
    // Configuración del indicador de conexión
    Color statusColor;
    switch (dataService.connectivityStatus) {
      case ConnectivityStatus.wifi: statusColor = Colors.green; break;
      case ConnectivityStatus.mobile: statusColor = Colors.blue; break;
      case ConnectivityStatus.none: statusColor = Colors.red; break;
      case ConnectivityStatus.syncing: statusColor = colorScheme.primary; break;
    }

    final double sidebarWidth = isLandscape ? 360 : 280;

    return Container(
      width: sidebarWidth,
      color: isDark ? const Color(0xFF0A0A0A) : Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(isLandscape ? 24 : 16, isLandscape ? 32 : 20, 16, isLandscape ? 20 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.groups,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: isLandscape ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildSmallAvatar(context, photoUrl, statusColor, colorScheme, isDark),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Material(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _showUnifiedGroupSheet(context),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isLandscape ? 16 : 8),
          const Divider(height: 1),

          // Master List
          Expanded(
            child: _buildMasterList(dataService, colorScheme, isDark, l10n, isLandscape),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterList(DataService dataService, ColorScheme colorScheme, bool isDark, AppLocalizations l10n, bool isLandscape) {
    final items = dataService.groups.where((g) => g.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final group = items[index];
        return _buildMasterTile(
          id: group.id,
          title: group.name,
          subtitle: '${group.members.length} miembros',
          icon: Icons.groups_rounded,
          color: group.color,
          imagePath: group.imagePath,
          isSelected: _selectedItemId == group.id,
          onTap: () => setState(() {
            _selectedItemId = (_selectedItemId == group.id ? null : group.id);
          }),
          isDark: isDark,
          isLandscape: isLandscape,
        );
      },
    );
  }

  Widget _buildMasterTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? imagePath,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required bool isLandscape,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: isLandscape ? 4 : 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 16 : 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: isLandscape ? 40 : 38,
                height: isLandscape ? 40 : 38,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: imagePath != null ? DecorationImage(image: NetworkImage(imagePath), fit: BoxFit.cover) : null,
                ),
                child: imagePath == null ? Icon(icon, color: isSelected ? Colors.white : color, size: isLandscape ? 20 : 18) : null,
              ),
              SizedBox(width: isLandscape ? 18 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: isLandscape ? 14 : 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.chevron_right_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallAvatar(BuildContext context, String? photoUrl, Color statusColor, ColorScheme colorScheme, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactsScreen()));
      },
      child: Stack(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: photoUrl != null
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.person, color: colorScheme.primary, size: 18),
                  )
                : Container(
                    color: colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.person, color: colorScheme.primary, size: 18),
                  ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF151515) : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab(DataService dataService, AppLocalizations l10n) {
    final groups = dataService.groups;
    if (groups.isEmpty) {
      return Center(child: Text(l10n.noGroupsYet));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      itemCount: groups.length,
      itemBuilder: (context, index) => _buildGroupCard(context, group: groups[index]),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final dataService = context.watch<DataService>();
    final photoUrl = FirebaseService().userPhotoUrl;
    
    // Configuración del indicador de conexión
    Color statusColor;
    switch (dataService.connectivityStatus) {
      case ConnectivityStatus.wifi: statusColor = Colors.green; break;
      case ConnectivityStatus.mobile: statusColor = Colors.blue; break;
      case ConnectivityStatus.none: statusColor = Colors.red; break;
      case ConnectivityStatus.syncing: statusColor = colorScheme.primary; break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.groups,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactsScreen()),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            Icon(Icons.person, color: colorScheme.primary, size: 20),
                        )
                      : Container(
                          color: colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.person, color: colorScheme.primary, size: 20),
                        ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestRestriction(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded, color: colorScheme.primary, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.nestStudioForTeams,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.nestStudioGuestDesc,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(l10n.registerAccount, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, {required Group group}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupColor = group.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A).withOpacity(0.5) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: groupColor.withOpacity(isDark ? 0.2 : 0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GroupDetailsScreen(groupId: group.id))),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 48, decoration: BoxDecoration(color: groupColor.withAlpha(150), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('${group.members.length} miembros', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 14)),
                      ],
                    ),
                  ),
                  Container(
                    width: 56, 
                    height: 56, 
                    decoration: BoxDecoration(
                      color: groupColor.withAlpha(25), 
                      borderRadius: BorderRadius.circular(18),
                      image: group.imagePath != null ? DecorationImage(image: NetworkImage(group.imagePath!), fit: BoxFit.cover) : null,
                    ), 
                    child: group.imagePath == null ? Icon(Icons.groups_rounded, color: groupColor, size: 28) : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Código de invitación:', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3), fontSize: 13)),
                  Text(group.inviteCode, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace', letterSpacing: 1.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnifiedGroupSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UnifiedGroupScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

class UnifiedGroupScreen extends StatefulWidget {
  const UnifiedGroupScreen({super.key});

  @override
  State<UnifiedGroupScreen> createState() => _UnifiedGroupScreenState();
}

class _UnifiedGroupScreenState extends State<UnifiedGroupScreen> {
  final nameController = TextEditingController();
  final joinCodeController = TextEditingController();
  late String createInviteCode;
  bool isCreating = true;
  bool isLoading = false;
  Color _selectedColor = const Color(0xFF6366F1);
  XFile? _selectedImage;

  final List<Color> _availableColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFEC4899), // Pink
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEF4444), // Red
    const Color(0xFF06B6D4), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    createInviteCode = _generateRandomCode();
  }

  @override
  void dispose() {
    nameController.dispose();
    joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) => chars[math.Random().nextInt(chars.length)]).join();
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreating ? l10n.newGroup : l10n.joinGroup),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Switcher
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isCreating = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isCreating ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            l10n.newGroup,
                            style: TextStyle(
                              color: isCreating ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isCreating = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isCreating ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            l10n.joinGroup,
                            style: TextStyle(
                              color: !isCreating ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (isCreating) ...[
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _selectedColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: _selectedColor.withOpacity(0.5), width: 2),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: kIsWeb ? NetworkImage(_selectedImage!.path) : FileImage(File(_selectedImage!.path)) as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _selectedImage == null
                            ? Icon(Icons.add_a_photo_rounded, color: _selectedColor, size: 32)
                            : null,
                      ),
                      if (_selectedImage != null)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildLabel(l10n.groupNameLabel),
              TextField(
                controller: nameController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: l10n.groupNameHint,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.4)),
                ),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildLabel(l10n.distinctiveColor),
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  itemBuilder: (context, index) {
                    final color = _availableColors[index];
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 45,
                        height: 45,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3) : null,
                          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel(l10n.inviteCodeLabel),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Text(
                      createInviteCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => setState(() => createInviteCode = _generateRandomCode()),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildLabel(l10n.enterInviteCode.toUpperCase()),
              const SizedBox(height: 12),
              TextField(
                controller: joinCodeController,
                autofocus: false,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: "ABC123",
                  counterText: "",
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(l10n.joinGroupSubtitle, style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final dataService = Provider.of<DataService>(context, listen: false);
                  if (isCreating) {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.enterGroupNameError)));
                       return;
                    }
                    setState(() => isLoading = true);
                    final userId = dataService.userId;
                    if (userId != null) {
                      String? uploadedUrl;
                      if (_selectedImage != null) {
                        final fb = FirebaseService();
                        final extension = _selectedImage!.path.split('.').last;
                        final path = 'groups/${const Uuid().v4()}.$extension';
                        uploadedUrl = await fb.uploadFile(path, File(_selectedImage!.path));
                      }

                      final newGroup = Group(
                        id: const Uuid().v4(),
                        name: name,
                        imagePath: uploadedUrl,
                        color: _selectedColor,
                        inviteCode: createInviteCode,
                        members: [userId],
                        admins: [userId],
                      );
                      dataService.addGroup(newGroup);
                      Navigator.pop(context);
                    }
                  } else {
                    final code = joinCodeController.text.trim().toUpperCase();
                    if (code.length < 6) return;
                    setState(() => isLoading = true);
                    try {
                      await dataService.joinGroup(code);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('¡Te has unido al grupo correctamente!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        String msg = e.toString();
                        if (msg.contains('invalidCode')) msg = l10n.invalidCodeError;
                        else if (msg.contains('alreadyInGroup')) msg = l10n.alreadyInGroupError;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    } finally {
                      if (context.mounted) setState(() => isLoading = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isCreating ? l10n.createGroup : l10n.joinBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

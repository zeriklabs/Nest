import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../utils/web_reload_helper.dart';

class AppDataScreen extends StatefulWidget {
  const AppDataScreen({super.key});

  @override
  State<AppDataScreen> createState() => _AppDataScreenState();
}

class _AppDataScreenState extends State<AppDataScreen> {
  double _totalMb = 0.0;
  double _cacheMb = 0.0;
  double _dataMb = 0.0;
  bool _isLoadingStorage = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _calculateStorageUsage();
    }
  }

  Future<void> _calculateStorageUsage() async {
    try {
      double cacheBytes = 0.0;
      double dataBytes = 0.0;

      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        cacheBytes += await _getDirSize(tempDir);
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (await appDir.exists()) {
        dataBytes += await _getDirSize(appDir);
      }

      try {
        final dbPath = await getDatabasesPath();
        final dbDir = Directory(dbPath);
        if (await dbDir.exists()) {
          dataBytes += await _getDirSize(dbDir);
        }
      } catch (_) {}

      final totalBytes = cacheBytes + dataBytes;

      if (mounted) {
        setState(() {
          _cacheMb = cacheBytes / (1024 * 1024);
          _dataMb = dataBytes / (1024 * 1024);
          _totalMb = totalBytes / (1024 * 1024);
          _isLoadingStorage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStorage = false;
        });
      }
    }
  }

  Future<double> _getDirSize(Directory dir) async {
    double size = 0.0;
    try {
      final files = dir.listSync(recursive: true, followLinks: false);
      for (var file in files) {
        if (file is File) {
          size += await file.length();
        }
      }
    } catch (_) {}
    return size;
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dataService = Provider.of<DataService>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.syncAndData,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 768;
          final double maxContentWidth = isWide ? 880 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32.0 : 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Tarjeta de Estado de Conexión y Nube
                    _buildStatusCard(dataService, colorScheme, isDark, l10n),
                    const SizedBox(height: 28),

                    // Preferencias de Red (Solo Móvil o Web)
                    _buildSectionTitle(context, l10n.networkAndCloudPreferences),
                    const SizedBox(height: 12),
                    if (!kIsWeb)
                      _buildCardContainer(
                        isDark: isDark,
                        colorScheme: colorScheme,
                        child: SwitchListTile(
                          value: dataService.syncOnlyWifi,
                          activeThumbColor: colorScheme.primary,
                          title: Text(
                            l10n.syncWifiOnly,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Text(
                            l10n.syncWifiOnlyDesc,
                            style: TextStyle(
                              color: colorScheme.onSurface.withAlpha(127),
                              fontSize: 12,
                            ),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.wifi_rounded, color: colorScheme.primary, size: 22),
                          ),
                          onChanged: (val) {
                            dataService.setSyncOnlyWifi(val);
                          },
                        ),
                      )
                    else
                      _buildDataActionCard(
                        context: context,
                        title: l10n.automaticCloudSyncTitle,
                        subtitle: l10n.automaticCloudSyncDesc,
                        icon: Icons.cloud_done_rounded,
                        onTap: () {},
                        showArrow: false,
                      ),

                    if (kIsWeb) ...[
                      const SizedBox(height: 28),
                      _buildSectionTitle(context, l10n.webVersionAndUpdates),
                      const SizedBox(height: 12),
                      _buildCardContainer(
                        isDark: isDark,
                        colorScheme: colorScheme,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.system_update_rounded, color: colorScheme.primary, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.webAppNest,
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.webAppBuildInfo,
                                          style: TextStyle(
                                            color: colorScheme.onSurface.withAlpha(140),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.withAlpha(80)),
                                    ),
                                    child: Text(
                                      l10n.upToDate,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Si se ha publicado una actualización de Nest Web o deseas asegurarte de contar con la versión más reciente del servidor, puedes forzar el refresco a continuación.',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withAlpha(150),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.reloadingWeb),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    Future.delayed(const Duration(milliseconds: 400), () {
                                      if (kIsWeb) {
                                        reloadWebPage();
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.refresh_rounded, size: 20),
                                  label: Text(l10n.reloadApplyUpdate),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Sección de Almacenamiento y Respaldo
                    _buildSectionTitle(context, l10n.storageManagement),
                    const SizedBox(height: 12),

                    if (!kIsWeb) ...[
                      _buildStorageUsageCard(colorScheme, isDark, l10n),
                      const SizedBox(height: 16),
                      _buildDataActionCard(
                        context: context,
                        title: l10n.createBackup,
                        subtitle: l10n.createBackupSubtitle,
                        icon: Icons.backup_outlined,
                        onTap: () => _createBackup(context, dataService, l10n),
                      ),
                      const SizedBox(height: 12),
                      _buildDataActionCard(
                        context: context,
                        title: l10n.restoreBackup,
                        subtitle: l10n.restoreBackupSubtitle,
                        icon: Icons.settings_backup_restore_rounded,
                        onTap: () => _restoreBackup(context, dataService, l10n),
                      ),
                      const SizedBox(height: 12),
                      _buildDataActionCard(
                        context: context,
                        title: l10n.clearCacheTitle,
                        subtitle: l10n.clearCacheSubtitle,
                        icon: Icons.cleaning_services_rounded,
                        onTap: () async {
                          final freedMb = _cacheMb;
                          try {
                            final tempDir = await getTemporaryDirectory();
                            if (await tempDir.exists()) {
                              final files = tempDir.listSync(recursive: true, followLinks: false);
                              for (var file in files) {
                                if (file is File) {
                                  try { file.deleteSync(); } catch (_) {}
                                }
                              }
                            }
                          } catch (_) {}

                          dataService.clearLocalCache();
                          await _calculateStorageUsage();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.cacheClearedReleased(freedMb.toStringAsFixed(1))),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ] else ...[
                      _buildDataActionCard(
                        context: context,
                        title: l10n.resyncCloudData,
                        subtitle: l10n.resyncCloudDataDesc,
                        icon: Icons.sync_rounded,
                        onTap: () async {
                          await dataService.syncAllFromCloud();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.cloudSyncCompleted),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDataActionCard(
                        context: context,
                        title: l10n.clearBrowserCache,
                        subtitle: l10n.clearBrowserCacheDesc,
                        icon: Icons.cleaning_services_rounded,
                        onTap: () {
                          dataService.clearLocalCache();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.browserCacheCleared),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(DataService dataService, ColorScheme colorScheme, bool isDark, AppLocalizations l10n) {
    final status = dataService.connectivityStatus;
    IconData icon;
    String label;
    Color color;

    if (kIsWeb) {
      icon = Icons.cloud_done_rounded;
      label = l10n.onlineWeb;
      color = colorScheme.primary;
    } else {
      switch (status) {
        case ConnectivityStatus.wifi:
          icon = Icons.wifi_rounded;
          label = l10n.connected;
          color = Colors.green;
          break;
        case ConnectivityStatus.mobile:
          icon = Icons.swap_vert_rounded;
          label = l10n.mobileData;
          color = Colors.blue;
          break;
        case ConnectivityStatus.none:
          icon = Icons.cloud_off_rounded;
          label = l10n.noConnection;
          color = Colors.red;
          break;
        case ConnectivityStatus.syncing:
          icon = Icons.sync_rounded;
          label = l10n.syncing;
          color = colorScheme.primary;
          break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withAlpha(51), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kIsWeb 
                          ? l10n.cloudServerActive
                          : (status == ConnectivityStatus.none
                              ? l10n.cannotSyncNow
                              : l10n.syncStatusDesc),
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(140),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colorScheme.outlineVariant.withAlpha(40), height: 1),
          const SizedBox(height: 14),
          Text(
            l10n.syncInfo,
            style: TextStyle(
              color: colorScheme.onSurface.withAlpha(150),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageUsageCard(ColorScheme colorScheme, bool isDark, AppLocalizations l10n) {
    final double safeTotal = _totalMb > 0 ? _totalMb : 1.0;
    final double dataRatio = (_dataMb / safeTotal).clamp(0.02, 0.98);
    final double cacheRatio = (_cacheMb / safeTotal).clamp(0.02, 0.98);

    final String totalUsedText = l10n.totalUsed(_totalMb.toStringAsFixed(1));
    final String dataSizeText = l10n.appDataSize(_dataMb.toStringAsFixed(1));
    final String cacheSizeText = l10n.cacheSize(_cacheMb.toStringAsFixed(1));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.storage_rounded, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nestStorage,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isLoadingStorage ? l10n.syncing : totalUsedText,
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(140),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 12,
              child: _isLoadingStorage
                  ? LinearProgressIndicator(
                      backgroundColor: colorScheme.outlineVariant.withAlpha(51),
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: (dataRatio * 100).toInt(),
                          child: Container(color: colorScheme.primary),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: (cacheRatio * 100).toInt(),
                          child: Container(color: Colors.amber.shade600),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(dataSizeText, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withAlpha(180), fontWeight: FontWeight.w500)),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.amber.shade600, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(cacheSizeText, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withAlpha(180), fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required bool isDark, required ColorScheme colorScheme, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(51)),
      ),
      child: child,
    );
  }

  Widget _buildDataActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showArrow = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(51)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? colorScheme.error.withAlpha(25)
                      : colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? colorScheme.error : colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive ? colorScheme.error : colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(140),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (showArrow)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.onSurface.withAlpha(76),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createBackup(BuildContext context, DataService dataService, AppLocalizations l10n) async {
    try {
      final jsonStr = dataService.exportBackupJson();

      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        final directory = await getTemporaryDirectory();
        final fileName = 'nest_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonStr);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Nest Backup - $fileName',
        );
      } else {
        await Clipboard.setData(ClipboardData(text: jsonStr));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.backupSuccess),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, DataService dataService, AppLocalizations l10n) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String? jsonStr;

        if (file.bytes != null) {
          jsonStr = String.fromCharCodes(file.bytes!);
        } else if (file.path != null) {
          jsonStr = await File(file.path!).readAsString();
        }

        if (jsonStr != null && jsonStr.isNotEmpty) {
          final success = await dataService.importBackupJson(jsonStr);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? l10n.restorationCompleted : 'Error al importar la copia de seguridad'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

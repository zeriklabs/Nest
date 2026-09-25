import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nest/l10n/app_localizations.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late MobileScannerController _controller;
  bool _isInstructionOpen = true;
  bool _hasDetected = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      autoStart: true, // Iniciamos la cámara de inmediato para que enfoque
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionDialog();
    });
  }

  void _showInstructionDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            Text(l10n.qrScanner),
          ],
        ),
        content: Text(
          l10n.qrScannerInstruction,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                setState(() => _isInstructionOpen = false);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.understood),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.qrScanner, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              // Log para verificar si el callback se está ejecutando
              if (capture.barcodes.isNotEmpty) {
                debugPrint('Scanner: Detectados ${capture.barcodes.length} códigos');
              }

              if (_isInstructionOpen || _hasDetected) return;

              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null && code.isNotEmpty) {
                  debugPrint('Scanner: QR Válido -> $code');
                  _hasDetected = true;
                  HapticFeedback.vibrate();
                  
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (mounted) Navigator.pop(context, code);
                  });
                  break;
                }
              }
            },
          ),

          // Overlay Visual
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.primary, width: 4),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Apunta al código QR",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          
          // Flash
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 30,
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 30),
                ),
                onPressed: () => _controller.toggleTorch(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

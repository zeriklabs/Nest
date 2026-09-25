import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../models/group.dart';
import '../services/data_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  String _inviteCode = '';

  @override
  void initState() {
    super.initState();
    _inviteCode = _generateRandomCode();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterGroupNameError)),
      );
      return;
    }

    final dataService = Provider.of<DataService>(context, listen: false);
    final userId = dataService.userId;
    if (userId == null) return;

    final newGroup = Group(
      id: Uuid().v4(),
      name: _nameController.text.trim(),
      inviteCode: _inviteCode,
      members: [userId],
      admins: [userId],
    );

    dataService.addGroup(newGroup);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newGroup, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.groups_rounded, size: 60, color: colorScheme.primary),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primary,
                    child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildLabel(l10n.groupNameLabel),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: l10n.groupNameHint,
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.4)),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 30),
            _buildLabel(l10n.inviteCodeLabel),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Text(
                    _inviteCode,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4, fontFamily: 'monospace'),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => setState(() => _inviteCode = _generateRandomCode()),
                  ),
                ],
              ),
            ),
            Text(
              l10n.shareCodeMsg,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Text(l10n.createGroup, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 1.2,
      ),
    );
  }
}

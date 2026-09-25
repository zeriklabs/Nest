import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../services/data_service.dart';
import '../utils/date_utils.dart';
import '../utils/html_utils.dart';
import '../widgets/rich_text_webview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final String? notebookId;
  final String? groupId;
  final PageType pageType;
  final List<String>? initialSharedWith;

  const NoteEditorScreen({
    super.key, 
    this.note, 
    this.notebookId,
    this.groupId,
    this.pageType = PageType.plain,
    this.initialSharedWith,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _DesktopToolbar extends StatelessWidget {
  final Function(String, [String?]) onCommand;
  final VoidCallback onLinkTap;
  final Map<String, bool> activeStyles;
  final Color? currentColor;
  final ValueChanged<Color?> onColorSelected;
  final AppLocalizations l10n;
  final ThemeData theme;
  final Function(String) onAttachmentSelected;

  const _DesktopToolbar({
    super.key,
    required this.onCommand,
    required this.onLinkTap,
    required this.activeStyles,
    required this.currentColor,
    required this.onColorSelected,
    required this.l10n,
    required this.theme,
    required this.onAttachmentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Color toolbarBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F3F5);
    final Color toolbarIconColor = isDark ? Colors.white : const Color(0xFF1C1B1F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: toolbarBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: toolbarIconColor.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BlockStyleMenu(activeStyles: activeStyles, iconColor: toolbarIconColor, onCommand: onCommand),
          _FontSizeMenu(activeStyles: activeStyles, iconColor: toolbarIconColor, onCommand: onCommand),
          _vDivider(toolbarIconColor),
          _ToolbarButton(icon: Icons.format_bold, color: toolbarIconColor, onTap: () => onCommand('bold'), isActive: activeStyles['bold'] ?? false),
          _ToolbarButton(icon: Icons.format_italic, color: toolbarIconColor, onTap: () => onCommand('italic'), isActive: activeStyles['italic'] ?? false),
          _ToolbarButton(icon: Icons.format_underlined, color: toolbarIconColor, onTap: () => onCommand('underline'), isActive: activeStyles['underline'] ?? false),
          _ToolbarButton(icon: Icons.format_strikethrough, color: toolbarIconColor, onTap: () => onCommand('strikeThrough'), isActive: activeStyles['strikeThrough'] ?? false),
          _vDivider(toolbarIconColor),
          _ToolbarButton(icon: Icons.format_list_bulleted, color: toolbarIconColor, onTap: () => onCommand('insertUnorderedList'), isActive: activeStyles['insertUnorderedList'] ?? false),
          _ToolbarButton(icon: Icons.format_list_numbered, color: toolbarIconColor, onTap: () => onCommand('insertOrderedList'), isActive: activeStyles['insertOrderedList'] ?? false),
          _AlignmentMenu(activeStyles: activeStyles, iconColor: toolbarIconColor, onCommand: onCommand),
          _vDivider(toolbarIconColor),
          _ToolbarButton(icon: Icons.functions, color: toolbarIconColor, onTap: () => onCommand('insertMath')),
          _ToolbarButton(icon: Icons.link, color: toolbarIconColor, onTap: onLinkTap),
          _ToolbarButton(icon: Icons.format_quote, color: toolbarIconColor, onTap: () => onCommand('formatBlock', 'blockquote'), isActive: activeStyles['blockquote'] ?? false),
          _ToolbarButton(icon: Icons.code, color: toolbarIconColor, onTap: () => onCommand('formatBlock', activeStyles['code'] == true ? 'p' : 'pre'), isActive: activeStyles['code'] ?? false),
          _vDivider(toolbarIconColor),
          _ColorMenu(currentColor: currentColor, onColorSelected: onColorSelected, iconColor: toolbarIconColor),
          _AttachmentMenu(theme: theme, l10n: l10n, color: toolbarIconColor, onAttachmentSelected: onAttachmentSelected),
        ],
      ),
    );
  }

  Widget _vDivider(Color color) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: color.withOpacity(0.12),
    );
  }
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final GlobalKey<RichTextEditorWebViewState> _editorKey = GlobalKey();
  String _currentHtml = '';
  
  final TextEditingController _titleController = TextEditingController();
  Color? _backgroundColor;
  bool _isEditing = false;
  bool _hasSaved = false;
  bool _isReadOnly = true;
  late PageType _pageType;
  bool _isSharedInGroup = false;
  Map<String, bool> _activeStyles = {};
  Note? _activeNote;

  DataService? _dataService;
  AppLocalizations? _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = Provider.of<DataService>(context, listen: false);
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _activeNote = widget.note;
    final bool noteExists = _activeNote != null;
    _isEditing = noteExists;
    _isReadOnly = noteExists;
    _pageType = _activeNote?.pageType ?? widget.pageType;
    _isSharedInGroup = widget.groupId != null;
    _titleController.text = _activeNote?.title ?? '';
    
    // Default color to Post-it yellow for new notes
    _backgroundColor = _activeNote?.backgroundColor ?? 
        (noteExists ? null : const Color(0xFFFFF9C4));
        
    _titleController.addListener(_onTitleChanged);

    if (noteExists) {
      _currentHtml = _activeNote!.htmlContent ?? HtmlUtils.deltaToHtml(_activeNote!.content);
    } else {
      _currentHtml = '';
    }
  }

  void _onTitleChanged() {
    setState(() {
      _hasSaved = false;
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _autoSave();
    _titleController.dispose();
    super.dispose();
  }

  bool get _hasContent {
    final String title = _titleController.text.trim();
    // Limpiamos etiquetas HTML (<...>), entidades (&nbsp;, etc.) y todo tipo de espacios/saltos de línea
    final String plainText = _currentHtml
        .replaceAll(RegExp(r'<[^>]*>|&[a-z]+;|[\s\n\r]'), '')
        .trim();
    
    // Una nota es válida SOLAMENTE si tiene un título O tiene contenido real en el cuerpo
    return title.isNotEmpty || plainText.isNotEmpty;
  }

  bool get _isNotebookNote => widget.notebookId != null || (_activeNote?.notebookId != null);

  void _autoSave() {
    // Protección de seguridad doble: no guardar si no hay contenido o si ya se guardó esta versión
    if (!_hasContent || _hasSaved) {
      if (!_hasContent) debugPrint("NoteEditor: Guardado cancelado (Nota vacía)");
      return;
    }

    final String title = _titleController.text.trim().isEmpty 
        ? 'Sin título' 
        : _titleController.text.trim();
        
    final deltaContent = HtmlUtils.htmlToDelta(_currentHtml);

    if (_activeNote != null) {
      _activeNote = _activeNote!.copyWith(
        title: title,
        content: deltaContent,
        htmlContent: _currentHtml,
        backgroundColor: _backgroundColor,
        pageType: _pageType,
        updatedAt: DateTime.now(),
        sharedWith: _activeNote!.sharedWith, // Mantener compartidos
      );
      _dataService?.updateNote(_activeNote!);
    } else {
      _activeNote = Note(
        id: const Uuid().v4(),
        author: _dataService?.userName ?? 'Anónimo',
        title: title,
        content: deltaContent,
        htmlContent: _currentHtml,
        backgroundColor: _backgroundColor,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notebookId: widget.notebookId,
        pageType: _pageType,
        sharedWith: widget.initialSharedWith ?? [],
      );
      
      if (widget.groupId != null && _isSharedInGroup) {
        _dataService?.addNoteToGroup(widget.groupId!, _activeNote!);
      } else {
        _dataService?.addNote(_activeNote!);
      }
    }
    
    _hasSaved = true;
  }

  Future<void> _showMathHint() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('math_hint_shown') ?? false) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Escribe tu fórmula entre \$ y pulsa el icono del Libro para verla'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
    await prefs.setBool('math_hint_shown', true);
  }

  Future<void> _showLinkDialog() async {
    final l10n = AppLocalizations.of(context)!;
    String url = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.insertLink),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.urlLabel),
          onChanged: (val) => url = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              if (url.isNotEmpty) {
                if (!url.startsWith('http')) url = 'https://$url';
                _editorKey.currentState?.format('createLink', url);
              }
              Navigator.pop(context);
            },
            child: Text(l10n.insertBtn),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachment(String type) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type == 'image' ? FileType.image : FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        // ...
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorOpeningUrl} (FilePicker)')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bool isAppDark = theme.brightness == Brightness.dark;
    final bool isNoteDark = _backgroundColor != null 
        ? _backgroundColor!.computeLuminance() < 0.5 
        : isAppDark;

    final Color contentColor = isNoteDark ? Colors.white : Colors.black;
    final Color topBarTextColor = isAppDark ? Colors.white : const Color(0xFF1C1B1F);

    final String lastModified = _activeNote != null 
        ? DateUtilsFormatter.formatDynamicDate(context, _activeNote!.updatedAt)
        : DateUtilsFormatter.formatDynamicDate(context, DateTime.now());

    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      final Color scaffoldBg = isAppDark ? const Color(0xFF121212) : const Color(0xFFF3F4F6);
      final Color topBarBg = isAppDark ? const Color(0xFF1E1E1E) : Colors.white;

      return PopScope(
        onPopInvokedWithResult: (didPop, result) { if (didPop) _autoSave(); },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: isAppDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: scaffoldBg,
            body: SafeArea(
              child: Column(
                children: [
                  // Desktop Navigation Bar with Integrated Formatting Toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: topBarBg,
                      border: Border(bottom: BorderSide(color: topBarTextColor.withOpacity(0.06))),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isAppDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          color: topBarTextColor,
                          onPressed: () {
                            _autoSave();
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isNotebookNote ? 'Cuaderno / Nota' : 'Nota',
                          style: TextStyle(
                            color: topBarTextColor.withOpacity(0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!_isReadOnly)
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: _DesktopToolbar(
                                  activeStyles: _activeStyles,
                                  onCommand: (cmd, [val]) {
                                    _editorKey.currentState?.format(cmd, val);
                                    if (cmd == 'insertMath') _showMathHint();
                                  },
                                  onLinkTap: _showLinkDialog,
                                  currentColor: _backgroundColor,
                                  onColorSelected: (color) => setState(() => _backgroundColor = color),
                                  l10n: l10n,
                                  theme: theme,
                                  onAttachmentSelected: _pickAttachment,
                                ),
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(_isReadOnly ? Icons.edit_outlined : Icons.menu_book_outlined),
                          color: topBarTextColor,
                          tooltip: _isReadOnly ? 'Editar' : 'Modo Lectura',
                          onPressed: () {
                            setState(() {
                              if (!_isReadOnly) _autoSave();
                              _isReadOnly = !_isReadOnly;
                            });
                          },
                        ),
                        if (!_isReadOnly)
                          IconButton(
                            icon: Icon(
                              Icons.check_rounded, 
                              color: _hasContent ? Colors.green : Colors.green.withOpacity(0.3)
                            ),
                            tooltip: 'Guardar cambios',
                            onPressed: _hasContent ? () {
                              _autoSave();
                              setState(() => _isReadOnly = true);
                            } : null,
                          ),
                      ],
                    ),
                  ),

                  // Centered Desktop Document Sheet
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 650),
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: _backgroundColor ?? (isAppDark ? const Color(0xFF1E1E1E) : Colors.white),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: contentColor.withOpacity(0.08)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isAppDark ? 0.3 : 0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _PagePatternPainter(
                                    type: _pageType, 
                                    isDark: isNoteDark,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _titleController,
                                      enabled: !_isReadOnly,
                                      decoration: InputDecoration(
                                        hintText: l10n.pageTitleHint,
                                        hintStyle: TextStyle(
                                          color: contentColor.withOpacity(0.3),
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      style: TextStyle(
                                        color: contentColor,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_rounded, size: 14, color: contentColor.withOpacity(0.4)),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${l10n.modifiedAt}$lastModified',
                                          style: TextStyle(
                                            color: contentColor.withOpacity(0.5),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Divider(color: contentColor.withOpacity(0.08), height: 1),
                                    const SizedBox(height: 20),

                                    SizedBox(
                                      height: 600,
                                      child: RichTextEditorWebView(
                                        key: _editorKey,
                                        initialHtml: _currentHtml,
                                        readOnly: _isReadOnly,
                                        backgroundColor: _backgroundColor,
                                        textColor: contentColor,
                                        onChanged: (html) {
                                          setState(() {
                                            _currentHtml = html;
                                            _hasSaved = false;
                                          });
                                        },
                                        onStyleChanged: (styles) {
                                          setState(() => _activeStyles = styles);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final Widget modifiedAtLabel = Positioned(
      bottom: 8,
      right: 16,
      child: Text(
        '${l10n.modifiedAt}$lastModified',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isNoteDark
              ? Colors.white.withOpacity(0.5)
              : Colors.black.withOpacity(0.6),
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, result) { if (didPop) _autoSave(); },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isNoteDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Theme(
          data: theme.copyWith(
            brightness: isNoteDark ? Brightness.dark : Brightness.light,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.colorScheme.primary,
              brightness: isNoteDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: Scaffold(
            backgroundColor: _backgroundColor ?? theme.scaffoldBackgroundColor,
            appBar: AppBar(
              systemOverlayStyle: isNoteDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
              backgroundColor: _backgroundColor ?? theme.appBarTheme.backgroundColor,
              iconTheme: IconThemeData(color: contentColor),
              actionsIconTheme: IconThemeData(color: contentColor),
              title: _isNotebookNote 
                ? TextField(
                    controller: _titleController,
                    enabled: !_isReadOnly,
                    decoration: InputDecoration(
                      hintText: l10n.pageTitleHint, 
                      border: InputBorder.none,
                    ),
                    style: theme.appBarTheme.titleTextStyle?.copyWith(color: contentColor, fontSize: 18),
                  )
                : const SizedBox.shrink(),
              actions: [
                if (!_isReadOnly) ...[
                  _ColorMenu(
                    currentColor: _backgroundColor,
                    onColorSelected: (color) => setState(() => _backgroundColor = color),
                    iconColor: contentColor,
                  ),
                  _AttachmentMenu(
                    theme: theme, 
                    l10n: l10n, 
                    color: contentColor, 
                    onAttachmentSelected: _pickAttachment,
                  ),
                ],
                IconButton(
                  icon: Icon(_isReadOnly ? Icons.edit_outlined : Icons.menu_book_outlined),
                  color: contentColor,
                  onPressed: () {
                    setState(() {
                      if (!_isReadOnly) _autoSave();
                      _isReadOnly = !_isReadOnly;
                    });
                  },
                ),
                if (!_isReadOnly)
                  IconButton(
                    icon: Icon(
                      Icons.check_rounded, 
                      color: _hasContent ? Colors.green : Colors.green.withOpacity(0.3)
                    ),
                    onPressed: _hasContent ? () {
                      _autoSave();
                      setState(() => _isReadOnly = true);
                    } : null,
                  ),
              ],
              bottom: _isReadOnly ? null : PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: _TopToolbar(
                  activeStyles: _activeStyles,
                  iconColor: contentColor,
                  onCommand: (cmd, [val]) => _editorKey.currentState?.format(cmd, val),
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _PagePatternPainter(type: _pageType, isDark: theme.brightness == Brightness.dark)),
                      Positioned.fill(
                        child: Stack(
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: 1, // Mostrar siempre de inmediato
                              child: RichTextEditorWebView(
                                key: _editorKey,
                                initialHtml: _currentHtml,
                                readOnly: _isReadOnly,
                                backgroundColor: _backgroundColor,
                                textColor: contentColor,
                                onChanged: (html) {
                                  setState(() {
                                    _currentHtml = html;
                                    _hasSaved = false;
                                  });
                                },
                                onStyleChanged: (styles) {
                                  setState(() => _activeStyles = styles);
                                },
                              ),
                            ),
                            modifiedAtLabel,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isReadOnly) _BottomToolbar(
                  activeStyles: _activeStyles,
                  iconColor: contentColor,
                  onCommand: (cmd, [val]) {
                    _editorKey.currentState?.format(cmd, val);
                    if (cmd == 'insertMath') _showMathHint();
                  },
                  onLinkTap: _showLinkDialog,
                  backgroundColor: _backgroundColor,
                ),
                if (widget.groupId != null)
                  Consumer<DataService>(
                    builder: (context, data, child) {
                      final group = data.groups.firstWhereOrNull((g) => g.id == widget.groupId);
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        decoration: BoxDecoration(
                          color: isNoteDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          border: Border(top: BorderSide(color: contentColor.withValues(alpha: 0.05))),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.groups_rounded, size: 16, color: contentColor.withOpacity(0.5)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Se publicará en: ${group?.name ?? "Grupo"}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: contentColor.withOpacity(0.6),
                                ),
                              ),
                            ),
                            if (_activeNote == null)
                              Switch(
                                value: _isSharedInGroup,
                                onChanged: (val) => setState(() => _isSharedInGroup = val),
                                activeColor: Colors.green,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopToolbar extends StatelessWidget {
  final Function(String, [String?]) onCommand;
  final Color iconColor;
  final Map<String, bool> activeStyles;

  const _TopToolbar({
    required this.onCommand,
    required this.iconColor,
    required this.activeStyles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: iconColor.withOpacity(0.05))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _BlockStyleMenu(
            activeStyles: activeStyles,
            iconColor: iconColor,
            onCommand: onCommand,
          ),
          _FontSizeMenu(
            activeStyles: activeStyles,
            iconColor: iconColor,
            onCommand: onCommand,
          ),
          _AlignmentMenu(
            activeStyles: activeStyles,
            iconColor: iconColor,
            onCommand: onCommand,
          ),
          VerticalDivider(width: 20, indent: 8, endIndent: 8, color: iconColor.withOpacity(0.2)),
          _ToolbarButton(
            icon: Icons.format_list_bulleted, 
            color: iconColor, 
            onTap: () => onCommand('insertUnorderedList'),
            isActive: activeStyles['insertUnorderedList'] ?? false,
          ),
          _ToolbarButton(
            icon: Icons.format_list_numbered, 
            color: iconColor, 
            onTap: () => onCommand('insertOrderedList'),
            isActive: activeStyles['insertOrderedList'] ?? false,
          ),
          VerticalDivider(width: 20, indent: 8, endIndent: 8, color: iconColor.withOpacity(0.2)),
          _ToolbarButton(
            icon: Icons.format_indent_increase,
            color: iconColor,
            onTap: () => onCommand('indent'),
          ),
          _ToolbarButton(
            icon: Icons.format_indent_decrease,
            color: iconColor,
            onTap: () => onCommand('outdent'),
          ),
        ],
      ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final Function(String, [String?]) onCommand;
  final VoidCallback onLinkTap;
  final Color iconColor;
  final Map<String, bool> activeStyles;
  final Color? backgroundColor;

  const _BottomToolbar({
    required this.onCommand, 
    required this.onLinkTap,
    required this.iconColor,
    required this.activeStyles,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color effectiveBg = backgroundColor ?? theme.colorScheme.surface;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: effectiveBg.withOpacity(0.95),
        border: Border(top: BorderSide(color: iconColor.withOpacity(0.1))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _ToolbarButton(
            icon: Icons.format_bold, 
            color: iconColor, 
            onTap: () => onCommand('bold'),
            isActive: activeStyles['bold'] ?? false,
          ),
          _ToolbarButton(
            icon: Icons.format_italic, 
            color: iconColor, 
            onTap: () => onCommand('italic'),
            isActive: activeStyles['italic'] ?? false,
          ),
          _ToolbarButton(
            icon: Icons.format_underlined, 
            color: iconColor, 
            onTap: () => onCommand('underline'),
            isActive: activeStyles['underline'] ?? false,
          ),
          _ToolbarButton(
            icon: Icons.format_strikethrough, 
            color: iconColor, 
            onTap: () => onCommand('strikeThrough'),
            isActive: activeStyles['strikeThrough'] ?? false,
          ),
          _ToolbarButton(
            icon: Icons.subscript, 
            color: iconColor, 
            onTap: () => onCommand('subscript'),
            isActive: activeStyles['subscript'] ?? false,
          ),
          _ToolbarButton(
            icon: Icons.superscript, 
            color: iconColor, 
            onTap: () => onCommand('superscript'),
            isActive: activeStyles['superscript'] ?? false,
          ),
          VerticalDivider(width: 20, indent: 10, endIndent: 10, color: iconColor.withOpacity(0.2)),
          _ToolbarButton(
            icon: Icons.functions, 
            color: iconColor, 
            onTap: () => onCommand('insertMath'),
          ),
          _ToolbarButton(
            icon: Icons.link, 
            color: iconColor, 
            onTap: onLinkTap,
          ),
          _ToolbarButton(
            icon: Icons.format_quote, 
            color: iconColor, 
            onTap: () => onCommand('formatBlock', 'blockquote'),
            isActive: activeStyles['blockquote'] ?? false,
          ),
          _ToolbarButton(
            icon: Icons.code, 
            color: iconColor, 
            onTap: () => onCommand('formatBlock', activeStyles['code'] == true ? 'p' : 'pre'),
            isActive: activeStyles['code'] ?? false,
          ),
        ],
      ),
    );
  }
}


class _BlockStyleMenu extends StatelessWidget {
  final Map<String, bool> activeStyles;
  final Color iconColor;
  final Function(String, [String?]) onCommand;

  const _BlockStyleMenu({
    required this.activeStyles,
    required this.iconColor,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    IconData getSelectedIcon() {
      if (activeStyles['h1'] == true) return Icons.looks_one_outlined;
      if (activeStyles['h2'] == true) return Icons.looks_two_outlined;
      if (activeStyles['h3'] == true) return Icons.looks_3_outlined;
      return Icons.text_fields_rounded;
    }

    return PopupMenuButton<String>(
      tooltip: l10n.normalText,
      icon: Icon(getSelectedIcon(), color: iconColor, size: 20),
      offset: const Offset(0, -180),
      onSelected: (val) => onCommand('formatBlock', val),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'p',
          child: Row(
            children: [
              const Icon(Icons.text_fields_rounded, size: 20),
              const SizedBox(width: 12),
              Text(l10n.normalText, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'h1',
          child: Row(
            children: [
              const Icon(Icons.looks_one_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l10n.h1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'h2',
          child: Row(
            children: [
              const Icon(Icons.looks_two_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l10n.h2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'h3',
          child: Row(
            children: [
              const Icon(Icons.looks_3_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l10n.h3, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}


class _FontSizeMenu extends StatelessWidget {
  final Map<String, bool> activeStyles;
  final Color iconColor;
  final Function(String, [String?]) onCommand;

  const _FontSizeMenu({
    required this.activeStyles,
    required this.iconColor,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    // execCommand 'fontSize' values are 1-7. 
    // We'll map them to names for the user.
    final currentSize = activeStyles['fontSize']?.toString() ?? '3';

    String getSizeLabel(String size) {
      switch (size) {
        case '1': return 'Muy pequeño';
        case '2': return 'Pequeño';
        case '3': return 'Normal';
        case '4': return 'Grande';
        case '5': return 'Muy grande';
        case '6': return 'Extra grande';
        case '7': return 'Gigante';
        default: return 'Normal';
      }
    }

    return PopupMenuButton<String>(
      tooltip: 'Tamaño de fuente',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_size_rounded, color: iconColor, size: 18),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down_rounded, size: 16),
        ],
      ),
      offset: const Offset(0, -250),
      onSelected: (val) => onCommand('fontSize', val),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        _buildSizeItem('1', 'Muy pequeño', 12),
        _buildSizeItem('2', 'Pequeño', 14),
        _buildSizeItem('3', 'Normal', 16),
        _buildSizeItem('4', 'Grande', 18),
        _buildSizeItem('5', 'Muy grande', 22),
        _buildSizeItem('6', 'Extra grande', 26),
        _buildSizeItem('7', 'Gigante', 32),
      ],
    );
  }

  PopupMenuItem<String> _buildSizeItem(String value, String label, double fontSize) {
    return PopupMenuItem(
      value: value,
      child: Text(
        label,
        style: TextStyle(fontSize: fontSize),
      ),
    );
  }
}

class _AlignmentMenu extends StatelessWidget {
  final Map<String, bool> activeStyles;
  final Color iconColor;
  final Function(String, [String?]) onCommand;

  const _AlignmentMenu({
    required this.activeStyles,
    required this.iconColor,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    IconData getSelectedIcon() {
      if (activeStyles['justifyCenter'] == true) return Icons.format_align_center;
      if (activeStyles['justifyRight'] == true) return Icons.format_align_right;
      if (activeStyles['justifyFull'] == true) return Icons.format_align_justify;
      return Icons.format_align_left;
    }

    return PopupMenuButton<String>(
      tooltip: 'Alineación',
      icon: Icon(getSelectedIcon(), color: iconColor, size: 20),
      offset: const Offset(0, -220),
      onSelected: (val) => onCommand(val),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'justifyLeft',
          child: Row(
            children: [
              Icon(Icons.format_align_left, size: 20),
              SizedBox(width: 12),
              Text('Izquierda', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'justifyCenter',
          child: Row(
            children: [
              Icon(Icons.format_align_center, size: 20),
              SizedBox(width: 12),
              Text('Centro', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'justifyRight',
          child: Row(
            children: [
              Icon(Icons.format_align_right, size: 20),
              SizedBox(width: 12),
              Text('Derecha', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'justifyFull',
          child: Row(
            children: [
              Icon(Icons.format_align_justify, size: 20),
              SizedBox(width: 12),
              Text('Justificado', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool isActive;

  const _ToolbarButton({
    required this.icon, 
    required this.onTap, 
    required this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon, 
        size: 20, 
        color: isActive ? Theme.of(context).colorScheme.primary : color,
      ),
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: isActive ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

class _PagePatternPainter extends StatelessWidget {
  final PageType type;
  final bool isDark;

  const _PagePatternPainter({required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (type == PageType.plain) return const SizedBox.shrink();

    return CustomPaint(
      painter: _PatternPainter(type: type, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final PageType type;
  final Color color;

  _PatternPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    switch (type) {
      case PageType.ruled:
        const step = 30.0;
        for (double y = 60.0; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        paint.color = Colors.red.withValues(alpha: 0.2);
        canvas.drawLine(const Offset(40, 0), Offset(40, size.height), paint);
        break;
      case PageType.grid:
        const step = 30.0;
        for (double y = 0.0; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        for (double x = 0.0; x < size.width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        break;
      case PageType.dotted:
        const step = 30.0;
        for (double y = step; y < size.height; y += step) {
          for (double x = step; x < size.width; x += step) {
            canvas.drawCircle(Offset(x, y), 1.0, paint);
          }
        }
        break;
      case PageType.plain:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AttachmentMenu extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations l10n;
  final Color color;
  final Function(String) onAttachmentSelected;
  const _AttachmentMenu({required this.theme, required this.l10n, required this.onAttachmentSelected, required this.color});
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      elevation: 0,
      icon: Icon(Icons.attach_file, color: color),
      onSelected: onAttachmentSelected,
      itemBuilder: (context) => [
        PopupMenuItem(value: 'image', child: Row(children: [const Icon(Icons.image_outlined), const SizedBox(width: 12), Text(l10n.imageLabel)])),
        PopupMenuItem(value: 'audio', child: Row(children: [const Icon(Icons.mic_none_outlined), const SizedBox(width: 12), Text(l10n.audioLabel)])),
      ],
    );
  }
}

class _ColorMenu extends StatelessWidget {
  final Color? currentColor;
  final Function(Color?) onColorSelected;
  final Color iconColor;

  const _ColorMenu({
    required this.currentColor,
    required this.onColorSelected,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<Color?> palette = [
      null,
      const Color(0xFFFFCDD2), // Red
      const Color(0xFFF8BBD0), // Pink
      const Color(0xFFE1BEE7), // Purple
      const Color(0xFFD1C4E9), // Deep Purple
      const Color(0xFFC5CAE9), // Indigo
      const Color(0xFFBBDEFB), // Blue
      const Color(0xFFB3E5FC), // Light Blue
      const Color(0xFFB2EBF2), // Cyan
      const Color(0xFFB2DFDB), // Teal
      const Color(0xFFC8E6C9), // Green
      const Color(0xFFDCEDC8), // Light Green
      const Color(0xFFF0F4C3), // Lime
      const Color(0xFFFFF9C4), // Yellow (Post-it)
      const Color(0xFFFFECB3), // Amber
      const Color(0xFFFFE0B2), // Orange
      const Color(0xFFFFCCBC), // Deep Orange
      const Color(0xFFD7CCC8), // Brown
      const Color(0xFFCFD8DC), // Blue Grey
      const Color(0xFFFFFFFF), // White
      const Color(0xFFE0E0E0), // Grey
      const Color(0xFFF5F5F5), // Light Grey
    ];

    return PopupMenuButton<Color?>(
      elevation: 4,
      icon: Icon(Icons.palette_outlined, color: iconColor),
      onSelected: onColorSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Row(
            children: [
              const Icon(Icons.format_color_reset_outlined),
              const SizedBox(width: 12),
              Text(l10n.defaultOrder),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 210,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: palette.skip(1).map((color) {
                return InkWell(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentColor?.value == color?.value 
                            ? Colors.black 
                            : Colors.grey.withValues(alpha: 0.3),
                        width: currentColor?.value == color?.value ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

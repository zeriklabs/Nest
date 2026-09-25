import 'dart:convert';
// Force compiler refresh
import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../models/reminder.dart';
import '../models/notification.dart';
import '../models/recurrence.dart';
import '../models/group.dart';
import '../models/group_post.dart';
import '../models/group_poll.dart';
import '../models/group_comment.dart';
import '../models/project.dart';
import '../models/focus_session.dart';
import '../models/contact.dart';
import '../models/friend_request.dart';
import '../theme_constants.dart';
import 'database_service.dart';
import 'firebase_service.dart';
import 'web_notification_service.dart';
import 'greeting_service.dart';
import 'calendar_service.dart';

enum ConnectivityStatus {
  wifi,
  mobile,
  none,
  syncing
}

enum ReminderViewMode {
  list,
  calendar,
  board
}

enum HomeLayout {
  original,
  simplified
}

enum ScheduleStyle {
  grid,
  timeline
}

class DataService extends ChangeNotifier {
  final List<Contact> _contacts = [];
  final List<FriendRequest> _friendRequests = [];
  List<Contact> get contacts => _contacts;
  List<FriendRequest> get friendRequests => _friendRequests;

  Future<void> sendFriendRequest(Contact target) async {
    if (_fb.userId == null) return;
    
    final request = {
      'fromId': _fb.userId,
      'fromName': userName,
      'fromAlias': userAlias,
      'fromPhoto': _fb.userPhotoUrl,
      'toId': target.id,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Guardamos la solicitud en una colección global de Firestore
    await _fb.syncEntity('friend_requests', '${_fb.userId}_${target.id}', request);
  }

  Future<void> removeContact(String contactId) async {
    _contacts.removeWhere((c) => c.id == contactId);
    await _db.deleteEntity('contacts', contactId);
    notifyListeners();
    await _fb.deleteEntity('contacts', contactId);
  }

  Future<void> addContact(Contact contact) async {
    if (!_contacts.any((c) => c.id == contact.id)) {
      _contacts.add(contact);
      await _db.saveEntity('contacts', contact.id, contact.toJson());
      notifyListeners();
      await _fb.syncEntity('contacts', contact.id, contact.toJson());
    }
  }

  Future<void> acceptFriendRequest(FriendRequest request) async {
    await _fb.updateFriendRequestStatus(request.id, 'accepted');
    final newContact = Contact(
      id: request.fromId,
      nestId: '',
      name: request.fromName,
      alias: request.fromAlias,
      photoUrl: request.fromPhoto,
      addedAt: DateTime.now(),
    );
    await addContact(newContact);
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _fb.updateFriendRequestStatus(requestId, 'rejected');
  }

  // Appearance Notifiers
  final appLocale = ValueNotifier<Locale>(determineInitialLocale());
  final useDynamicColor = ValueNotifier<bool>(false);
  final appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  final appAccentColor = ValueNotifier<Color>(appAccentColors[0]);
  final useMulticolor = ValueNotifier<bool>(true);
  final homeLayout = ValueNotifier<HomeLayout>(HomeLayout.original);
  final scheduleStyle = ValueNotifier<ScheduleStyle>(ScheduleStyle.grid);
  final pendingDeletionDate = ValueNotifier<DateTime?>(null);
  final accountDeletionNotice = ValueNotifier<String?>(null);

  int _mainTabIndex = 0;
  int _previousTabIndex = 0;
  int get mainTabIndex => _mainTabIndex;
  int get previousTabIndex => _previousTabIndex;
  
  set mainTabIndex(int index) {
    if (_mainTabIndex != index) {
      _previousTabIndex = _mainTabIndex;
      _mainTabIndex = index;
      _saveAppearanceSettings();
      notifyListeners();
    }
  }

  int _notesTabIndex = 0;
  int get notesTabIndex => _notesTabIndex;
  set notesTabIndex(int index) {
    if (_notesTabIndex != index) {
      _notesTabIndex = index;
      _saveAppearanceSettings();
      notifyListeners();
    }
  }

  int _groupsTabIndex = 0;
  int get groupsTabIndex => _groupsTabIndex;
  set groupsTabIndex(int index) {
    if (_groupsTabIndex != index) {
      _groupsTabIndex = index;
      _saveAppearanceSettings();
      notifyListeners();
    }
  }

  String _reminderSelectedCategory = 'all';
  String get reminderSelectedCategory => _reminderSelectedCategory;
  set reminderSelectedCategory(String category) {
    if (_reminderSelectedCategory != category) {
      _reminderSelectedCategory = category;
      _saveAppearanceSettings();
      notifyListeners();
    }
  }

  String _reminderSelectedFilter = 'default';
  String get reminderSelectedFilter => _reminderSelectedFilter;
  set reminderSelectedFilter(String filter) {
    if (_reminderSelectedFilter != filter) {
      _reminderSelectedFilter = filter;
      _saveAppearanceSettings();
      notifyListeners();
    }
  }

  ReminderViewMode _reminderViewMode = ReminderViewMode.list;
  ReminderViewMode get reminderViewMode => _reminderViewMode;
  set reminderViewMode(ReminderViewMode mode) {
    if (_reminderViewMode != mode) {
      _reminderViewMode = mode;
      _saveAppearanceSettings();
      notifyListeners();
    }
  }

  bool _lockScheduleAutoScroll = false;
  bool get lockScheduleAutoScroll => _lockScheduleAutoScroll;
  set lockScheduleAutoScroll(bool value) {
    if (_lockScheduleAutoScroll != value) {
      _lockScheduleAutoScroll = value;
      _saveAppearanceSettings();
      notifyListeners();
    }
  }

  bool _isAndroid12OrHigher = false;
  bool get isAndroid12OrHigher => _isAndroid12OrHigher;

  final List<Subject> _subjects = [];
  final List<ScheduleOverride> _overrides = [];
  final List<Note> _notes = [];
  final List<Notebook> _notebooks = [];
  final List<Reminder> _reminders = [];
  final List<RecurringProgram> _recurringPrograms = [];
  final List<AppNotification> _notifications = [];
  final List<Group> _groups = [];
  final List<Project> _projects = [];
  final List<FocusSession> _focusSessions = [];

  // Greeting Session Cache
  String? _sessionGreeting;
  int? _greetingPeriod;
  String? _greetingLocale;
  bool? _lastHasExamToday;
  bool? _lastHasFinishedExam;

  final DatabaseService _db = DatabaseService();
  final FirebaseService _fb = FirebaseService();
  bool _initialized = false;
  bool get initialized => _initialized;

  final initializationMessage = ValueNotifier<String>("");

  bool _profileCompleted = false;
  bool _forceProfileCheck = false;
  bool _calendarSyncEnabled = false;
  bool _googleCalendarSyncEnabled = false;
  String? _selectedCalendarId;
  String? _selectedCalendarName;
  final Map<String, Map<String, dynamic>> _userProfilesCache = {};
  bool get profileCompleted => _profileCompleted;
  bool get forceProfileCheck => _forceProfileCheck;
  bool get calendarSyncEnabled => _calendarSyncEnabled;
  bool get googleCalendarSyncEnabled => _googleCalendarSyncEnabled;
  String? get selectedCalendarId => _selectedCalendarId;
  String? get selectedCalendarName => _selectedCalendarName;

  String? _lastAccountName;
  String? _lastAccountEmail;
  String? _lastAccountPhoto;
  String? get lastAccountName => _lastAccountName;
  String? get lastAccountEmail => _lastAccountEmail;
  String? get lastAccountPhoto => _lastAccountPhoto;

  bool _classRemindersEnabled = true;
  int _classReminderMinutesBefore = 15;
  bool _allNotificationsEnabled = true;
  bool _remindersNotificationsEnabled = true;
  bool _groupActivityNotificationsEnabled = true;
  bool _calendarEventsNotificationsEnabled = true;
  bool _appUpdatesNotificationsEnabled = false;

  bool get classRemindersEnabled => _classRemindersEnabled;
  int get classReminderMinutesBefore => _classReminderMinutesBefore;
  bool get allNotificationsEnabled => _allNotificationsEnabled;
  bool get remindersNotificationsEnabled => _remindersNotificationsEnabled;
  bool get groupActivityNotificationsEnabled => _groupActivityNotificationsEnabled;
  bool get calendarEventsNotificationsEnabled => _calendarEventsNotificationsEnabled;
  bool get appUpdatesNotificationsEnabled => _appUpdatesNotificationsEnabled;

  void setAllNotificationsEnabled(bool enabled) async {
    _allNotificationsEnabled = enabled;
    if (!enabled) {
      _classRemindersEnabled = false;
      _remindersNotificationsEnabled = false;
      _groupActivityNotificationsEnabled = false;
      _calendarEventsNotificationsEnabled = false;
      _appUpdatesNotificationsEnabled = false;
    } else {
      _classRemindersEnabled = true;
      _remindersNotificationsEnabled = true;
      _groupActivityNotificationsEnabled = true;
      _calendarEventsNotificationsEnabled = true;
    }
    _saveAppearanceSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allNotificationsEnabled', enabled);
    _db.saveSetting('allNotificationsEnabled', enabled.toString());
    notifyListeners();
  }

  void setRemindersNotificationsEnabled(bool enabled) async {
    _remindersNotificationsEnabled = enabled;
    _saveAppearanceSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remindersNotificationsEnabled', enabled);
    _db.saveSetting('remindersNotificationsEnabled', enabled.toString());
    notifyListeners();
  }

  void setGroupActivityNotificationsEnabled(bool enabled) async {
    _groupActivityNotificationsEnabled = enabled;
    _saveAppearanceSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('groupActivityNotificationsEnabled', enabled);
    _db.saveSetting('groupActivityNotificationsEnabled', enabled.toString());
    notifyListeners();
  }

  void setCalendarEventsNotificationsEnabled(bool enabled) async {
    _calendarEventsNotificationsEnabled = enabled;
    _saveAppearanceSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendarEventsNotificationsEnabled', enabled);
    _db.saveSetting('calendarEventsNotificationsEnabled', enabled.toString());
    notifyListeners();
  }

  void setAppUpdatesNotificationsEnabled(bool enabled) async {
    _appUpdatesNotificationsEnabled = enabled;
    _saveAppearanceSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appUpdatesNotificationsEnabled', enabled);
    _db.saveSetting('appUpdatesNotificationsEnabled', enabled.toString());
    notifyListeners();
  }

  bool _syncOnlyWifi = false;
  bool get syncOnlyWifi => _syncOnlyWifi;

  void setSyncOnlyWifi(bool enabled) async {
    _syncOnlyWifi = enabled;
    _saveAppearanceSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('syncOnlyWifi', enabled);
    _db.saveSetting('syncOnlyWifi', enabled.toString());
    notifyListeners();
  }

  void setClassRemindersEnabled(bool enabled) async {
    _classRemindersEnabled = enabled;
    _saveAppearanceSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('classRemindersEnabled', enabled);
    _db.saveSetting('classRemindersEnabled', enabled.toString());
    notifyListeners();
  }

  void setClassReminderMinutesBefore(int minutes) async {
    _classReminderMinutesBefore = minutes;
    _saveAppearanceSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('classReminderMinutesBefore', minutes);
    _db.saveSetting('classReminderMinutesBefore', minutes.toString());
    notifyListeners();
  }

  void setSelectedCalendar(String id, String name) async {
    _selectedCalendarId = id;
    _selectedCalendarName = name;
    _db.saveSetting('selectedCalendarId', id);
    _db.saveSetting('selectedCalendarName', name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCalendarId', id);
    await prefs.setString('selectedCalendarName', name);

    if (_calendarSyncEnabled) {
      _syncAllRemindersToCalendar();
    }
    notifyListeners();
  }

  void setCalendarSyncEnabled(bool enabled) async {
    _calendarSyncEnabled = enabled;
    if (!enabled) _googleCalendarSyncEnabled = false;
    _db.saveSetting('calendarSyncEnabled', enabled.toString());
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendarSyncEnabled', enabled);
    
    if (enabled) {
      Future.microtask(() => _syncAllRemindersToCalendar());
    }
  }

  Future<void> _syncAllRemindersToCalendar() async {
    for (int i = 0; i < _reminders.length; i++) {
      if (!_reminders[i].isCompleted) {
        final eventId = await CalendarService().syncReminder(_reminders[i], targetCalendarId: _selectedCalendarId);
        if (eventId != null) {
          _reminders[i] = _reminders[i].copyWith(calendarEventId: eventId);
          _saveLocalAndRemote('reminders', _reminders[i].id, _reminders[i].toJson());
        }
      }
    }
    notifyListeners();
  }

  void setGoogleCalendarSyncEnabled(bool enabled) async {
    _googleCalendarSyncEnabled = enabled;
    _db.saveSetting('googleCalendarSyncEnabled', enabled.toString());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('googleCalendarSyncEnabled', enabled);
    notifyListeners();
  }

  void setForceProfileCheck(bool value) {
    _forceProfileCheck = value;
    notifyListeners();
  }

  // Real-time Subscriptions
  final List<StreamSubscription> _fbSubscriptions = [];
  final Map<String, StreamSubscription> _groupSubSubscriptions = {};

  // Connectivity
  ConnectivityStatus _connectivityStatus = ConnectivityStatus.none;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  DataService({Map<String, dynamic>? initialSettings}) {
    if (initialSettings != null) {
      _applyAppearanceSettings(initialSettings);

      // Basic profile data from settings if present
      if (initialSettings['userName'] != null) _userName = initialSettings['userName'];
      if (initialSettings['userAlias'] != null) _userAlias = initialSettings['userAlias'];
      if (initialSettings['userEmail'] != null) _userEmail = initialSettings['userEmail'];
      if (initialSettings['profileCompleted'] != null) {
        _profileCompleted = initialSettings['profileCompleted'] is bool
            ? initialSettings['profileCompleted']
            : initialSettings['profileCompleted'] == 'true';
      }
      if (initialSettings['userBirthday'] != null) {
        _userBirthday = DateTime.tryParse(initialSettings['userBirthday']);
      }
    }
    _initConnectivity();
    _initData(); // Cargar datos locales siempre al inicio
    _initAuthListener();
    _initAppearanceListeners();
  }

  void _initAppearanceListeners() {
    void save() {
      _saveAppearanceSettings();
      notifyListeners();
    }
    appLocale.addListener(save);
    useDynamicColor.addListener(save);
    appThemeMode.addListener(save);
    appAccentColor.addListener(save);
    useMulticolor.addListener(save);
    homeLayout.addListener(save);
    scheduleStyle.addListener(save);
  }

  Future<void> _saveAppearanceSettings() async {
    final settings = {
      'locale': appLocale.value.languageCode,
      'useDynamicColor': useDynamicColor.value,
      'themeMode': appThemeMode.value.index,
      'accentColor': appAccentColor.value.toARGB32(),
      'useMulticolor': useMulticolor.value,
      'homeLayout': homeLayout.value.index,
      'scheduleStyle': scheduleStyle.value.index,
      'reminderViewMode': _reminderViewMode.index,
      'notesTabIndex': _notesTabIndex,
      'groupsTabIndex': _groupsTabIndex,
      'reminderSelectedCategory': _reminderSelectedCategory,
      'reminderSelectedFilter': _reminderSelectedFilter,
      'lockScheduleAutoScroll': _lockScheduleAutoScroll,
      'classRemindersEnabled': _classRemindersEnabled,
      'classReminderMinutesBefore': _classReminderMinutesBefore,
    };

    // Local save (Database)
    await _db.saveSetting('appearance', jsonEncode(settings));

    // Local save (SharedPreferences) - Faster for startup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appearance_cache', jsonEncode(settings));
  }

  Future<void> _loadAppearanceSettings() async {
    Map<String, dynamic>? settings;

    // 1. Try SharedPreferences (Fastest)
    final prefs = await SharedPreferences.getInstance();
    String? cached = prefs.getString('appearance_cache');
    if (cached != null) {
      try {
        settings = jsonDecode(cached);
      } catch (e) {
        debugPrint("Error decoding SharedPreferences appearance: $e");
      }
    }

    // 2. Try local Database (Fallback)
    if (settings == null) {
      String? local = await _db.getSetting('appearance');
      if (local != null) {
        try {
          settings = jsonDecode(local);
          // Sync back to prefs
          await prefs.setString('appearance_cache', local);
        } catch (e) {
          debugPrint("Error decoding local appearance: $e");
        }
      }
    }

    if (settings != null) {
      _applyAppearanceSettings(settings);
    }
  }

  void _applyAppearanceSettings(Map<String, dynamic> settings) {
    if (settings['locale'] != null) {
      appLocale.value = Locale(settings['locale']);
    }
    if (settings['useDynamicColor'] != null) {
      useDynamicColor.value = settings['useDynamicColor'] as bool;
    }
    if (settings['themeMode'] != null) {
      appThemeMode.value = ThemeMode.values[settings['themeMode'] as int];
    }
    if (settings['accentColor'] != null) {
      appAccentColor.value = Color(settings['accentColor'] as int);
    }
    if (settings['useMulticolor'] != null) {
      useMulticolor.value = settings['useMulticolor'] as bool;
    }
    if (settings['homeLayout'] != null) {
      homeLayout.value = HomeLayout.values[settings['homeLayout'] as int];
    }
    if (settings['scheduleStyle'] != null) {
      scheduleStyle.value = ScheduleStyle.values[settings['scheduleStyle'] as int];
    }
    if (settings['reminderViewMode'] != null) {
      _reminderViewMode = ReminderViewMode.values[settings['reminderViewMode'] as int];
    }
    if (settings['notesTabIndex'] != null) {
      _notesTabIndex = settings['notesTabIndex'] as int;
    }
    if (settings['groupsTabIndex'] != null) {
      _groupsTabIndex = settings['groupsTabIndex'] as int;
    }
    if (settings['reminderSelectedCategory'] != null) {
      _reminderSelectedCategory = settings['reminderSelectedCategory'] as String;
    }
    if (settings['reminderSelectedFilter'] != null) {
      _reminderSelectedFilter = settings['reminderSelectedFilter'] as String;
    }
    if (settings['lockScheduleAutoScroll'] != null) {
      _lockScheduleAutoScroll = settings['lockScheduleAutoScroll'] as bool;
    }
    if (settings['classRemindersEnabled'] != null) {
      _classRemindersEnabled = settings['classRemindersEnabled'] as bool;
    }
    if (settings['classReminderMinutesBefore'] != null) {
      _classReminderMinutesBefore = settings['classReminderMinutesBefore'] as int;
    }
  }

  String? _currentSyncUserId;

  void _initAuthListener() {
    try {
      _fb.authStateChanges.listen((user) async {
        debugPrint("DataService: Auth state changed. User: ${user?.uid}, Anonymous: ${user?.isAnonymous}");
        
        if (user != null) {
          if (user.uid == _currentSyncUserId && _isSyncing) {
            debugPrint("DataService: Sync already active for this user, skipping restart.");
            return;
          }
          
          _currentSyncUserId = user.uid;

          // Si ya se está inicializando por el constructor, esperamos
          while (_isInitializing) {
            await Future.delayed(const Duration(milliseconds: 100));
          }

          if (!_initialized) {
            await _initData();
          }
          
          if (!user.isAnonymous) {
            _startFirebaseSync();
          }
        } else {
          _currentSyncUserId = null;
          _stopFirebaseSync();
        }
      }, onError: (e) {
        debugPrint("DataService: Auth listener error: $e");
      });
    } catch (e) {
      debugPrint("DataService: Could not initialize auth listener: $e");
    }
  }

  Future<void> logout() async {
    // Cerramos sesión y limpiamos datos locales explícitamente
    await _fb.signOut();
    await _clearLocalData();
  }

  bool _isClearing = false;
  Future<void> _clearLocalData() async {
    if (_isClearing) return;
    _isClearing = true;
    
    debugPrint("DataService: Clearing all local data...");
    
    try {
      // 1. Limpiar listas en memoria
      _subjects.clear();
      _overrides.clear();
      _notes.clear();
      _notebooks.clear();
      _reminders.clear();
      _recurringPrograms.clear();
      _notifications.clear();
      _groups.clear();
      _projects.clear();
      _focusSessions.clear();
      
      // 2. Resetear estados
      _initialized = false;
      _isInitializing = false;
      _userName = 'Javier';
      _userAlias = '';
      _profileCompleted = false;
      _forceProfileCheck = false;
      _mainTabIndex = 0;
      _notesTabIndex = 0;
      _groupsTabIndex = 0;
      
      // 3. Limpiar Base de Datos SQLite
      await _db.clearAllUserData();
      
      // 4. Limpiar SharedPreferences (Nombre, Perfil, etc)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userName');
      await prefs.remove('userAlias');
      await prefs.remove('userPhotoUrl');
      await prefs.remove('profileCompleted');
      await prefs.remove('userBirthday');
      await prefs.remove('last_groups_tab');
      
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('sync_cache_')) {
          await prefs.remove(key);
        }
      }
      
      debugPrint("DataService: Local data cleared successfully.");
    } catch (e) {
      debugPrint("Error during data clearing: $e");
    } finally {
      _isClearing = false;
      notifyListeners();
    }
  }

  void _startFirebaseSync() async {
    if (_fb.isAnonymous || _fb.userId == null) return;
    
    // Evitar reinicios si ya estamos sincronizando el mismo usuario
    if (_isSyncing && _currentSyncUserId == _fb.userId) {
      debugPrint("DataService: Sincronización ya activa para ${_fb.userId}, omitiendo...");
      return;
    }

    _stopFirebaseSync(); 
    _currentSyncUserId = _fb.userId;
    _isSyncing = true;

    debugPrint("DataService: _startFirebaseSync iniciando streams para ${_fb.userId}...");
    notifyListeners();

    // Listen to Root User Doc for migration and basic profile
    final userSub = _fb.getUserDocumentStream().listen((data) async {
      if (data == null) {
        _isSyncing = false;
        notifyListeners();
        return;
      }
      
      // migration logic: if legacy arrays exist, process them
      if (data.containsKey('reminders') || data.containsKey('notes') || data.containsKey('schedule') || data.containsKey('subjects')) {
        debugPrint("Legacy data detected. Starting migration...");
        await _handleLegacyData(data);
        // triggerSync will upload them to new subcollections
        await triggerSync(); 
        // After successful sync, clear the legacy fields from root doc
        await _fb.cleanLegacyFields();
      }
      
      _updateProfileFromData(data);
      
      if (_isSyncing) {
        _isSyncing = false;
        notifyListeners();
      }
    });
    _fbSubscriptions.add(userSub);

    // Listen to Friend Requests (Temporarily disabled to focus on core features)
    /*
    final friendsSub = _fb.getFriendRequestsStream().listen((data) {
      _friendRequests.clear();
      _friendRequests.addAll(data.map((d) => FriendRequest.fromJson(d)));
      notifyListeners();
    });
    _fbSubscriptions.add(friendsSub);
    */

    // Carga inicial forzada de grupos para asegurar compatibilidad legacy inmediata
    _fb.fetchCollection('groups').then((items) {
      if (items.isNotEmpty) {
        _handleRemoteUpdate('groups', items, (data) => Group.fromJson(data));
        _syncGroupSubcollections(items);
      }
    });

    final collections = {
      'schedule': (data) => Subject.fromJson(data),
      'subjects': (data) => Subject.fromJson(data),
      'notes': (data) => Note.fromJson(data),
      'notebooks': (data) => Notebook.fromJson(data),
      'reminders': (data) => Reminder.fromJson(data),
      'notifications': (data) => AppNotification.fromJson(data),
      'groups': (data) => Group.fromJson(data),
      // 'projects': (data) => Project.fromJson(data), // Disabled
      // 'focus_sessions': (data) => FocusSession.fromJson(data), // Disabled
      'contacts': (data) => Contact.fromJson(data),
    };

    collections.forEach((collection, parser) {
      final sub = _fb.getCollectionStream(collection).listen(
            (List<Map<String, dynamic>> items) async {
          // Mapeamos de vuelta al nombre lógico de la tabla local
          final localTable = (collection == 'schedule' || collection == 'subjects') ? 'subjects' : collection;
          
          if (collection == 'groups') {
            debugPrint('DataService: Sincronizando ${items.length} grupos desde Firestore');
          }
          
          await _handleRemoteUpdate(localTable, items, parser);
          
          if (collection == 'groups') {
            _syncGroupSubcollections(items);
          }
        },
        onError: (e) {
          debugPrint("Error sync $collection: $e");
        },
      );
      _fbSubscriptions.add(sub);
    });
  }

  void _syncGroupSubcollections(List<Map<String, dynamic>> groupsData) {
    for (var gData in groupsData) {
      final groupId = gData['id'];
      if (groupId == null) continue;

      if (!_groupSubSubscriptions.containsKey('${groupId}_sub')) {
        final sub = _fb.getGroupPostsStream(groupId).listen((data) {
          debugPrint('DataService: Recibidos ${data.length} items de la subcolección posts para el grupo $groupId');
          if (data.isEmpty) {
            debugPrint('DataService: ¡ADVERTENCIA! La subcolección posts está vacía en Firestore para $groupId');
          }
          
          final List<GroupPost> posts = [];
          final List<GroupPoll> polls = [];
          final List<Reminder> sharedReminders = [];
          final List<Note> sharedNotes = [];

          for (var item in data) {
            try {
              final type = item['type']?.toString().toUpperCase();
              if (type == 'POLL') {
                polls.add(GroupPoll.fromJson(item));
              } else if (type == 'TASK' || type == 'REMINDER') {
                sharedReminders.add(Reminder.fromJson(item));
              } else if (type == 'NOTE') {
                sharedNotes.add(Note.fromJson(item));
              } else {
                posts.add(GroupPost.fromJson(item));
              }
            } catch (e, stack) {
              debugPrint("DataService: Error parseando item legacy [ID: ${item['id']}]: $e");
              debugPrint(stack.toString());
            }
          }

          final index = _groups.indexWhere((g) => g.id == groupId);
          if (index != -1) {
            final oldGroup = _groups[index];
            _groups[index] = oldGroup.copyWith(
              posts: posts,
              polls: polls,
              sharedReminders: sharedReminders,
              sharedNotes: sharedNotes,
            );
            debugPrint('DataService: Grupo ${oldGroup.name} actualizado con ${posts.length} posts, ${polls.length} polls, ${sharedNotes.length} notes');
            notifyListeners();
          }
        }, onError: (e) => debugPrint("DataService: Error crítico en stream de posts: $e"));
        _groupSubSubscriptions['${groupId}_sub'] = sub;
      }
    }
  }

  Future<void> _handleLegacyData(Map<String, dynamic> data) async {
    bool changed = false;

    // 1. Process Legacy Notes
    if (data['notes'] is List) {
      final legacyNotes = (data['notes'] as List);
      for (var n in legacyNotes) {
        try {
          final note = Note.fromJson(Map<String, dynamic>.from(n));
          final existingIndex = _notes.indexWhere((existing) => existing.id == note.id);
          if (existingIndex == -1) {
            _notes.add(note);
            await _db.saveEntity('notes', note.id, note.toJson());
            changed = true;
          }
        } catch (_) {}
      }
    }

    // 2. Process Legacy Reminders
    if (data['reminders'] is List) {
      final legacyReminders = (data['reminders'] as List);
      for (var r in legacyReminders) {
        try {
          final reminder = Reminder.fromJson(Map<String, dynamic>.from(r));
          if (!_reminders.any((existing) => existing.id == reminder.id)) {
            _reminders.add(reminder);
            await _db.saveEntity('reminders', reminder.id, reminder.toJson());
            changed = true;
          }
        } catch (_) {}
      }
    }

    // 3. Process Legacy Schedule (from 'schedule' or 'subjects' array)
    final List<dynamic> legacyScheduleItems = [];
    if (data['schedule'] is List) legacyScheduleItems.addAll(data['schedule'] as List);
    if (data['subjects'] is List) legacyScheduleItems.addAll(data['subjects'] as List);

    if (legacyScheduleItems.isNotEmpty) {
      for (var item in legacyScheduleItems) {
        try {
          final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
          final subject = Subject.fromJson(itemMap);
          final existingIndex = _subjects.indexWhere((s) => s.name == subject.name && s.group == subject.group);

          if (existingIndex == -1) {
            _subjects.add(subject);
            await _db.saveEntity('subjects', subject.id, subject.toJson());
            changed = true;
          }

          // Process Overrides if present in the legacy item
          final subjectId = existingIndex != -1 ? _subjects[existingIndex].id : subject.id;
          final currentSubject = existingIndex != -1 ? _subjects[existingIndex] : subject;
          
          if (currentSubject.schedules.isNotEmpty) {
            final schedule = currentSubject.schedules.first;
            
            // Discarded dates
            if (itemMap['discardedDates'] is List) {
              for (var dateStr in (itemMap['discardedDates'] as List)) {
                final date = _parseLegacyDate(dateStr.toString());
                if (date != null) discardClassForDate(subjectId, date);
              }
            }

            // Shifted dates
            if (itemMap['shiftedDates'] is Map) {
              final shifted = Map<String, dynamic>.from(itemMap['shiftedDates']);
              shifted.forEach((dateStr, info) {
                final date = _parseLegacyDate(dateStr);
                if (date != null && info is Map) {
                  final String? newStart = info['startTime'];
                  if (newStart != null) {
                    final parts = newStart.split(':');
                    final double targetStart = int.parse(parts[0]) + (parts.length > 1 ? int.parse(parts[1]) / 60.0 : 0.0);
                    final double originalStart = schedule.startTime.hour + schedule.startTime.minute / 60.0;
                    addOverride(ScheduleOverride(
                      subjectId: subjectId,
                      date: date,
                      originalStartTime: schedule.startTime,
                      offsetHours: targetStart - originalStart,
                    ));
                  }
                }
              });
            }
          }
        } catch (_) {}
      }
    }

    if (changed) notifyListeners();
  }

  DateTime? _parseLegacyDate(String dateStr) {
    try {
      if (dateStr.contains('-')) return DateTime.parse(dateStr);
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          // Asumimos dd/MM/yyyy o yyyy/MM/dd
          if (parts[0].length == 4) return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    } catch (_) {}
    return null;
  }

  void _stopFirebaseSync() {
    for (var sub in _fbSubscriptions) {
      sub.cancel();
    }
    _fbSubscriptions.clear();
    for (var sub in _groupSubSubscriptions.values) {
      sub.cancel();
    }
    _groupSubSubscriptions.clear();
  }

  Future<void> _handleRemoteUpdate(String collection, List<Map<String, dynamic>> items, Function parser) async {
    // Sincronización Silenciosa y Eficiente
    final prefs = await SharedPreferences.getInstance();
    final String cacheKey = 'sync_cache_$collection';
    final String remoteJson = jsonEncode(items);
    final String? localCache = prefs.getString(cacheKey);

    if (remoteJson == localCache) {
      return; 
    }

    await prefs.setString(cacheKey, remoteJson);

    bool changed = false;
    final List<dynamic> targetList;

    switch (collection) {
      case 'subjects': targetList = _subjects; break;
      case 'notes': targetList = _notes; break;
      case 'notebooks': targetList = _notebooks; break;
      case 'reminders': targetList = _reminders; break;
      case 'notifications': targetList = _notifications; break;
      case 'groups': targetList = _groups; break;
      case 'projects': targetList = _projects; break;
      case 'focus_sessions': targetList = _focusSessions; break;
      case 'contacts': targetList = _contacts; break;
      default: return;
    }

    // Actualizamos o añadimos los que vienen de remoto
    for (final itemData in items) {
      try {
        final remoteItem = parser(itemData);
        final index = targetList.indexWhere((i) => i.id == remoteItem.id);

        if (index == -1) {
          targetList.add(remoteItem);
          changed = true;
          _db.saveEntity(collection, remoteItem.id, itemData).catchError((_) => null);
        } else {
          // COMPARACIÓN ROBUSTA
          bool hasRealChanges = false;
          final localData = targetList[index].toJson();
          
          if (collection == 'subjects') {
            hasRealChanges = !const DeepCollectionEquality().equals(localData['overrides'], itemData['overrides']) ||
                             !const DeepCollectionEquality().equals(localData['schedules'], itemData['schedules']);
          } else if (collection == 'groups') {
            final Map<String, dynamic> filteredLocal = Map.from(localData);
            ['posts', 'mensajes', 'sharedNotes', 'sharedReminders', 'polls'].forEach(filteredLocal.remove);
            
            final Map<String, dynamic> filteredRemote = Map.from(itemData);
            ['posts', 'mensajes', 'sharedNotes', 'sharedReminders', 'polls'].forEach(filteredRemote.remove);
            
            hasRealChanges = !const DeepCollectionEquality().equals(filteredLocal, filteredRemote);
          } else {
            hasRealChanges = !const DeepCollectionEquality().equals(localData, itemData);
          }

          if (hasRealChanges) {
            if (collection == 'groups') {
              // PRESERVAR SUB-LISTAS: Al actualizar el doc principal del grupo,
              // no debemos perder los posts/notas que se cargan por subcolecciones.
              final existingGroup = targetList[index] as Group;
              final updatedRemoteGroup = remoteItem as Group;
              
              targetList[index] = updatedRemoteGroup.copyWith(
                posts: existingGroup.posts,
                polls: existingGroup.polls,
                sharedNotes: existingGroup.sharedNotes,
                sharedReminders: existingGroup.sharedReminders,
                legacyPosts: existingGroup.legacyPosts,
              );
            } else {
              targetList[index] = remoteItem;
            }
            
            changed = true;
            _db.saveEntity(collection, remoteItem.id, itemData).catchError((_) => null);
          }
        }
      } catch (e) {
        debugPrint("DataService: Error procesando item en $collection: $e");
      }
    }

    if (changed && collection == 'subjects') {
      _rebuildOverridesFromSubjects();
    }

    if (changed) notifyListeners();
  }

  void _rebuildOverridesFromSubjects() {
    _overrides.clear();
    for (var subject in _subjects) {
      // 1. Primero recolectamos todos los días que están descartados (Clave corta)
      final Set<String> subjectDiscardedDays = {};
      subject.overrides.forEach((key, value) {
        try {
          if (!key.contains('|') && value is Map && value['discarded'] == true) {
            subjectDiscardedDays.add(key);
          }
        } catch (_) {}
      });

      // 2. Procesamos todas las entradas del mapa
      subject.overrides.forEach((key, value) {
        try {
          if (value is! Map) return;
          final parts = key.split('|');
          final dateStr = parts[0];
          final List<String> dateParts;
          if (dateStr.contains('/')) {
            dateParts = dateStr.split('/');
          } else if (dateStr.contains('-')) {
            dateParts = dateStr.split('-');
          } else {
            return;
          }
          
          if (dateParts.length < 3) return;
          
          final DateTime date;
          if (dateParts[0].length == 4) {
            // yyyy-MM-dd or yyyy/MM/dd
            date = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
          } else {
            // dd/MM/yyyy or dd-MM-yyyy
            date = DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));
          }

          if (parts.length >= 2) {
            // Caso: Override de sesión específica
            final timeParts = parts[1].split(':');
            if (timeParts.length < 2) return;
            final originalStartTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));

            // LÓGICA DE PRIORIDAD ABSOLUTA: 
            // Si el día está descartado (Imagen 2), la sesión se considera descartada SIEMPRE.
            final bool effectiveDiscard = subjectDiscardedDays.contains(dateStr) || 
                                        value['discarded'] == true || 
                                        value['isDiscarded'] == true;

            double offset = 0.0;
            double? customDuration;
            if (value['startTime'] != null) {
              final newStartParts = value['startTime'].toString().split(':');
              final newStartHour = int.parse(newStartParts[0]) + int.parse(newStartParts[1]) / 60.0;
              final oldStartHour = originalStartTime.hour + originalStartTime.minute / 60.0;
              offset = newStartHour - oldStartHour;

              if (value['endTime'] != null) {
                final newEndParts = value['endTime'].toString().split(':');
                final newEndHour = int.parse(newEndParts[0]) + int.parse(newEndParts[1]) / 60.0;
                customDuration = newEndHour - newStartHour;
                if (customDuration < 0) customDuration += 24; // Cruce de medianoche
              }
            } else if (value['offset'] != null) {
              offset = (value['offset'] as num).toDouble();
            }

            // Evitar duplicados con comparación de fecha segura (solo año/mes/día)
            _overrides.removeWhere((o) => 
              o.subjectId == subject.id && 
              o.date.year == date.year &&
              o.date.month == date.month &&
              o.date.day == date.day &&
              o.originalStartTime.hour == originalStartTime.hour &&
              o.originalStartTime.minute == originalStartTime.minute
            );

            _overrides.add(ScheduleOverride(
              subjectId: subject.id,
              date: date,
              originalStartTime: originalStartTime,
              offsetHours: offset,
              customDurationHours: customDuration,
              isDiscarded: effectiveDiscard,
            ));
          } else if (value['discarded'] == true) {
            // Caso: Día completo. Añadimos overrides para todas las sesiones que NO tengan uno específico aún
            for (var schedule in subject.schedules) {
              if (schedule.matchesDate(date)) {
                final exists = _overrides.any((o) => 
                  o.subjectId == subject.id && 
                  o.date.year == date.year &&
                  o.date.month == date.month &&
                  o.date.day == date.day &&
                  o.originalStartTime.hour == schedule.startTime.hour &&
                  o.originalStartTime.minute == schedule.startTime.minute
                );
                if (!exists) {
                  _overrides.add(ScheduleOverride(
                    subjectId: subject.id,
                    date: date,
                    originalStartTime: schedule.startTime,
                    isDiscarded: true,
                  ));
                }
              }
            }
          }
        } catch (_) {}
      });
    }
  }

  void _updateProfileFromData(Map<String, dynamic> profile) async {
    debugPrint("DataService: Updating profile with: $profile");
    // 'username' defines the Display Name
    _userName = profile['username'] ?? profile['name'] ?? _userName;
    
    // 'alias' defines the @handle
    _userAlias = profile['alias'] ?? profile['handle'] ?? '';

    _userIdentifier = profile['userIdentifier'] ?? profile['useridentifier'] ?? _userIdentifier;

    // Asegurar que el ID esté en Firestore para que otros puedan encontrar al usuario
    if (!profile.containsKey('userIdentifier') && !profile.containsKey('useridentifier') && _fb.userId != null) {
      _fb.saveUserProfile(_fb.userId!, {'userIdentifier': _fb.nestId});
    }

    _userEmail = profile['email'] ?? _fb.userEmail ?? _userEmail;
    
    _profileCompleted = (profile['profileCompleted'] == true) || 
                       (_userName.isNotEmpty && _userAlias.isNotEmpty);
    
    if (profile['dob'] != null) {
      _userBirthday = DateTime.tryParse(profile['dob']);
    }

    final prefs = await SharedPreferences.getInstance();

    final customPhoto = profile['photoUrl'] ?? profile['userPhotoUrl'] ?? profile['photo'] ?? _fb.userPhotoUrl;
    if (customPhoto is String && customPhoto.isNotEmpty) {
      String formattedPhoto = customPhoto;
      if (formattedPhoto.contains('googleusercontent.com') && !formattedPhoto.contains('=s')) {
        formattedPhoto = '$formattedPhoto=s200-c';
      }
      _fb.setCustomPhotoUrl(formattedPhoto);
      await prefs.setString('userPhotoUrl', formattedPhoto);

      if (profile['photoUrl'] == null && _fb.userId != null) {
        _fb.saveUserProfile(_fb.userId!, {'photoUrl': formattedPhoto});
      }
    } else {
      final savedPhoto = prefs.getString('userPhotoUrl');
      if (savedPhoto != null && savedPhoto.isNotEmpty) {
        String formattedPhoto = savedPhoto;
        if (formattedPhoto.contains('googleusercontent.com') && !formattedPhoto.contains('=s')) {
          formattedPhoto = '$formattedPhoto=s200-c';
        }
        _fb.setCustomPhotoUrl(formattedPhoto);
      }
    }

    _db.saveSetting('userName', _userName);
    _db.saveSetting('userAlias', _userAlias);
    _db.saveSetting('userEmail', _userEmail);
    _db.saveSetting('profileCompleted', _profileCompleted.toString());
    
    await prefs.setString('userName', _userName);
    await prefs.setString('userAlias', _userAlias);
    await prefs.setString('userEmail', _userEmail);
    await prefs.setBool('profileCompleted', _profileCompleted);

    // Persistir info de la última cuenta para el login rápido
    _lastAccountName = _userName;
    _lastAccountEmail = _userEmail;
    _lastAccountPhoto = _fb.userPhotoUrl;

    if (_lastAccountName != null) await prefs.setString('lastAccountName', _lastAccountName!);
    if (_lastAccountEmail != null) await prefs.setString('lastAccountEmail', _lastAccountEmail!);
    if (_lastAccountPhoto != null) await prefs.setString('lastAccountPhoto', _lastAccountPhoto!);

    notifyListeners();
  }

  bool _isInitializing = false;
  Future<void> _initData() async {
    debugPrint("DataService: _initData starting...");
    if (_initialized || _isInitializing) {
      debugPrint("DataService: Already initialized or initializing, skipping.");
      return;
    }
    _isInitializing = true;
    _initialized = false;
    initializationMessage.value = "Cargando datos...";

    try {
      // Cargar datos locales
      debugPrint("DataService: Loading from DB...");
      try {
        // En la Web damos más margen de tiempo inicial
        final timeout = kIsWeb ? const Duration(seconds: 8) : const Duration(seconds: 5);
        await _loadFromDb().timeout(timeout);
      } catch (e) {
        debugPrint("DataService: Local DB skip (expected on first web load): $e");
      }

      debugPrint("DataService: Loading appearance...");
      try {
        await _loadAppearanceSettings().timeout(const Duration(seconds: 2));
      } catch (_) {}

      // Sincronización de perfil
      if (_fb.isAuthenticated && !_fb.isAnonymous) {
        if (_userEmail.isEmpty && _fb.userEmail != null) {
          _userEmail = _fb.userEmail!;
        }

        try {
          final profile = await _fb.getUserProfile(_fb.userId!).timeout(const Duration(seconds: 3));
          if (profile != null) {
            _updateProfileFromData(profile);
            await _checkAccountDeletionStatus(profile);
          }
        } catch (_) {}
      }
    } finally {
      _initialized = true;
      _isInitializing = false;
      debugPrint("DataService: Initialized set to true (finalized).");
      notifyListeners();
    }

    // Tareas no críticas en segundo plano
    _initDeviceCapabilities();
  }

  Future<void> _initDeviceCapabilities() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        _isAndroid12OrHigher = androidInfo.version.sdkInt >= 31;
        if (!_isAndroid12OrHigher && useDynamicColor.value) {
          useDynamicColor.value = false;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("DataService: Device info failed: $e");
    }
  }

  Future<void> _loadFromDb() async {
    final subjectsData = await _db.getAllEntities('subjects');
    _subjects.clear();
    for (var d in subjectsData) {
      try {
        _subjects.add(Subject.fromJson(d));
      } catch (e) {
        debugPrint("Error loading subject from DB: $e");
      }
    }

    // Reconstruir overrides en memoria una sola vez al cargar todo
    _rebuildOverridesFromSubjects();

    final notesData = await _db.getAllEntities('notes');
    _notes.clear();
    _notes.addAll(notesData.map((d) => Note.fromJson(d)));

    final notebooksData = await _db.getAllEntities('notebooks');
    _notebooks.clear();
    _notebooks.addAll(notebooksData.map((d) => Notebook.fromJson(d)));

    final remindersData = await _db.getAllEntities('reminders');
    _reminders.clear();
    _reminders.addAll(remindersData.map((d) => Reminder.fromJson(d)));

    final notificationsData = await _db.getAllEntities('notifications');
    _notifications.clear();
    _notifications.addAll(notificationsData.map((d) => AppNotification.fromJson(d)));

    final groupsData = await _db.getAllEntities('groups');
    _groups.clear();
    for (var d in groupsData) {
      try {
        _groups.add(Group.fromJson(d));
      } catch (e) {
        debugPrint("Error loading group from local DB: $e");
      }
    }

    final projectsData = await _db.getAllEntities('projects');
    _projects.clear();
    _projects.addAll(projectsData.map((d) => Project.fromJson(d)));

    final focusSessionsData = await _db.getAllEntities('focus_sessions');
    _focusSessions.clear();
    _focusSessions.addAll(focusSessionsData.map((d) => FocusSession.fromJson(d)));

    final contactsData = await _db.getAllEntities('contacts');
    _contacts.clear();
    _contacts.addAll(contactsData.map((d) => Contact.fromJson(d)));

    // Load from SharedPreferences first (fastest)
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? await _db.getSetting('userName') ?? 'Javier';
    _userAlias = prefs.getString('userAlias') ?? await _db.getSetting('userAlias') ?? '';
    _userEmail = prefs.getString('userEmail') ?? await _db.getSetting('userEmail') ?? '';
    _profileCompleted = prefs.getBool('profileCompleted') ?? (await _db.getSetting('profileCompleted') == 'true');
    _calendarSyncEnabled = prefs.getBool('calendarSyncEnabled') ?? (await _db.getSetting('calendarSyncEnabled') == 'true');
    _googleCalendarSyncEnabled = prefs.getBool('googleCalendarSyncEnabled') ?? (await _db.getSetting('googleCalendarSyncEnabled') == 'true');
    _selectedCalendarId = prefs.getString('selectedCalendarId') ?? await _db.getSetting('selectedCalendarId');
    _selectedCalendarName = prefs.getString('selectedCalendarName') ?? await _db.getSetting('selectedCalendarName');

    _lastAccountName = prefs.getString('lastAccountName');
    _lastAccountEmail = prefs.getString('lastAccountEmail');
    _lastAccountPhoto = prefs.getString('lastAccountPhoto');

    final birthdayStr = prefs.getString('userBirthday') ?? await _db.getSetting('userBirthday');
    if (birthdayStr != null) {
      _userBirthday = DateTime.parse(birthdayStr);
    }

    _startReminderNotificationChecker();
  }

  ConnectivityStatus get connectivityStatus => _isSyncing ? ConnectivityStatus.syncing : _connectivityStatus;

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();

    // Initial check
    final result = await connectivity.checkConnectivity();
    _updateStatus(result);

    // Listen to changes
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final prevStatus = _connectivityStatus;

    if (results.contains(ConnectivityResult.wifi)) {
      _connectivityStatus = ConnectivityStatus.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _connectivityStatus = ConnectivityStatus.mobile;
    } else {
      _connectivityStatus = ConnectivityStatus.none;
    }

    // Solo disparamos sincronización si acabamos de recuperar la conexión
    if (prevStatus == ConnectivityStatus.none && _connectivityStatus != ConnectivityStatus.none) {
      triggerSync();
    }

    notifyListeners();
  }

  void _saveLocalAndRemote(String table, String id, Map<String, dynamic> data) async {
    _db.saveEntity(table, id, data);
    
    // Actualizar el caché de sincronización inmediatamente y ESPERAR a que termine
    // para evitar que el "eco" de Firebase sobrescriba los datos locales.
    await _updateSyncCache(table);

    // Solo subimos a la nube si el usuario NO es invitado
    if (_fb.isAuthenticated && !_fb.isAnonymous) {
      final remoteCollection = table == 'subjects' ? 'schedule' : table;
      _fb.syncEntity(remoteCollection, id, data);
    }
  }

  Future<void> _updateSyncCache(String collection) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'sync_cache_$collection';
      final List<dynamic> targetList;

      switch (collection) {
        case 'subjects': targetList = _subjects; break;
        case 'notes': targetList = _notes; break;
        case 'notebooks': targetList = _notebooks; break;
        case 'reminders': targetList = _reminders; break;
        case 'notifications': targetList = _notifications; break;
        case 'groups': targetList = _groups; break;
        case 'projects': targetList = _projects; break;
        case 'focus_sessions': targetList = _focusSessions; break;
        default: return;
      }

      await prefs.setString(cacheKey, jsonEncode(targetList.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint("Error updating sync cache: $e");
    }
  }

  Future<void> _deleteLocalAndRemote(String table, String id) async {
    await _db.deleteEntity(table, id);
    if (_fb.isAuthenticated && !_fb.isAnonymous) {
      final remoteCollection = table == 'subjects' ? 'schedule' : table;
      await _fb.deleteEntity(remoteCollection, id);
    }
  }

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      if (_fb.isAuthenticated && !_fb.isAnonymous) {
        await _pushAllLocalToRemote();
        // Los listeners de Firebase se encargarán de traer lo nuevo del servidor
      }
    } catch (e) {
      debugPrint("Error durante la sincronización: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _pushAllLocalToRemote() async {
    // Sincronizar todas las colecciones principales usando WriteBatch
    // según directrices de Arquitectura Cloud
    
    final tasks = [
      _fb.saveBatch('reminders', _reminders.map((e) => e.toJson()).toList()),
      _fb.saveBatch('notes', _notes.map((e) => e.toJson()).toList()),
      _fb.saveBatch('schedule', _subjects.map((e) => e.toJson()).toList()),
      _fb.saveBatch('notebooks', _notebooks.map((e) => e.toJson()).toList()),
      _fb.saveBatch('projects', _projects.map((e) => e.toJson()).toList()),
      _fb.saveBatch('contacts', _contacts.map((e) => e.toJson()).toList()),
    ];

    await Future.wait(tasks);
    
    // El resto de colecciones (notificaciones, grupos, etc) se pueden sincronizar individualmente
    // o añadir a más batches si es necesario.
  }

  void _startArchiveTimer() {
    // Check every hour for projects to archive and events to auto-complete
    Timer.periodic(const Duration(hours: 1), (timer) {
      // checkAndArchiveProjects(); // Disabled
      autoCompletePastEvents();
    });
  }

  void checkAndArchiveProjects() {
    /*
    bool changed = false;
    final now = DateTime.now();
    for (int i = 0; i < _projects.length; i++) {
      final p = _projects[i];
      if (p.status != ProjectStatus.archived && p.endDate != null && now.isAfter(p.endDate!)) {
        _projects[i] = p.copyWith(status: ProjectStatus.archived);
        changed = true;
      }
    }
    if (changed) notifyListeners();
    */
  }

  void autoCompletePastEvents() {
    bool changed = false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (int i = 0; i < _reminders.length; i++) {
      final r = _reminders[i];
      // Solo auto-completar Eventos que ya pasaron (el día terminó)
      if (r.category == 'Evento' && !r.isCompleted) {
        final reminderDate = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
        if (reminderDate.isBefore(today)) {
          _reminders[i] = r.copyWith(
            isCompleted: true,
            completedAt: DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day, 23, 59, 59),
          );
          _saveLocalAndRemote('reminders', _reminders[i].id, _reminders[i].toJson());
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // User Profile
  // Contact support added
  String _userName = 'Javier';
  String _userAlias = '';
  String _userEmail = '';
  String _userIdentifier = '';
  DateTime? _userBirthday = DateTime(1998, 5, 16);

  void setUserName(String name) async {
    _userName = name;
    _db.saveSetting('userName', name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    notifyListeners();
  }

  void setUserAlias(String alias) async {
    _userAlias = alias;
    _db.saveSetting('userAlias', alias);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userAlias', alias);
    notifyListeners();
  }

  void setUserEmail(String email) async {
    _userEmail = email;
    _db.saveSetting('userEmail', email);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);
    notifyListeners();
  }

  void setProfileCompleted(bool completed) async {
    _profileCompleted = completed;
    if (completed) _forceProfileCheck = false;
    _db.saveSetting('profileCompleted', completed.toString());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profileCompleted', completed);
    notifyListeners();
  }

  void setUserBirthday(DateTime birthday) async {
    _userBirthday = birthday;
    _db.saveSetting('userBirthday', birthday.toIso8601String());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userBirthday', birthday.toIso8601String());
    notifyListeners();
  }

  List<Subject> get subjects => _subjects;
  List<ScheduleOverride> get overrides => _overrides;
  List<Note> get notes => List<Note>.from(_notes)..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  List<Notebook> get notebooks => _notebooks;
  List<Reminder> get reminders => _reminders;
  List<RecurringProgram> get recurringPrograms => _recurringPrograms;
  List<AppNotification> get notifications => _notifications;
  List<Group> get groups => _groups;
  List<Project> get projects => _projects;
  List<FocusSession> get focusSessions => _focusSessions;

  FocusSession? get activeFocusSession {
    final curId = userId ?? userName;
    return _focusSessions.firstWhereOrNull((s) {
      final isParticipant = s.participants.any((p) => 
        p == curId || p == userId || p == userName || p == _userName
      );
      return isParticipant && s.status != FocusSessionStatus.idle;
    });
  }

  String get userName => _userName;
  String get userAlias => _userAlias;
  String get userEmail => _userEmail;
  String get userIdentifier => _userIdentifier.isNotEmpty ? _userIdentifier : _fb.nestId;
  String? get userId => _fb.userId;
  DateTime? get userBirthday => _userBirthday;
  bool get isGuest => !_fb.isAuthenticated || _fb.isAnonymous;

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    if (_userProfilesCache.containsKey(uid)) {
      return _userProfilesCache[uid];
    }
    try {
      final profile = await _fb.getUserProfile(uid);
      if (profile != null) {
        _userProfilesCache[uid] = profile;
      }
      return profile;
    } catch (e) {
      debugPrint("Error fetching profile for $uid: $e");
      return null;
    }
  }

  Future<void> requestAccountDeletion({
    required String reason,
    required bool wipeAllData,
    String? feedback,
  }) async {
    final uid = _fb.userId;
    if (uid == null) return;

    final now = DateTime.now();
    final scheduledDate = now.add(const Duration(days: 30));

    final deletionData = <String, dynamic>{
      'status': 'pending_deletion',
      'deletionRequestedAt': now.toIso8601String(),
      'scheduledDeletionDate': scheduledDate.toIso8601String(),
      'deletionReason': reason,
      'deletionFeedback': feedback ?? '',
      'wipeAllData': wipeAllData,
    };

    await _fb.saveUserProfile(uid, deletionData);
    await logout();
  }

  Future<void> cancelAccountDeletion() async {
    final uid = _fb.userId;
    if (uid == null) return;

    final restoreData = <String, dynamic>{
      'status': 'active',
      'deletionRequestedAt': FieldValue.delete(),
      'scheduledDeletionDate': FieldValue.delete(),
      'deletionReason': FieldValue.delete(),
      'deletionFeedback': FieldValue.delete(),
      'wipeAllData': FieldValue.delete(),
    };

    await _fb.saveUserProfile(uid, restoreData);
    pendingDeletionDate.value = null;
    notifyListeners();
  }

  Future<void> _checkAccountDeletionStatus(Map<String, dynamic> profile) async {
    final status = profile['status'];
    if (status != 'pending_deletion') {
      pendingDeletionDate.value = null;
      return;
    }

    final scheduledStr = profile['scheduledDeletionDate'];
    if (scheduledStr == null) return;

    DateTime? scheduledDate;
    try {
      scheduledDate = DateTime.parse(scheduledStr.toString());
    } catch (_) {
      return;
    }

    final now = DateTime.now();

    if (now.isAfter(scheduledDate)) {
      debugPrint("DataService: Account scheduled deletion date expired. Permanently wiping account data...");
      await deleteAccountPermanently();
      accountDeletionNotice.value = "Tu cuenta y datos se han eliminado permanentemente tras transcurrir los 30 días de gracia.";
      await logout();
    } else {
      debugPrint("DataService: Account is pending deletion on $scheduledDate");
      pendingDeletionDate.value = scheduledDate;
    }
  }

  Future<void> deleteAccountPermanently() async {
    final uid = _fb.userId;
    if (uid == null) return;

    try {
      await _fb.deleteUserSubcollectionsAndProfile(uid);

      for (var group in List<Group>.from(_groups)) {
        if (group.members.contains(uid)) {
          final updatedMembers = List<String>.from(group.members)..remove(uid);
          final updatedAdmins = List<String>.from(group.admins)..remove(uid);
          updateGroup(group.copyWith(members: updatedMembers, admins: updatedAdmins));
        }
      }

      await _db.clearAllUserData();
      _notes.clear();
      _subjects.clear();
      _reminders.clear();
      _projects.clear();
      _notebooks.clear();
      _groups.clear();

      await _fb.deleteAuthUser();
    } catch (e) {
      debugPrint("Error permanently deleting user account: $e");
    }
  }

  bool get hasUnreadNotifications => _notifications.any((n) => !n.isRead);

  // Trigger recompile
  void markAllNotificationsAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
      _db.saveEntity('notifications', _notifications[i].id, _notifications[i].toJson());
    }
    if (_fb.isAuthenticated && !_fb.isAnonymous) {
      _fb.saveBatch('notifications', _notifications.map((n) => n.toJson()).toList());
    }
    notifyListeners();
  }

  bool get isBirthdayToday {
    if (_userBirthday == null) return false;
    final now = DateTime.now();
    return _userBirthday!.day == now.day && _userBirthday!.month == now.month;
  }

  String getSessionGreeting({
    required String locale,
    required String morningPool,
    required String afternoonPool,
    required String eveningPool,
    required String noTasksPool,
    required String busyDayPool,
    required String examPool,
    required String postExamPool,
    required String birthdayPool,
    int taskCount = 0,
    bool hasExamToday = false,
    bool hasFinishedExam = false,
  }) {
    final now = DateTime.now();
    final currentPeriod = GreetingService.getPeriod(now.hour);

    // Si el saludo ya existe Y es del mismo periodo E idioma Y el estado de exámenes es el mismo, no lo regeneramos
    if (_sessionGreeting != null &&
        _greetingPeriod == currentPeriod &&
        _greetingLocale == locale &&
        _lastHasExamToday == hasExamToday &&
        _lastHasFinishedExam == hasFinishedExam) {
      return _sessionGreeting!;
    }

    // Si no, generamos uno nuevo y lo cacheamos para la sesión
    _sessionGreeting = GreetingService.getGreeting(
      userName: userName,
      morningPool: morningPool,
      afternoonPool: afternoonPool,
      eveningPool: eveningPool,
      noTasksPool: noTasksPool,
      busyDayPool: busyDayPool,
      examPool: examPool,
      postExamPool: postExamPool,
      birthdayPool: birthdayPool,
      taskCount: taskCount,
      hasExamToday: hasExamToday,
      hasFinishedExam: hasFinishedExam,
      isBirthday: isBirthdayToday,
    );

    _greetingPeriod = currentPeriod;
    _greetingLocale = locale;
    _lastHasExamToday = hasExamToday;
    _lastHasFinishedExam = hasFinishedExam;

    return _sessionGreeting!;
  }

  Timer? _reminderCheckerTimer;
  final Set<String> _notifiedReminderIds = {};
  final Set<String> _notifiedClassReminderKeys = {};

  void _startReminderNotificationChecker() {
    _reminderCheckerTimer?.cancel();
    final now = DateTime.now();
    // Mark past reminders so they are not notified retroactively
    for (var r in _reminders) {
      if (r.dateTime.isBefore(now)) {
        _notifiedReminderIds.add(r.id);
      }
    }
    _checkDueReminders();
    _checkDueClassReminders();
    _reminderCheckerTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkDueReminders();
      _checkDueClassReminders();
    });
  }

  void _checkDueReminders() {
    final now = DateTime.now();
    for (var r in _reminders) {
      if (r.isCompleted) continue;
      if (_notifiedReminderIds.contains(r.id)) continue;

      final diffInSeconds = now.difference(r.dateTime).inSeconds;
      // Trigger notification ONLY at the exact scheduled moment (0 to 60 seconds window)
      if (diffInSeconds >= 0 && diffInSeconds <= 60) {
        _notifiedReminderIds.add(r.id);
        _triggerReminderNotification(r);
      }
    }
  }

  void _triggerReminderNotification(Reminder reminder) {
    final timeLabel = reminder.time != null ? ' (${reminder.time})' : '';

    // 1. Web Notification
    if (WebNotificationService().isPermissionGranted()) {
      WebNotificationService().showNotification(
        title: '📌 ¡Es hora! ${reminder.title}',
        body: 'Tienes un recordatorio programado$timeLabel',
      );
    }

    // 2. In-App Notification
    final notifId = const Uuid().v4();
    final notif = AppNotification(
      id: notifId,
      title: 'Recordatorio: ${reminder.title}',
      body: 'Es hora de tu recordatorio$timeLabel',
      timestamp: DateTime.now(),
      isRead: false,
    );
    _notifications.add(notif);
    _saveLocalAndRemote('notifications', notif.id, notif.toJson());
    notifyListeners();
  }

  void _checkDueClassReminders() {
    if (!_classRemindersEnabled) return;

    final now = DateTime.now();
    final datesToCheck = [
      now,
      now.add(const Duration(days: 1)),
    ];

    for (var date in datesToCheck) {
      final classes = getClassesForDate(date);
      for (var c in classes) {
        if (c.isDiscarded) continue;

        final startHourInt = c.startHour.floor();
        final startMinuteInt = ((c.startHour - startHourInt) * 60).round();
        final classStartTime = DateTime(
          date.year,
          date.month,
          date.day,
          startHourInt,
          startMinuteInt,
        );

        final reminderTriggerTime = classStartTime.subtract(
          Duration(minutes: _classReminderMinutesBefore),
        );

        final key = 'class_${c.subject.id}_${c.schedule.id}_${date.year}_${date.month}_${date.day}_$_classReminderMinutesBefore';

        // Pre-fill keys for class reminders that have already passed so we don't trigger retroactively
        if (reminderTriggerTime.isBefore(now.subtract(const Duration(minutes: 5)))) {
          _notifiedClassReminderKeys.add(key);
          continue;
        }

        if (_notifiedClassReminderKeys.contains(key)) continue;

        final diffInSeconds = now.difference(reminderTriggerTime).inSeconds;
        // Trigger notification if current time is within 0 to 60 seconds after trigger time
        if (diffInSeconds >= 0 && diffInSeconds <= 60) {
          _notifiedClassReminderKeys.add(key);
          _triggerClassReminderNotification(c, _classReminderMinutesBefore);
        }
      }
    }
  }

  void _triggerClassReminderNotification(ClassInstance c, int minutesBefore) {
    final roomInfo = c.schedule.room != null && c.schedule.room!.isNotEmpty
        ? ' en el salón ${c.schedule.room}'
        : '';
    final buildingInfo = c.subject.building != null && c.subject.building!.isNotEmpty
        ? ' (${c.subject.building})'
        : '';

    final bodyMessage = minutesBefore == 0
        ? '¡Tu clase de ${c.subject.name} está por comenzar$roomInfo$buildingInfo!'
        : 'Tu clase de ${c.subject.name} comienza en $minutesBefore minutos$roomInfo$buildingInfo.';

    // 1. Web & Desktop System Notification
    if (WebNotificationService().isPermissionGranted()) {
      WebNotificationService().showNotification(
        title: '📚 ¡Clase por comenzar! - ${c.subject.name}',
        body: bodyMessage,
      );
    }

    // 2. In-App Notification Center
    final notifId = const Uuid().v4();
    final notif = AppNotification(
      id: notifId,
      title: 'Clase: ${c.subject.name}',
      body: bodyMessage,
      timestamp: DateTime.now(),
      isRead: false,
    );
    _notifications.add(notif);
    _saveLocalAndRemote('notifications', notif.id, notif.toJson());
    notifyListeners();
  }

  void addReminder(Reminder reminder) async {
    _reminders.add(reminder);
    
    if (_calendarSyncEnabled) {
      final eventId = await CalendarService().syncReminder(reminder, targetCalendarId: _selectedCalendarId);
      if (eventId != null) {
        reminder = reminder.copyWith(calendarEventId: eventId);
        final idx = _reminders.indexWhere((r) => r.id == reminder.id);
        if (idx != -1) _reminders[idx] = reminder;
      }
    }

    _saveLocalAndRemote('reminders', reminder.id, reminder.toJson());
    _checkDueReminders();
    notifyListeners();
  }

  void addRecurringProgram(RecurringProgram program) {
    _recurringPrograms.add(program);
    // Note: Recurring programs are currently not persisted in DatabaseService
    // because I didn't add a table for them yet.
    // I should probably add one or save them as part of reminders/settings.
    _generateInstancesForProgram(program);
    notifyListeners();
  }

  void _generateInstancesForProgram(RecurringProgram program) {
    // Generate instances for the next 90 days or until end condition
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 90));

    DateTime current = program.startDate;
    int count = 0;

    while (current.isBefore(limit)) {
      if (program.config.endDate != null && current.isAfter(program.config.endDate!)) break;
      if (program.config.occurrences != null && count >= program.config.occurrences!) break;

      bool shouldAdd = true;
      if (program.config.frequency == RecurrenceFrequency.weekly && program.config.daysOfWeek != null) {
        if (!program.config.daysOfWeek!.contains(current.weekday)) {
          shouldAdd = false;
        }
      }

      if (shouldAdd) {
        // Add instance(s) for the current date
        if (program.config.timesOfDay != null && program.config.timesOfDay!.isNotEmpty) {
          for (var time in program.config.timesOfDay!) {
            final instanceDateTime = DateTime(current.year, current.month, current.day, time.hour, time.minute);
            if (instanceDateTime.isBefore(program.startDate)) continue;
            _addInstance(program, instanceDateTime);
          }
        } else {
          _addInstance(program, current);
        }
        count++;
      }

      // Advance current date
      switch (program.config.frequency) {
        case RecurrenceFrequency.hourly:
          current = current.add(Duration(hours: program.config.interval));
          break;
        case RecurrenceFrequency.daily:
          current = current.add(Duration(days: program.config.interval));
          break;
        case RecurrenceFrequency.weekly:
        // If daysOfWeek is set, we advance day by day to check each day
          if (program.config.daysOfWeek != null) {
            current = current.add(const Duration(days: 1));
          } else {
            current = current.add(Duration(days: 7 * program.config.interval));
          }
          break;
        case RecurrenceFrequency.monthly:
          current = DateTime(current.year, current.month + program.config.interval, current.day);
          break;
        case RecurrenceFrequency.yearly:
          current = DateTime(current.year + program.config.interval, current.month, current.day);
          break;
      }

      if (program.config.interval <= 0 && program.config.frequency != RecurrenceFrequency.hourly) break;
    }
  }

  void _addInstance(RecurringProgram program, DateTime dateTime) {
    final id = const Uuid().v4();
    _reminders.add(Reminder(
      id: id,
      author: _userName,
      title: program.title,
      date: '${dateTime.day}/${dateTime.month}/${dateTime.year}',
      time: '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
      category: program.category,
      location: program.location,
      description: program.description,
      subjectId: program.subjectId,
      isUrgent: program.isUrgent,
      dateTime: dateTime,
      programId: program.id,
    ));
  }

  void updateRecurringProgram(RecurringProgram program) {
    final index = _recurringPrograms.indexWhere((p) => p.id == program.id);
    if (index != -1) {
      _recurringPrograms[index] = program;
      // If disabled, we might want to remove future instances. 
      // If re-enabled, we might want to re-generate them.
      // For now, let's just update the list and notify.
      if (!program.isActive) {
        _reminders.removeWhere((r) => r.programId == program.id && !r.isCompleted && r.dateTime.isAfter(DateTime.now()));
      } else {
        _generateInstancesForProgram(program);
      }
      notifyListeners();
    }
  }

  void deleteRecurringProgram(String id) {
    _recurringPrograms.removeWhere((p) => p.id == id);
    // Optionally delete future uncompleted instances
    _reminders.removeWhere((r) => r.programId == id && !r.isCompleted && r.dateTime.isAfter(DateTime.now()));
    notifyListeners();
  }

  void updateReminder(Reminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      if (_calendarSyncEnabled) {
        final eventId = await CalendarService().syncReminder(reminder, targetCalendarId: _selectedCalendarId);
        if (eventId != null) {
          reminder = reminder.copyWith(calendarEventId: eventId);
        }
      }

      _reminders[index] = reminder;
      _saveLocalAndRemote('reminders', reminder.id, reminder.toJson());
      notifyListeners();
    }
  }

  void deleteReminder(String id) async {
    final reminder = _reminders.firstWhereOrNull((r) => r.id == id);
    if (reminder != null && _calendarSyncEnabled && reminder.calendarEventId != null) {
      await CalendarService().deleteEvent(reminder.calendarEventId);
    }

    _reminders.removeWhere((r) => r.id == id);
    await _deleteLocalAndRemote('reminders', id);
    notifyListeners();
  }

  void addNotebook(Notebook notebook) {
    _notebooks.add(notebook);
    _saveLocalAndRemote('notebooks', notebook.id, notebook.toJson());
    notifyListeners();
  }

  void deleteNotebook(String id) async {
    _notebooks.removeWhere((n) => n.id == id);
    await _deleteLocalAndRemote('notebooks', id);
    // Also delete notes from DB
    final notesToDelete = _notes.where((note) => note.notebookId == id).toList();
    for (var note in notesToDelete) {
      await _deleteLocalAndRemote('notes', note.id);
    }
    _notes.removeWhere((note) => note.notebookId == id);
    notifyListeners();
  }

  List<Note> getNotesForNotebook(String notebookId) {
    return _notes
        .where((n) => n.notebookId == notebookId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void _syncLegacySchedule() {}

  void addSubject(Subject subject) {
    _subjects.add(subject);
    _saveLocalAndRemote('subjects', subject.id, subject.toJson());
    notifyListeners();
  }

  void addNote(Note note) {
    _notes.add(note);
    _saveLocalAndRemote('notes', note.id, note.toJson());
    notifyListeners();
  }

  void updateNote(Note note) {
    // 1. Buscar en notas personales
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      _saveLocalAndRemote('notes', note.id, note.toJson());
      notifyListeners();
      return;
    }

    // 2. Buscar en notas compartidas de grupos
    for (int i = 0; i < _groups.length; i++) {
      final group = _groups[i];
      final noteIndex = group.sharedNotes.indexWhere((n) => n.id == note.id);
      if (noteIndex != -1) {
        final updatedSharedNotes = List<Note>.from(group.sharedNotes);
        updatedSharedNotes[noteIndex] = note;
        _groups[i] = group.copyWith(sharedNotes: updatedSharedNotes);
        _saveLocalAndRemote('groups', group.id, _groups[i].toJson());
        notifyListeners();
        return;
      }
    }
  }

  void deleteNote(String id) async {
    // 1. Borrar de notas personales
    final originalLength = _notes.length;
    _notes.removeWhere((n) => n.id == id);
    if (_notes.length < originalLength) {
      await _deleteLocalAndRemote('notes', id);
      notifyListeners();
      return;
    }

    // 2. Borrar de notas compartidas de grupos
    for (int i = 0; i < _groups.length; i++) {
      final group = _groups[i];
      final noteIndex = group.sharedNotes.indexWhere((n) => n.id == id);
      if (noteIndex != -1) {
        final updatedSharedNotes = List<Note>.from(group.sharedNotes)..removeAt(noteIndex);
        _groups[i] = group.copyWith(sharedNotes: updatedSharedNotes);
        _saveLocalAndRemote('groups', group.id, _groups[i].toJson());
        notifyListeners();
        return;
      }
    }
  }

  // Group Management
  void addGroup(Group group) {
    _groups.add(group);
    _saveLocalAndRemote('groups', group.id, group.toJson());
    notifyListeners();
  }

  Future<void> joinGroup(String inviteCode) async {
    if (userId == null) return;
    
    final groupData = await _fb.getGroupByInviteCode(inviteCode);
    if (groupData == null) throw Exception('invalidCode');

    final group = Group.fromJson(groupData);
    final curUserId = userId!;
    
    // Comprobación robusta en ambos campos posibles
    if (group.members.contains(curUserId) || group.admins.contains(curUserId)) {
      throw Exception('alreadyInGroup');
    }

    final updatedMembers = List<String>.from(group.members)..add(curUserId);
    // Aseguramos que members y memberIds (vía toJson) estén sincronizados
    final updatedGroup = group.copyWith(members: updatedMembers);
    
    // Guardar remotamente (actualizar el documento compartido)
    await _fb.syncEntity('groups', updatedGroup.id, updatedGroup.toJson());
    
    if (!_groups.any((g) => g.id == updatedGroup.id)) {
      _groups.add(updatedGroup);
      notifyListeners();
    }
  }

  void updateGroup(Group group) {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
      _saveLocalAndRemote('groups', group.id, group.toJson());
      notifyListeners();
    }
  }

  void deleteGroup(String id) async {
    _groups.removeWhere((g) => g.id == id);
    await _deleteLocalAndRemote('groups', id);
    notifyListeners();
  }

  void leaveGroup(String groupId, String userName) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = _groups[index];
      final updatedMembers = List<String>.from(group.members)..remove(userName);
      _groups[index] = group.copyWith(members: updatedMembers);
      _saveLocalAndRemote('groups', groupId, _groups[index].toJson());
      notifyListeners();
    }
  }

  void addPostToGroup(String groupId, GroupPost post) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final curUserId = userId ?? _fb.userId;
      final curUserPhoto = _fb.userPhotoUrl;
      
      final postWithAuthor = GroupPost(
        id: post.id,
        author: post.author,
        authorId: curUserId,
        authorPhotoUrl: curUserPhoto,
        title: post.title,
        content: post.content,
        images: post.images,
        timestamp: post.timestamp,
        reactions: post.reactions,
        comments: post.comments,
        type: 'ANNOUNCEMENT',
      );

      // Local update
      final group = _groups[index];
      final updatedPosts = List<GroupPost>.from(group.posts);
      if (!updatedPosts.any((p) => p.id == postWithAuthor.id)) {
        updatedPosts.insert(0, postWithAuthor);
        _groups[index] = group.copyWith(posts: updatedPosts);
      }
      
      // Remote update: Guardar en subcolección posts
      _fb.syncGroupPost(groupId, postWithAuthor.id, postWithAuthor.toJson());
      
      notifyListeners();
    }
  }

  void addNoteToGroup(String groupId, Note note) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final curUserId = userId ?? _fb.userId;
      final curUserPhoto = _fb.userPhotoUrl;
      
      final noteWithAuthor = note.copyWith(
        authorId: curUserId,
        authorPhotoUrl: curUserPhoto,
      );

      final group = _groups[index];
      
      // Añadir a la lista de notas compartidas
      final updatedNotes = List<Note>.from(group.sharedNotes)..insert(0, noteWithAuthor);
      
      _groups[index] = group.copyWith(
        sharedNotes: updatedNotes,
      );

      // Sincronizar como un POST de tipo NOTE
      _fb.syncGroupPost(groupId, noteWithAuthor.id, noteWithAuthor.toJson());

      notifyListeners();
    }
  }

  void addReminderToGroup(String groupId, Reminder reminder) async {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final curUserId = userId ?? _fb.userId;
      final curUserPhoto = _fb.userPhotoUrl;

      final reminderWithAuthor = reminder.copyWith(
        authorId: curUserId,
        authorPhotoUrl: curUserPhoto,
      );

      if (_calendarSyncEnabled) {
        final eventId = await CalendarService().syncReminder(reminderWithAuthor, targetCalendarId: _selectedCalendarId);
        if (eventId != null) {
          // Nota: copyWith de Reminder no tiene calendarEventId como argumento directo en el anterior replace
          // pero el reminderWithAuthor ya está creado.
        }
      }

      final group = _groups[index];
      final updatedReminders = List<Reminder>.from(group.sharedReminders)..insert(0, reminderWithAuthor);
      _groups[index] = group.copyWith(sharedReminders: updatedReminders);
      
      // Sincronizar como un POST de tipo TASK
      _fb.syncGroupPost(groupId, reminderWithAuthor.id, reminderWithAuthor.toJson());

      notifyListeners();
    }
  }

  void addPollToGroup(String groupId, GroupPoll poll) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final curUserId = userId ?? _fb.userId;
      final curUserPhoto = _fb.userPhotoUrl;

      final pollWithAuthor = GroupPoll(
        id: poll.id,
        author: poll.author,
        authorId: curUserId,
        authorPhotoUrl: curUserPhoto,
        question: poll.question,
        description: poll.description,
        images: poll.images,
        options: poll.options,
        timestamp: poll.timestamp,
        expiresAt: poll.expiresAt,
        reactions: poll.reactions,
        comments: poll.comments,
      );

      final group = _groups[index];
      final updatedPolls = List<GroupPoll>.from(group.polls);
      if (!updatedPolls.any((p) => p.id == pollWithAuthor.id)) {
        updatedPolls.insert(0, pollWithAuthor);
        _groups[index] = group.copyWith(polls: updatedPolls);
      }
      
      // Remote update: Guardar en subcolección posts (vía syncGroupPoll que ahora apunta a posts)
      _fb.syncGroupPoll(groupId, pollWithAuthor.id, pollWithAuthor.toJson());

      notifyListeners();
    }
  }

  void deleteItemFromGroup(String groupId, String itemId, String type) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    
    final group = _groups[index];
    Group updatedGroup = group;
    
    if (type == 'post') {
      final updatedPosts = List<GroupPost>.from(group.posts)..removeWhere((p) => p.id == itemId);
      updatedGroup = group.copyWith(posts: updatedPosts);
      _fb.deleteGroupItem(groupId, 'posts', itemId);
    } else if (type == 'poll') {
      final updatedPolls = List<GroupPoll>.from(group.polls)..removeWhere((p) => p.id == itemId);
      updatedGroup = group.copyWith(polls: updatedPolls);
      _fb.deleteGroupItem(groupId, 'polls', itemId);
    } else if (type == 'note') {
      final updatedNotes = List<Note>.from(group.sharedNotes)..removeWhere((n) => n.id == itemId);
      updatedGroup = group.copyWith(sharedNotes: updatedNotes);
    } else if (type == 'reminder') {
      final updatedReminders = List<Reminder>.from(group.sharedReminders)..removeWhere((r) => r.id == itemId);
      updatedGroup = group.copyWith(sharedReminders: updatedReminders);
    }
    
    _groups[index] = updatedGroup;
    _saveLocalAndRemote('groups', groupId, updatedGroup.toJson());
    notifyListeners();
  }

  void addAdminToGroup(String groupId, String userName) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = _groups[index];
      if (!group.admins.contains(userName)) {
        final updatedAdmins = List<String>.from(group.admins)..add(userName);
        _groups[index] = group.copyWith(admins: updatedAdmins);
        _saveLocalAndRemote('groups', groupId, _groups[index].toJson());
        notifyListeners();
      }
    }
  }

  void voteInPoll(String groupId, String pollId, int optionIndex, String userName) {
    final gIndex = _groups.indexWhere((g) => g.id == groupId);
    if (gIndex != -1) {
      final group = _groups[gIndex];
      final pIndex = group.polls.indexWhere((p) => p.id == pollId);
      if (pIndex != -1) {
        final poll = group.polls[pIndex];

        // Check if poll is expired
        if (poll.isExpired) return;

        // Check if user already voted in this poll
        bool alreadyVoted = false;
        for (var opt in poll.options) {
          if (opt.votedBy.contains(userName)) {
            alreadyVoted = true;
            break;
          }
        }
        if (alreadyVoted) return;

        final updatedOptions = List<PollOption>.from(poll.options);
        final option = updatedOptions[optionIndex];
        updatedOptions[optionIndex] = PollOption(
          text: option.text,
          votes: option.votes + 1,
          votedBy: List<String>.from(option.votedBy)..add(userId ?? userName),
        );

        final updatedPolls = List<GroupPoll>.from(group.polls);
        updatedPolls[pIndex] = GroupPoll(
          id: poll.id,
          author: poll.author,
          authorId: poll.authorId,
          authorPhotoUrl: poll.authorPhotoUrl,
          question: poll.question,
          description: poll.description,
          images: poll.images,
          options: updatedOptions,
          timestamp: poll.timestamp,
          expiresAt: poll.expiresAt,
          reactions: poll.reactions,
          comments: poll.comments,
        );

        _groups[gIndex] = group.copyWith(polls: updatedPolls);
        _fb.syncGroupPoll(groupId, pollId, updatedPolls[pIndex].toJson());
        _saveLocalAndRemote('groups', groupId, _groups[gIndex].toJson());
        notifyListeners();
      }
    }
  }

  void toggleReaction(String groupId, String itemId, String itemType, String emoji) {
    final curUserId = userId ?? userName;
    final gIndex = _groups.indexWhere((g) => g.id == groupId);
    if (gIndex == -1) return;
    final group = _groups[gIndex];

    if (itemType == 'post' || itemType == 'announcement') {
      final items = List<GroupPost>.from(group.posts);
      final index = items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final reactions = Map<String, List<String>>.from(items[index].reactions);
        final users = List<String>.from(reactions[emoji] ?? []);

        if (users.contains(curUserId)) {
          users.remove(curUserId);
        } else {
          users.add(curUserId);
        }

        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }

        items[index] = GroupPost(
          id: items[index].id,
          author: items[index].author,
          authorId: items[index].authorId,
          authorPhotoUrl: items[index].authorPhotoUrl,
          title: items[index].title,
          content: items[index].content,
          images: items[index].images,
          timestamp: items[index].timestamp,
          reactions: reactions,
          comments: items[index].comments,
          type: items[index].type,
        );
        _groups[gIndex] = group.copyWith(posts: items);
        _fb.syncGroupPost(groupId, itemId, items[index].toJson());
        _saveLocalAndRemote('groups', groupId, _groups[gIndex].toJson());
        notifyListeners();
      }
    } else if (itemType == 'poll') {
      final items = List<GroupPoll>.from(group.polls);
      final index = items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final reactions = Map<String, List<String>>.from(items[index].reactions);
        final users = List<String>.from(reactions[emoji] ?? []);
        if (users.contains(curUserId)) {
          users.remove(curUserId);
        } else {
          users.add(curUserId);
        }
        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }

        items[index] = GroupPoll(
          id: items[index].id,
          author: items[index].author,
          authorId: items[index].authorId,
          authorPhotoUrl: items[index].authorPhotoUrl,
          question: items[index].question,
          description: items[index].description,
          images: items[index].images,
          options: items[index].options,
          timestamp: items[index].timestamp,
          expiresAt: items[index].expiresAt,
          reactions: reactions,
          comments: items[index].comments,
        );
        _groups[gIndex] = group.copyWith(polls: items);
        _fb.syncGroupPoll(groupId, itemId, items[index].toJson());
        _saveLocalAndRemote('groups', groupId, _groups[gIndex].toJson());
        notifyListeners();
      }
    } else if (itemType == 'note') {
      final items = List<Note>.from(group.sharedNotes);
      final index = items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final reactions = Map<String, List<String>>.from(items[index].reactions);
        final users = List<String>.from(reactions[emoji] ?? []);
        if (users.contains(curUserId)) {
          users.remove(curUserId);
        } else {
          users.add(curUserId);
        }
        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }

        items[index] = items[index].copyWith(reactions: reactions);
        _groups[gIndex] = group.copyWith(sharedNotes: items);
        _fb.syncGroupPost(groupId, itemId, items[index].toJson());
        _saveLocalAndRemote('groups', groupId, _groups[gIndex].toJson());
        notifyListeners();
      }
    } else if (itemType == 'reminder' || itemType == 'task') {
      final items = List<Reminder>.from(group.sharedReminders);
      final index = items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final reactions = Map<String, List<String>>.from(items[index].reactions);
        final users = List<String>.from(reactions[emoji] ?? []);
        if (users.contains(curUserId)) {
          users.remove(curUserId);
        } else {
          users.add(curUserId);
        }
        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }

        final old = items[index];
        items[index] = old.copyWith(reactions: reactions);
        _groups[gIndex] = group.copyWith(sharedReminders: items);
        _fb.syncGroupPost(groupId, itemId, items[index].toJson());
        _saveLocalAndRemote('groups', groupId, _groups[gIndex].toJson());
        notifyListeners();
      }
    }
  }

  void addComment(String groupId, String itemId, String itemType, String text) {
    final gIndex = _groups.indexWhere((g) => g.id == groupId);
    if (gIndex == -1) return;
    final group = _groups[gIndex];

    final comment = GroupComment(
      id: const Uuid().v4(),
      author: userId ?? userName,
      text: text,
      timestamp: DateTime.now(),
    );

    final curUserId = userId ?? _fb.userId;
    if (itemType == 'post' || itemType == 'announcement') {
      final items = List<GroupPost>.from(group.posts);
      final index = items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final comments = List<GroupComment>.from(items[index].comments)..add(comment);
        items[index] = GroupPost(
          id: items[index].id,
          author: items[index].author,
          authorId: items[index].authorId,
          authorPhotoUrl: items[index].authorPhotoUrl,
          title: items[index].title,
          content: items[index].content,
          images: items[index].images,
          timestamp: items[index].timestamp,
          reactions: items[index].reactions,
          comments: comments,
          type: items[index].type,
        );
        _groups[gIndex] = group.copyWith(posts: items);
        _fb.syncGroupPost(groupId, itemId, items[index].toJson());
        _saveLocalAndRemote('groups', groupId, _groups[gIndex].toJson());
        notifyListeners();
      }
    } else if (itemType == 'poll') {
      final items = List<GroupPoll>.from(group.polls);
      final index = items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final comments = List<GroupComment>.from(items[index].comments)..add(comment);
        items[index] = GroupPoll(
          id: items[index].id,
          author: items[index].author,
          authorId: items[index].authorId,
          authorPhotoUrl: items[index].authorPhotoUrl,
          question: items[index].question,
          description: items[index].description,
          images: items[index].images,
          options: items[index].options,
          timestamp: items[index].timestamp,
          expiresAt: items[index].expiresAt,
          reactions: items[index].reactions,
          comments: comments,
        );
        _groups[gIndex] = group.copyWith(polls: items);
        _fb.syncGroupPoll(groupId, itemId, items[index].toJson());
        _saveLocalAndRemote('groups', groupId, _groups[gIndex].toJson());
        notifyListeners();
      }
    } else if (itemType == 'note') {
      final items = List<Note>.from(group.sharedNotes);
      final index = items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final comments = List<GroupComment>.from(items[index].comments)..add(comment);
        items[index] = items[index].copyWith(comments: comments);
        _groups[gIndex] = group.copyWith(sharedNotes: items);
        _fb.syncGroupPost(groupId, itemId, items[index].toJson());
        _saveLocalAndRemote('groups', groupId, _groups[gIndex].toJson());
        notifyListeners();
      }
    } else if (itemType == 'reminder' || itemType == 'task') {
      final items = List<Reminder>.from(group.sharedReminders);
      final index = items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final comments = List<GroupComment>.from(items[index].comments)..add(comment);
        final old = items[index];
        items[index] = old.copyWith(comments: comments);
        _groups[gIndex] = group.copyWith(sharedReminders: items);
        _fb.syncGroupPost(groupId, itemId, items[index].toJson());
        _saveLocalAndRemote('groups', groupId, _groups[gIndex].toJson());
        notifyListeners();
      }
    }
  }

  // Project Management (Disabled)
  void addProject(Project project) {
    /*
    _projects.add(project);
    _saveLocalAndRemote('projects', project.id, project.toJson());
    notifyListeners();
    */
  }

  void updateProject(Project project) {
    /*
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
      _saveLocalAndRemote('projects', project.id, project.toJson());
      notifyListeners();
    }
    */
  }

  void deleteProject(String id) async {
    /*
    _projects.removeWhere((p) => p.id == id);
    await _deleteLocalAndRemote('projects', id);
    notifyListeners();
    */
  }

  void toggleTaskInProject(String projectId, String taskId) {
    final pIndex = _projects.indexWhere((p) => p.id == projectId);
    if (pIndex != -1) {
      final project = _projects[pIndex];
      final updatedPhases = List<ProjectPhase>.from(project.phases);
      final currentPhase = updatedPhases[project.currentPhaseIndex];
      final updatedTasks = List<ProjectTask>.from(currentPhase.tasks);

      final tIndex = updatedTasks.indexWhere((t) => t.id == taskId);
      if (tIndex != -1) {
        updatedTasks[tIndex] = updatedTasks[tIndex].copyWith(isCompleted: !updatedTasks[tIndex].isCompleted);
        updatedPhases[project.currentPhaseIndex] = currentPhase.copyWith(tasks: updatedTasks);

        // Recalculate global progress
        int totalTasks = 0;
        int completedTasks = 0;
        for (var phase in updatedPhases) {
          totalTasks += phase.tasks.length;
          completedTasks += phase.tasks.where((t) => t.isCompleted).length;
        }
        final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

        _projects[pIndex] = project.copyWith(phases: updatedPhases, progress: progress);
        _saveLocalAndRemote('projects', projectId, _projects[pIndex].toJson());
        notifyListeners();
      }
    }
  }

  void finishCurrentPhase(String projectId, String nextPhaseTitle) {
    final pIndex = _projects.indexWhere((p) => p.id == projectId);
    if (pIndex != -1) {
      final project = _projects[pIndex];
      final updatedPhases = List<ProjectPhase>.from(project.phases);

      // Mark current phase as completed
      updatedPhases[project.currentPhaseIndex] = updatedPhases[project.currentPhaseIndex].copyWith(isCompleted: true);

      // Add next phase if provided
      if (nextPhaseTitle.isNotEmpty) {
        updatedPhases.add(ProjectPhase(
          id: const Uuid().v4(),
          title: nextPhaseTitle,
          tasks: [],
        ));
      }

      _projects[pIndex] = project.copyWith(
        phases: updatedPhases,
        currentPhaseIndex: project.currentPhaseIndex + 1,
      );
      _saveLocalAndRemote('projects', projectId, _projects[pIndex].toJson());
      notifyListeners();
    }
  }

  void finishProject(String projectId) {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      _projects[index] = _projects[index].copyWith(
        status: ProjectStatus.completed,
        progress: 1.0,
      );
      _saveLocalAndRemote('projects', projectId, _projects[index].toJson());
      notifyListeners();
    }
  }

  void archiveProject(String projectId) {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      _projects[index] = _projects[index].copyWith(status: ProjectStatus.archived);
      _saveLocalAndRemote('projects', projectId, _projects[index].toJson());
      notifyListeners();
    }
  }

  // Focus Sessions
  static const _dndChannel = MethodChannel('com.pixelfox.agenda/dnd');

  Future<bool> isDNDPermissionGranted() async {
    try {
      return await _dndChannel.invokeMethod('isPermissionGranted') ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<void> openDNDSettings() async {
    try {
      await _dndChannel.invokeMethod('gotoSettings');
    } catch (_) {}
  }

  Future<void> startAppPinning() async {
    try {
      await _dndChannel.invokeMethod('startAppPinning');
    } catch (_) {}
  }

  Future<void> stopAppPinning() async {
    try {
      await _dndChannel.invokeMethod('stopAppPinning');
    } catch (_) {}
  }

  void addFocusSession(FocusSession session) {
    /*
    if (activeFocusSession != null) return; 
    _focusSessions.add(session);
    _saveLocalAndRemote('focus_sessions', session.id, session.toJson());
    notifyListeners();
    */
  }

  void joinFocusSession(String sessionId, String participantId) {
    final index = _focusSessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final session = _focusSessions[index];
      if (!session.participants.contains(participantId)) {
        final updatedParticipants = List<String>.from(session.participants)..add(participantId);
        _focusSessions[index] = session.copyWith(participants: updatedParticipants);
        notifyListeners();
      }
    }
  }

  void leaveFocusSession(String sessionId, String participantId) async {
    final index = _focusSessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final session = _focusSessions[index];

      // If we are leaving while focusing, restore notifications if needed
      if (session.silenceNotifications && session.status == FocusSessionStatus.focusing && participantId == userId) {
        await _dndChannel.invokeMethod('setDNDMode', {'enable': false});
      }

      // If we are leaving while focusing in strict mode, stop app pinning
      if (session.isStrictMode && session.status == FocusSessionStatus.focusing && participantId == userId) {
        await stopAppPinning();
      }

      bool isStrictMode = session.isStrictMode;
      // If host leaves, strict mode is deactivated for everyone
      if (participantId == session.creatorId) {
        isStrictMode = false;
      }

      final updatedParticipants = List<String>.from(session.participants)..remove(participantId);

      _focusSessions[index] = session.copyWith(
        participants: updatedParticipants,
        isStrictMode: isStrictMode,
      );
      notifyListeners();
    }
  }

  void requestLeaveFocusSession(String sessionId, String userName) {
    final index = _focusSessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final session = _focusSessions[index];
      if (!session.leaveRequests.contains(userName)) {
        final updatedRequests = List<String>.from(session.leaveRequests)..add(userName);
        _focusSessions[index] = session.copyWith(leaveRequests: updatedRequests);
        notifyListeners();
      }
    }
  }

  void approveLeaveRequest(String sessionId, String userName) {
    final index = _focusSessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final session = _focusSessions[index];
      final updatedRequests = List<String>.from(session.leaveRequests)..remove(userName);
      _focusSessions[index] = session.copyWith(leaveRequests: updatedRequests);
      notifyListeners();
      leaveFocusSession(sessionId, userName);
    }
  }

  Future<void> _moveSessionNotesToNotebook(String sessionId) async {
    final sessionNotes = _notes.where((n) => n.focusSessionId == sessionId).toList();
    if (sessionNotes.isEmpty) return;

    // Buscar o crear libreta para sesiones de enfoque
    Notebook? targetNotebook = _notebooks.firstWhereOrNull((nb) => nb.name == 'Sesiones de Enfoque');
    
    if (targetNotebook == null) {
      targetNotebook = Notebook(
        id: const Uuid().v4(),
        name: 'Sesiones de Enfoque',
        icon: Icons.timer_rounded,
        color: appAccentColor.value,
        createdAt: DateTime.now(),
      );
      addNotebook(targetNotebook);
    }

    for (var note in sessionNotes) {
      final updatedNote = note.copyWith(
        notebookId: targetNotebook.id,
        // Limpiamos focusSessionId para que no aparezcan como "notas de sesión activa" si se iniciara otra con el mismo ID (raro pero posible por reuso de mocks)
        // focusSessionId: null, 
      );
      updateNote(updatedNote);
    }
  }

  void addFocusComment(String sessionId, String text) {
    final index = _focusSessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final session = _focusSessions[index];
      final comment = GroupComment(
        id: const Uuid().v4(),
        author: userId ?? userName,
        text: text,
        timestamp: DateTime.now(),
      );
      final updatedChat = List<GroupComment>.from(session.chat)..add(comment);
      _focusSessions[index] = session.copyWith(chat: updatedChat);
      _saveLocalAndRemote('focus_sessions', sessionId, _focusSessions[index].toJson());
      notifyListeners();
    }
  }

  void updateFocusSessionStatus(String sessionId, FocusSessionStatus status) async {
    final index = _focusSessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final session = _focusSessions[index];

      // If we are starting focus, clear any pending leave requests
      final leaveRequests = status == FocusSessionStatus.focusing ? <String>[] : session.leaveRequests;

      // Generate random exit key for the host if strict mode is on
      String? exitKey;
      DateTime? keyAppearanceTime;
      if (session.isStrictMode && status == FocusSessionStatus.focusing) {
        exitKey = (1000 + (DateTime.now().millisecond % 9000)).toString(); // 4 digit code
        // Key appears at a random point in the focus session (between 30% and 90% of duration)
        final randomOffset = 0.3 + (DateTime.now().microsecond % 600) / 1000.0;
        keyAppearanceTime = DateTime.now().add(Duration(seconds: (session.focusDuration * 60 * randomOffset).toInt()));
      }

      if (status == FocusSessionStatus.idle && session.isPrivate) {
        await _moveSessionNotesToNotebook(session.id);
      }

      _focusSessions[index] = session.copyWith(
        status: status,
        startTime: (status == FocusSessionStatus.focusing || status == FocusSessionStatus.shortBreak || status == FocusSessionStatus.longBreak) ? DateTime.now() : null,
        leaveRequests: leaveRequests,
        exitKey: exitKey,
        keyAppearanceTime: keyAppearanceTime,
      );

      _saveLocalAndRemote('focus_sessions', sessionId, _focusSessions[index].toJson());

      // Handle Silence Notifications (DND)
      if (session.silenceNotifications) {
        if (status == FocusSessionStatus.focusing) {
          await _dndChannel.invokeMethod('setDNDMode', {'enable': true});
        } else if (status == FocusSessionStatus.idle || status == FocusSessionStatus.shortBreak || status == FocusSessionStatus.longBreak) {
          await _dndChannel.invokeMethod('setDNDMode', {'enable': false});
        }
      }

      // Handle Strict Mode (App Pinning)
      if (session.isStrictMode) {
        if (status == FocusSessionStatus.focusing) {
          await startAppPinning();
        } else if (status == FocusSessionStatus.idle || status == FocusSessionStatus.shortBreak || status == FocusSessionStatus.longBreak) {
          await stopAppPinning();
        }
      }

      notifyListeners();
    }
  }

  void addOverride(ScheduleOverride override) {
    // 1. Persistir en el objeto Subject (Formato Exacto App Anterior - Imagen 2)
    final sIndex = _subjects.indexWhere((s) => s.id == override.subjectId);
    if (sIndex != -1) {
      final subject = _subjects[sIndex];
      final dateStr = "${override.date.day.toString().padLeft(2, '0')}/${override.date.month.toString().padLeft(2, '0')}/${override.date.year}";
      final timeStr = "${override.originalStartTime.hour.toString().padLeft(2, '0')}:${override.originalStartTime.minute.toString().padLeft(2, '0')}";
      final key = "$dateStr|$timeStr";

      final updatedOverrides = Map<String, dynamic>.from(subject.overrides);
      
      if (override.isDiscarded) {
        // REPLICA EXACTA IMAGEN 2:
        // 1. Clave de fecha corta -> discarded: true
        updatedOverrides[dateStr] = {
          'discarded': true,
          'startTime': null,
          'endTime': null,
        };
        // 2. Clave de sesión -> discarded: false (para indicar que el descarte es por el día)
        updatedOverrides[key] = {
          'discarded': false,
          'startTime': null,
          'endTime': null,
        };
      } else {
        // Reprogramación de horario
        String? newStart;
        String? newEnd;
        try {
          final schedule = subject.schedules.firstWhere((s) => 
            s.startTime.hour == override.originalStartTime.hour && 
            s.startTime.minute == override.originalStartTime.minute);
            
          final startDouble = schedule.startHourDouble + override.offsetHours;
          final duration = override.customDurationHours ?? (schedule.endHourDouble - schedule.startHourDouble);
          final endDouble = startDouble + duration;
          newStart = _doubleToTimeStr(startDouble);
          newEnd = _doubleToTimeStr(endDouble);
        } catch(_) {}

        updatedOverrides[key] = {
          'discarded': false,
          'startTime': newStart,
          'endTime': newEnd,
        };
      }

      // 2. Actualizar la asignatura en la lista local antes de reconstruir
      _subjects[sIndex] = subject.copyWith(overrides: updatedOverrides);
      
      // 3. RECONSTRUCCIÓN INMEDIATA DE LA MEMORIA
      _rebuildOverridesFromSubjects();
      
      // 4. Guardar en DB y Cloud (Esto ahora actualiza el caché de sync)
      _saveLocalAndRemote('subjects', subject.id, _subjects[sIndex].toJson());
      
      // 5. Notificar a la UI
      notifyListeners();
    }
  }

  String _doubleToTimeStr(double value) {
    int hour = value.floor();
    int minute = ((value - hour) * 60).round();
    if (minute == 60) { hour++; minute = 0; }
    return "${(hour % 24).toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }

  void removeOverride(String subjectId, DateTime date, TimeOfDay startTime) {
    // 1. Actualizar memoria
    _overrides.removeWhere((o) =>
    o.subjectId == subjectId &&
        o.date.year == date.year &&
        o.date.month == date.month &&
        o.date.day == date.day &&
        o.originalStartTime.hour == startTime.hour &&
        o.originalStartTime.minute == startTime.minute
    );

    // 2. Eliminar del objeto Subject y persistir
    final sIndex = _subjects.indexWhere((s) => s.id == subjectId);
    if (sIndex != -1) {
      final subject = _subjects[sIndex];
      final dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      final timeStr = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
      final key = "$dateStr|$timeStr";

      final updatedOverrides = Map<String, dynamic>.from(subject.overrides);
      
      // Al restaurar, eliminamos tanto el override de sesión como el de día completo
      updatedOverrides.remove(key);
      updatedOverrides.remove(dateStr);
      
      _subjects[sIndex] = subject.copyWith(overrides: updatedOverrides);
      _saveLocalAndRemote('subjects', subject.id, _subjects[sIndex].toJson());
    }

    notifyListeners();
  }

  bool isDiscarded(String subjectId, DateTime date, TimeOfDay startTime) {
    final dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    final timeStr = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
    
    try {
      final subject = _subjects.firstWhere((s) => s.id == subjectId);
      
      // 1. Prioridad Máxima: Descarte diario en el mapa (Imagen 2)
      // Si el día está descartado, cualquier sesión del mismo es descartada automáticamente
      final dailyOverride = subject.overrides[dateStr];
      if (dailyOverride != null && dailyOverride['discarded'] == true) return true;

      // 2. Descarte específico de sesión en el mapa (si no hay descarte diario)
      final sessionOverride = subject.overrides["$dateStr|$timeStr"];
      if (sessionOverride != null && (sessionOverride['discarded'] == true || sessionOverride['isDiscarded'] == true)) return true;

      // 3. Soporte legacy (lista de strings)
      if (subject.discardedDates.contains(dateStr)) return true;
    } catch (_) {}

    // 4. Fallback a la lista de memoria para cambios locales instantáneos
    final o = getOverride(subjectId, date, startTime);
    return o?.isDiscarded ?? false;
  }

  List<ClassInstance> getClassesForDate(DateTime date, {bool includeDiscarded = false}) {
    List<ClassInstance> instances = [];
    for (var subject in _subjects) {
      for (var schedule in subject.schedules) {
        if (schedule.matchesDate(date)) {
          final discarded = isDiscarded(subject.id, date, schedule.startTime);
          if (discarded && !includeDiscarded) continue;

          final override = getOverride(subject.id, date, schedule.startTime);
          instances.add(ClassInstance(
            subject: subject,
            schedule: schedule,
            date: date,
            offsetHours: override?.offsetHours ?? 0.0,
            customDurationHours: override?.customDurationHours,
            isDiscarded: discarded,
          ));
        }
      }
    }
    instances.sort((a, b) => a.startHour.compareTo(b.startHour));
    return instances;
  }

  List<TimeSlot> getFreeSlots(DateTime date) {
    List<TimeSlot> freeSlots = [];
    final activeClasses = getClassesForDate(date);

    double current = 6.0; // School day can start early
    for (var c in activeClasses) {
      if (c.startHour > current + 0.05) { // Min 3 min gap
        freeSlots.add(TimeSlot(startHour: current, endHour: c.startHour));
      }
      if (c.endHour > current) {
        current = c.endHour;
      }
    }
    if (current < 23.5) {
      freeSlots.add(TimeSlot(startHour: current, endHour: 23.5));
    }
    return freeSlots;
  }

  List<TimeSlot> getRecommendedSlots(DateTime date, double durationHours) {
    final freeSlots = getFreeSlots(date);
    List<TimeSlot> recommended = [];

    for (var slot in freeSlots) {
      double current = slot.startHour;
      // Ajustar al inicio de hora o media hora si es posible para que sea más "natural"
      if (current % 0.5 != 0) {
        current = (current * 2).ceil() / 2;
      }

      while (current + durationHours <= slot.endHour) {
        recommended.add(TimeSlot(startHour: current, endHour: current + durationHours));
        current += 0.5; // Sugerir cada media hora
        if (recommended.length >= 12) break; 
      }
      if (recommended.length >= 12) break;
    }

    return recommended;
  }

  Map<String, double> getNormalClassRange() {
    double minStart = 24.0;
    double maxEnd = 0.0;
    bool found = false;

    for (var subject in _subjects) {
      for (var schedule in subject.schedules) {
        found = true;
        if (schedule.startHourDouble < minStart) minStart = schedule.startHourDouble;
        if (schedule.endHourDouble > maxEnd) maxEnd = schedule.endHourDouble;
      }
    }

    if (!found) return {'start': 8.0, 'end': 16.0};
    return {'start': minStart, 'end': maxEnd};
  }

  void updateSubject(Subject subject) {
    int index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      _subjects[index] = subject;
      _saveLocalAndRemote('subjects', subject.id, subject.toJson());
      notifyListeners();
    }
  }

  void deleteSubject(String id) async {
    _subjects.removeWhere((s) => s.id == id);
    await _deleteLocalAndRemote('subjects', id);
    notifyListeners();
  }

  void clearAllSubjects() async {
    _subjects.clear();
    await _db.clearTable('subjects');
    
    // Sincronizar con Firebase para limpiar la nube
    if (_fb.isAuthenticated && !_fb.isAnonymous) {
      final cloudDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(_fb.userId)
          .collection('schedule')
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in cloudDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    notifyListeners();
  }

  void importSubjects(List<Subject> newSubjects) {
    _subjects.clear();
    _db.clearTable('subjects');
    
    final Map<String, Subject> grouped = {};
    final uuid = const Uuid();

    for (var s in newSubjects) {
      final key = '${s.name}-${s.group ?? ''}';
      
      // Regenerar ID de la materia y de cada sesión para evitar colisiones según Jerarquía de Datos v2
      final processedSubject = s.copyWith(
        id: uuid.v4(),
        schedules: s.schedules.map((sch) => SubjectSchedule(
          id: uuid.v4(),
          day: sch.day,
          startTime: sch.startTime,
          endTime: sch.endTime,
        )).toList(),
      );

      if (grouped.containsKey(key)) {
        grouped[key]!.schedules.addAll(processedSubject.schedules);
      } else {
        grouped[key] = processedSubject;
      }
    }

    _subjects.addAll(grouped.values);
    for (var s in _subjects) {
      _db.saveEntity('subjects', s.id, s.toJson());
    }
    if (_fb.isAuthenticated && !_fb.isAnonymous) {
      _fb.saveBatch('schedule', _subjects.map((s) => s.toJson()).toList());
    }
    notifyListeners();
  }

  String exportBackupJson() {
    final Map<String, dynamic> data = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'subjects': _subjects.map((s) => s.toJson()).toList(),
      'notes': _notes.map((n) => n.toJson()).toList(),
      'notebooks': _notebooks.map((nb) => nb.toJson()).toList(),
      'reminders': _reminders.map((r) => r.toJson()).toList(),
      'projects': _projects.map((p) => p.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> importBackupJson(String jsonString) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data.containsKey('subjects') && data['subjects'] is List) {
        final List<Subject> importedSubjects = (data['subjects'] as List)
            .map((j) => Subject.fromJson(Map<String, dynamic>.from(j)))
            .toList();
        if (importedSubjects.isNotEmpty) importSubjects(importedSubjects);
      }

      if (data.containsKey('notes') && data['notes'] is List) {
        final List<Note> importedNotes = (data['notes'] as List)
            .map((j) => Note.fromJson(Map<String, dynamic>.from(j)))
            .toList();
        for (var n in importedNotes) {
          addNote(n);
        }
      }

      if (data.containsKey('reminders') && data['reminders'] is List) {
        final List<Reminder> importedReminders = (data['reminders'] as List)
            .map((j) => Reminder.fromJson(Map<String, dynamic>.from(j)))
            .toList();
        for (var r in importedReminders) {
          addReminder(r);
        }
      }

      if (data.containsKey('projects') && data['projects'] is List) {
        final List<Project> importedProjects = (data['projects'] as List)
            .map((j) => Project.fromJson(Map<String, dynamic>.from(j)))
            .toList();
        for (var p in importedProjects) {
          addProject(p);
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("DataService: Error importing backup: $e");
      return false;
    }
  }

  Future<void> syncAllFromCloud() async {
    if (!_fb.isAuthenticated) return;
    try {
      _connectivityStatus = ConnectivityStatus.syncing;
      notifyListeners();

      await _initData();

      _connectivityStatus = ConnectivityStatus.wifi;
      notifyListeners();
    } catch (e) {
      debugPrint("DataService: Error syncing from cloud: $e");
    }
  }

  void clearLocalCache() {
    _userProfilesCache.clear();
    notifyListeners();
  }

  ScheduleOverride? getOverride(String subjectId, DateTime date, TimeOfDay startTime) {
    try {
      return _overrides.firstWhere((o) =>
      o.subjectId == subjectId &&
          o.date.year == date.year &&
          o.date.month == date.month &&
          o.date.day == date.day &&
          o.originalStartTime.hour == startTime.hour &&
          o.originalStartTime.minute == startTime.minute
      );
    } catch (_) {
      return null;
    }
  }

  void discardClassForDate(String subjectId, DateTime date) {
    final sIndex = _subjects.indexWhere((s) => s.id == subjectId);
    if (sIndex != -1) {
      final subject = _subjects[sIndex];
      final dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      
      final updatedOverrides = Map<String, dynamic>.from(subject.overrides);
      // Clave diaria corta como en la imagen 2
      updatedOverrides[dateStr] = {
        'discarded': true,
        'startTime': null,
        'endTime': null,
      };
      
      _subjects[sIndex] = subject.copyWith(overrides: updatedOverrides);

      // Reconstrucción inmediata de la memoria para evitar el "rebote"
      _rebuildOverridesFromSubjects();
      
      _saveLocalAndRemote('subjects', subject.id, _subjects[sIndex].toJson());
      notifyListeners();
    }
  }

  void discardPeriod(DateTime start, DateTime end) {
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      final date = start.add(Duration(days: i));
      final classes = getClassesForDate(date);
      for (var c in classes) {
        discardClassForDate(c.subject.id, date);
      }
    }
  }

  void resumePeriod(DateTime start, DateTime end) {
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      final date = start.add(Duration(days: i));
      final dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

      // 1. Limpiar de la lista de memoria
      _overrides.removeWhere((o) =>
        o.date.year == date.year &&
        o.date.month == date.month &&
        o.date.day == date.day &&
        o.isDiscarded == true
      );

      // 2. Limpiar del mapa de cada asignatura y persistir
      for (int j = 0; j < _subjects.length; j++) {
        final subject = _subjects[j];
        final updatedOverrides = Map<String, dynamic>.from(subject.overrides);

        // Eliminamos la clave del día y cualquier sesión que estuviera descartada (específicamente o por herencia)
        bool changedMap = false;
        if (updatedOverrides.containsKey(dateStr)) {
          updatedOverrides.remove(dateStr);
          changedMap = true;
        }

        updatedOverrides.removeWhere((key, value) {
          if (key.startsWith("$dateStr|") && (value['discarded'] == true || value['isDiscarded'] == true || value['discarded'] == false)) {
            // Nota: El discarded: false se usa como marcador en sesiones dentro de un día descartado
            changedMap = true;
            return true;
          }
          return false;
        });
        
        if (changedMap) {
          _subjects[j] = subject.copyWith(overrides: updatedOverrides);
          _saveLocalAndRemote('subjects', _subjects[j].id, _subjects[j].toJson());
        }
        
        // También limpiamos la lista legacy
        if (subject.discardedDates.contains(dateStr)) {
          final updatedDates = List<String>.from(subject.discardedDates)..remove(dateStr);
          _subjects[j] = _subjects[j].copyWith(discardedDates: updatedDates);
          _saveLocalAndRemote('subjects', _subjects[j].id, _subjects[j].toJson());
        }
      }
    }
    _rebuildOverridesFromSubjects();
    notifyListeners();
  }

  bool hasFutureDiscarded() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var subject in _subjects) {
      for (var dateStr in subject.discardedDates) {
        try {
          final parts = dateStr.split('/');
          final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          if (date.isAfter(today) || (date.year == today.year && date.month == today.month && date.day == today.day)) {
            return true;
          }
        } catch (_) {}
      }
    }

    return _overrides.any((o) =>
    o.isDiscarded &&
        (o.date.isAfter(today) || (o.date.year == today.year && o.date.month == today.month && o.date.day == today.day))
    );
  }

  void addMockData() {
    _subjects.clear();
    _notebooks.clear();
    _notes.clear();

    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    final uuid = const Uuid();

    final s1 = Subject(
      id: '1',
      name: 'Inteligencia Artificial',
      color: Colors.deepPurple,
      schedules: [
        for (var day in days)
          SubjectSchedule(
            id: uuid.v4(),
            day: day,
            startTime: const TimeOfDay(hour: 8, minute: 30),
            endTime: const TimeOfDay(hour: 10, minute: 0),
            room: 'CELEX',
          ),
      ],
    );
    _subjects.add(s1);
    _db.saveEntity('subjects', s1.id, s1.toJson());

    final s2 = Subject(
      id: '2',
      name: 'Machine Learning',
      color: Colors.teal,
      schedules: [
        SubjectSchedule(
          id: uuid.v4(),
          day: 'Lunes',
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 11, minute: 30),
          room: 'LC4',
        ),
        SubjectSchedule(
          id: uuid.v4(),
          day: 'Miércoles',
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 11, minute: 30),
          room: 'LC4',
        ),
        SubjectSchedule(
          id: uuid.v4(),
          day: 'Viernes',
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 11, minute: 30),
          room: 'LC4',
        ),
      ],
    );
    _subjects.add(s2);
    _db.saveEntity('subjects', s2.id, s2.toJson());

    final s3 = Subject(
      id: '3',
      name: 'Software Quality',
      color: Colors.pink,
      schedules: [
        SubjectSchedule(
          id: uuid.v4(),
          day: 'Martes',
          startTime: const TimeOfDay(hour: 11, minute: 30),
          endTime: const TimeOfDay(hour: 13, minute: 0),
          room: 'LC2',
        ),
        SubjectSchedule(
          id: uuid.v4(),
          day: 'Jueves',
          startTime: const TimeOfDay(hour: 11, minute: 30),
          endTime: const TimeOfDay(hour: 13, minute: 0),
          room: 'LC2',
        ),
      ],
    );
    _subjects.add(s3);
    _db.saveEntity('subjects', s3.id, s3.toJson());

    final s4 = Subject(
      id: '4',
      name: 'Sistemas en Chip',
      color: Colors.blue,
      schedules: [
        for (var day in ['Lunes', 'Martes', 'Miércoles'])
          SubjectSchedule(
            id: uuid.v4(),
            day: day,
            startTime: const TimeOfDay(hour: 14, minute: 0),
            endTime: const TimeOfDay(hour: 15, minute: 30),
            room: 'LE2',
          ),
      ],
    );
    _subjects.add(s4);
    _db.saveEntity('subjects', s4.id, s4.toJson());

    final s5 = Subject(
      id: '5',
      name: 'Proyecto Integrador',
      color: Colors.orange,
      schedules: [
        SubjectSchedule(
          id: uuid.v4(),
          day: 'Jueves',
          startTime: const TimeOfDay(hour: 7, minute: 0),
          endTime: const TimeOfDay(hour: 8, minute: 30),
          room: 'Lab Sim',
        ),
        SubjectSchedule(
          id: uuid.v4(),
          day: 'Viernes',
          startTime: const TimeOfDay(hour: 13, minute: 0),
          endTime: const TimeOfDay(hour: 14, minute: 30),
          room: 'Lab Sim',
        ),
      ],
    );
    _subjects.add(s5);
    _db.saveEntity('subjects', s5.id, s5.toJson());

    // Mock Notebooks
    final uniId = const Uuid().v4();
    final nb1 = Notebook(
      id: uniId,
      name: 'Universidad',
      icon: Icons.school_rounded,
      color: const Color(0xFF6366F1),
      createdAt: DateTime.now(),
    );
    _notebooks.add(nb1);
    _db.saveEntity('notebooks', nb1.id, nb1.toJson());

    final nb2 = Notebook(
      id: const Uuid().v4(),
      name: 'Proyectos',
      icon: Icons.rocket_launch_rounded,
      color: const Color(0xFF8B5CF6),
      createdAt: DateTime.now(),
    );
    _notebooks.add(nb2);
    _db.saveEntity('notebooks', nb2.id, nb2.toJson());

    // Mock Note inside notebook
    final note1 = Note(
      id: const Uuid().v4(),
      title: 'Apuntes de IA',
      content: jsonEncode([{"insert": "Estos son los apuntes de la clase de hoy sobre Redes Neuronales.\n"}]),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notebookId: uniId,
      pageType: PageType.ruled,
    );
    _notes.add(note1);
    _db.saveEntity('notes', note1.id, note1.toJson());

    // Mock Reminders
    final now = DateTime.now();
    final r1 = Reminder(
      id: '1',
      title: 'Entrega de Proyecto',
      date: '${now.day}/${now.month}/${now.year}',
      category: 'Proyectos',
      dateTime: now,
      isUrgent: true,
      isAllDay: false,
    );
    _reminders.add(r1);
    _db.saveEntity('reminders', r1.id, r1.toJson());

    final r2 = Reminder(
      id: '2',
      title: 'Examen de Redes',
      date: '${now.day}/${now.month}/${now.year}',
      category: 'Exámenes',
      dateTime: now,
      isUrgent: true,
      isAllDay: false,
    );
    _reminders.add(r2);
    _db.saveEntity('reminders', r2.id, r2.toJson());

    final r3 = Reminder(
      id: '3',
      title: 'Conferencia de IA',
      date: '${now.day}/${now.month}/${now.year}',
      time: '18:00',
      category: 'Eventos',
      location: 'Auditorio Principal',
      dateTime: now,
      isAllDay: false,
    );
    _reminders.add(r3);
    _db.saveEntity('reminders', r3.id, r3.toJson());

    // Multi-day sample events (September 2026)
    final sep1 = DateTime(2026, 9, 1);
    final sep2 = DateTime(2026, 9, 2);
    final sep3 = DateTime(2026, 9, 3);
    final sep4 = DateTime(2026, 9, 4);
    final sep6 = DateTime(2026, 9, 6);

    final conf = Reminder(
      id: 'multi_1',
      title: 'Annual Conference',
      date: '01/09/2026',
      category: 'Evento',
      location: 'Convention Center',
      dateTime: sep1,
      endDate: sep3,
      isAllDay: true,
    );
    _reminders.add(conf);
    _db.saveEntity('reminders', conf.id, conf.toJson());

    final workshop = Reminder(
      id: 'multi_2',
      title: 'Project Workshop',
      date: '02/09/2026',
      category: 'Evento',
      location: 'Meeting Room B',
      dateTime: sep2,
      endDate: sep3,
      isAllDay: true,
    );
    _reminders.add(workshop);
    _db.saveEntity('reminders', workshop.id, workshop.toJson());

    final retreat = Reminder(
      id: 'multi_3',
      title: 'Team Retreat',
      date: '04/09/2026',
      category: 'Evento',
      location: 'Mountain Resort',
      dateTime: sep4,
      endDate: sep6,
      isAllDay: true,
    );
    _reminders.add(retreat);
    _db.saveEntity('reminders', retreat.id, retreat.toJson());

    // Mock Notifications
    final n1 = AppNotification(
      id: '1',
      title: '¡Bienvenido a Nest!',
      body: 'Tu estudio, en sintonía. Comienza organizando tu horario.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      icon: Icons.auto_awesome_rounded,
      iconColor: Colors.amber,
    );
    _notifications.add(n1);
    _db.saveEntity('notifications', n1.id, n1.toJson());

    final n2 = AppNotification(
      id: '2',
      title: 'Nuevo recurso disponible',
      body: 'Hemos añadido nuevas plantillas para tus notas.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.edit_note_rounded,
      iconColor: Colors.blue,
    );
    _notifications.add(n2);
    _db.saveEntity('notifications', n2.id, n2.toJson());

    // Mock Groups
    _groups.clear();
    final g1 = Group(
      id: 'g1',
      name: 'Pruebas',
      inviteCode: '9C5D97',
      members: ['Javier', 'Ana', 'Carlos'],
      admins: ['Javier'],
      posts: [
        GroupPost(
          id: 'p1',
          author: 'Ana',
          title: '¿Apuntes?',
          content: '¿Alguien tiene los apuntes de la clase pasada?',
          images: [],
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ],
      sharedNotes: [
        Note(
          id: 'gn1',
          author: 'Ana',
          title: 'Resumen Unidad 1',
          content: jsonEncode([{"insert": "Conceptos básicos de IA...\n"}]),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
      sharedReminders: [
        Reminder(
          id: 'gr1',
          author: 'Carlos',
          title: 'Entrega de Tarea 1',
          date: '25/10/2023',
          category: 'Tareas',
          dateTime: DateTime(2023, 10, 25),
        ),
      ],
      polls: [
        GroupPoll(
          id: 'pol1',
          author: 'Carlos',
          question: '¿Cuándo nos reunimos para el proyecto?',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          options: [
            PollOption(text: 'Lunes 4pm', votes: 1, votedBy: ['Ana']),
            PollOption(text: 'Martes 5pm', votes: 1, votedBy: ['Carlos']),
          ],
        ),
      ],
    );
    _groups.add(g1);
    _db.saveEntity('groups', g1.id, g1.toJson());

    final g2 = Group(
      id: 'g2',
      name: 'Tareas',
      inviteCode: '998DDE',
      members: ['Javier', 'Elena'],
      admins: ['Javier'],
    );
    _groups.add(g2);
    _db.saveEntity('groups', g2.id, g2.toJson());

    // Mock Projects
    _projects.clear();
    final pr1 = Project(
      id: 'proj1',
      title: 'Rediseño de App',
      description: 'Mejorar la interfaz de usuario de Nest Studio',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 20)),
      createdAt: DateTime.now().subtract(const Duration(days: 11)),
      isIndependent: false,
      groupId: 'g1',
      members: ['Javier', 'Ana', 'Carlos'],
      progress: 0.65,
      phases: [
        ProjectPhase(
          id: 'ph1',
          title: 'Diseño UI/UX',
          isCompleted: true,
          tasks: [
            ProjectTask(id: 't1', title: 'Definir paleta de colores', isCompleted: true, assignedTo: 'Javier'),
            ProjectTask(id: 't2', title: 'Crear prototipos', isCompleted: true, assignedTo: 'Ana'),
          ],
        ),
        ProjectPhase(
          id: 'ph2',
          title: 'Desarrollo Frontend',
          isCompleted: false,
          tasks: [
            ProjectTask(id: 't3', title: 'Implementar temas', isCompleted: false, assignedTo: 'Carlos'),
          ],
        ),
      ],
      currentPhaseIndex: 1,
    );
    _projects.add(pr1);
    _db.saveEntity('projects', pr1.id, pr1.toJson());

    final pr2 = Project(
      id: 'proj2',
      title: 'Tesis de Grado',
      description: 'Investigación sobre IA en la educación',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 90)),
      createdAt: DateTime.now().subtract(const Duration(days: 31)),
      isIndependent: true,
      progress: 0.15,
      members: ['Javier'],
      phases: [
        ProjectPhase(
          id: 'ph3',
          title: 'Investigación Preliminar',
          tasks: [
            ProjectTask(id: 't4', title: 'Estado del arte', isCompleted: false),
          ],
        ),
      ],
      currentPhaseIndex: 0,
    );
    _projects.add(pr2);
    _db.saveEntity('projects', pr2.id, pr2.toJson());

    // Mock Focus Sessions
    _focusSessions.clear();
    final fs1 = FocusSession(
      id: 'focus1',
      title: 'Sprint de Diseño',
      groupId: 'g1',
      creatorId: 'Ana',
      participants: ['Javier', 'Ana', 'Carlos'],
      status: FocusSessionStatus.focusing,
      startTime: DateTime.now().subtract(const Duration(minutes: 6, seconds: 15)),
    );
    _focusSessions.add(fs1);
    _db.saveEntity('focus_sessions', fs1.id, fs1.toJson());

    final fs2 = FocusSession(
      id: 'focus2',
      title: 'Repaso Examen',
      groupId: 'g2',
      creatorId: 'Javier',
      participants: ['Javier'],
      status: FocusSessionStatus.idle,
      scheduledFor: DateTime.now().add(const Duration(hours: 3)),
    );
    _focusSessions.add(fs2);
    _db.saveEntity('focus_sessions', fs2.id, fs2.toJson());

    notifyListeners();
  }
}

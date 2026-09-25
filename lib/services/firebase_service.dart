import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '498676147966-jcss6cllvoqcl5nsljf35840671r4pbh.apps.googleusercontent.com' : null,
    serverClientId: kIsWeb ? null : '498676147966-jcss6cllvoqcl5nsljf35840671r4pbh.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
      'openid',
    ],
  );

  static String? _cachedNestId;
  static String? _customPhotoUrl;

  String? get userId => _auth.currentUser?.uid;
  String? get userEmail => _auth.currentUser?.email;
  String? get userName => _auth.currentUser?.displayName;
  String? get userPhotoUrl {
    String? url = _customPhotoUrl ?? _auth.currentUser?.photoURL;
    if (url == null || url.isEmpty) {
      final providerData = _auth.currentUser?.providerData;
      if (providerData != null) {
        for (final info in providerData) {
          if (info.photoURL != null && info.photoURL!.isNotEmpty) {
            url = info.photoURL;
            break;
          }
        }
      }
    }
    if (url != null && url.isNotEmpty && url.contains('googleusercontent.com') && !url.contains('=s')) {
      url = '$url=s200-c';
    }
    return url;
  }
  
  void setCustomPhotoUrl(String? url) {
    _customPhotoUrl = url;
  }
  
  String get nestId {
    if (_cachedNestId != null) return _cachedNestId!;
    if (userId == null) return 'N-0000';
    return 'N-${userId!.hashCode.abs().toString().padLeft(4, '0').substring(0, 4)}';
  }
  bool get isAuthenticated => _auth.currentUser != null;
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential credentialResult = await _auth.signInWithCredential(credential);
    final user = credentialResult.user;

    debugPrint("FirebaseService: signInWithGoogle complete. googleUser.photoUrl: ${googleUser.photoUrl}, user.photoURL: ${user?.photoURL}");

    String? photoUrl = googleUser.photoUrl ?? user?.photoURL;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.contains('googleusercontent.com') && !photoUrl.contains('=s')) {
        photoUrl = '$photoUrl=s200-c';
      }
      setCustomPhotoUrl(photoUrl);
      if (user != null) {
        await saveUserProfile(user.uid, {
          'photoUrl': photoUrl,
          'username': user.displayName ?? '',
          'email': user.email ?? '',
        });
      }
    }

    return credentialResult;
  }

  // Generic method to sync an entity to Firestore
  Future<void> syncEntity(String collection, String id, Map<String, dynamic> data) async {
    if (!isAuthenticated) return;
    
    if (collection == 'groups') {
      final Map<String, dynamic> filteredData = Map.from(data);
      filteredData.remove('posts');
      filteredData.remove('mensajes');
      filteredData.remove('sharedNotes');
      filteredData.remove('sharedReminders');
      filteredData.remove('polls');
      
      // Protección: No sobrescribir miembros con lista vacía si parece que es un error de carga local
      final List? members = filteredData['memberIds'] ?? filteredData['members'];
      if (members != null && members.isEmpty) {
        debugPrint('FirebaseService: Bloqueada actualización de grupo con miembros vacíos para evitar pérdida de acceso.');
        filteredData.remove('memberIds');
        filteredData.remove('members');
      }
      
      /*
      await _db.collection('groups').doc(id).set(filteredData, SetOptions(merge: true));
    } else if (collection == 'focus_sessions' && data['groupId'] != null) {
      // Sesiones grupales: Ubicación global compartida
      await _db.collection('focus_sessions').doc(id).set(data, SetOptions(merge: true));
      */
    } else {
      await _db.collection('users').doc(userId).collection(collection).doc(id).set(data);
    }
  }

  // Delete an entity from Firestore
  Future<void> deleteEntity(String collection, String id) async {
    if (!isAuthenticated) return;
    
    if (collection == 'groups') {
      await _db.collection('groups').doc(id).delete();
    } else {
      /*
      // Intentamos borrar de ambos sitios por seguridad si es una sesión
      if (collection == 'focus_sessions') {
        await _db.collection('focus_sessions').doc(id).delete();
      }
      */
      await _db.collection('users').doc(userId).collection(collection).doc(id).delete();
    }
  }

  // Batch save for a collection
  Future<void> saveBatch(String collection, List<Map<String, dynamic>> items) async {
    if (!isAuthenticated) return;
    
    final userDocRef = _db.collection('users').doc(userId);
    final subColRef = userDocRef.collection(collection);
    
    final batch = _db.batch();
    
    // 1. Update or create
    final List<String> localIds = [];
    for (var item in items) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) continue; 
      
      localIds.add(id);
      batch.set(subColRef.doc(id), item);
    }

    // 2. Clean Deleted (Comparison with cloud)
    // Solo realizamos la limpieza si tenemos datos locales, para evitar borrar 
    // la nube en un inicio de sesión limpio en un nuevo dispositivo.
    if (items.isNotEmpty) {
      final cloudDocs = await subColRef.get();
      for (var doc in cloudDocs.docs) {
        if (!localIds.contains(doc.id)) {
          batch.delete(doc.reference);
        }
      }
    }

    await batch.commit();
  }

  // Cleanup Legacy Fields from Root Document
  Future<void> cleanLegacyFields() async {
    if (!isAuthenticated) return;
    await _db.collection('users').doc(userId).set({
      'reminders': FieldValue.delete(),
      'notes': FieldValue.delete(),
      'schedule': FieldValue.delete(),
      'subjects': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  // Fetch all entities of a type
  Future<List<Map<String, dynamic>>> fetchCollection(String collection) async {
    if (!isAuthenticated) return [];
    
    final targetCollection = collection == 'subjects' ? 'schedule' : collection;
    QuerySnapshot snapshot;
    
    if (collection == 'groups') {
      // Para grupos, buscamos donde el usuario sea miembro o administrador
      // Primero intentamos con memberIds (formato legacy)
      snapshot = await _db.collection('groups').where('memberIds', arrayContains: userId).get();
      
      if (snapshot.docs.isEmpty) {
        // Si no hay resultados, intentamos con members (formato nuevo)
        snapshot = await _db.collection('groups').where('members', arrayContains: userId).get();
      }
    } else {
      snapshot = await _db.collection('users').doc(userId).collection(collection).get();
    }
    
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<Map<String, dynamic>?> getGroupByInviteCode(String code) async {
    final snapshot = await _db.collection('groups').where('inviteCode', isEqualTo: code).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    data['id'] = snapshot.docs.first.id;
    return data;
  }

  // Listen for changes (Real-time)
  Stream<List<Map<String, dynamic>>> getCollectionStream(String collection, {List<String>? groupIds}) {
    if (!isAuthenticated) return Stream.value([]);
    
    final targetCollection = collection == 'subjects' ? 'schedule' : collection;
    
    if (targetCollection == 'groups') {
      // Escuchamos grupos donde el usuario es miembro o admin.
      // Intentamos con memberIds primero por compatibilidad legacy.
      return _db.collection('groups').where('memberIds', arrayContains: userId).snapshots().map((snap) {
        debugPrint('FirebaseService: Grupos recibidos del stream para el usuario $userId: ${snap.docs.length}');
        return snap.docs.map((doc) => {
          ...doc.data(), 
          'id': doc.id,
          'docId': doc.id // Asegurar que el ID del documento esté disponible bajo ambos nombres
        }).toList();
      });
    }

    if (targetCollection == 'focus_sessions' && groupIds != null && groupIds.isNotEmpty) {
      // Escuchar sesiones de mis grupos + mis sesiones privadas
      return _db.collection('focus_sessions').where('groupId', whereIn: groupIds).snapshots().map(
        (snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList()
      );
    }

    return _db.collection('users').doc(userId).collection(collection).snapshots().map(
      (snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList()
    );
  }

  // User Auth
  Future<UserCredential> loginAnonymously() async {
    return await _auth.signInAnonymously();
  }

  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> loginWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = credential.user;
    if (user != null) {
      String? photoUrl = user.photoURL;
      if (photoUrl == null || photoUrl.isEmpty) {
        for (final info in user.providerData) {
          if (info.photoURL != null && info.photoURL!.isNotEmpty) {
            photoUrl = info.photoURL;
            break;
          }
        }
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        if (photoUrl.contains('googleusercontent.com') && !photoUrl.contains('=s')) {
          photoUrl = '$photoUrl=s200-c';
        }
        setCustomPhotoUrl(photoUrl);
      }
    }
    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    ActionCodeSettings? actionCodeSettings;
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        actionCodeSettings = ActionCodeSettings(
          url: '$origin/?mode=resetPassword',
          handleCodeInApp: true,
        );
      } catch (e) {
        debugPrint("Error creating ActionCodeSettings: $e");
      }
    }
    await _auth.sendPasswordResetEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }

  Future<void> saveUserProfile(String uid, Map<String, dynamic> profile) async {
    // Aseguramos que el identificador esté presente en el perfil
    if (!profile.containsKey('userIdentifier')) {
      profile['userIdentifier'] = nestId;
    }
    await _db.collection('users').doc(uid).set(profile, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserByNestId(String nestId) async {
    final searchId = nestId.trim().toUpperCase();
    debugPrint('FirebaseService: Buscando usuario con ID: $searchId');
    
    // Buscamos en el campo estándar
    final snapshot = await _db.collection('users')
        .where('userIdentifier', isEqualTo: searchId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      data['uid'] = snapshot.docs.first.id;
      debugPrint('FirebaseService: Usuario encontrado: ${data['username']}');
      return data;
    }

    // Por si acaso, buscamos en minúsculas (legacy)
    final snapshotLegacy = await _db.collection('users')
        .where('useridentifier', isEqualTo: searchId)
        .limit(1)
        .get();

    if (snapshotLegacy.docs.isNotEmpty) {
      final data = snapshotLegacy.docs.first.data();
      data['uid'] = snapshotLegacy.docs.first.id;
      debugPrint('FirebaseService: Usuario encontrado (legacy ID): ${data['username']}');
      return data;
    }
    
    debugPrint('FirebaseService: No se encontró ningún usuario con ID: $searchId');
    return null;
  }

  Future<void> saveAppearanceSettings(String uid, Map<String, dynamic> settings) async {
    await _db.collection('users').doc(uid).set({
      'appearance': settings,
    }, SetOptions(merge: true));
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> reauthenticate(String email, String password) async {
    final credential = EmailAuthProvider.credential(email: email, password: password);
    await _auth.currentUser?.reauthenticateWithCredential(credential);
  }

  Future<void> reauthenticateWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Cancelado por el usuario');
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.currentUser?.reauthenticateWithCredential(credential);
  }

  bool get hasPasswordProvider => _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ?? false;
  bool get hasGoogleProvider => _auth.currentUser?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null && data.containsKey('userIdentifier')) {
      _cachedNestId = data['userIdentifier'];
    }
    return data;
  }

  Future<bool> isAliasAvailable(String alias, {String? excludeUserId}) async {
    try {
      final snapshot = await _db.collection('users')
          .where('alias', isEqualTo: alias)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return true;
      if (excludeUserId != null && snapshot.docs.first.id == excludeUserId) return true;
      return false;
    } catch (e) {
      // Si el usuario aún no está autenticado y las reglas de seguridad de Firestore
      // restringen la consulta de usuarios, permitimos continuar.
      return true;
    }
  }

  Future<void> signOut() async {
    _customPhotoUrl = null;
    _cachedNestId = null;
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> deleteUserSubcollectionsAndProfile(String uid) async {
    final collections = ['notes', 'reminders', 'subjects', 'projects', 'notebooks', 'notifications', 'focusSessions', 'contacts'];
    for (var col in collections) {
      try {
        final snapshot = await _db.collection('users').doc(uid).collection(col).get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("FirebaseService: Error clearing subcollection $col for $uid: $e");
      }
    }
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint("FirebaseService: Error deleting user doc $uid: $e");
    }
  }

  Future<void> deleteAuthUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      debugPrint("FirebaseService: Error deleting Firebase Auth user: $e");
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Listen to the root user document (Java format)
  Stream<Map<String, dynamic>?> getUserDocumentStream() {
    if (!isAuthenticated) return Stream.value(null);
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (data != null && data.containsKey('userIdentifier')) {
        _cachedNestId = data['userIdentifier'];
      }
      return data;
    });
  }

  // --- Subcollections for Groups ---

  Future<void> syncGroupPost(String groupId, String postId, Map<String, dynamic> data) async {
    if (!isAuthenticated) return;
    await _db.collection('groups').doc(groupId).collection('posts').doc(postId).set(data);
  }

  Stream<List<Map<String, dynamic>>> getGroupPostsStream(String groupId) {
    // Stream con reintento automático y manejo de errores para evitar que el muro desaparezca
    return _db.collection('groups').doc(groupId).collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('FirebaseService: Error en stream de posts para $groupId: $error');
          // Podríamos lanzar un error personalizado o devolver un stream vacío temporalmente
        })
        .map((snap) => snap.docs.map((doc) => {
          ...doc.data(), 
          'id': doc.id,
          'docId': doc.id
        }).toList());
  }

  Future<void> syncGroupPoll(String groupId, String pollId, Map<String, dynamic> data) async {
    if (!isAuthenticated) return;
    await _db.collection('groups').doc(groupId).collection('posts').doc(pollId).set(data);
  }

  Stream<List<Map<String, dynamic>>> getGroupPollsStream(String groupId) {
    return _db.collection('groups').doc(groupId).collection('posts').where('type', isEqualTo: 'POLL').snapshots().map(
      (snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList()
    );
  }

  Future<void> deleteGroupItem(String groupId, String subCollection, String itemId) async {
    if (!isAuthenticated) return;
    await _db.collection('groups').doc(groupId).collection(subCollection).doc(itemId).delete();
  }

  // --- Friend Requests ---

  Stream<List<Map<String, dynamic>>> getFriendRequestsStream() {
    if (!isAuthenticated) return Stream.value([]);
    return _db.collection('friend_requests')
        .where('toId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> updateFriendRequestStatus(String requestId, String status) async {
    await _db.collection('friend_requests').doc(requestId).update({'status': status});
  }

  // --- Storage ---

  Future<String?> uploadFile(String path, dynamic fileSource) async {
    if (!isAuthenticated) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      if (kIsWeb) {
        if (fileSource is Uint8List) {
          await ref.putData(fileSource);
        } else {
          // Si es XFile o File, intentamos leer bytes
          await ref.putData(await fileSource.readAsBytes());
        }
      } else {
        if (fileSource is File) {
          await ref.putFile(fileSource);
        } else {
          await ref.putFile(File(fileSource.path));
        }
      }
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('FirebaseService: Error uploading file: $e');
      return null;
    }
  }
}

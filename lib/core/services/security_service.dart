import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import '../../core/di/service_locator.dart';

class SecurityService {
  final StorageService _storage = sl<StorageService>();
  // Getters para acceso diferido (evita error [core/no-app])
  FirebaseAuth get _auth {
    if (!isFirebaseReady) throw FirebaseException(plugin: 'auth', message: 'Firebase not initialized');
    return FirebaseAuth.instance;
  }
  FirebaseFirestore get _firestore {
    if (!isFirebaseReady) throw FirebaseException(plugin: 'firestore', message: 'Firebase not initialized');
    return FirebaseFirestore.instance;
  }
  
  late final gsi.GoogleSignIn _googleSignIn;

  SecurityService() {
    _googleSignIn = gsi.GoogleSignIn(
      clientId: kIsWeb 
          ? '474933138096-i9m8vn3qonujq4qgnq75jhu80flm6lsj.apps.googleusercontent.com' 
          : null,
    );
  }
  
  static const String _keyUserEmail = 'user_email';
  static const String _keyIsActivated = 'is_activated';

  /// Lista de correos con privilegios de administrador.
  /// TODO: Migrar a roles definidos en Firestore para mayor escalabilidad.
  static const List<String> _adminEmails = [
    'brizq02@gmail.com',
    'admin@psicolearn.com',
  ];

  String? _deviceId;
  String? _cachedRole;
  StreamSubscription? _sessionSubscription;
  final ValueNotifier<bool> isLocked = ValueNotifier<bool>(false);

  bool get isFirebaseReady => Firebase.apps.isNotEmpty;
  User? get currentUser => isFirebaseReady ? _auth.currentUser : null;

  bool get isAdmin {
    final email = currentUser?.email;
    if (email == null) return false;
    // Fallback de seguridad (hardcoded) + check de rol cacheado
    return _adminEmails.contains(email) || _cachedRole == 'admin';
  }

  bool get isPremium {
    return true;
  }

  /// Obtiene el ID único del dispositivo
  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    // Intentar recuperar ID persistente del storage primero
    final savedId = _storage.getString('persistent_device_id');
    if (savedId != null) {
      _deviceId = savedId;
      return _deviceId!;
    }

    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      // Generar un ID basado en hardware/browser + un componente aleatorio para unicidad
      final randomPart = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      _deviceId = 'WEB-${webInfo.vendor}-${webInfo.platform}-$randomPart'.toUpperCase();
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = 'AND-${androidInfo.id}'.toUpperCase();
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _deviceId = 'IOS-${iosInfo.identifierForVendor}'.toUpperCase();
    } else if (Platform.isWindows) {
      final winInfo = await deviceInfo.windowsInfo;
      _deviceId = 'WIN-${winInfo.deviceId}'.toUpperCase();
    } else {
      _deviceId = 'UNKNOWN-${DateTime.now().millisecondsSinceEpoch}'.toUpperCase();
    }
    
    // Guardar para que sea persistente en este dispositivo
    await _storage.setString('persistent_device_id', _deviceId!);
    return _deviceId!;
  }

  /// Verifica si la aplicación está activada para este dispositivo
  Future<bool> checkActivation() async {
    // Si Firebase no está listo (ej. en web sin config), usamos el estado local
    if (!isFirebaseReady) {
      if (kDebugMode && !kIsWeb && Platform.isWindows) return true;
      return _storage.getBool(_keyIsActivated) ?? false;
    }

    final email = _auth.currentUser?.email;
    if (email == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(email).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final bool active = data['active'] ?? false;
      _cachedRole = data['role'] ?? 'user';
      if (!active) return false;

      await _storage.setBool(_keyIsActivated, true);
      return true;
    } catch (e) {
      debugPrint('⚠️ SecurityService: Error en checkActivation: $e');
      
      // Permitir acceso en debug Windows incluso si falla la red
      if (kDebugMode && !kIsWeb && Platform.isWindows) return true;
      
      return false; // Retornar false para forzar login/free mode si falla
    }
  }

  /// Establece el modo gratuito (no persistente por seguridad, se re-evalúa al iniciar)
  Future<void> setFreeMode() async {
    await _storage.setBool(_keyIsActivated, false);
  }

  /// Activa el dispositivo
  Future<void> activate(String email) async {
    await _firestore.collection('users').doc(email).set({
      'email': email,
      'active': true,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _storage.setString(_keyUserEmail, email);
    await _storage.setBool(_keyIsActivated, true);
  }

  /// Escucha en tiempo real si el ID del dispositivo cambia en la nube
  void _startSessionVigilance(String email) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _firestore
        .collection('users')
        .doc(email)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final String? lastId = data['last_device_id'];
        final currentId = await getDeviceId();

        if (lastId != null && lastId != currentId) {
          isLocked.value = true;
          debugPrint('¡SESIÓN CERRADA! Iniciada en otro dispositivo.');
        }
      }
    });
  }

  /// Iniciar sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      final gsi.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final gsi.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null && user.email != null) {
        // Registrar en Firestore si es nuevo (pero con active: false por defecto)
        final userDoc = await _firestore.collection('users').doc(user.email).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.email).set({
            'email': user.email,
            'displayName': user.displayName,
            'active': false, // Requiere aprobación del admin
            'role': 'user',
            'created_at': FieldValue.serverTimestamp(),
          });
          _cachedRole = 'user';
        } else {
          _cachedRole = userDoc.data()?['role'] ?? 'user';
        }
        await _storage.setString(_keyUserEmail, user.email!);
      }
      
      return user;
    } catch (e) {
      debugPrint('Error en Google Sign-In: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await _storage.remove(_keyUserEmail);
    await _storage.remove(_keyIsActivated);
  }

  // --- MÉTODOS DE ADMINISTRADOR ---

  /// Obtener flujo de todos los usuarios (solo para admin)
  Stream<QuerySnapshot> getUsersStream() {
    return _firestore.collection('users').snapshots();
  }

  /// Cambiar estado de activación de un usuario
  Future<void> toggleUserStatus(String email, bool newStatus) async {
    await _firestore.collection('users').doc(email).update({
      'active': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Eliminar usuario (resetear ID para que pueda usar otro dispositivo)
  Future<void> resetUserDevice(String email) async {
    await _firestore.collection('users').doc(email).update({
      'last_device_id': null,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Eliminar definitivamente un usuario de la base de datos
  Future<void> deleteUser(String email) async {
    await _firestore.collection('users').doc(email).delete();
  }

  void dispose() {
    _sessionSubscription?.cancel();
    isLocked.dispose();
  }
}

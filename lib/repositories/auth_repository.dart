import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

class AuthRepository {
  final Box<User> _userBox;
  final Box _sessionBox; // Used to store active session
  final _uuid = const Uuid();

  AuthRepository(this._userBox, this._sessionBox);

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<User?> login(String email, String password) async {
    final hash = _hashPassword(password);
    print('DEBUG: Attempting login for email: $email');
    print('DEBUG: Password hash: $hash');
    print('DEBUG: Total users in box: ${_userBox.length}');

    try {
      final user = _userBox.values.firstWhere(
        (u) {
          final match = u.email.toLowerCase() == email.toLowerCase() && u.passwordHash == hash;
          if (u.email.toLowerCase() == email.toLowerCase()) {
            print('DEBUG: Found user with matching email. Password match: ${u.passwordHash == hash}');
          }
          return match;
        },
      );
      print('DEBUG: Login successful for user: ${user.name}');
      // Persist session
      await _sessionBox.put('active_user_id', user.id);
      return user;
    } catch (e) {
      print('DEBUG: Login failed for $email. Error: $e');
      print('DEBUG: Registered emails in box: ${_userBox.values.map((u) => u.email).toList()}');
      return null;
    }
  }

  Future<User> signup(String name, String email, String password) async {
    // Check if email already exists
    final exists = _userBox.values.any((u) => u.email.toLowerCase() == email.toLowerCase());
    if (exists) {
      throw Exception('An account with this email already exists.');
    }

    final user = User(
      id: _uuid.v4(),
      name: name,
      email: email,
      passwordHash: _hashPassword(password),
      createdAt: DateTime.now(),
    );

    await _userBox.put(user.id, user);
    
    // Auto login
    await _sessionBox.put('active_user_id', user.id);
    return user;
  }

  Future<void> logout() async {
    await _sessionBox.delete('active_user_id');
  }

  User? getCurrentUser() {
    final id = _sessionBox.get('active_user_id');
    if (id == null) return null;

    try {
      return _userBox.get(id);
    } catch (_) {
      return null;
    }
  }

  bool get isLoggedIn => _sessionBox.containsKey('active_user_id');
}

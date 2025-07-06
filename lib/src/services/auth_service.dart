import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase.dart';
import '../models/user.dart';

class AuthService {
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userPhoneKey = 'user_phone';
  static const _userEmailKey = 'user_email';

  Future<User?> signUpCustomer(String name, String email, String password, String? phone) async {
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      if (response.user != null) {
        final userData = {
          'id': response.user!.id,
          'name': name,
          'email': email,
          'phone': phone,
        };

        // Check if user already exists
        final existing = await SupabaseConfig.client
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (existing == null) {
          await SupabaseConfig.client.from('users').insert(userData);
        }

        final user = User.fromJson(userData);
        await _saveUserToPrefs(user);
        return user;
      }
    } catch (e) {
      print('Sign-up error: $e');
    }

    return null;
  }

  Future<User?> signInCustomer(String email, String password) async {
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final id = response.user!.id;

        final userData = await SupabaseConfig.client
            .from('users')
            .select()
            .eq('id', id)
            .maybeSingle();

        if (userData != null) {
          final user = User.fromJson(userData);
          await _saveUserToPrefs(user);
          return user;
        }
      }
    } catch (e) {
      print('Sign-in error: $e');
    }

    return null;
  }

  Future<bool> signInAdmin(String email, String password) async {
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      const allowedAdminUID = 'c57e0905-e042-4f74-b9bd-80e86316422f';

      if (response.user?.id != allowedAdminUID) {
        await SupabaseConfig.client.auth.signOut();
        return false;
      }

      return true;
    } catch (e) {
      print('Admin sign-in error: $e');
      return false;
    }
  }

  Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userNameKey, user.name);
    await prefs.setString(_userEmailKey, user.email);
    if (user.phone != null) {
      await prefs.setString(_userPhoneKey, user.phone!);
    } else {
      await prefs.remove(_userPhoneKey);
    }
  }

  Future<User?> getUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_userIdKey);
    final name = prefs.getString(_userNameKey);
    final email = prefs.getString(_userEmailKey);
    final phone = prefs.getString(_userPhoneKey);

    if (id != null && name != null && email != null) {
      return User(id: id, name: name, email: email, phone: phone);
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userEmailKey);
    await SupabaseConfig.client.auth.signOut();
  }
}

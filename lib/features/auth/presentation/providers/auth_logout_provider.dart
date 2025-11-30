import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:boticart/features/auth/data/services/persistent_auth_service.dart';

class AuthLogoutNotifier extends StateNotifier<AsyncValue<void>> {
  AuthLogoutNotifier() : super(const AsyncValue.data(null));

  Future<void> logout() async {
    state = const AsyncValue.loading();

    try {
      await FirebaseAuth.instance.signOut();
      await PersistentAuthService.clearLoginState();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final authLogoutProvider =
    StateNotifierProvider<AuthLogoutNotifier, AsyncValue<void>>((ref) {
      return AuthLogoutNotifier();
    });

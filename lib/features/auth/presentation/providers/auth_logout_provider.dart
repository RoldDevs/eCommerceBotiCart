import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:boticart/features/auth/data/services/persistent_auth_service.dart';
import 'package:boticart/features/pharmacy/presentation/providers/chat_providers.dart';
import 'package:boticart/features/pharmacy/presentation/providers/pharmacy_providers.dart';
import 'package:boticart/features/pharmacy/presentation/providers/cart_provider.dart';

class AuthLogoutNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  
  AuthLogoutNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> logout() async {
    state = const AsyncValue.loading();

    try {
      // Clear chat-related providers before logout
      _ref.invalidate(userConversationsProvider);
      _ref.invalidate(filteredUserConversationsProvider);
      _ref.invalidate(unreadChatConversationCountProvider);
      _ref.read(selectedConversationIdProvider.notifier).state = null;
      _ref.read(selectedPharmacyForChatProvider.notifier).state = null;
      
      // Clear cart and user-specific state
      _ref.read(cartProvider.notifier).clearCart();
      _ref.read(favoritesProvider.notifier).state = [];
      _ref.read(selectedPharmacyStoreIdProvider.notifier).state = null;
      _ref.read(selectionModeProvider.notifier).state = false;
      _ref.read(selectAllProvider.notifier).state = false;
      _ref.read(cartSearchProvider.notifier).state = '';
      
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
      return AuthLogoutNotifier(ref);
    });

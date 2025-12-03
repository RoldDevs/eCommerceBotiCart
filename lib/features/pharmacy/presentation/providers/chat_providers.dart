import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/pharmacy.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import 'pharmacy_providers.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(firestore: FirebaseFirestore.instance);
});

final userConversationsProvider = StreamProvider.autoDispose<List<ChatConversation>>((ref) {
  final userAsyncValue = ref.watch(currentUserProvider);
  final repository = ref.watch(chatRepositoryProvider);

  return userAsyncValue.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return repository.getUserConversations(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final filteredUserConversationsProvider =
    StreamProvider.autoDispose<List<ChatConversation>>((ref) {
      final conversationsAsyncValue = ref.watch(userConversationsProvider);
      final selectedStoreId = ref.watch(selectedPharmacyStoreIdProvider);
      final pharmaciesAsyncValue = ref.watch(pharmaciesStreamProvider);

      return conversationsAsyncValue.when(
        data: (conversations) {
          if (selectedStoreId == null) return Stream.value([]);

          return pharmaciesAsyncValue.when(
            data: (pharmacies) {
              final selectedPharmacy = pharmacies.firstWhere(
                (p) => p.storeID == selectedStoreId,
                orElse: () => throw Exception('Pharmacy not found'),
              );

              final filteredConversations = conversations
                  .where(
                    (conversation) =>
                        conversation.pharmacyId == selectedPharmacy.id,
                  )
                  .toList();

              return Stream.value(filteredConversations);
            },
            loading: () => Stream.value([]),
            error: (_, __) => Stream.value([]),
          );
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
    });

final conversationMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, conversationId) {
      final repository = ref.watch(chatRepositoryProvider);
      return repository.getConversationMessages(conversationId);
    });

final selectedConversationIdProvider = StateProvider<String?>((ref) => null);

final selectedPharmacyForChatProvider = StateProvider<Pharmacy?>((ref) => null);

// Provider for unread chat conversation count
final unreadChatConversationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final conversationsAsyncValue = ref.watch(userConversationsProvider);

  return conversationsAsyncValue.when(
    data: (conversations) {
      final unreadCount = conversations
          .where((conversation) => conversation.hasUnreadMessages)
          .length;
      return Stream.value(unreadCount);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/help_chat_repository_impl.dart';
import '../../domain/entities/help_chat_message.dart';
import '../../domain/repositories/help_chat_repository.dart';

final helpChatRepositoryProvider = Provider<HelpChatRepository>((ref) {
  return HelpChatRepositoryImpl(
    firestore: FirebaseFirestore.instance,
  );
});

final userChatMessagesProvider = StreamProvider.family<List<HelpChatMessage>, String>((ref, userUID) {
  final repository = ref.watch(helpChatRepositoryProvider);
  return repository.getUserChatMessages(userUID);
});

final currentUserUIDProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import 'auth_providers.dart';

final currentUserProvider = StreamProvider<UserEntity?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) return null;
        
        final data = snapshot.data()!;
        
        List<String> addresses = [];
        if (data['addresses'] != null) {
          addresses = List<String>.from(data['addresses']);
        }
        
        String? defaultAddress;
        if (data['defaultAddress'] != null) {
          defaultAddress = data['defaultAddress'] as String;
        }
        
        return UserEntity(
          id: user.uid,
          firstName: data['firstName'] as String,
          lastName: data['lastName'] as String,
          email: data['email'] as String,
          contact: data['contact'] as String,
          address: data['address'] as String,
          addresses: addresses,
          defaultAddress: defaultAddress,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          isVerified: data['is_verified'] as bool,
          status: data['status'] as String,
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
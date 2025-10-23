import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import 'auth_providers.dart';

final currentUserProvider = StreamProvider<UserEntity?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      
      // Update user status to active when logged in
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'status': 'active'})
          // ignore: avoid_print
          .catchError((error) => ('$error'));
      
      // Listen for app termination to set status to inactive
      ref.onDispose(() {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'status': 'inactive'})
            .catchError((error) => ('$error'));
      });
      
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
        
        // Check if email is verified from Firebase Auth
        bool isEmailVerified = user.emailVerified;
        
        // If email verification status has changed, update it in Firestore
        if (isEmailVerified != (data['is_verified'] as bool)) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'is_verified': isEmailVerified})
              .catchError((error) => ('$error'));
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
          isVerified: isEmailVerified, 
          status: data['status'] as String,
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
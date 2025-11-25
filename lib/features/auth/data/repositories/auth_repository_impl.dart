import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:boticart/features/auth/domain/entities/user.dart';
import 'package:boticart/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:boticart/features/auth/data/services/persistent_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  @override
  Future<UserEntity> signUp({
    required String firstName,
    required String lastName,
    required String email,
    String contact = '',
    String address = '',
    required String password,
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get the user ID
      final userId = userCredential.user!.uid;
      
      // Create timestamp for createdAt
      final now = DateTime.now();
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(userId).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'contact': contact,
        'address': address,
        'createdAt': now,
        'is_verified': false,
        'status': 'inactive',
        'updatedAt': now,
      });
      
      // Send verification email
      await sendEmailVerification();
      
      // Save login state
      await PersistentAuthService.saveLoginState(true);
      
      // Return user entity
      return UserEntity(
        id: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        contact: contact,
        address: address,
        createdAt: now,
        isVerified: false,
        status: 'inactive',
        updatedAt: now,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with email and password
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get the user ID
      final userId = userCredential.user!.uid;
      
      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return null;
      }
      
      final userData = userDoc.data()!;
      
      // Save login state
      await PersistentAuthService.saveLoginState(true);
      
      // Return user entity
      return UserEntity(
        id: userId,
        firstName: userData['firstName'] as String,
        lastName: userData['lastName'] as String,
        email: userData['email'] as String,
        contact: userData['contact'] as String,
        address: userData['address'] as String,
        createdAt: (userData['createdAt'] as Timestamp).toDate(),
        isVerified: userData['is_verified'] as bool,
        status: userData['status'] as String,
        updatedAt: (userData['updatedAt'] as Timestamp).toDate(),
      );
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<bool> isEmailVerified() async {
    try {
      await reloadUser();
      final user = _firebaseAuth.currentUser;
      return user?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<void> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<void> updateUserVerificationStatus({
    required String userId,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'is_verified': true,
      'status': 'active',
      'updatedAt': DateTime.now(),
    });
  }
  
  @override
  Future<void> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'status': status,
      'updatedAt': DateTime.now(),
    });
  }
  
  @override
  Future<void> resetPassword({required String email}) async {
    try {
      // Check if the email exists in the users collection
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this email address',
        );
      }
      
      // If user exists, send password reset email
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign-In process');
      
      // Create a new instance of GoogleSignIn
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      // Check if a user is already signed in and disconnect if needed
      final currentUser = await googleSignIn.signInSilently();
      if (currentUser != null) {
        await googleSignIn.disconnect();
      }
      
      // Begin interactive sign-in process
      debugPrint('Requesting Google Sign-In');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      debugPrint('Google Sign-In result: ${googleUser != null ? 'Success' : 'Cancelled'}');
      
      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }
      
      // Obtain auth details from request
      debugPrint('Getting authentication details');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      debugPrint('Signing in to Firebase with Google credential');
      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user == null) {
        debugPrint('Firebase user is null after sign-in');
        return null;
      }
      
      debugPrint('Successfully signed in with Google: ${user.email}');
      
      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final now = DateTime.now();
      
      if (!userDoc.exists) {
        debugPrint('Creating new user document in Firestore');
        // Create new user document if it doesn't exist
        String firstName = '';
        String lastName = '';
        
        if (user.displayName != null) {
          final nameParts = user.displayName!.split(' ');
          firstName = nameParts.first;
          if (nameParts.length > 1) {
            lastName = nameParts.last;
          }
        }
        
        final userData = {
          'firstName': firstName,
          'lastName': lastName,
          'email': user.email ?? '',
          'contact': user.phoneNumber ?? '',
          'address': '',
          'createdAt': now,
          'is_verified': user.emailVerified,
          'status': 'active',
          'updatedAt': now,
        };
        
        await _firestore.collection('users').doc(user.uid).set(userData);
        
        return UserEntity(
          id: user.uid,
          firstName: firstName,
          lastName: lastName,
          email: user.email ?? '',
          contact: user.phoneNumber ?? '',
          address: '',
          createdAt: now,
          isVerified: user.emailVerified,
          status: 'active',
          updatedAt: now,
        );
      } else {
        debugPrint('User already exists in Firestore');
        // User exists, return user data
        final userData = userDoc.data()!;
        
        return UserEntity(
          id: user.uid,
          firstName: userData['firstName'] as String,
          lastName: userData['lastName'] as String,
          email: userData['email'] as String,
          contact: userData['contact'] as String,
          address: userData['address'] as String,
          createdAt: (userData['createdAt'] as Timestamp).toDate(),
          isVerified: userData['is_verified'] as bool,
          status: userData['status'] as String,
          updatedAt: (userData['updatedAt'] as Timestamp).toDate(),
        );
      }
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> checkEmailExists({required String email}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }
  
  // Add a logout method that clears the persistent login state
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await PersistentAuthService.clearLoginState();
  }
}
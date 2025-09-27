import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionUploadNotifier extends StateNotifier<AsyncValue<String?>> {
  PrescriptionUploadNotifier() : super(const AsyncValue.data(null));
  
  Future<void> uploadPrescription({
    required String userId,
    required File file,
    required String fileName,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final storage = FirebaseStorage.instance;
      final firestore = FirebaseFirestore.instance;
      
      // Create reference to the prescriptions folder
      final prescriptionRef = storage.ref('prescriptions/$userId');
      
      // Upload the prescription file
      final uploadTask = await prescriptionRef.child(fileName).putFile(
        file,
        SettableMetadata(contentType: _getContentType(fileName)),
      );
      
      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Save the prescription URL to Firestore
      final prescriptionDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('prescriptions')
          .add({
        'url': downloadUrl,
        'fileName': fileName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // If note is provided, save it to prescriptionNotes collection
      if (note != null && note.isNotEmpty) {
        await firestore.collection('prescriptionNotes').add({
          'userUID': userId,
          'prescriptionId': prescriptionDoc.id,
          'note': note,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      state = AsyncValue.data(downloadUrl);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  String _getContentType(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return 'application/pdf';
    } else if (fileName.toLowerCase().endsWith('.jpg') || 
              fileName.toLowerCase().endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (fileName.toLowerCase().endsWith('.png')) {
      return 'image/png';
    }
    return 'application/octet-stream';
  }
}

// Provider for prescription upload
final prescriptionUploadProvider = StateNotifierProvider<PrescriptionUploadNotifier, AsyncValue<String?>>((ref) {
  return PrescriptionUploadNotifier();
});

// Provider to fetch user's prescriptions
final userPrescriptionsProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  if (userId.isEmpty) return [];
  
  try {
    final storage = FirebaseStorage.instance;
    final listResult = await storage.ref('prescriptions/$userId').listAll();
    
    if (listResult.items.isEmpty) return [];
    
    // Get all prescription URLs
    final prescriptionUrls = <String>[];
    for (var item in listResult.items) {
      final url = await item.getDownloadURL();
      prescriptionUrls.add(url);
    }
    
    return prescriptionUrls;
  } catch (e) {
    return [];
  }
});
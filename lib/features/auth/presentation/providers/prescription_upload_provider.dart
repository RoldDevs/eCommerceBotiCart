import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/file_item.dart';

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
      
      // Determine file type
      final fileType = _getFileType(fileName);
      
      // Check if a file of this type already exists
      final existingFiles = await firestore
          .collection('users')
          .doc(userId)
          .collection('prescriptions')
          .where('fileType', isEqualTo: fileType)
          .get();
      
      // If a file of this type already exists, delete it from storage and Firestore
      if (existingFiles.docs.isNotEmpty) {
        for (var doc in existingFiles.docs) {
          final _ = doc['url'] as String;
          final existingFileName = doc['fileName'] as String;
          
          // Delete from Storage
          try {
            await storage.ref('prescriptions/$userId/$existingFileName').delete();
          } catch (e) {
            // File might not exist in storage, continue anyway
          }
          
          // Delete from Firestore
          await doc.reference.delete();
        }
      }
      
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
        'fileType': fileType,
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
  
  // Add the deletePrescription method
  Future<void> deletePrescription({
    required String userId,
    required String fileUrl,
    required String fileName,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final storage = FirebaseStorage.instance;
      final firestore = FirebaseFirestore.instance;
      
      // Find the document in Firestore
      final querySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('prescriptions')
          .where('url', isEqualTo: fileUrl)
          .get();
      
      // Delete from Firestore
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete from Storage
      try {
        await storage.ref('prescriptions/$userId/$fileName').delete();
      } catch (e) {
        // File might not exist in storage, continue anyway
      }
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  String _getFileType(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return 'pdf';
    } else {
      return 'image';
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
final userPrescriptionsProvider = StreamProvider.family<List<FileItem>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('prescriptions')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return FileItem(
          url: data['url'] as String,
          fileName: data['fileName'] as String,
          fileType: data['fileType'] as String? ?? _determineFileTypeFromUrl(data['url'] as String),
          createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
        );
      }).toList());
});

String _determineFileTypeFromUrl(String url) {
  return url.toLowerCase().contains('.pdf') ? 'pdf' : 'image';
}
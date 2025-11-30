import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/legacy.dart';

final profilePictureProvider = FutureProvider.family<String?, String>((
  ref,
  userId,
) async {
  if (userId.isEmpty) return null;

  try {
    final storage = FirebaseStorage.instance;
    final listResult = await storage.ref('profilePictures/$userId').listAll();

    if (listResult.items.isEmpty) return null;

    // Get the most recent profile picture
    final mostRecentFile = listResult.items.last;
    return await mostRecentFile.getDownloadURL();
  } catch (e) {
    return null;
  }
});

// Notifier for profile picture upload
class ProfilePictureUploadNotifier extends StateNotifier<AsyncValue<String?>> {
  ProfilePictureUploadNotifier() : super(const AsyncValue.data(null));

  Future<void> uploadProfilePicture({
    required String userId,
    required String username,
    required File file,
  }) async {
    state = const AsyncValue.loading();

    try {
      final storage = FirebaseStorage.instance;

      // Create reference to the user's profile pictures folder
      final userFolderRef = storage.ref('profilePictures/$userId');

      // List existing files to delete previous profile pictures
      try {
        final listResult = await userFolderRef.listAll();
        for (var item in listResult.items) {
          await item.delete();
        }
      } catch (e) {
        // Folder might not exist yet, which is fine
      }

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_$timestamp.jpg';

      // Upload the new profile picture
      final uploadTask = await userFolderRef
          .child(fileName)
          .putFile(file, SettableMetadata(contentType: 'image/jpeg'));

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      state = AsyncValue.data(downloadUrl);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Provider for profile picture upload
final profilePictureUploadProvider =
    StateNotifierProvider<ProfilePictureUploadNotifier, AsyncValue<String?>>((
      ref,
    ) {
      return ProfilePictureUploadNotifier();
    });

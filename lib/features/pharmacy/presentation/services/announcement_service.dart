import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../domain/entities/announcement.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(firestore: FirebaseFirestore.instance);
});

final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  final repository = ref.watch(announcementRepositoryProvider);
  return AnnouncementService(repository);
});

class AnnouncementService {
  final AnnouncementRepository _repository;

  AnnouncementService(this._repository);

  Future<Announcement?> getAnnouncementById(String id) {
    return _repository.getAnnouncementById(id);
  }

  Future<String> createAnnouncement({
    required String title,
    required String message,
    required AnnouncementType type,
    DateTime? expiresAt,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    int? storeID,
  }) {
    final announcement = Announcement(
      id: '',
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      imageUrl: imageUrl,
      metadata: metadata,
      storeID: storeID,
    );

    return _repository.createAnnouncement(announcement);
  }

  Future<void> updateAnnouncement(String id, Announcement announcement) {
    return _repository.updateAnnouncement(id, announcement);
  }

  Future<void> deleteAnnouncement(String id) {
    return _repository.deleteAnnouncement(id);
  }

  Future<void> deactivateAnnouncement(String id) {
    return _repository.deactivateAnnouncement(id);
  }
}

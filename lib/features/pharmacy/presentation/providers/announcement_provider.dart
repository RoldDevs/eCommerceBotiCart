import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/announcement.dart';
import '../../data/repositories/announcement_repository.dart';
import 'pharmacy_providers.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(firestore: FirebaseFirestore.instance);
});

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  final repository = ref.watch(announcementRepositoryProvider);
  final selectedStoreId = ref.watch(selectedPharmacyStoreIdProvider);

  if (selectedStoreId != null) {
    return repository.getAnnouncementsForStoreAndGlobal(selectedStoreId);
  } else {
    return repository.getGlobalAnnouncements();
  }
});

final announcementProvider = FutureProvider.family<Announcement?, String>((
  ref,
  announcementId,
) {
  final repository = ref.watch(announcementRepositoryProvider);
  return repository.getAnnouncementById(announcementId);
});

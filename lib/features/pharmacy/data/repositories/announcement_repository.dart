import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import '../../domain/entities/announcement.dart';

class AnnouncementRepository {
  final FirebaseFirestore _firestore;

  AnnouncementRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Stream<List<Announcement>> getAnnouncementsForStoreAndGlobal(int storeID) {
    
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .where('storeID', isEqualTo: storeID)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final announcements = snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .where((announcement) => announcement.isVisible)
          .toList();
      
      return announcements;
    });
  }

  Stream<List<Announcement>> getAnnouncementsForStore(int storeID) {
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .where('storeID', isEqualTo: storeID)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .where((announcement) => announcement.isVisible)
          .toList();
    });
  }

  Stream<List<Announcement>> getGlobalAnnouncements() {
    debugPrint('DEBUG: getGlobalAnnouncements called');
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .where('storeID', isEqualTo: null)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final announcements = snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .where((announcement) => announcement.isVisible)
          .toList();  
      return announcements;
    });
  }

  Future<Announcement?> getAnnouncementById(String id) async {
    try {
      final doc = await _firestore.collection('announcements').doc(id).get();
      if (doc.exists) {
        return Announcement.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get announcement: $e');
    }
  }

  Future<void> markAnnouncementAsRead(String announcementId, String userId) async {
    try {
      await _firestore
          .collection('announcement_reads')
          .doc('${announcementId}_$userId')
          .set({
        'announcementId': announcementId,
        'userId': userId,
        'readAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to mark announcement as read: $e');
    }
  }

  Future<bool> hasUserReadAnnouncement(String announcementId, String userId) async {
    try {
      final doc = await _firestore
          .collection('announcement_reads')
          .doc('${announcementId}_$userId')
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<String> createAnnouncement(Announcement announcement) async {
    try {
      final docRef = await _firestore
          .collection('announcements')
          .add(announcement.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  Future<void> updateAnnouncement(String id, Announcement announcement) async {
    try {
      await _firestore
          .collection('announcements')
          .doc(id)
          .update(announcement.toFirestore());
    } catch (e) {
      throw Exception('Failed to update announcement: $e');
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _firestore.collection('announcements').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }

  Future<void> deactivateAnnouncement(String id) async {
    try {
      await _firestore.collection('announcements').doc(id).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to deactivate announcement: $e');
    }
  }
}
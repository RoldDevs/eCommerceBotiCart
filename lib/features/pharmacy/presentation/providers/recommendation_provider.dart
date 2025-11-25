import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/order.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import 'order_provider.dart';
import 'medicine_provider.dart';

/// Provider to get user's purchased medicines from Vitamins & Supplements and Health Essentials
final userPurchasedMedicinesProvider = FutureProvider<List<Medicine>>((
  ref,
) async {
  final userAsyncValue = ref.watch(currentUserProvider);
  final user = userAsyncValue.value;

  if (user == null) return [];

  final ordersAsyncValue = ref.watch(userOrdersProvider);

  return ordersAsyncValue.when(
    data: (orders) async {
      // Filter completed/delivered orders only
      final completedOrders = orders.where((order) {
        return order.status == OrderStatus.completed ||
            order.status == OrderStatus.delivered;
      }).toList();

      if (completedOrders.isEmpty) return [];

      final firestore = FirebaseFirestore.instance;
      final List<Medicine> purchasedMedicines = [];

      // Get medicine details for each order
      for (final order in completedOrders) {
        try {
          final medicineDoc = await firestore
              .collection('medicines')
              .doc(order.medicineID)
              .get();

          if (!medicineDoc.exists) continue;

          final medicineData = medicineDoc.data()!;
          final medicine = Medicine.fromFirestore(medicineData, medicineDoc.id);

          // Only include Vitamins & Supplements and Health Essentials
          if (medicine.productType == MedicineProductType.vitaminsSupplements ||
              medicine.productType == MedicineProductType.healthEssentials) {
            // Avoid duplicates
            if (!purchasedMedicines.any((m) => m.id == medicine.id)) {
              purchasedMedicines.add(medicine);
            }
          }
        } catch (e) {
          // Skip if medicine not found
          continue;
        }
      }

      return purchasedMedicines;
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});

/// Provider to check if user has purchased from target categories
final hasPurchasedFromTargetCategoriesProvider = Provider<bool>((ref) {
  final purchasedMedicinesAsync = ref.watch(userPurchasedMedicinesProvider);

  return purchasedMedicinesAsync.when(
    data: (medicines) => medicines.isNotEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Calculate similarity score between two medicines
double _calculateSimilarity(Medicine purchased, Medicine candidate) {
  double score = 0.0;
  double maxScore = 0.0;

  // 1. Product type match (30% weight)
  maxScore += 30;
  if (purchased.productType == candidate.productType) {
    score += 30;
  }

  // 2. Condition type match (20% weight)
  maxScore += 20;
  if (purchased.conditionType == candidate.conditionType) {
    score += 20;
  }

  // 3. Major type match (10% weight)
  maxScore += 10;
  if (purchased.majorType == candidate.majorType) {
    score += 10;
  }

  // 4. Name similarity (20% weight)
  maxScore += 20;
  final nameSimilarity = _calculateStringSimilarity(
    purchased.medicineName.toLowerCase(),
    candidate.medicineName.toLowerCase(),
  );
  score += nameSimilarity * 20;

  // 5. Description similarity (10% weight)
  maxScore += 10;
  final descSimilarity = _calculateStringSimilarity(
    purchased.productDescription.toLowerCase(),
    candidate.productDescription.toLowerCase(),
  );
  score += descSimilarity * 10;

  // 6. Product offerings similarity (10% weight)
  maxScore += 10;
  final offeringsSimilarity = _calculateListSimilarity(
    purchased.productOffering,
    candidate.productOffering,
  );
  score += offeringsSimilarity * 10;

  return maxScore > 0 ? (score / maxScore) * 100 : 0;
}

/// Calculate similarity between two strings using word matching
double _calculateStringSimilarity(String str1, String str2) {
  if (str1.isEmpty && str2.isEmpty) return 1.0;
  if (str1.isEmpty || str2.isEmpty) return 0.0;

  final words1 = str1.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
  final words2 = str2.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();

  if (words1.isEmpty && words2.isEmpty) return 1.0;
  if (words1.isEmpty || words2.isEmpty) return 0.0;

  final intersection = words1.intersection(words2).length;
  final union = words1.union(words2).length;

  return union > 0 ? intersection / union : 0.0;
}

/// Calculate similarity between two lists
double _calculateListSimilarity(List<String> list1, List<String> list2) {
  if (list1.isEmpty && list2.isEmpty) return 1.0;
  if (list1.isEmpty || list2.isEmpty) return 0.0;

  final set1 = list1.map((e) => e.toLowerCase()).toSet();
  final set2 = list2.map((e) => e.toLowerCase()).toSet();

  final intersection = set1.intersection(set2).length;
  final union = set1.union(set2).length;

  return union > 0 ? intersection / union : 0.0;
}

/// Provider for recommended medicines based on user's purchase history
final recommendedMedicinesProvider = FutureProvider<List<Medicine>>((
  ref,
) async {
  final purchasedMedicinesAsync = ref.watch(userPurchasedMedicinesProvider);
  final allMedicinesAsync = ref.watch(allMedicinesProvider);

  return purchasedMedicinesAsync.when(
    data: (purchasedMedicines) async {
      final allMedicines = allMedicinesAsync.value ?? [];

      if (purchasedMedicines.isEmpty || allMedicines.isEmpty) {
        return [];
      }

      // Get all purchased medicine IDs to exclude them from recommendations
      final purchasedIds = purchasedMedicines.map((m) => m.id).toSet();

      // Filter candidates: only Vitamins & Supplements and Health Essentials
      final candidates = allMedicines.where((medicine) {
        return (medicine.productType ==
                    MedicineProductType.vitaminsSupplements ||
                medicine.productType == MedicineProductType.healthEssentials) &&
            !purchasedIds.contains(medicine.id) &&
            medicine.stock > 0; // Only recommend in-stock items
      }).toList();

      if (candidates.isEmpty) return [];

      // Calculate similarity scores for each candidate
      final List<({Medicine medicine, double score})> scoredCandidates = [];

      for (final candidate in candidates) {
        double maxSimilarity = 0.0;

        // Find the highest similarity score across all purchased medicines
        for (final purchased in purchasedMedicines) {
          final similarity = _calculateSimilarity(purchased, candidate);
          if (similarity > maxSimilarity) {
            maxSimilarity = similarity;
          }
        }

        // Only include if similarity is above threshold (30%)
        if (maxSimilarity >= 30.0) {
          scoredCandidates.add((medicine: candidate, score: maxSimilarity));
        }
      }

      // Sort by similarity score (descending) and take top 10
      scoredCandidates.sort((a, b) => b.score.compareTo(a.score));

      return scoredCandidates.take(10).map((item) => item.medicine).toList();
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});

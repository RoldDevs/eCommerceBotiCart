import 'package:boticart/features/pharmacy/presentation/providers/medicine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/medicine.dart';

final selectedMedicineProvider = StateProvider<Medicine?>((ref) => null);

final relatedMedicinesProvider = Provider<List<Medicine>>((ref) {
  final allMedicinesAsyncValue = ref.watch(allMedicinesProvider);
  final selectedMedicine = ref.watch(selectedMedicineProvider);
  
  return allMedicinesAsyncValue.when(
    data: (medicines) {
      if (selectedMedicine == null) return [];
      
      // Filter medicines to exclude the selected one and limit to 4 items
      return medicines
          .where((medicine) => medicine.id != selectedMedicine.id)
          .take(4)
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
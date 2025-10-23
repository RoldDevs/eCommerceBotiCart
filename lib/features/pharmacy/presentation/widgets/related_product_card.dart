import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/medicine.dart';
import '../providers/medicine_provider.dart';
import '../providers/stock_provider.dart';
import '../screens/medicine_detail_screen.dart';
import 'stock_badge.dart';

class RelatedProductCard extends ConsumerWidget {
  final Medicine medicine;

  const RelatedProductCard({
    super.key,
    required this.medicine,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteMedicinesProvider);
    final isFavorite = favorites.contains(medicine.id);
    
    // Watch real-time stock updates
    final stockAsyncValue = ref.watch(stockStreamProvider(medicine.id));

    return stockAsyncValue.when(
      data: (currentStock) => _buildCard(context, ref, isFavorite, currentStock),
      loading: () => _buildCard(context, ref, isFavorite, medicine.stock),
      error: (_, __) => _buildCard(context, ref, isFavorite, medicine.stock),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, bool isFavorite, int currentStock) {

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MedicineDetailScreen(medicine: medicine),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  Image.network(
                    medicine.imageURL,
                    height: 105, // Reduced from 110 to 105
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 105, // Reduced from 120 to 105
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                  // Stock badge overlay
                  Positioned(
                    top: 6,
                    right: 6,
                    child: StockBadge(
                      stock: currentStock,
                      fontSize: 8,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    ),
                  ),
                ],
              ),
            ),
            
            // Medicine details
            Padding(
              padding: const EdgeInsets.all(6.0), // Reduced from 8.0 to 6.0
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.medicineName,
                    style: GoogleFonts.poppins(
                      fontSize: 13, // Reduced from 14 to 13
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1), // Reduced from 2 to 1
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8ECAE6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      medicine.majorTypeDisplayName,
                      style: GoogleFonts.poppins(
                        fontSize: 9, // Reduced from 10 to 9
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2A4B8D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 1), // Reduced from 2 to 1
                  Text(
                    medicine.productTypeDisplayName,
                    style: GoogleFonts.poppins(
                      fontSize: 9, // Reduced from 10 to 9
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2), // Reduced from 4 to 2
                  Text(
                    ' ${medicine.productOffering.join(", ")}',
                    style: GoogleFonts.poppins(
                      fontSize: 10, // Reduced from 11 to 10
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱ ${medicine.price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12, // Reduced from 14 to 12
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : const Color(0xFF8ECAE6),
                          size: 40, // Reduced from 35 to 28
                        ),
                        onPressed: () {
                          ref.read(favoriteMedicinesProvider.notifier).toggleFavorite(medicine.id);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28), // Added constraints
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
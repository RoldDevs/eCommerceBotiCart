import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/pharmacy.dart';
import '../providers/pharmacy_providers.dart';
import '../screens/pharmacy_detail_screen.dart';

class PharmacyCard extends ConsumerWidget {
  final Pharmacy pharmacy;

  const PharmacyCard({
    super.key,
    required this.pharmacy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(pharmacy.id);

    return GestureDetector(
      onTap: () {
        debugPrint('DEBUG: PharmacyCard tapped - Setting selectedPharmacyStoreIdProvider to: ${pharmacy.storeID}');
        ref.read(selectedPharmacyStoreIdProvider.notifier).state = pharmacy.storeID;
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PharmacyDetailScreen(pharmacy: pharmacy),
          ),
        );
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.all(4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Background image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 90,
                    decoration: BoxDecoration(
                      image: pharmacy.backgroundImgUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(pharmacy.backgroundImgUrl),
                              fit: BoxFit.cover, 
                            )
                          : null,
                    ),
                  ),
                ),
                
                // Pharmacy logo circle
                Transform.translate(
                  offset: const Offset(0, 20),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: pharmacy.imageUrl.isEmpty
                          ? const Color(0xFF8ECAE6)
                          : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: pharmacy.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(pharmacy.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: pharmacy.imageUrl.isEmpty
                        ? const Icon(
                            Icons.local_pharmacy,
                            color: Colors.white,
                            size: 28,
                          )
                        : null,
                  ),
                ),
              ],
            ),

            // Pharmacy name and location
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 28.0, 12.0, 0.0), // Reduced top padding from 30 to 28
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pharmacy.name,
                      style: TextStyle(
                        fontSize: 15, // Reduced from 16 to 15
                        fontWeight: FontWeight.bold,
                        fontFamily: GoogleFonts.poppins().fontFamily,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3), // Reduced from 4 to 3
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1.5), // Reduced from 2.0 to 1.5
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 16, // Reduced from 18 to 16
                            color: Color(0xFF8ECAE6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            pharmacy.location,
                            style: TextStyle(
                              fontSize: 11, // Reduced from 11 to 10
                              color: Colors.black87,
                              fontFamily: GoogleFonts.poppins().fontFamily,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Rating + Favorite button
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 6.0), // Reduced padding: top from 4 to 2, bottom from 8 to 6
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 12), // Reduced from 14 to 12
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      '${pharmacy.rating} (${pharmacy.reviewCount} Ratings)',
                      style: TextStyle(
                        fontSize: 11, // Reduced from 11 to 10
                        color: Colors.black87,
                        fontFamily: GoogleFonts.poppins().fontFamily,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32), // Reduced from 36x36 to 32x32
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? const Color(0xFF8ECAE6) : const Color(0xFF8ECAE6),
                      size: 40, // Reduced from 24 to 20
                    ),
                    onPressed: () {
                      final favoritesNotifier = ref.read(favoritesProvider.notifier);
                      favoritesNotifier.state = isFavorite
                          ? favorites.where((id) => id != pharmacy.id).toList()
                          : [...favorites, pharmacy.id];
                    },
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
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
                              image: NetworkImage(Uri.encodeFull(pharmacy.backgroundImgUrl)),
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
                              image: NetworkImage(Uri.encodeFull(pharmacy.imageUrl)),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 30.0, 12.0, 0.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: Color(0xFF8ECAE6),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          pharmacy.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontFamily: GoogleFonts.poppins().fontFamily,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Rating + Favorite button
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 12.0), 
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '${pharmacy.rating} (${pharmacy.reviewCount} Ratings)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                  const Spacer(), 
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? const Color(0xFF8ECAE6) : const Color(0xFF8ECAE6),
                      size: 40,
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
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

// Provider to store the selected address from user's saved addresses
final selectedAddressProvider = StateProvider<String?>((ref) => null);

// Provider to store the LatLng coordinates for the selected address
final selectedAddressLocationProvider = StateProvider<LatLng?>((ref) => null);

// Provider to track if beneficiary ID card should be applied
final applyBeneficiaryIdProvider = StateProvider<bool>((ref) => false);

// Provider to store the selected beneficiary ID card
final selectedBeneficiaryIdProvider = StateProvider<String?>((ref) => null);

// Function to get LatLng from address string
Future<LatLng?> getLocationFromAddress(String address) async {
  try {
    List<Location> locations = await locationFromAddress(address);
    if (locations.isNotEmpty) {
      return LatLng(locations.first.latitude, locations.first.longitude);
    }
  } catch (e) {
    // Handle error
  }
  return null;
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../providers/location_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/pharmacy_providers.dart';
import '../../domain/entities/pharmacy.dart';
import '../services/checkout_service.dart';
import 'orders_screen.dart';

class CartCheckoutScreen extends ConsumerStatefulWidget {
  const CartCheckoutScreen({super.key});

  @override
  ConsumerState<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends ConsumerState<CartCheckoutScreen> {
  bool isHomeDelivery = true;
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  bool isProcessing = false;
  Pharmacy? pharmacy;
  LatLng? pharmacyLocation;

  @override
  void initState() {
    super.initState();
    // Reset providers when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedAddressProvider.notifier).state = null;
      ref.read(selectedAddressLocationProvider.notifier).state = null;
      ref.read(applyBeneficiaryIdProvider.notifier).state = false;
      ref.read(selectedBeneficiaryIdProvider.notifier).state = null;

      // Load pharmacy information
      _loadPharmacyInfo();

      // Load default address if available (only for home delivery)
      if (isHomeDelivery) {
        _loadDefaultAddress();
      }
    });
  }

  Future<void> _loadPharmacyInfo() async {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    // Get the first item's storeID to find the pharmacy
    final firstItem = cartItems.first;
    final pharmaciesAsyncValue = ref.read(pharmaciesStreamProvider);
    pharmaciesAsyncValue.whenData((pharmacies) async {
      try {
        final foundPharmacy = pharmacies.firstWhere(
          (p) => p.storeID == firstItem.medicine.storeID,
        );
        setState(() {
          pharmacy = foundPharmacy;
        });

        // Get pharmacy location
        if (foundPharmacy.location.isNotEmpty) {
          final location = await getLocationFromAddress(foundPharmacy.location);
          if (location != null) {
            setState(() {
              pharmacyLocation = location;
            });
            if (!isHomeDelivery) {
              _updateMapLocation(location, foundPharmacy.name);
            }
          }
        }
      } catch (e) {
        // Pharmacy not found, handle gracefully
      }
    });
  }

  Future<void> _loadDefaultAddress() async {
    final userAsyncValue = ref.read(currentUserProvider);
    userAsyncValue.whenData((user) async {
      if (user != null && user.defaultAddress != null) {
        // Set the selected address to the default address
        ref.read(selectedAddressProvider.notifier).state = user.defaultAddress;

        // Get location from address and update map
        final location = await getLocationFromAddress(user.defaultAddress!);
        if (location != null) {
          ref.read(selectedAddressLocationProvider.notifier).state = location;
          _updateMapLocation(location);
        }
      }
    });
  }

  void _updateMapLocation(LatLng location, [String? title]) {
    if (mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
      setState(() {
        if (title != null) {
          markers = {
            Marker(
              markerId: const MarkerId('selectedLocation'),
              position: location,
              infoWindow: InfoWindow(title: title),
            ),
          };
        } else {
          markers = {
            Marker(
              markerId: const MarkerId('selectedLocation'),
              position: location,
            ),
          };
        }
      });
    }
  }

  Future<void> _onAddressSelected(String address) async {
    ref.read(selectedAddressProvider.notifier).state = address;

    // Get location from address and update map
    final location = await getLocationFromAddress(address);
    if (location != null) {
      ref.read(selectedAddressLocationProvider.notifier).state = location;
      _updateMapLocation(location);
    }
  }

  Future<void> _processCheckout() async {
    final selectedAddress = ref.read(selectedAddressProvider);

    // For home delivery, address is required
    if (isHomeDelivery &&
        (selectedAddress == null || selectedAddress.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a delivery address',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // For pickup, use pharmacy location as address
    final String? deliveryAddress = isHomeDelivery
        ? selectedAddress
        : pharmacy?.location;

    if (deliveryAddress == null || deliveryAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHomeDelivery
                ? 'Please select a delivery address'
                : 'Pharmacy location not available',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final checkoutService = ref.read(checkoutServiceProvider);

      final orderIds = await checkoutService.checkoutSelectedItems(
        deliveryAddress: deliveryAddress,
        isHomeDelivery: isHomeDelivery,
        beneficiaryId: null,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully created ${orderIds.length} order(s)!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate based on delivery type
        if (isHomeDelivery) {
          // For home delivery, navigate to orders screen (no verification needed)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OrdersScreen()),
            (route) => route.isFirst,
          );
        } else {
          // For pickup orders, navigate to orders screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OrdersScreen()),
            (route) => route.isFirst,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final selectedItems = cartItems.where((item) => item.isSelected).toList();
    final isSelectionMode = ref.watch(selectionModeProvider);
    final itemsToCheckout = isSelectionMode ? selectedItems : cartItems;

    // ignore: avoid_types_as_parameter_names
    final totalPrice = itemsToCheckout.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    final userAsync = ref.watch(currentUserProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final selectedLocation = ref.watch(selectedAddressLocationProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8ECAE6)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'CHECKOUT',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8ECAE6),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery options
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DELIVERY OPTIONS',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    isHomeDelivery = true;
                                  });
                                  // Reload default address when switching to home delivery
                                  _loadDefaultAddress();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isHomeDelivery
                                        ? const Color(0xFF8ECAE6)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isHomeDelivery
                                          ? const Color(0xFF8ECAE6)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Home delivery',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isHomeDelivery
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    isHomeDelivery = false;
                                  });
                                  // Update map to show pharmacy location when switching to pickup
                                  if (pharmacyLocation != null &&
                                      pharmacy != null) {
                                    _updateMapLocation(
                                      pharmacyLocation!,
                                      pharmacy!.name,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isHomeDelivery
                                        ? const Color(0xFF8ECAE6)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !isHomeDelivery
                                          ? const Color(0xFF8ECAE6)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Pick up',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: !isHomeDelivery
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Lalamove delivery info section
                        if (isHomeDelivery) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF8ECAE6),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  color: const Color(0xFF8ECAE6),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lalamove Delivery',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF8ECAE6),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Your order will be delivered via Lalamove. You can track your delivery once the order is confirmed.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Pickup benefits section
                        if (!isHomeDelivery) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF8ECAE6,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF8ECAE6),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.store_outlined,
                                      color: const Color(0xFF8ECAE6),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Pickup Benefits',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF8ECAE6),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildBenefitItem(
                                  Icons.access_time,
                                  'Skip the line - Order ahead and pick up when ready',
                                ),
                                const SizedBox(height: 8),
                                _buildBenefitItem(
                                  Icons.notifications_outlined,
                                  'Get notified when your order is ready for pickup',
                                ),
                                const SizedBox(height: 8),
                                _buildBenefitItem(
                                  Icons.verified_outlined,
                                  'Guaranteed availability - Your items are reserved',
                                ),
                                const SizedBox(height: 8),
                                _buildBenefitItem(
                                  Icons.receipt_long_outlined,
                                  'Order history tracking - Keep records of all purchases',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Map and address section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Map preview
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                (isHomeDelivery && selectedLocation != null) ||
                                    (!isHomeDelivery &&
                                        pharmacyLocation != null)
                                ? GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: isHomeDelivery
                                          ? selectedLocation!
                                          : pharmacyLocation!,
                                      zoom: 15,
                                    ),
                                    markers: markers,
                                    onMapCreated: (controller) {
                                      mapController = controller;
                                      // Update map location after controller is ready
                                      if (!isHomeDelivery &&
                                          pharmacyLocation != null &&
                                          pharmacy != null) {
                                        _updateMapLocation(
                                          pharmacyLocation!,
                                          pharmacy!.name,
                                        );
                                      } else if (isHomeDelivery &&
                                          selectedLocation != null) {
                                        _updateMapLocation(selectedLocation);
                                      }
                                    },
                                    zoomControlsEnabled: false,
                                    mapToolbarEnabled: false,
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.map,
                                      size: 50,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Address dropdown for delivery OR pickup location info
                        if (isHomeDelivery)
                          userAsync.when(
                            data: (user) {
                              if (user == null || user.addresses.isEmpty) {
                                return const Text('No saved addresses found');
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select delivery address',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                      ),
                                      iconSize: 24,
                                      elevation: 2,
                                      isExpanded: true,
                                      initialValue: selectedAddress,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                        border: InputBorder.none,
                                        hintText: 'Select address',
                                        hintStyle: GoogleFonts.poppins(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      menuMaxHeight: 300,
                                      items: user.addresses.map((address) {
                                        return DropdownMenuItem<String>(
                                          value: address,
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.only(
                                              right: 30,
                                            ),
                                            child: Text(
                                              address,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          _onAddressSelected(value);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, __) =>
                                const Text('Error loading addresses'),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You will pickup your item here',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: const Color(0xFF8ECAE6),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        pharmacy?.location ??
                                            'Loading pharmacy location...',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Order summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORDER SUMMARY (${itemsToCheckout.length} items)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...itemsToCheckout.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: item.medicine.imageURL.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            item.medicine.imageURL,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.medication,
                                                      size: 25,
                                                      color: Color(0xFF8ECAE6),
                                                    ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.medication,
                                          size: 25,
                                          color: Color(0xFF8ECAE6),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.medicine.medicineName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₱${item.totalPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF8ECAE6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Price breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...itemsToCheckout.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.medicine.medicineName} x${item.quantity}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₱${item.totalPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              '₱${totalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(thickness: 2),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₱${totalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8ECAE6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isProcessing ||
                        ((isHomeDelivery && selectedAddress == null) ||
                            (!isHomeDelivery && pharmacy == null))
                    ? null
                    : _processCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8ECAE6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Place Order',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8ECAE6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
import 'package:boticart/features/pharmacy/presentation/screens/orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/pharmacy.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../providers/location_provider.dart';
import '../providers/pharmacy_providers.dart';
import '../services/checkout_service.dart';
import '../widgets/pickup/pickup_time_selector_widget.dart';
import '../widgets/pickup/pickup_promotion_card.dart';
import '../widgets/pickup/curbside_pickup_widget.dart';
import '../widgets/pickup/inventory_availability_widget.dart';
import '../providers/pickup_provider.dart';

class OrderInformationScreen extends ConsumerStatefulWidget {
  final Medicine medicine;
  final int quantity;

  const OrderInformationScreen({
    super.key,
    required this.medicine,
    required this.quantity,
  });

  @override
  ConsumerState<OrderInformationScreen> createState() =>
      _OrderInformationScreenState();
}

class _OrderInformationScreenState
    extends ConsumerState<OrderInformationScreen> {
  bool isHomeDelivery = true;
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  bool isApplyingBeneficiaryId = false;
  bool isLoading = false;
  String? orderId;
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

      // Reset pickup providers
      ref.read(selectedPickupTimeSlotProvider.notifier).state = null;
      ref.read(isCurbsidePickupProvider.notifier).state = false;
      ref.read(pickupInstructionsProvider.notifier).state = null;
      ref.read(selectedPickupPromotionProvider.notifier).state = null;

      // Load pharmacy information
      _loadPharmacyInfo();

      // Load default address if available (only for home delivery)
      if (isHomeDelivery) {
        _loadDefaultAddress();
      }
    });
  }

  Future<void> _loadPharmacyInfo() async {
    final pharmaciesAsyncValue = ref.read(pharmaciesStreamProvider);
    pharmaciesAsyncValue.whenData((pharmacies) async {
      try {
        final foundPharmacy = pharmacies.firstWhere(
          (p) => p.storeID == widget.medicine.storeID,
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
    final selectedBeneficiaryId = ref.read(selectedBeneficiaryIdProvider);

    // For home delivery, address is required
    if (isHomeDelivery && selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a delivery address',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          backgroundColor: const Color(0xFF8ECAE6),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        ),
      );
      return;
    }

    // For pickup, validate pickup time is selected
    if (!isHomeDelivery) {
      final selectedPickupTime = ref.read(selectedPickupTimeSlotProvider);
      if (selectedPickupTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select a pickup time',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
            backgroundColor: const Color(0xFF8ECAE6),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          ),
        );
        return;
      }
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
              fontWeight: FontWeight.w400,
            ),
          ),
          backgroundColor: const Color(0xFF8ECAE6),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final checkoutService = ref.read(checkoutServiceProvider);

      // Get pickup-related data if it's a pickup order
      final pickupTimeSlot = !isHomeDelivery
          ? ref.read(selectedPickupTimeSlotProvider)
          : null;
      final isCurbside = !isHomeDelivery
          ? ref.read(isCurbsidePickupProvider)
          : false;
      final pickupInstructions = !isHomeDelivery
          ? ref.read(pickupInstructionsProvider)
          : null;
      final pickupPromotion = !isHomeDelivery
          ? ref.read(selectedPickupPromotionProvider)
          : null;

      // Create the order
      final newOrderId = await checkoutService.checkoutSingleItem(
        medicine: widget.medicine,
        quantity: widget.quantity,
        deliveryAddress: deliveryAddress,
        isHomeDelivery: isHomeDelivery,
        beneficiaryId: selectedBeneficiaryId,
        pickupTimeSlot: pickupTimeSlot,
        isCurbsidePickup: isCurbside,
        pickupInstructions: pickupInstructions,
        pickupPromotion: pickupPromotion,
      );

      setState(() {
        orderId = newOrderId;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order placed successfully!',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          backgroundColor: const Color(0xFF8ECAE6),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate based on delivery type
      if (isHomeDelivery) {
        // For home delivery, navigate to orders screen (no verification needed)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrdersScreen()),
        );
      } else {
        // For pickup orders, navigate to orders screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrdersScreen()),
        );
      }
    } catch (e) {
      // Extract clean error message
      String errorMessage = e.toString();

      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // Check if it's a delivery/feature error
      final isFeatureError =
          errorMessage.contains('This feature is not yet available') ||
          errorMessage.contains('Delivery are not yet available') ||
          errorMessage.contains('Delivery is not yet available');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFeatureError
                ? 'This feature is not yet available at this moment'
                : errorMessage,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          backgroundColor: const Color(0xFF8ECAE6),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.medicine.price * widget.quantity;
    final userAsync = ref.watch(currentUserProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final selectedLocation = ref.watch(selectedAddressLocationProvider);
    final selectedPickupTimeSlot = ref.watch(selectedPickupTimeSlotProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8ECAE6)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ORDER INFORMATION',
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
                          'ORDER INFORMATION',
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
                          const SizedBox(height: 16),
                          // Pickup time selector
                          const PickupTimeSelectorWidget(),
                          const SizedBox(height: 16),
                          // Curbside pickup option
                          const CurbsidePickupWidget(),
                          const SizedBox(height: 16),
                          // Inventory availability
                          InventoryAvailabilityWidget(
                            medicines: [widget.medicine],
                          ),
                          const SizedBox(height: 16),
                          // Pickup promotions
                          Consumer(
                            builder: (context, ref, child) {
                              final promotionsAsync = ref.watch(
                                pickupPromotionsProvider,
                              );
                              return promotionsAsync.when(
                                data: (promotions) {
                                  if (promotions.isEmpty)
                                    return const SizedBox.shrink();
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PICKUP EXCLUSIVE PROMOTIONS',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...promotions.map(
                                        (promotion) => PickupPromotionCard(
                                          promotion: promotion,
                                          orderAmount: totalPrice,
                                          onApply: () {
                                            // Promotion applied via provider
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
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
                          height: 250,
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: widget.medicine.imageURL.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    widget.medicine.imageURL,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.medication,
                                              size: 30,
                                              color: Color(0xFF8ECAE6),
                                            ),
                                  ),
                                )
                              : const Icon(
                                  Icons.medication,
                                  size: 30,
                                  color: Color(0xFF8ECAE6),
                                ),
                        ),
                        const SizedBox(width: 16),
                        // Product details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.medicine.medicineName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total item: ${widget.quantity}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey,
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

                  const SizedBox(height: 8),

                  // Order Summary section
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.medicine.medicineName} x${widget.quantity}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₱${totalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Discount',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              '₱0.00',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₱${totalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
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

          // Bottom checkout button
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
                    ((isHomeDelivery && selectedAddress != null) ||
                            (!isHomeDelivery &&
                                pharmacy != null &&
                                selectedPickupTimeSlot != null)) &&
                        !isLoading
                    ? _processCheckout
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8ECAE6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'CHECKOUT',
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

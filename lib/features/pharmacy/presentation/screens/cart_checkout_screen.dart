import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../../auth/presentation/models/file_item.dart';
import '../providers/location_provider.dart';
import '../providers/cart_provider.dart';
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
  
  @override
  void initState() {
    super.initState();
    // Reset providers when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedAddressProvider.notifier).state = null;
      ref.read(selectedAddressLocationProvider.notifier).state = null;
      ref.read(applyBeneficiaryIdProvider.notifier).state = false;
      ref.read(selectedBeneficiaryIdProvider.notifier).state = null;
      
      // Load default address if available
      _loadDefaultAddress();
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
  
  void _updateMapLocation(LatLng location) {
    if (mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
      setState(() {
        markers = {
          Marker(
            markerId: const MarkerId('selectedLocation'),
            position: location,
          ),
        };
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
    final applyBeneficiaryId = ref.read(applyBeneficiaryIdProvider);
    final selectedBeneficiaryId = ref.read(selectedBeneficiaryIdProvider);

    if (selectedAddress == null || selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (applyBeneficiaryId && (selectedBeneficiaryId == null || selectedBeneficiaryId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a beneficiary ID card'),
          backgroundColor: Colors.red,
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
        deliveryAddress: selectedAddress,
        isHomeDelivery: isHomeDelivery,
        beneficiaryId: applyBeneficiaryId ? selectedBeneficiaryId : null,
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
    final totalPrice = itemsToCheckout.fold(0.0, (sum, item) => sum + item.totalPrice);
    
    final userAsync = ref.watch(currentUserProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final selectedLocation = ref.watch(selectedAddressLocationProvider);
    final applyBeneficiaryId = ref.watch(applyBeneficiaryIdProvider);
    final selectedBeneficiaryId = ref.watch(selectedBeneficiaryIdProvider);

    // Calculate discount
    double discountAmount = 0.0;
    if (applyBeneficiaryId && selectedBeneficiaryId != null) {
      discountAmount = totalPrice * 0.20; // 20% discount
    }
    final finalTotal = totalPrice - discountAmount;

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
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isHomeDelivery ? const Color(0xFF8ECAE6) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isHomeDelivery ? const Color(0xFF8ECAE6) : Colors.grey.shade300,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Home delivery',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isHomeDelivery ? Colors.white : Colors.black,
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
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !isHomeDelivery ? const Color(0xFF8ECAE6) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !isHomeDelivery ? const Color(0xFF8ECAE6) : Colors.grey.shade300,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Pick up',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: !isHomeDelivery ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                            child: selectedLocation != null
                              ? GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: selectedLocation,
                                    zoom: 15,
                                  ),
                                  markers: markers,
                                  onMapCreated: (controller) {
                                    mapController = controller;
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
                        // Address dropdown
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
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    iconSize: 24,
                                    elevation: 2,
                                    isExpanded: true, 
                                    initialValue: selectedAddress,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                          padding: const EdgeInsets.only(right: 30),
                                          child: Text(
                                            address,
                                            style: GoogleFonts.poppins(fontSize: 14),
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
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Text('Error loading addresses'),
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
                        ...itemsToCheckout.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: item.medicine.imageURL.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.medicine.imageURL,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => 
                                          const Icon(Icons.medication, size: 25, color: Color(0xFF8ECAE6)),
                                      ),
                                    )
                                  : const Icon(Icons.medication, size: 25, color: Color(0xFF8ECAE6)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        )),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Beneficiary ID section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apply Beneficiary ID Card for discount?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ref.read(applyBeneficiaryIdProvider.notifier).state = true;
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: applyBeneficiaryId ? const Color(0xFF8ECAE6) : Colors.white,
                                  foregroundColor: applyBeneficiaryId ? Colors.white : Colors.black,
                                  side: BorderSide(color: applyBeneficiaryId ? const Color(0xFF8ECAE6) : Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  'Yes',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ref.read(applyBeneficiaryIdProvider.notifier).state = false;
                                  ref.read(selectedBeneficiaryIdProvider.notifier).state = null;
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !applyBeneficiaryId ? const Color(0xFF8ECAE6) : Colors.white,
                                  foregroundColor: !applyBeneficiaryId ? Colors.white : Colors.black,
                                  side: BorderSide(color: !applyBeneficiaryId ? const Color(0xFF8ECAE6) : Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  'No',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (applyBeneficiaryId) ...[
                          const SizedBox(height: 16),
                          _buildBeneficiaryIdSelection(),
                        ],
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
                        ...itemsToCheckout.map((item) => Padding(
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
                        )),
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
                              discountAmount > 0 ? '-₱${discountAmount.toStringAsFixed(2)}' : '₱0.00',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: discountAmount > 0 ? Colors.green : null,
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
                              '₱${finalTotal.toStringAsFixed(2)}',
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
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : _processCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8ECAE6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Place Order',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBeneficiaryIdSelection() {
    final userAsync = ref.watch(currentUserProvider);
    final selectedBeneficiaryId = ref.watch(selectedBeneficiaryIdProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox();
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.id)
              .collection('discountCards')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            
            final discountCards = snapshot.data?.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return FileItem(
                url: data['url'] as String,
                fileName: data['fileName'] as String,
                fileType: data['fileType'] as String,
                createdAt: data['uploadedAt'] != null 
                    ? (data['uploadedAt'] as Timestamp).toDate() 
                    : null,
              );
            }).toList() ?? [];
            
            if (discountCards.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No beneficiary ID cards found',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Navigate to account screen to upload ID
                      Navigator.pushNamed(context, '/account');
                    },
                    child: Text(
                      'Upload ID in Account Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF8ECAE6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Beneficiary ID Card',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedBeneficiaryId,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                      hintText: 'Select ID card',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    items: discountCards.map((card) {
                      return DropdownMenuItem<String>(
                        value: card.url,
                        child: Text(
                          'Senior Citizen ID (${card.fileType})',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(selectedBeneficiaryIdProvider.notifier).state = value;
                      }
                    },
                  ),
                ),
                if (selectedBeneficiaryId != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '20% discount will be applied',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading user data'),
    );
  }
}
import 'package:boticart/core/widgets/custom_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import 'edit_address_screen.dart';
import 'package:geocoding/geocoding.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  String? defaultAddress;
  Map<String, String> addressCities = {};

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    final userAsyncValue = ref.read(currentUserProvider);
    userAsyncValue.whenData((user) async {
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .get();
        
        if (userDoc.data()?.containsKey('defaultAddress') ?? false) {
          if (mounted) { 
            setState(() {
              defaultAddress = userDoc.data()?['defaultAddress'];
            });
          }
        }

        for (String address in user.addresses) {
          _extractCityFromAddress(address);
        }
      }
    });
  }

  Future<void> _extractCityFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          locations.first.latitude,
          locations.first.longitude,
        );
        
        if (placemarks.isNotEmpty && mounted) { 
          setState(() {
            addressCities[address] = placemarks.first.locality ?? 'Unknown';
          });
        }
      }
    } catch (e) {
      if (mounted) { 
        setState(() {
          addressCities[address] = 'Unknown';
        });
      }
    }
  }

  Future<void> _deleteAddress(String address) async {
    final userAsyncValue = ref.read(currentUserProvider);
    userAsyncValue.whenData((user) async {
      if (user != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.id);
        final userDoc = await userRef.get();
        
        // If deleting the default address, reset the default
        if (address == defaultAddress) {
          await userRef.update({
            'defaultAddress': null,
            'defaultAddressData': FieldValue.delete()
          });
          if (mounted) {
            setState(() {
              defaultAddress = null;
            });
          }
        }
        
        // Find the index of the address to delete
        int addressIndex = user.addresses.indexOf(address);
        
        // Remove the address from the list
        List<String> updatedAddresses = List.from(user.addresses);
        updatedAddresses.remove(address);
        
        // Update addressesData by removing the corresponding entry
        List<dynamic> addressesData = userDoc.data()?['addressesData'] ?? [];
        if (addressIndex >= 0 && addressIndex < addressesData.length) {
          addressesData.removeAt(addressIndex);
        }
        
        // Update both addresses and addressesData in Firestore
        await userRef.update({
          'addresses': updatedAddresses,
          'addressesData': addressesData
        });
        
        // Refresh user data
        if (mounted) {
          ref.invalidate(currentUserProvider);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ref.refresh(currentUserProvider);
    final userAsyncValue = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8ECAE6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Addresses',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8ECAE6),
          ),
        ),
        centerTitle: true,
      ),
      body: userAsyncValue.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }
          
          return Column(
            children: [
              Expanded(
                child: user.addresses.isEmpty
                    ? Center(
                        child: Text(
                          'No addresses found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF8ECAE6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: user.addresses.length,
                        itemBuilder: (context, index) {
                          final address = user.addresses[index];
                          final isDefault = address == defaultAddress;
                          final cityName = addressCities[address] ?? 'Unknown';
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                  title: Text(
                                    address,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    cityName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF8ECAE6)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditAddressScreen(
                                                address: address,
                                                index: index,
                                              ),
                                            ),
                                          ).then((_) {
                                            if (mounted) {
                                              ref.invalidate(currentUserProvider);
                                              _loadDefaultAddress();
                                            }
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFF8ECAE6)),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => CustomModal(
                                              title: 'Delete Address',
                                              content: 'Are you sure you want to delete this address?',
                                              confirmText: 'Delete',
                                              confirmButtonColor: Colors.redAccent,
                                              onCancel: () => Navigator.pop(context),
                                              onConfirm: () {
                                                _deleteAddress(address);
                                                Navigator.pop(context);
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (isDefault)
                                  Container(
                                    margin: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8ECAE6).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Default',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF8ECAE6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: user.addresses.length >= 3 
                          ? null // Disable button if 3 addresses already exist
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditAddressScreen(),
                                ),
                              ).then((_) {
                                // ignore: unused_result
                                ref.refresh(currentUserProvider);
                                _loadDefaultAddress();
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8ECAE6),
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        user.addresses.length >= 3 
                            ? 'Add new address' 
                            : 'Add new address',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: user.addresses.length >= 3 ? Colors.grey.shade600 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF8ECAE6))),
        error: (error, stackTrace) {
          return Center(
            child: Text(
              'Error loading user data',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF8ECAE6),
              ),
            ),
          );
        },
      ),
    );
  }
}
import 'package:boticart/features/auth/presentation/screens/search_location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

class EditAddressScreen extends ConsumerStatefulWidget {
  final String? address;
  final int? index;
  final bool isDefault;

  const EditAddressScreen({
    super.key,
    this.address,
    this.index,
    this.isDefault = false,
  });

  @override
  ConsumerState<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends ConsumerState<EditAddressScreen> {
  late TextEditingController _addressController;
  late TextEditingController _detailsController;
  bool _isLoading = false;
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(14.5995, 120.9842); 
  Set<Marker> _markers = {};
  bool _isMapReady = false;
  bool _isDefaultAddress = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.address ?? '');
    _detailsController = TextEditingController();
    _getUserLocation();
    _checkIfDefaultAddress();
    _loadAddressDetails();
  }

  Future<void> _loadAddressDetails() async {
    if (widget.address != null && widget.index != null) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .get();
        
        final addressesData = userDoc.data()?['addressesData'];
        if (addressesData != null && 
            addressesData is List && 
            widget.index! < addressesData.length) {
          
          final addressData = addressesData[widget.index!];
          if (addressData != null && addressData is Map<String, dynamic>) {
            // Load the details
            if (mounted) {
              setState(() {
                _detailsController.text = addressData['details'] ?? '';
                
                if (addressData['coordinates'] != null) {
                  final coordinates = addressData['coordinates'];
                  if (coordinates['latitude'] != null && coordinates['longitude'] != null) {
                    _selectedLocation = LatLng(
                      coordinates['latitude'],
                      coordinates['longitude']
                    );
                    _updateMarker();
                  }
                }
              });
            }
          }
        }
      }
    }
  }

  Future<void> _checkIfDefaultAddress() async {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .get();
      
      if (userDoc.data()?.containsKey('defaultAddress') ?? false) {
        String defaultAddr = userDoc.data()?['defaultAddress'];
        if (widget.address == defaultAddr) {
          setState(() {
            _isDefaultAddress = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _detailsController.dispose();  
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    if (widget.address != null && widget.address!.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(widget.address!)
            .catchError((e) {
          return <Location>[];
        });
        
        if (locations.isNotEmpty) {
          setState(() {
            _selectedLocation = LatLng(locations.first.latitude, locations.first.longitude);
            _updateMarker();
          });
          _getAddressFromLatLng();
        } else {
          _getCurrentLocation();
        }
      } catch (e) {
        _getCurrentLocation();
      }
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    final location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;
    loc.LocationData locationData;

    try {
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          return;
        }
      }

      setState(() {
        _isLoading = true;
      });
      
      locationData = await location.getLocation();
      
      setState(() {
        _selectedLocation = LatLng(
          locationData.latitude ?? _selectedLocation.latitude,
          locationData.longitude ?? _selectedLocation.longitude,
        );
        _updateMarker();
        _isLoading = false;
      });
      
      _getAddressFromLatLng();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
              _getAddressFromLatLng();
            });
          },
        ),
      };
    });

    if (_isMapReady && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 15),
      );
    }
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      ).catchError((e) {
        return <Placemark>[];
      });

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        
        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
        if (place.country != null && place.country!.isNotEmpty) addressParts.add(place.country!);
        
        String address = addressParts.join(', ');
                    
        setState(() {
          _addressController.text = address;
        });
      } else {
        setState(() {
          _addressController.text = 'Location selected (${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)})';
        });
      }
    } catch (e) {
      setState(() {
        _addressController.text = 'Location selected (${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)})';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _searchAddressAndUpdateMap(String address) async {
    if (address.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<Location> locations = await locationFromAddress(address)
          .catchError((e) {
        return <Location>[];
      });
      
      if (locations.isNotEmpty) {
        setState(() {
          _selectedLocation = LatLng(locations.first.latitude, locations.first.longitude);
          _updateMarker();
        });
        _getAddressFromLatLng();
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not find the address. Please try again.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error searching address: ${e.toString()}',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveAddress() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter an address',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  
    setState(() {
      _isLoading = true;
    });
  
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        throw Exception('User not found');
      }
  
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.id);
      
      // Create address object with main address and additional details
      Map<String, dynamic> addressData = {
        'mainAddress': _addressController.text.trim(),
        'details': _detailsController.text.trim(),
        'coordinates': {
          'latitude': _selectedLocation.latitude,
          'longitude': _selectedLocation.longitude,
        }
      };
      
      // Get current addresses collection
      final userDoc = await userRef.get();
      List<dynamic> currentAddresses = userDoc.data()?['addressesData'] ?? [];
      
      if (widget.index != null) {
        // Update existing address
        if (currentAddresses.length > widget.index!) {
          currentAddresses[widget.index!] = addressData;
        } else {
          currentAddresses.add(addressData);
        }
      } else {
        // Add new address
        currentAddresses.add(addressData);
      }
      
      // Update the addressesData field
      await userRef.update({
        'addressesData': currentAddresses,
      });
      
      // For backward compatibility, also update the addresses array with just the main address
      List<String> updatedAddresses = currentAddresses
          .map<String>((addr) => addr['mainAddress'] as String)
          .toList();
      
      await userRef.update({
        'addresses': updatedAddresses,
      });
      
      // Handle default address
      if (_isDefaultAddress) {
        // Store the current address as default in the user document
        await userRef.update({
          'defaultAddress': _addressController.text.trim(),
          'defaultAddressData': addressData
        });
      } else if (widget.address != null) {
        // Check if this was previously the default address
        final currentDefault = userDoc.data()?['defaultAddress'];
        
        // If this was the default address but is no longer, remove the default setting
        if (currentDefault == widget.address) {
          await userRef.update({
            'defaultAddress': FieldValue.delete(),
            'defaultAddressData': FieldValue.delete()
          });
        }
      }
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.index != null ? 'Address updated' : 'Address added',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF8ECAE6),
        ),
      );
      
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Edit your address',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8ECAE6),
          ),
        ),
        centerTitle: true,
        // Removed the Save button from here
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map with confirm button
                  Stack(
                    children: [
                      SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation,
                            zoom: 15,
                          ),
                          markers: _markers,
                          onMapCreated: (controller) {
                            _mapController = controller;
                            setState(() {
                              _isMapReady = true;
                              _updateMarker();
                            });
                          },
                          onTap: (position) {
                            setState(() {
                              _selectedLocation = position;
                              _updateMarker();
                              _getAddressFromLatLng();
                            });
                          },
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                        ),
                      ),
                      // Current location button
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white,
                          onPressed: _getCurrentLocation,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF8ECAE6),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location, color: Color(0xFF8ECAE6)),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: double.infinity,
                          color: const Color(0xFF8ECAE6),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8), 
                              Text(
                                'Confirm your map location',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Address section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address with chevron
                        InkWell(
                          onTap: () {
                            // Navigate to the search location screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchLocationScreen(
                                  onLocationSelected: (address, location) {
                                    setState(() {
                                      _addressController.text = address;
                                      _selectedLocation = location;
                                      _updateMarker();
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _addressController.text.isEmpty ? 'Select address' : _addressController.text,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Text(
                          'Address Details',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _detailsController,
                          decoration: InputDecoration(
                            hintText: 'Enter other details (optional)',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF8ECAE6)),
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _searchAddressAndUpdateMap(value);
                            }
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Set as default address',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            Switch(
                              value: _isDefaultAddress,
                              onChanged: (value) {
                                setState(() {
                                  _isDefaultAddress = value;
                                });
                              },
                              activeThumbColor: const Color(0xFF8ECAE6),
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
          // Add Save and Continue button at the bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8ECAE6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save and Continue',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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
}
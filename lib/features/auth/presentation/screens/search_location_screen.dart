import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class SearchLocationScreen extends StatefulWidget {
  final Function(String address, LatLng location) onLocationSelected;

  const SearchLocationScreen({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(14.5995, 120.9842); 
  Set<Marker> _markers = {};
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Debounce mechanism
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isLoading = true;
      });

      try {
        // Generate multiple search queries to get more comprehensive results
        List<String> searchQueries = [
          query,
          "$query, Philippines",
          "$query City, Philippines",
          "$query Street, Philippines",
          "$query Barangay, Philippines",
        ];

        List<Map<String, dynamic>> allResults = [];

        // Process each search query
        for (String searchQuery in searchQueries) {
          try {
            List<Location> locations = await locationFromAddress(searchQuery);
            
            for (var location in locations) {
              try {
                List<Placemark> placemarks = await placemarkFromCoordinates(
                  location.latitude,
                  location.longitude,
                );
                
                if (placemarks.isNotEmpty) {
                  for (var placemark in placemarks) {
                    // Create a more descriptive main address
                    String mainAddress = '';
                    
                    // Try to use the most specific part first
                    if (placemark.name != null && placemark.name!.isNotEmpty && placemark.name != placemark.street) {
                      mainAddress = placemark.name!;
                    } else if (placemark.street != null && placemark.street!.isNotEmpty) {
                      mainAddress = placemark.street!;
                    } else if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
                      mainAddress = placemark.subLocality!;
                    } else if (placemark.locality != null && placemark.locality!.isNotEmpty) {
                      mainAddress = placemark.locality!;
                    } else {
                      mainAddress = query;
                    }
                    
                    // Create a more descriptive sub address
                    List<String> subAddressParts = [];
                    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty && placemark.subLocality != mainAddress) {
                      subAddressParts.add(placemark.subLocality!);
                    }
                    if (placemark.locality != null && placemark.locality!.isNotEmpty && placemark.locality != mainAddress) {
                      subAddressParts.add(placemark.locality!);
                    }
                    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
                      subAddressParts.add(placemark.administrativeArea!);
                    }
                    
                    String subAddress = subAddressParts.join(', ');
                    
                    // Create full address
                    String fullAddress = [mainAddress, subAddress].where((e) => e.isNotEmpty).join(', ');
                    
                    // Check if this result is already in our list (avoid duplicates)
                    bool isDuplicate = allResults.any((result) => 
                      result['fullAddress'] == fullAddress && 
                      result['location'].latitude == location.latitude && 
                      result['location'].longitude == location.longitude
                    );
                    
                    // Only add if we have a meaningful address and it's not a duplicate
                    if (mainAddress.isNotEmpty && !isDuplicate) {
                      allResults.add({
                        'mainAddress': mainAddress,
                        'subAddress': subAddress,
                        'fullAddress': fullAddress,
                        'location': LatLng(location.latitude, location.longitude),
                        // Add relevance score based on how closely it matches the original query
                        'relevance': _calculateRelevance(query, mainAddress, subAddress),
                      });
                    }
                  }
                }
              } catch (e) {
                // Skip this location if there's an error getting placemarks
                continue;
              }
            }
          } catch (e) {
            // Skip this query if there's an error
            continue;
          }
        }
        
        // Sort results by relevance
        allResults.sort((a, b) => (b['relevance'] as double).compareTo(a['relevance'] as double));
        
        // Limit to top 10 results
        if (allResults.length > 10) {
          allResults = allResults.sublist(0, 10);
        }
        
        setState(() {
          _searchResults = allResults;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error searching for location. Please try a more specific search term.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // Calculate relevance score based on how closely the result matches the query
  double _calculateRelevance(String query, String mainAddress, String subAddress) {
    double score = 0.0;
    
    // Normalize strings for comparison
    String normalizedQuery = query.toLowerCase();
    String normalizedMain = mainAddress.toLowerCase();
    String normalizedSub = subAddress.toLowerCase();
    
    // Exact match in main address gets highest score
    if (normalizedMain == normalizedQuery) {
      score += 100.0;
    }
    // Main address contains query
    else if (normalizedMain.contains(normalizedQuery)) {
      score += 50.0;
    }
    // Query contains main address
    else if (normalizedQuery.contains(normalizedMain)) {
      score += 40.0;
    }
    
    // Sub address contains query
    if (normalizedSub.contains(normalizedQuery)) {
      score += 30.0;
    }
    
    // Check for word matches
    List<String> queryWords = normalizedQuery.split(' ');
    for (String word in queryWords) {
      if (word.length > 2) { // Only consider words with more than 2 characters
        if (normalizedMain.contains(word)) {
          score += 10.0;
        }
        if (normalizedSub.contains(word)) {
          score += 5.0;
        }
      }
    }
    
    return score;
  }

  void _selectLocation(Map<String, dynamic> result) {
    final LatLng location = result['location'];
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
        ),
      };
    });
    
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map at the top
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 15,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          
          // Search panel at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF8ECAE6)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search location',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onChanged: (value) {
                              if (value.length > 2) {
                                _searchLocation(value);
                              } else if (value.isEmpty) {
                                setState(() {
                                  _searchResults = [];
                                });
                              }
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  
                  // Search results
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF8ECAE6),
                            ),
                          )
                        : _searchResults.isEmpty && _searchController.text.isNotEmpty && _searchController.text.length > 2
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.location_off,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No results found',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try a different search term',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final result = _searchResults[index];
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFF8ECAE6),
                                    ),
                                    title: Text(
                                      result['mainAddress'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      result['subAddress'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    onTap: () {
                                      _selectLocation(result);
                                      widget.onLocationSelected(
                                        result['fullAddress'],
                                        result['location'],
                                      );
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
          
          // Back button at the top
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: const Color(0xFF8ECAE6),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
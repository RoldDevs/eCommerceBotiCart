import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/config/app_config.dart';

/// Service to get directions between two points
class DirectionsService {
  /// Route information for comparison
  static Map<String, dynamic> _parseRouteInfo(Map<String, dynamic> route) {
    int totalDuration = 0;
    int totalDurationInTraffic = 0;
    int totalDistance = 0;

    if (route['legs'] != null && route['legs'].isNotEmpty) {
      final legs = route['legs'] as List;
      for (var leg in legs) {
        if (leg['duration'] != null && leg['duration']['value'] != null) {
          totalDuration += leg['duration']['value'] as int;
        }
        if (leg['duration_in_traffic'] != null &&
            leg['duration_in_traffic']['value'] != null) {
          totalDurationInTraffic += leg['duration_in_traffic']['value'] as int;
        } else {
          // If no traffic data, use regular duration
          totalDurationInTraffic += totalDuration;
        }
        if (leg['distance'] != null && leg['distance']['value'] != null) {
          totalDistance += leg['distance']['value'] as int;
        }
      }
    }

    return {
      'duration': totalDuration,
      'duration_in_traffic': totalDurationInTraffic,
      'distance': totalDistance,
      'traffic_delay': totalDurationInTraffic - totalDuration,
    };
  }

  /// Calculate route score (lower is better)
  /// Considers: duration, distance, and traffic conditions
  static double _calculateRouteScore(Map<String, dynamic> routeInfo) {
    // Normalize values (assuming max reasonable values)
    const maxDuration = 7200; // 2 hours in seconds
    const maxDistance = 200000; // 200 km in meters
    const maxTrafficDelay = 1800; // 30 minutes in seconds

    final duration = routeInfo['duration_in_traffic'] as int;
    final distance = routeInfo['distance'] as int;
    final trafficDelay = routeInfo['traffic_delay'] as int;

    // Weighted scoring (duration is most important, then traffic, then distance)
    final durationScore = (duration / maxDuration) * 0.5; // 50% weight
    final trafficScore = (trafficDelay / maxTrafficDelay) * 0.3; // 30% weight
    final distanceScore = (distance / maxDistance) * 0.2; // 20% weight

    return durationScore + trafficScore + distanceScore;
  }

  /// Get route polyline between origin and destination
  /// Automatically selects the best route (shortest, fastest, least traffic)
  /// Returns list of LatLng points for the optimal route with real-time traffic data
  static Future<List<LatLng>> getRoutePolyline({
    required LatLng origin,
    required LatLng destination,
    String? apiKey,
  }) async {
    // Use API key from config if not provided
    final key = apiKey ?? AppConfig.googleMapsApiKey;

    // If API key is available, try to get directions from Google
    if (key.isNotEmpty && key != 'YOUR_GOOGLE_MAPS_API_KEY') {
      try {
        // Get current timestamp for real-time traffic-aware routing
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Request multiple route alternatives to find the best one
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&departure_time=$now' // Real-time traffic-aware routing
          '&traffic_model=best_guess' // Use best guess for traffic
          '&alternatives=true' // Get multiple route alternatives
          '&key=$key',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
            final routes = data['routes'] as List;

            // If only one route, use it
            if (routes.length == 1) {
              return _extractRoutePolyline(routes[0]);
            }

            // Compare multiple routes and select the best one
            Map<String, dynamic>? bestRoute;
            double bestScore = double.infinity;

            for (var route in routes) {
              final routeInfo = _parseRouteInfo(route);
              final score = _calculateRouteScore(routeInfo);

              if (score < bestScore) {
                bestScore = score;
                bestRoute = route;
              }
            }

            // Return the best route
            if (bestRoute != null) {
              return _extractRoutePolyline(bestRoute);
            }

            // Fallback to first route if comparison failed
            return _extractRoutePolyline(routes[0]);
          }
        }
      } catch (e) {
        // If API fails, fall through to straight line
        print('Directions API error: $e');
      }
    }

    // Fallback: return straight line between points
    // This provides a visual connection even without Directions API
    return [origin, destination];
  }

  /// Extract polyline points from a route
  static List<LatLng> _extractRoutePolyline(Map<String, dynamic> route) {
    // Use detailed polyline from route steps for more accurate route
    List<LatLng> allPoints = [];

    // Get detailed route from steps
    if (route['legs'] != null && route['legs'].isNotEmpty) {
      final legs = route['legs'] as List;
      for (var leg in legs) {
        if (leg['steps'] != null) {
          final steps = leg['steps'] as List;
          for (var step in steps) {
            if (step['polyline'] != null &&
                step['polyline']['points'] != null) {
              final stepPolyline = step['polyline']['points'] as String;
              final stepPoints = _decodePolyline(stepPolyline);
              allPoints.addAll(stepPoints);
            }
          }
        }
      }
    }

    // If we got detailed points, use them; otherwise use overview polyline
    if (allPoints.isNotEmpty) {
      return allPoints;
    } else if (route['overview_polyline'] != null &&
        route['overview_polyline']['points'] != null) {
      final polyline = route['overview_polyline']['points'] as String;
      return _decodePolyline(polyline);
    }

    return [];
  }

  /// Decode polyline string to list of LatLng points
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  /// Calculate distance between two points in kilometers
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    double dLat = _toRadians(point2.latitude - point1.latitude);
    double dLng = _toRadians(point2.longitude - point1.longitude);

    double a =
        (dLat / 2) * (dLat / 2) +
        _toRadians(point1.latitude) *
            _toRadians(point2.latitude) *
            (dLng / 2) *
            (dLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }
}

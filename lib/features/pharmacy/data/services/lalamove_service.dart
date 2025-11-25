import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LalamoveService {
  // Sandbox credentials
  static const String _apiKey = 'pk_test_712aacaf0ce4aab3b4472b5cac86a36d';
  static const String _apiSecret = 'sk_test_3BZBBzCuRcAKWFtObygYa8bUBejrPlxMqpB25b98Pw6LcPIo4SElsKL+PrT9pwMX';
  static const String _baseUrl = 'https://rest.sandbox.lalamove.com';
  static const String _apiVersion = 'v3';
  
  // Create a delivery order with Lalamove
  Future<Map<String, dynamic>> createDeliveryOrder({
    required String orderId,
    required String pickupAddress,
    required String deliveryAddress,
    required String customerPhone,
    required String customerName,
    String pharmacyName = 'Pharmacy',
    String pharmacyPhone = '+63',
    LatLng? pickupCoordinates,
    LatLng? deliveryCoordinates,
  }) async {
    try {
      // First, get a quotation
      final quotationResult = await _getQuotation(
        orderId: orderId,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        pickupCoordinates: pickupCoordinates,
        deliveryCoordinates: deliveryCoordinates,
      );
      
      final quotationId = quotationResult['data']['quotationId'];
      
      // Extract stop IDs from quotation result
      final stops = quotationResult['data']['stops'] as List;
      final pickupStopId = stops[0]['stopId'];
      final deliveryStopId = stops[1]['stopId'];
      
      final path = '/$_apiVersion/orders';
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create request body
      final body = {
        'data': {
          'quotationId': quotationId,
          'sender': {
            'stopId': pickupStopId,
            'name': pharmacyName,
            'phone': pharmacyPhone.startsWith('+') ? pharmacyPhone : '+63${pharmacyPhone.startsWith('0') ? pharmacyPhone.substring(1) : pharmacyPhone}',
          },
          'recipients': [
            {
              'stopId': deliveryStopId,
              'name': customerName,
              'phone': customerPhone.startsWith('+') ? customerPhone : '+63${customerPhone.startsWith('0') ? customerPhone.substring(1) : customerPhone}',
            }
          ],
          'isRecipientSMSEnabled': true,
        }
      };

      // Generate signature
      final signature = _generateSignature(
        method: 'POST',
        path: path,
        timestamp: timestamp,
        body: jsonEncode(body),
      );

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: {
          'Authorization': 'hmac $_apiKey:$timestamp:$signature',
          'Content-Type': 'application/json',
          'Market': 'PH', 
          'Request-ID': 'req_$orderId',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create Lalamove delivery: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating delivery order: $e');
    }
  }

  // Get a quotation first before creating an order
  Future<Map<String, dynamic>> _getQuotation({
    required String orderId,
    required String pickupAddress,
    required String deliveryAddress,
    LatLng? pickupCoordinates,
    LatLng? deliveryCoordinates,
  }) async {
    final path = '/$_apiVersion/quotations';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create request body with proper structure matching Lalamove API requirements
    final body = {
      'data': {
        'serviceType': 'MOTORCYCLE',
        'language': 'en_PH',
        'stops': [
          {
            'coordinates': {
              'lat': pickupCoordinates?.latitude.toString(),
              'lng': pickupCoordinates?.longitude.toString()
            },
            'address': pickupAddress,
          },
          {
            'coordinates': {
              'lat': deliveryCoordinates?.latitude.toString(),
              'lng': deliveryCoordinates?.longitude.toString()
            },
            'address': deliveryAddress,
          }
        ]
      }
    };

    // Generate signature
    final signature = _generateSignature(
      method: 'POST',
      path: path,
      timestamp: timestamp,
      body: jsonEncode(body),
    );

    // Make API request
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Authorization': 'hmac $_apiKey:$timestamp:$signature',
        'Content-Type': 'application/json',
        'Market': 'PH',
        'Request-ID': 'req_quotation_$orderId',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get Lalamove quotation: ${response.body}');
    }
  }


  // Get delivery status
  Future<Map<String, dynamic>> getDeliveryStatus(String deliveryId) async {
    final path = '/$_apiVersion/orders/$deliveryId';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Generate signature
    final signature = _generateSignature(
      method: 'GET',
      path: path,
      timestamp: timestamp,
      body: '',
    );

    // Make API request
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Authorization': 'hmac $_apiKey:$timestamp:$signature',
        'Content-Type': 'application/json',
        'Market': 'PH', 
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get delivery status: ${response.body}');
    }
  }

  // Generate HMAC signature for Lalamove API
  String _generateSignature({
    required String method,
    required String path,
    required String timestamp,
    required String body,
  }) {
    final rawSignature = '$timestamp\r\n$method\r\n$path\r\n\r\n$body';
    final key = utf8.encode(_apiSecret);
    final bytes = utf8.encode(rawSignature);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }
}
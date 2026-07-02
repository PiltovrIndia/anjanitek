// lib/utils/designoftheday.dart

import 'dart:convert';
import 'package:anjanitek/modals/product.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:http/http.dart';
import 'package:flutter/foundation.dart';


import 'api_urls.dart';

/// Fetches "Design of the Day" products from the API and returns a List<Product>.
/// - Returns an empty list when the API indicates "no data" (status 402 or 404).
/// - Throws an Exception on network errors or unexpected responses.
/// - Optionally provide a custom http.Client for testing.
Future<Object> getDesignOfTheDay() async {

  try {
    final uri = Uri.parse(APIUrls.getUrl("${APIUrls.products}${APIUrls.pass}/U9/", {}));
    final response = await get(uri, headers: {"Accept": "application/json"});

    // Basic HTTP-level check
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Network error: ${response.statusCode}');
    }

    final Map<String, dynamic> jsonObject = jsonDecode(response.body) as Map<String, dynamic>;
    final status = jsonObject['status'];

    if (status == 200) {
      final data = jsonObject['data'] as List<dynamic>? ?? [];
      final data1 = jsonObject['tags'] as List<dynamic>? ?? [];
      final List<Product> designDayList = data.map<Product>((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
      final List<ProductTag> productTagsList = data1.map<ProductTag>((json) => ProductTag.fromJson(json as Map<String, dynamic>)).toList();
      
      
      return {
        'products': designDayList,
        'tags': productTagsList,
      };

    } else if (status == 402 || status == 404) {
      
      return <Product>[];
    
    } else {
      // Unexpected API-level error; include message if available
      final message = jsonObject['message'] ?? 'Unexpected error from server';
      throw Exception('API error: $message (status: $status)');
    }
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('getDesignOfTheDay error: $e');
    }
    rethrow;
  } finally {
    
  }
}
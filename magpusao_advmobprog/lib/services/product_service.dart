import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/product.dart';

class ProductService {
  Future<List<Product>> getAllProducts() async {
    return _getProducts(Uri.parse('$host/products'));
  }

  Future<List<Product>> searchProducts(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return getAllProducts();
    }

    final searchUri = Uri.parse(
      '$host/products/search',
    ).replace(queryParameters: {'q': normalizedQuery});
    final products = await _getProducts(searchUri);
    if (products.isNotEmpty) {
      return products;
    }

    final fallbackQuery = fallbackQueryFor(normalizedQuery);
    if (fallbackQuery == null) {
      return products;
    }

    final fallbackUri = Uri.parse(
      '$host/products/search',
    ).replace(queryParameters: {'q': fallbackQuery});
    return _getProducts(fallbackUri);
  }

  static String? fallbackQueryFor(String query) {
    final terms = query.trim().split(RegExp(r'\s+'));
    if (terms.length < 2 || !RegExp(r'^\d+$').hasMatch(terms.last)) {
      return null;
    }
    return terms.sublist(0, terms.length - 1).join(' ');
  }

  Future<List<Product>> _getProducts(Uri uri) async {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List productsJson = data['products'] ?? [];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products (${response.statusCode})');
    }
  }
}

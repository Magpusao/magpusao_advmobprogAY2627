import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

/// Holds the cart for the current app session so Home and Cart use the same data.
class CartProvider extends ChangeNotifier {
  CartProvider({CartService? cartService})
    : _cartService = cartService ?? CartService();

  final CartService _cartService;
  final Map<int, CartProduct> _products = {};
  final Map<int, int> _quantities = {};
  bool _isLoading = false;
  bool _hasLoaded = false;
  Object? _loadError;

  List<CartProduct> get products => List.unmodifiable(_products.values);

  bool get isEmpty => _products.isEmpty;

  bool get isLoading => _isLoading;

  Object? get loadError => _loadError;

  int get totalQuantity =>
      _quantities.values.fold(0, (sum, quantity) => sum + quantity);

  double get subtotal => _products.values.fold(0, (sum, product) {
    return sum + (product.price * quantityOf(product));
  });

  double get discountedTotal => _products.values.fold(0, (sum, product) {
    return sum + (_discountedUnitPrice(product) * quantityOf(product));
  });

  Future<void> loadUserCart(int userId) async {
    if (_isLoading || _hasLoaded) return;

    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final cart = await _cartService.getCartByUser(userId);
      if (cart != null) {
        for (final product in cart.products) {
          // Keep anything the user added while the API request was running.
          if (_products.containsKey(product.id)) continue;
          _products[product.id] = product;
          _quantities[product.id] = product.quantity;
        }
      }
      _hasLoaded = true;
    } catch (error) {
      _loadError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryLoad(int userId) async {
    _hasLoaded = false;
    await loadUserCart(userId);
  }

  void addProduct(Product product) {
    final existing = _products[product.id];
    if (existing != null) {
      _quantities[product.id] = (quantityOf(existing) + 1).clamp(1, 99);
    } else {
      final discountedPrice =
          product.price * (1 - (product.discountPercentage / 100));
      _products[product.id] = CartProduct(
        id: product.id,
        title: product.title,
        price: product.price,
        quantity: 1,
        total: product.price,
        discountPercentage: product.discountPercentage,
        discountedTotal: discountedPrice,
        thumbnail: product.thumbnail,
      );
      _quantities[product.id] = 1;
    }
    notifyListeners();
  }

  int quantityOf(CartProduct product) => _quantities[product.id] ?? 0;

  void increaseQuantity(CartProduct product) {
    _quantities[product.id] = (quantityOf(product) + 1).clamp(1, 99);
    notifyListeners();
  }

  void decreaseQuantity(CartProduct product) {
    final updatedQuantity = quantityOf(product) - 1;
    if (updatedQuantity <= 0) {
      _products.remove(product.id);
      _quantities.remove(product.id);
    } else {
      _quantities[product.id] = updatedQuantity;
    }
    notifyListeners();
  }

  CartProduct withCurrentQuantity(CartProduct product) {
    final quantity = quantityOf(product);
    return CartProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      quantity: quantity,
      total: product.price * quantity,
      discountPercentage: product.discountPercentage,
      discountedTotal: _discountedUnitPrice(product) * quantity,
      thumbnail: product.thumbnail,
    );
  }

  double _discountedUnitPrice(CartProduct product) {
    return product.price * (1 - (product.discountPercentage / 100));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.userId = 5});

  final int userId;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<Cart?> _cartFuture;
  final Map<int, int> _quantities = {};
  final List<CartProduct> _cartProducts = [];
  int? _loadedCartId;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() {
    _quantities.clear();
    _cartProducts.clear();
    _loadedCartId = null;
    _cartFuture = CartService().getCartByUser(widget.userId);
  }

  void _retry() {
    setState(_loadCart);
  }

  void _changeQuantity(CartProduct product, int change) {
    final current = _quantities[product.id] ?? product.quantity;
    final updatedQuantity = current + change;
    setState(() {
      if (updatedQuantity <= 0) {
        _cartProducts.removeWhere((item) => item.id == product.id);
        _quantities.remove(product.id);
      } else {
        _quantities[product.id] = updatedQuantity.clamp(1, 99);
      }
    });
  }

  double _subtotal() {
    return _cartProducts.fold(0, (sum, product) {
      final quantity = _quantities[product.id] ?? product.quantity;
      return sum + (product.price * quantity);
    });
  }

  double _discountedTotal() {
    return _cartProducts.fold(0, (sum, product) {
      final quantity = _quantities[product.id] ?? product.quantity;
      final unitPrice = product.quantity == 0
          ? product.price
          : product.discountedTotal / product.quantity;
      return sum + (unitPrice * quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: FutureBuilder<Cart?>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _CartMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load the cart',
              message: '${snapshot.error}',
              actionLabel: 'Try again',
              onAction: _retry,
            );
          }

          final cart = snapshot.data;
          if (cart == null) {
            return const _CartMessage(
              icon: Icons.remove_shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Add a product from Home to get started.',
            );
          }

          if (_loadedCartId != cart.id) {
            _loadedCartId = cart.id;
            _cartProducts
              ..clear()
              ..addAll(cart.products);
            _quantities
              ..clear()
              ..addEntries(
                cart.products.map(
                  (product) => MapEntry(product.id, product.quantity),
                ),
              );
          }

          if (_cartProducts.isEmpty) {
            return const _CartMessage(
              icon: Icons.remove_shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Add a product from Home to get started.',
            );
          }

          final subtotal = _subtotal();
          final total = _discountedTotal();
          final savings = subtotal - total;

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _retry();
                    await _cartFuture;
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
                    itemCount: _cartProducts.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final product = _cartProducts[index];
                      final quantity = _quantities[product.id]!;
                      return _CartProductCard(
                        product: product,
                        quantity: quantity,
                        onIncrease: () => _changeQuantity(product, 1),
                        onDecrease: () => _changeQuantity(product, -1),
                        onOpen: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
                color: Theme.of(context).colorScheme.surface,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Subtotal', value: subtotal),
                      SizedBox(height: 4.h),
                      _SummaryRow(label: 'Discount', value: -savings),
                      Divider(height: 18.h),
                      _SummaryRow(
                        label: 'Total',
                        value: total,
                        emphasized: true,
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFBE24),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order confirmed successfully.'),
                              ),
                            );
                          },
                          child: const Text(
                            'Confirm Order',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartProductCard extends StatelessWidget {
  const _CartProductCard({
    required this.product,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    required this.onOpen,
  });

  final CartProduct product;
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              SizedBox(
                width: 78.w,
                height: 78.w,
                child: Hero(
                  tag: 'cart-product-${product.id}',
                  child: Image.network(
                    product.thumbnail,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: product.title,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFB300),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    CustomText(
                      text:
                          '${product.discountPercentage.toStringAsFixed(0)}% off - \$${product.total.toStringAsFixed(2)} total',
                      fontSize: 10.sp,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                children: [
                  _QuantityButton(icon: Icons.add, onPressed: onIncrease),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: CustomText(
                      text: '$quantity',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _QuantityButton(
                    icon: Icons.remove,
                    onPressed: onDecrease,
                    muted: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    this.muted = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34.w,
      height: 30.h,
      child: IconButton.filled(
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: muted
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : const Color(0xFFFFBE24),
          foregroundColor: muted ? Colors.black54 : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9.r),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 17.sp),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final formatted = value < 0
        ? '-\$${value.abs().toStringAsFixed(2)}'
        : '\$${value.toStringAsFixed(2)}';
    return Row(
      children: [
        Expanded(
          child: CustomText(
            text: label,
            fontSize: emphasized ? 15.sp : 12.sp,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          formatted,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: emphasized ? 16.sp : 12.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFFB300),
          ),
        ),
      ],
    );
  }
}

class _CartMessage extends StatelessWidget {
  const _CartMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 16.h),
            CustomText(
              text: title,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            CustomText(
              text: message,
              fontSize: 13.sp,
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              SizedBox(height: 16.h),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

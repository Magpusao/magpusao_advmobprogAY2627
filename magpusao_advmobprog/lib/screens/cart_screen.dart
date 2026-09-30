import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/cart.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.userId = 5});

  final int userId;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartProducts = cart.products;

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
      body: cart.isLoading && cart.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cart.loadError != null && cart.isEmpty
          ? _CartMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load the cart',
              message: '${cart.loadError}',
              actionLabel: 'Try again',
              onAction: () => cart.retryLoad(userId),
            )
          : cart.isEmpty
          ? const _CartMessage(
              icon: Icons.remove_shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Add a product from Home to get started.',
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
                    itemCount: cartProducts.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final product = cartProducts[index];
                      final quantity = cart.quantityOf(product);
                      return _CartProductCard(
                        product: product,
                        quantity: quantity,
                        onIncrease: () => cart.increaseQuantity(product),
                        onDecrease: () => cart.decreaseQuantity(product),
                        onOpen: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(
                                product: cart.withCurrentQuantity(product),
                              ),
                            ),
                          );
                        },
                      );
                    },
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
                        _SummaryRow(label: 'Subtotal', value: cart.subtotal),
                        SizedBox(height: 4.h),
                        _SummaryRow(
                          label: 'Discount',
                          value: -(cart.subtotal - cart.discountedTotal),
                        ),
                        Divider(height: 18.h),
                        _SummaryRow(
                          label: 'Total',
                          value: cart.discountedTotal,
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
                                  content: Text(
                                    'Order confirmed successfully.',
                                  ),
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
                          '${product.discountPercentage.toStringAsFixed(0)}% off - \$${(product.price * quantity).toStringAsFixed(2)} total',
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

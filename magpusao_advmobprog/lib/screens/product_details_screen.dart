import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 2: This screen receives the selected Product model and renders
// its complete details without making another request to the API endpoint.
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.userId = 5,
  });

  final Product product;
  final int userId;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isAdding = false;

  Product get product => widget.product;

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    try {
      final cart = await CartService().addToCart(
        userId: widget.userId,
        productId: product.id,
        quantity: 1,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.title} added to simulated cart #${cart.id}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add to cart: $error')));
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 270.h,
            color: colorScheme.surfaceContainerHighest,
            padding: EdgeInsets.all(24.w),
            child: Hero(
              tag: 'product-${product.id}',
              child: Image.network(
                product.thumbnail,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 80);
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: product.title,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(label: Text(product.category)),
                    if (product.brand.isNotEmpty)
                      Text(
                        product.brand,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14.sp,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Icon(Icons.star, color: colorScheme.primary),
                    SizedBox(width: 4.w),
                    CustomText(
                      text: product.rating.toStringAsFixed(1),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                CustomText(
                  text: '${product.stock} items in stock',
                  fontSize: 14.sp,
                ),
                SizedBox(height: 22.h),
                CustomText(
                  text: 'Description',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 8.h),
                CustomText(text: product.description, fontSize: 15.sp),
                SizedBox(height: 24.h),
                _DetailRow(
                  label: 'Shipping',
                  value: product.shippingInformation,
                ),
                _DetailRow(
                  label: 'Warranty',
                  value: product.warrantyInformation,
                ),
                _DetailRow(label: 'Returns', value: product.returnPolicy),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                    ),
                    onPressed: _isAdding ? null : _addToCart,
                    icon: _isAdding
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart),
                    label: Text(
                      _isAdding ? 'Adding…' : 'Add to Cart',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86.w,
            child: CustomText(
              text: label,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: CustomText(text: value, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}

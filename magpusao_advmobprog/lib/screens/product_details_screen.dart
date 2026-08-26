import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../widgets/custom_text.dart';

// Enhancement 2: This screen receives the selected Product model and renders
// its complete details without making another request to the API endpoint.
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

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
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const Icon(Icons.star, color: Colors.amber),
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

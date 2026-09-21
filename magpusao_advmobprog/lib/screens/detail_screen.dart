import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../widgets/custom_text.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.product});

  final CartProduct product;

  @override
  Widget build(BuildContext context) {
    final discountedUnitPrice = product.quantity == 0
        ? product.price
        : product.discountedTotal / product.quantity;

    return Scaffold(
      appBar: AppBar(title: const Text('Cart Item Details')),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          Container(
            height: 280.h,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Hero(
              tag: 'cart-product-${product.id}',
              child: Image.network(
                product.thumbnail,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image_outlined, size: 80),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          CustomText(
            text: product.title,
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: 8.h),
          Text(
            '\$${discountedUnitPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 24.h),
          _DetailRow(label: 'Quantity', value: '${product.quantity}'),
          _DetailRow(
            label: 'Original total',
            value: '\$${product.total.toStringAsFixed(2)}',
          ),
          _DetailRow(
            label: 'Discount',
            value: '${product.discountPercentage.toStringAsFixed(1)}%',
          ),
          _DetailRow(
            label: 'Discounted total',
            value: '\$${product.discountedTotal.toStringAsFixed(2)}',
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
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              text: label,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          CustomText(text: value, fontSize: 14.sp),
        ],
      ),
    );
  }
}

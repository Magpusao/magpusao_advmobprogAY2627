import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BrandedLoadingIndicator extends StatelessWidget {
  const BrandedLoadingIndicator({super.key, this.message = 'Loading...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/cat.png',
              key: const Key('brandedLoadingLogo'),
              width: 112.w,
              height: 112.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: 22.w,
              height: 22.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.secondary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

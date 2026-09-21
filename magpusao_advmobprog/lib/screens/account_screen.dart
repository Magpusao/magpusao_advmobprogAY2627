import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/custom_text.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _AccountTile(
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            subtitle: 'Review your current and previous orders',
            onTap: () => _showMessage(context, 'Order history is up to date.'),
          ),
          _AccountTile(
            icon: Icons.location_on_outlined,
            title: 'Delivery Address',
            subtitle: 'Manage your delivery details',
            onTap: () => _showMessage(context, 'No saved address yet.'),
          ),
          _AccountTile(
            icon: Icons.payment_outlined,
            title: 'Payment Methods',
            subtitle: 'Manage cards and payment preferences',
            onTap: () => _showMessage(context, 'No payment method saved.'),
          ),
          _AccountTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Theme and application preferences',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
          leading: Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: colors.primary),
          ),
          title: CustomText(
            text: title,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
          subtitle: CustomText(text: subtitle, fontSize: 11.sp),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

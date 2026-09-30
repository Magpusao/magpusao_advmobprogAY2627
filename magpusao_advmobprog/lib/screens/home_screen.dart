import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'chat_screen.dart';
import 'product_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = 'User'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _navigationBarHeight = 72;

  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().totalQuantity;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          ProductScreen(),
          CartScreen(userId: 5),
          AccountScreen(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              key: const Key('homeChatButton'),
              tooltip: 'Open chat',
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.black,
              shape: const CircleBorder(),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const ChatScreen(),
                  ),
                );
              },
              child: const Icon(Icons.chat, size: 25),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomAppBar(
        height: _navigationBarHeight,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: _NavigationButton(
                icon: Icons.home,
                label: 'Home',
                selected: _selectedIndex == 0,
                height: _navigationBarHeight,
                onPressed: () => _onTapped(0),
              ),
            ),
            Expanded(
              child: _NavigationButton(
                icon: Icons.shopping_cart,
                label: 'Cart',
                selected: _selectedIndex == 1,
                height: _navigationBarHeight,
                badgeCount: cartItemCount,
                onPressed: () => _onTapped(1),
              ),
            ),
            Expanded(
              child: _NavigationButton(
                icon: Icons.person,
                label: 'Account',
                selected: _selectedIndex == 2,
                height: _navigationBarHeight,
                onPressed: () => _onTapped(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.height,
    required this.onPressed,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final double height;
  final VoidCallback onPressed;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: SizedBox(
          height: height,
          child: Center(
            child: Badge(
              isLabelVisible: badgeCount > 0,
              label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
              child: Icon(icon, color: color, size: 27),
            ),
          ),
        ),
      ),
    );
  }
}

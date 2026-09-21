import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roles_advmobprog/models/cart.dart';
import 'package:roles_advmobprog/providers/theme_provider.dart';
import 'package:roles_advmobprog/screens/chat_screen.dart';
import 'package:roles_advmobprog/screens/home_screen.dart';
import 'package:roles_advmobprog/screens/settings_screen.dart';
import 'package:roles_advmobprog/services/product_service.dart';
import 'package:provider/provider.dart';

void main() {
  test('Cart.fromJson maps user cart totals and products', () {
    final cart = Cart.fromJson({
      'id': 19,
      'products': [
        {
          'id': 144,
          'title': 'Cricket Helmet',
          'price': 44.99,
          'quantity': 4,
          'total': 179.96,
          'discountPercentage': 11.47,
          'discountedTotal': 159.32,
          'thumbnail': 'https://example.com/helmet.png',
        },
      ],
      'total': 2492,
      'discountedTotal': 2140,
      'userId': 5,
      'totalProducts': 5,
      'totalQuantity': 14,
    });

    expect(cart.id, 19);
    expect(cart.userId, 5);
    expect(cart.total, 2492.0);
    expect(cart.products.single.title, 'Cricket Helmet');
    expect(cart.products.single.discountedTotal, 159.32);
  });

  test('CartProduct JSON conversion preserves add-to-cart values', () {
    final product = CartProduct.fromJson({
      'id': 98,
      'title': 'Rolex Submariner Watch',
      'price': 13999.99,
      'quantity': 1,
      'total': 13999.99,
      'discountPercentage': 0.82,
      'discountedTotal': 13885.19,
      'thumbnail': 'https://example.com/watch.png',
    });

    expect(product.toJson()['id'], 98);
    expect(product.toJson()['quantity'], 1);
    expect(product.toJson()['discountedTotal'], 13885.19);
  });

  test('numbered product searches provide a useful fallback term', () {
    expect(ProductService.fallbackQueryFor('iPhone 7'), 'iPhone');
    expect(ProductService.fallbackQueryFor('iPhone 5'), 'iPhone');
    expect(ProductService.fallbackQueryFor('motorcycle'), isNull);
  });

  test('light and dark themes keep the branded settings app bar', () {
    final provider = ThemeProvider();

    expect(
      provider.lightTheme.scaffoldBackgroundColor,
      const Color(0xFFF8F5FC),
    );
    expect(
      provider.lightTheme.appBarTheme.backgroundColor,
      const Color(0xFF3F51B5),
    );
    expect(provider.darkTheme.scaffoldBackgroundColor, const Color(0xFF121212));
    expect(provider.darkTheme.colorScheme.surface, const Color(0xFF1E1E1E));
    expect(
      provider.darkTheme.appBarTheme.backgroundColor,
      const Color(0xFF3F51B5),
    );
  });

  testWidgets('settings switch applies the selected theme state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 715);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = ThemeProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: provider,
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) => MaterialApp(
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const SettingsScreen(),
          ),
        ),
      ),
    );

    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.light,
    );
    expect(find.byIcon(Icons.light_mode), findsOneWidget);
    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Use the dark theme throughout the app'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(provider.isDark, isTrue);
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    expect(find.text('Light mode'), findsOneWidget);
    expect(find.text('Use the light theme throughout the app'), findsOneWidget);
    expect(find.text('Dark mode'), findsNothing);
  });

  testWidgets('chat button only appears on Home and opens the chat page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 715);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 715),
        builder: (context, child) => MaterialApp(
          theme: ThemeProvider().lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('homeChatButton')).hitTestable(),
      findsOneWidget,
    );
    final chatButton = tester.widget<FloatingActionButton>(
      find.byKey(const Key('homeChatButton')),
    );
    expect(chatButton.backgroundColor, const Color(0xFFFFBE24));
    expect(chatButton.foregroundColor, Colors.black);
    expect((chatButton.child! as Icon).icon, Icons.chat);

    await tester.tap(find.bySemanticsLabel('Cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('homeChatButton')).hitTestable(), findsNothing);

    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const Key('homeChatButton')).hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('homeChatButton')));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Chat messaging is not available yet.'), findsOneWidget);
    expect(find.byKey(const Key('homeChatButton')).hitTestable(), findsNothing);
  });
}

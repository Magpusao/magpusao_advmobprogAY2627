import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roles_advmobprog/models/cart.dart';
import 'package:roles_advmobprog/models/user.dart';
import 'package:roles_advmobprog/providers/theme_provider.dart';
import 'package:roles_advmobprog/screens/chat_screen.dart';
import 'package:roles_advmobprog/screens/home_screen.dart';
import 'package:roles_advmobprog/screens/profile_screen.dart';
import 'package:roles_advmobprog/screens/settings_screen.dart';
import 'package:roles_advmobprog/screens/signin_screen.dart';
import 'package:roles_advmobprog/screens/splash_screen.dart';
import 'package:roles_advmobprog/services/product_service.dart';
import 'package:roles_advmobprog/services/user_service.dart';
import 'package:roles_advmobprog/widgets/branded_loading.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    expect(ProductService.searchQueryFor('Motorcycle'), 'motorcycle');
    expect(ProductService.searchQueryFor(' motorcycle '), 'motorcycle');
    expect(ProductService.searchQueryFor('iPhone 7'), 'iPhone');
    expect(ProductService.searchQueryFor('IPHONE 7'), 'iPhone');
    expect(ProductService.fallbackQueryFor('iPhone 7'), 'iPhone');
    expect(ProductService.fallbackQueryFor('iPhone 5'), 'iPhone');
    expect(ProductService.fallbackQueryFor('motorcycle'), isNull);
  });

  test('UserService persists and clears authenticated user data', () async {
    SharedPreferences.setMockInitialValues({});
    final service = UserService();
    const user = User(
      id: 7,
      username: 'testuser',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      gender: 'female',
      image: 'https://example.com/avatar.png',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );

    await service.saveUserData(user.toJson());

    expect(await service.isLoggedIn(), isTrue);
    expect(await service.getUserData(), {
      ...user.toJson(),
      'username': UserService.profileUsername,
      'email': UserService.profileEmail,
      'firstName': UserService.profileFirstName,
      'lastName': UserService.profileLastName,
      'image': UserService.profileImageAsset,
    });

    await service.logout();
    expect(await service.isLoggedIn(), isFalse);
    expect(await service.getUserData(), isNull);
  });

  test('UserService accepts only the Meow credentials', () {
    expect(UserService.acceptsCredentials('Meow', 'Meow'), isTrue);
    expect(UserService.acceptsCredentials(' Meow ', 'Meow'), isTrue);
    expect(UserService.acceptsCredentials('emilys', 'emilyspass'), isFalse);
    expect(UserService.acceptsCredentials('Meow', 'wrong'), isFalse);
  });

  testWidgets('splash sends a signed-out user to Sign In', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 715),
        builder: (context, child) => MaterialApp(
          home: const SplashScreen(splashDuration: Duration.zero),
          routes: {
            '/signin': (_) => const Scaffold(body: Text('Sign In destination')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign In destination'), findsOneWidget);
  });

  testWidgets('splash and sign-in screens use the cat artwork', (tester) async {
    tester.view.physicalSize = const Size(412, 715);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 715),
        builder: (context, child) => MaterialApp(
          home: const SplashScreen(splashDuration: Duration(milliseconds: 1)),
          routes: {'/signin': (_) => const SignInScreen()},
        ),
      ),
    );

    final splashImage = tester.widget<Image>(
      find.byKey(const Key('splashLogo')),
    );
    expect(
      (splashImage.image as AssetImage).assetName,
      'assets/images/cat.png',
    );
    expect(splashImage.fit, BoxFit.contain);
    expect(find.text('Chiikawa Shop'), findsOneWidget);
    expect(find.text('Cute finds, delivered with a smile.'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    final signInImage = tester.widget<Image>(
      find.byKey(const Key('signInLogo')),
    );
    expect(
      (signInImage.image as AssetImage).assetName,
      'assets/images/cat.png',
    );
    expect(signInImage.fit, BoxFit.contain);
    expect(find.text('Username: Meow  •  Password: Meow'), findsOneWidget);
  });

  testWidgets('full-page loading state uses the cat logo', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 715),
        builder: (context, child) => const MaterialApp(
          home: Scaffold(
            body: BrandedLoadingIndicator(message: 'Loading products...'),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(
      find.byKey(const Key('brandedLoadingLogo')),
    );
    expect((image.image as AssetImage).assetName, 'assets/images/cat.png');
    expect(image.fit, BoxFit.contain);
    expect(find.text('Loading products...'), findsOneWidget);
  });

  testWidgets('profile uses the smart cat image from UserService', (
    tester,
  ) async {
    const user = User(
      id: 7,
      username: 'Meow',
      email: 'zandra.meow@car.com',
      firstName: 'Zandra',
      lastName: 'Meow',
      gender: 'female',
      image: 'https://example.com/old-avatar.png',
      accessToken: 'token',
      refreshToken: 'refresh',
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 715),
        builder: (context, child) =>
            const MaterialApp(home: ProfileScreen(user: user)),
      ),
    );

    final image = tester.widget<Image>(find.byKey(const Key('profileImage')));
    expect(
      (image.image as AssetImage).assetName,
      UserService.profileImageAsset,
    );
    expect(find.text('Zandra Meow'), findsOneWidget);
    expect(find.text('@Meow'), findsOneWidget);
    expect(find.text('zandra.meow@car.com'), findsOneWidget);
  });

  testWidgets('splash restores the saved user into Home', (tester) async {
    SharedPreferences.setMockInitialValues({
      'user_id': 7,
      'username': 'saveduser',
      'email': 'saved@example.com',
      'firstName': 'Saved',
      'lastName': 'User',
      'gender': 'female',
      'image': '',
      'accessToken': 'saved-token',
      'refreshToken': 'saved-refresh-token',
    });

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 715),
        builder: (context, child) => MaterialApp(
          home: const SplashScreen(splashDuration: Duration.zero),
          onGenerateRoute: (settings) {
            if (settings.name != '/home') return null;
            final user = User.fromJson(
              settings.arguments! as Map<String, dynamic>,
            );
            return MaterialPageRoute<void>(
              builder: (_) => Scaffold(body: Text(user.username)),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meow'), findsOneWidget);
  });

  test('themes use the complete smoothie palette', () {
    final provider = ThemeProvider();
    final light = provider.lightTheme;

    expect(light.scaffoldBackgroundColor, ThemeProvider.honeyOatmilk);
    expect(light.colorScheme.primary, ThemeProvider.avocadoSmoothie);
    expect(light.colorScheme.secondary, ThemeProvider.blushBeet);
    expect(light.colorScheme.tertiary, ThemeProvider.peachProtein);
    expect(light.colorScheme.primaryContainer, ThemeProvider.oatLatte);
    expect(light.colorScheme.surface, ThemeProvider.coconutCream);
    expect(light.appBarTheme.backgroundColor, ThemeProvider.avocadoSmoothie);
    expect(provider.darkTheme.scaffoldBackgroundColor, const Color(0xFF28271F));
    expect(provider.darkTheme.colorScheme.surface, const Color(0xFF343227));
    expect(
      provider.darkTheme.appBarTheme.backgroundColor,
      ThemeProvider.avocadoSmoothie,
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
    expect(chatButton.backgroundColor, ThemeProvider.blushBeet);
    expect(
      chatButton.foregroundColor,
      ThemeProvider().lightTheme.colorScheme.onSecondary,
    );
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

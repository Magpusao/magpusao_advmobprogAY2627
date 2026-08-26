import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/product.dart';

// services
import '../services/product_service.dart';

// widgets
import '../widgets/custom_text.dart';
import 'product_details_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Future<List<Product>> _productsFuture;

  // Enhancement 1: Store the search text so the fetched product list can be
  // filtered locally without sending another API request for every keystroke.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductService().getAllProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Enhancement 1: Search the product title, category, brand, and description.
  List<Product> _filterProducts(List<Product> products) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return products;
    }

    return products.where((product) {
      return product.title.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          // Enhancement 3: Open the separate settings screen where the user
          // can switch between the application's light and dark themes.
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: CustomText(
                text: 'Error: ${snapshot.error}',
                fontSize: 16.sp,
              ),
            );
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return Center(
              child: CustomText(text: 'No products found.', fontSize: 16.sp),
            );
          }

          final filteredProducts = _filterProducts(products);

          return Column(
            children: [
              // Enhancement 1: The search bar is displayed above the product
              // list and updates the visible cards while the user types.
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 4.h),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: CustomText(
                          text: 'No matching products found.',
                          fontSize: 16.sp,
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(10.w),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.w,
                          mainAxisSpacing: 10.h,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Card(
                            elevation: 2,
                            clipBehavior: Clip.antiAlias,
                            // Enhancement 2: Make the complete card clickable
                            // and pass its Product model to the details screen.
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailsScreen(product: product),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Hero(
                                        tag: 'product-${product.id}',
                                        child: Image.network(
                                          product.thumbnail,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.w),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                          text: product.title,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          '\$${product.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

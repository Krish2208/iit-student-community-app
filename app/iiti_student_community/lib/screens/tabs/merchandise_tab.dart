import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiti_student_community/models/product.dart';
import 'package:iiti_student_community/models/club.dart';
import 'package:iiti_student_community/screens/product_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MerchandiseTab extends StatefulWidget {
  const MerchandiseTab({super.key});

  @override
  State<MerchandiseTab> createState() => _MerchandiseTabState();
}

class _MerchandiseTabState extends State<MerchandiseTab> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Club> _clubs = [];
  bool _isLoading = true;

  // Filter states
  String _selectedAvailability = 'All';
  String _selectedType = 'All';
  String _selectedClub = 'All';

  @override
  void initState() {
    super.initState();
    _fetchProductsAndClubs();
  }

  Future<void> _fetchProductsAndClubs() async {
    try {
      // Fetch products
      final productsSnapshot =
          await FirebaseFirestore.instance.collection('merchandise').get();
      final products =
          productsSnapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();

      // Fetch clubs
      final clubsSnapshot =
          await FirebaseFirestore.instance.collection('clubs').get();
      final clubs =
          clubsSnapshot.docs.map((doc) => Club.fromFirestore(doc)).toList();

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _clubs = clubs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading merchandise: $e')));
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts =
          _allProducts.where((product) {
            // Apply availability filter
            if (_selectedAvailability == 'Available Only' &&
                !product.isAvailable()) {
              return false;
            }

            // Apply type filter
            if (_selectedType != 'All' && product.type != _selectedType) {
              return false;
            }

            // Apply club filter
            if (_selectedClub != 'All' && product.clubId != _selectedClub) {
              return false;
            }

            return true;
          }).toList();
    });
  }

  List<String> _getUniqueProductTypes() {
    final types = _allProducts.map((p) => p.type).toSet().toList();
    return ['All', ...types];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          // Filter section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merchandise',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Availability Filter
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: DropdownButton<String>(
                            value: _selectedAvailability,
                            underline: Container(),
                            icon: const Icon(Icons.filter_list),
                            items:
                                ['All', 'Available Only']
                                    .map(
                                      (item) => DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(item),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedAvailability = value!;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Type Filter
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: DropdownButton<String>(
                            value: _selectedType,
                            underline: Container(),
                            icon: const Icon(Icons.category),
                            items:
                                _getUniqueProductTypes()
                                    .map(
                                      (item) => DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(item),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Club Filter
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: DropdownButton<String>(
                            value: _selectedClub,
                            underline: Container(),
                            icon: const Icon(Icons.groups),
                            items:
                                ['All', ..._clubs.map((c) => c.id)]
                                    .map(
                                      (item) => DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(
                                          item == 'All'
                                              ? 'All Clubs'
                                              : _clubs
                                                  .firstWhere(
                                                    (club) => club.id == item,
                                                  )
                                                  .name,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedClub = value!;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Products grid
          Expanded(
            child:
                _filteredProducts.isEmpty
                    ? const Center(
                      child: Text('No products match your filters'),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return _buildProductCard(product);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child:
                  product.images.isNotEmpty
                      ? Container(
                        constraints: BoxConstraints(
                          maxWidth: 175, // Set maximum width
                          maxHeight: 150, // Set maximum height
                        ),
                        child: CachedNetworkImage(
                          imageUrl: product.images[0],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder:
                              (context, url) =>
                                  Center(child: CircularProgressIndicator()),
                          errorWidget:
                              (context, url, error) => Center(
                                child: Icon(Icons.image_not_supported),
                              ),
                        ),
                      )
                      : Container(
                        color: Colors.grey[300],
                        constraints: BoxConstraints(
                          maxWidth: 200, // Set maximum width
                          maxHeight: 200, // Set maximum height
                        ),
                        child: Center(child: Icon(Icons.image_not_supported)),
                      ),
            ),

            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.clubName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          product.isAvailable()
                              ? Icons.check_circle
                              : Icons.timer_off,
                          size: 16,
                          color:
                              product.isAvailable() ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.isAvailable() ? 'Available' : 'Closed',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                product.isAvailable()
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../models/cart_item.dart';

class ProductDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String restaurantId;

  const ProductDetailsSheet({
    super.key,
    required this.productData,
    required this.restaurantId,
  });

  @override
  State<ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<ProductDetailsSheet> {
  int quantity = 1;
  final Map<String, dynamic> selectedOptions = {};

  @override
  Widget build(BuildContext context) {
    final data = widget.productData;
    final String productId = data['id'];

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              /// ================= SCROLL CONTENT =================
              SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// CLOSE
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),

                    /// TITLE
                    Text(
                      data['name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// PRICE
                    Text(
                      '${data['price']} MAD',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// ================= OPTIONS =================
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('restaurants')
                          .doc(widget.restaurantId)
                          .collection('products')
                          .doc(productId)
                          .collection('options')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Text(
                            'Error loading options',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Text(
                            'No options available',
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        final options = snapshot.data!.docs;

                        return Column(
                          children: options.map((doc) {
                            final opt =
                                doc.data() as Map<String, dynamic>;

                            final values =
                                List<String>.from(opt['values']);

                            final type = opt['type'];

                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                /// OPTION TITLE
                                Text(
                                  opt['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                /// SINGLE CHOICE
                                if (type == 'single')
                                  ...values.map(
                                    (v) => RadioListTile<String>(
                                      title: Text(v),
                                      value: v,
                                      groupValue:
                                          selectedOptions[doc.id],
                                      onChanged: (val) {
                                        setState(() {
                                          selectedOptions[doc.id] = val;
                                        });
                                      },
                                    ),
                                  ),

                                /// MULTIPLE CHOICE
                                if (type == 'multiple')
                                  ...values.map(
                                    (v) => CheckboxListTile(
                                      title: Text(v),
                                      value:
                                          (selectedOptions[doc.id] ?? [])
                                              .contains(v),
                                      onChanged: (checked) {
                                        setState(() {
                                          selectedOptions[doc.id] ??= [];

                                          checked!
                                              ? selectedOptions[doc.id]
                                                  .add(v)
                                              : selectedOptions[doc.id]
                                                  .remove(v);
                                        });
                                      },
                                    ),
                                  ),

                                const SizedBox(height: 24),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              /// ================= STICKY FOOTER =================
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      /// QUANTITY -
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                      ),

                      Text(
                        '$quantity',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      /// QUANTITY +
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () =>
                            setState(() => quantity++),
                      ),

                      const SizedBox(width: 16),

                      /// ADD TO CART BUTTON
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF0FA958),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            final cart =
                                context.read<CartService>();

                            cart.addToCart(
                              CartItem(
                                productId: productId,
                                name: data['name'],
                                price:
                                    data['price'].toDouble(),
                                quantity: quantity,
                                options: selectedOptions,
                              ),
                            );

                            Navigator.pop(context);
                          },
                          child: Text(
                            'Add $quantity for ${(data['price'] * quantity).toStringAsFixed(0)} MAD',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
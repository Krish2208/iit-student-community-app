import 'package:flutter/material.dart';
import 'package:iiti_student_community/models/product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PurchaseScreen extends StatefulWidget {
  final Product product;

  const PurchaseScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  late Razorpay _razorpay;
  String? _selectedSize;
  String? _selectedColor;
  List<TextEditingController> _customizationControllers = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    // Initialize customization field controllers
    for (int i = 0; i < widget.product.customizationFields; i++) {
      _customizationControllers.add(TextEditingController());
    }
    
    // Set default values if available
    if (widget.product.sizesAvailable.isNotEmpty) {
      _selectedSize = widget.product.sizesAvailable.first;
    }
    
    if (widget.product.colorsAvailable.isNotEmpty) {
      _selectedColor = widget.product.colorsAvailable.first;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _customizationControllers.forEach((controller) => controller.dispose());
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Save the order to Firestore
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Create a list of customization values
      List<String> customizationValues = _customizationControllers.map((controller) => controller.text).toList();
      
      // Save to Firestore
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'productId': widget.product.id,
        'size': _selectedSize,
        'color': _selectedColor,
        'phoneNumber': _phoneController.text,
        'customization': customizationValues,
        'paymentId': response.paymentId,
        'status': 'paid',
        'orderedAt': FieldValue.serverTimestamp(),
      });
      
      // Show success message
      Fluttertoast.showToast(
        msg: "Payment successful! Order placed.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      
      // Close the bottom sheet
      Navigator.pop(context);
      
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Order placed but failed to save details. Please contact support.",
        backgroundColor: Colors.red,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
    });
    
    Fluttertoast.showToast(
      msg: "Payment failed: ${response.message}",
      backgroundColor: Colors.red,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
      msg: "External wallet selected: ${response.walletName}",
    );
  }

  void _initiatePayment() {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // Get current user
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Fluttertoast.showToast(msg: "Please login to continue");
      setState(() {
        _isProcessing = false;
      });
      return;
    }
    
    // Convert price to paise (RazorPay accepts amount in smallest currency unit)
    int amountInPaise = (widget.product.price * 100).toInt();
    
    // Create payment options
    var options = {
      'key': dotenv.env['RAZORPAY_KEY'] ?? '',
      'amount': amountInPaise,
      'name': 'IITI Student Community',
      'description': widget.product.name,
      'prefill': {
        'contact': _phoneController.text,
        'email': currentUser.email ?? '',
      },
      'notes': {
        'product_id': widget.product.id,
        'user_id': currentUser.uid,
      }
    };
    
    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      Fluttertoast.showToast(
        msg: "Error: Something went wrong while processing payment.",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Form title
              Center(
                child: Text(
                  'Complete Your Purchase',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Product summary
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (widget.product.images.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.product.images.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${widget.product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Size selection
              if (widget.product.sizesAvailable.isNotEmpty) ...[
                Text(
                  'Select Size',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: widget.product.sizesAvailable.map((size) {
                    return ChoiceChip(
                      label: Text(size),
                      selected: _selectedSize == size,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSize = size;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // Color selection
              if (widget.product.colorsAvailable.isNotEmpty) ...[
                Text(
                  'Select Color',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: widget.product.colorsAvailable.map((colorName) {
                      final color = widget.product.getColorFromName(colorName);
                      final isSelected = _selectedColor == colorName;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = colorName;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: color.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                colorName,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Phone number
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Customization fields
              if (widget.product.customizationFields > 0) ...[
                Text(
                  'Customization',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(widget.product.customizationFields, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextFormField(
                      controller: _customizationControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Custom Text ${index + 1}',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter custom text';
                        }
                        return null;
                      },
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
              
              // Pay Now button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'PAY NOW - ₹${widget.product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
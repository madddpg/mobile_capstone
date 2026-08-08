import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:iconstruct/core/firebase/firestore_error.dart';
import 'package:iconstruct/features/project_creation/data/project_lifecycle.dart';

class AcceptOfferScreen extends StatefulWidget {
  final String postId;
  final String quotationId;
  final String shopName;
  final String shopId;
  final double totalAmount;

  const AcceptOfferScreen({
    super.key,
    required this.postId,
    required this.quotationId,
    required this.shopName,
    required this.shopId,
    required this.totalAmount,
  });

  @override
  State<AcceptOfferScreen> createState() => _AcceptOfferScreenState();
}

class _AcceptOfferScreenState extends State<AcceptOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _socialContactController = TextEditingController();
  final _remarksController = TextEditingController();

  String _paymentArrangement = 'Full payment upon agreement';
  bool _isLoading = false;

  final List<String> _paymentOptions = [
    'Full payment upon agreement',
    'Installment',
    'Cash on delivery / pickup',
    'To be discussed with shop',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactNumberController.dispose();
    _socialContactController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _acceptOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final projectRef = FirebaseFirestore.instance
          .collection('projectPosts')
          .doc(widget.postId);
      final quotationRef = projectRef
          .collection('quotations')
          .doc(widget.quotationId);

      // Atomically claim the selected shop so two devices cannot accept
      // different quotations for the same post.
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final projectDoc = await transaction.get(projectRef);
        if (!projectDoc.exists) {
          throw Exception('Project post not found');
        }

        final postData = projectDoc.data() ?? <String, dynamic>{};
        if (postData['userId'] != user.uid) {
          throw Exception('Not authorized to accept offers for this project');
        }
        if (postData['selectedQuotationId'] != null) {
          throw Exception('already_accepted');
        }

        final quotationDoc = await transaction.get(quotationRef);
        if (!quotationDoc.exists) {
          throw Exception('Quotation not found');
        }

        transaction.update(projectRef, {
          'selectedQuotationId': widget.quotationId,
          'selectedShopId': widget.shopId,
          'selectedShopName': widget.shopName,
          'status': 'offer_accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(quotationRef, {
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        final savedProjectId = postData['projectId']?.toString();
        if (savedProjectId != null && savedProjectId.isNotEmpty) {
          final savedProjectRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('saved_projects')
              .doc(savedProjectId);
          transaction.set(
            savedProjectRef,
            {
              'status': ProjectLifecycle.supplierSelected,
              'selectedShopName': widget.shopName,
              'supplierSelectedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      });

      // Best-effort follow-up: reject remaining bids + record acceptance
      // contact details. Selection above is already committed.
      final batch = FirebaseFirestore.instance.batch();
      final quotationsSnapshot =
          await projectRef.collection('quotations').get();
      for (final doc in quotationsSnapshot.docs) {
        if (doc.id != widget.quotationId) {
          batch.update(doc.reference, {'status': 'rejected'});
        }
      }

      final acceptanceRef = projectRef.collection('acceptance').doc();
      batch.set(acceptanceRef, {
        'userId': user.uid,
        'shopId': widget.shopId,
        'shopName': widget.shopName,
        'quotationId': widget.quotationId,
        'fullName': _fullNameController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'socialContact': _socialContactController.text.trim(),
        'paymentArrangement': _paymentArrangement,
        'remarks': _remarksController.text.trim(),
        'totalAmount': widget.totalAmount,
        'createdAt': FieldValue.serverTimestamp(),
        'note': 'No transaction/payment processed inside iConstruct.',
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Offer accepted. You can now coordinate with the selected hardware shop.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        final already = e.toString().contains('already_accepted');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              already
                  ? 'You already accepted an offer for this project.'
                  : firestoreUserMessage(e, action: 'accept this offer'),
            ),
            backgroundColor: already ? Colors.orange : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color creamBg = Color(0xFFEDE4D4);
    const Color darkBlue = Color(0xFF2C3E50);
    const Color midBlue = Color(0xFF648DB6);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: creamBg),
        title: const Text(
          'Accept Offer',
          style: TextStyle(color: creamBg, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBlue, midBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: creamBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Shop: ${widget.shopName}',
                        style: const TextStyle(
                          color: darkBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Amount: ₱${widget.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: darkBlue.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Form Fields
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: creamBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Contact Number
                      TextFormField(
                        controller: _contactNumberController,
                        decoration: InputDecoration(
                          labelText: 'Contact Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your contact number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Social/Contact Link (Optional)
                      TextFormField(
                        controller: _socialContactController,
                        decoration: InputDecoration(
                          labelText:
                              'Social/Contact Link or Username (Optional)',
                          hintText: 'e.g., @username, Facebook link, etc.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Preferred Payment Arrangement',
                        style: TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Payment Arrangement Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _paymentArrangement,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        items: _paymentOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _paymentArrangement = value!);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Remarks
                      TextFormField(
                        controller: _remarksController,
                        decoration: InputDecoration(
                          labelText: 'Remarks / Notes (Optional)',
                          hintText: 'Any additional information...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 20),

                      // Helper Text
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Text(
                          'No payment is processed in iConstruct. This information is only used to coordinate with the selected hardware shop.',
                          style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _acceptOffer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkBlue,
                            foregroundColor: creamBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Color(0xFFEDE4D4),
                                )
                              : const Text(
                                  'Accept Offer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

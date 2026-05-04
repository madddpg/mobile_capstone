import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconstruct/features/bidding/screens/accept_offer_screen.dart';

class ProjectBidsScreen extends StatelessWidget {
  final String postId;
  final String projectName;

  const ProjectBidsScreen({
    super.key,
    required this.postId,
    required this.projectName,
  });

  List<Map<String, dynamic>> _parseMaterials(dynamic rawMaterials) {
    if (rawMaterials == null || rawMaterials is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawMaterials.map<Map<String, dynamic>>((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }

      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }

      return {
        'name': item.toString(),
        'quantity': 0,
        'unit': '',
        'size': null,
        'category': 'Material',
      };
    }).toList();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _money(dynamic value) {
    final amount = _toDouble(value);
    return '₱${amount.toStringAsFixed(2)}';
  }

  Map<String, dynamic>? _findMaterialQuote(
    List<Map<String, dynamic>> quotedMaterials,
    String materialName,
  ) {
    final target = materialName.trim().toLowerCase();

    for (final quote in quotedMaterials) {
      final name = (quote['name'] ?? '').toString().trim().toLowerCase();

      if (name == target) {
        return quote;
      }
    }

    return null;
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'accepted':
        bgColor = Colors.green.shade100;
        textColor = const Color(0xFF2E7D32);
        break;
      case 'rejected':
        bgColor = Colors.red.shade100;
        textColor = const Color(0xFFC62828);
        break;
      default:
        bgColor = Colors.orange.shade100;
        textColor = const Color(0xFFEF6C00);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status == 'accepted'
            ? 'Accepted'
            : status == 'rejected'
            ? 'Rejected'
            : 'Pending',
        style: TextStyle(color: textColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color creamBg = Color(0xFFEDE4D4);
    const Color darkBlue = Color(0xFF2C3E50);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: creamBg),
        title: Text(
          '$projectName Bids',
          style: const TextStyle(color: creamBg, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projectPosts')
            .doc(postId)
            .snapshots(),
        builder: (context, projectSnapshot) {
          if (projectSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: creamBg),
            );
          }

          if (projectSnapshot.hasError ||
              !projectSnapshot.hasData ||
              !projectSnapshot.data!.exists) {
            return Center(
              child: Text(
                'Error loading project details.',
                style: TextStyle(color: creamBg.withValues(alpha: 0.8)),
              ),
            );
          }

          final projectData =
              projectSnapshot.data!.data() as Map<String, dynamic>? ?? {};

          final projectMaterials = _parseMaterials(projectData['materials']);
          final selectedQuotationId = projectData['selectedQuotationId'];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projectPosts')
                .doc(postId)
                .collection('quotations')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: creamBg),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading bids.',
                    style: TextStyle(color: creamBg.withValues(alpha: 0.8)),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No bids yet.',
                    style: TextStyle(color: creamBg, fontSize: 16),
                  ),
                );
              }

              final quotations = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: quotations.length,
                itemBuilder: (context, index) {
                  final data = quotations[index].data() as Map<String, dynamic>;
                  final quotationId = quotations[index].id;

                  final shopName = (data['shopName'] ?? 'Unknown Shop')
                      .toString();

                  final quotedMaterials = _parseMaterials(data['materials']);

                  final totalAmount =
                      data['totalAmount'] ?? data['amount'] ?? 0;

                  final status = data['status'] ?? 'pending';

                  final isAccepted = selectedQuotationId == quotationId;
                  final hasAcceptedOffer = selectedQuotationId != null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                shopName,
                                style: const TextStyle(
                                  color: darkBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),

                        const SizedBox(height: 14),

                        if (projectMaterials.isEmpty)
                          const Text(
                            'No materials listed in this project.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          ...projectMaterials.map((projectMaterial) {
                            final materialName = (projectMaterial['name'] ?? '')
                                .toString();

                            final quantity = projectMaterial['quantity'] ?? 0;

                            final unit = (projectMaterial['unit'] ?? '')
                                .toString();

                            final size = (projectMaterial['size'] ?? '')
                                .toString();

                            final quote = _findMaterialQuote(
                              quotedMaterials,
                              materialName,
                            );

                            final unitPrice =
                                quote?['unitPrice'] ??
                                quote?['price'] ??
                                quote?['amount'];

                            final subtotal =
                                quote?['subtotal'] ??
                                (_toDouble(unitPrice) * _toDouble(quantity));

                            final hasQuote =
                                quote != null && _toDouble(unitPrice) > 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    materialName,
                                    style: const TextStyle(
                                      color: darkBlue,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    [
                                      if (quantity != null)
                                        'Qty: $quantity $unit',
                                      if (size.trim().isNotEmpty) 'Size: $size',
                                    ].join(' • '),
                                    style: TextStyle(
                                      color: darkBlue.withValues(alpha: 0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        hasQuote
                                            ? 'Unit Price: ${_money(unitPrice)}'
                                            : 'Unit Price: No quote',
                                        style: TextStyle(
                                          color: hasQuote
                                              ? darkBlue
                                              : Colors.grey.shade700,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        hasQuote
                                            ? _money(subtotal)
                                            : 'No quote',
                                        style: TextStyle(
                                          color: hasQuote
                                              ? Colors.green.shade800
                                              : Colors.grey.shade700,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 12),

                        const Divider(color: darkBlue),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Overall Total',
                              style: TextStyle(
                                color: darkBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _money(totalAmount),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Accept Offer Button
                        if (status.toLowerCase() == 'pending' &&
                            !hasAcceptedOffer)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Accept this offer?'),
                                    content: const Text(
                                      'This will mark this hardware shop\'s quotation as your selected offer. No payment or transaction will be made inside the app.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Continue'),
                                      ),
                                    ],
                                  ),
                                );

                                if (result == true && context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AcceptOfferScreen(
                                        postId: postId,
                                        quotationId: quotationId,
                                        shopName: shopName,
                                        shopId: data['shopId'] ?? '',
                                        totalAmount: _toDouble(totalAmount),
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkBlue,
                                foregroundColor: creamBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Accept Offer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else if (isAccepted)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Offer Accepted',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

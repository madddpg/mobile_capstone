import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuotationsScreen extends StatelessWidget {
  final String postId;

  const QuotationsScreen({super.key, required this.postId});

  static const Color bgCream = Color(0xFFF9F6F0);
  static const Color navyColor = Color(0xFF1E2A38);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: bgCream,
        elevation: 0,
        iconTheme: const IconThemeData(color: navyColor),
        title: const Text(
          "Shop Quotations",
          style: TextStyle(color: navyColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Sort lowest budget first
        stream: FirebaseFirestore.instance
            .collection('projectPosts')
            .doc(postId)
            .collection('quotations')
            .orderBy('estimatedTotal', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: navyColor),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: navyColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No quotations yet",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: navyColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Hardware shops will appear here once they submit bids for your posted project.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final quote = docs[index].data() as Map<String, dynamic>;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
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
                            quote['shopName'] ?? 'Unknown Shop',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: navyColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          "₱${quote['estimatedTotal']}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quote['message'] ?? '',
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSubDetail(
                          Icons.local_shipping,
                          "Fee: ₱${quote['deliveryFee']}",
                        ),
                        _buildSubDetail(
                          Icons.timer,
                          quote['estimatedLeadTime'] ?? 'N/A',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Future Phase Space (Accept/Reject logic later)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          // Navigate to individual full quotation details/accept flow (Phase 3)
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: navyColor,
                          backgroundColor: bgCream,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("View Full Details"),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSubDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black45),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

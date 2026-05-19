import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FundiCard extends StatelessWidget {
  final String name;
  final String profession;
  final double rating;
  final int reviews;
  final double distance;
  final double price;
  final bool isOnline;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isLoading;

  const FundiCard({
    Key? key,
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.price,
    this.isOnline = true,
    this.imageUrl,
    required this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildShimmerCard();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green.shade100,
                  child: imageUrl != null
                      ? ClipOval(
                          child: Image.network(imageUrl!, fit: BoxFit.cover),
                        )
                      : Icon(Icons.construction, size: 30, color: Colors.green),
                ),
              ),
              SizedBox(width: 12),
              // Info section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        if (isOnline)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      profession,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          " ($reviews reviews)",
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.location_on, size: 14, color: Colors.grey),
                        SizedBox(width: 2),
                        Text("${distance.toStringAsFixed(1)} km"),
                      ],
                    ),
                  ],
                ),
              ),
              // Price and book button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "KSh ${price.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text("starting price", style: TextStyle(fontSize: 11)),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Book", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

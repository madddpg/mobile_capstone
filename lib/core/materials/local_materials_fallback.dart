import 'models/material_category.dart';
import 'models/material_item.dart';

String _normalizeKey(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
}

/// Local fallback dataset used when the backend (Cloud Functions) is not
/// reachable and Firestore is empty/unseeded.
List<MaterialCategory> localMaterialsForProject(String projectQuery) {
  final key = _normalizeKey(projectQuery);

  // Supports the UI's "Bathroom\nRenovation" name and the backend slug "bathroom".
  final isBathroom = key == 'bathroom renovation' || key == 'bathroom';
  if (!isBathroom) return const <MaterialCategory>[];

  const floorSurface = 'Floor Surface';
  const floorInstallation = 'Floor Installation';
  const wallSurface = 'Wall Surface';
  const wallFinishing = 'Wall Finishing';

  return const <MaterialCategory>[
    MaterialCategory(
      title: floorSurface,
      items: <MaterialItem>[
        MaterialItem(
          name: 'Ceramic Tiles',
          category: floorSurface,
          description: 'Affordable, easy to maintain, and widely available.',
          isRecommended: true,
        ),
        MaterialItem(
          name: 'Porcelain Tiles',
          category: floorSurface,
          description: 'Dense and low-porosity; great for wet areas.',
          isRecommended: true,
        ),
        MaterialItem(
          name: 'Non-Slip Tiles',
          category: floorSurface,
          description: 'Textured finish that improves grip in wet zones.',
          isRecommended: true,
        ),
        MaterialItem(
          name: 'Vinyl Flooring',
          category: floorSurface,
          description: 'Budget-friendly and water-resistant options exist.',
          isRecommended: false,
        ),
        MaterialItem(
          name: 'Natural Stone Tiles',
          category: floorSurface,
          description: 'Premium look; usually needs sealing and maintenance.',
          isRecommended: false,
        ),
      ],
    ),
    MaterialCategory(
      title: floorInstallation,
      items: <MaterialItem>[
        MaterialItem(
          name: 'Tile Adhesive',
          category: floorInstallation,
          description: 'Bonding layer that fixes tiles to the substrate.',
          isRecommended: true,
        ),
        MaterialItem(
          name: 'Grout',
          category: floorInstallation,
          description:
              'Fills joints and locks tiles in place; choose mold-resistant.',
          isRecommended: true,
        ),
        MaterialItem(
          name: 'Tile Spacers',
          category: floorInstallation,
          description: 'Keeps tile gaps consistent for a clean finish.',
          isRecommended: false,
        ),
        MaterialItem(
          name: 'Self-Leveling Compound',
          category: floorInstallation,
          description: 'Helps create a flat surface before tiling.',
          isRecommended: false,
        ),
      ],
    ),
    MaterialCategory(
      title: wallSurface,
      items: <MaterialItem>[
        MaterialItem(
          name: 'Ceramic Wall Tiles',
          category: wallSurface,
          description: 'Classic wall finish with wide style options.',
          isRecommended: true,
        ),
        MaterialItem(
          name: 'Porcelain Wall Tiles',
          category: wallSurface,
          description: 'Durable and low-absorption surface.',
          isRecommended: true,
        ),
        MaterialItem(
          name: 'PVC Wall Panels',
          category: wallSurface,
          description: 'Quick install, water-resistant, and easy to clean.',
          isRecommended: false,
        ),
        MaterialItem(
          name: 'Marble Tiles',
          category: wallSurface,
          description: 'Luxury look; requires proper sealing in wet areas.',
          isRecommended: false,
        ),
      ],
    ),
    MaterialCategory(
      title: wallFinishing,
      items: <MaterialItem>[
        MaterialItem(
          name: 'Sealant',
          category: wallFinishing,
          description: 'Seals edges and joints to prevent water ingress.',
          isRecommended: true,
        ),
        MaterialItem(
          name: 'Waterproofing Coating',
          category: wallFinishing,
          description: 'Moisture barrier applied before tile work.',
          isRecommended: true,
        ),
        MaterialItem(
          name: 'Tile Trim',
          category: wallFinishing,
          description: 'Finishing profile for corners and exposed edges.',
          isRecommended: false,
        ),
        MaterialItem(
          name: 'Silicone Caulk',
          category: wallFinishing,
          description: 'Flexible joint seal for corners/changes in plane.',
          isRecommended: false,
        ),
      ],
    ),
  ];
}

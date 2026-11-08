import 'package:flutter_test/flutter_test.dart';

import 'package:iconstruct/features/project_creation/data/bom_quantity_estimator.dart';
import 'package:iconstruct/features/project_creation/data/ph_renovation_rates.dart';
import 'package:iconstruct/features/project_creation/data/renovation_templates.dart';

void main() {
  const area = 12.0;

  test('vinyl flooring scales by qtyPerSqm, not as ceramic tile pieces', () {
    final item = RenovationTemplateItem(
      name: 'Vinyl Flooring',
      category: 'Flooring',
      unit: 'sqm',
      defaultQuantity: 1,
      qtyPerSqm: 1.0,
    );

    final qty = BomQuantityEstimator.estimateQuantity(item: item, areaSqm: area);
    final expected = (area * 1.0 * 1.08).ceilToDouble();
    expect(qty, expected);
    expect(
      qty,
      isNot(PhRenovationRates.calculateFloorTilePieces(area, '600x600')),
    );
  });

  test('roof tiles use qtyPerSqm, not floor-tile piece math', () {
    final item = RenovationTemplateItem(
      name: 'Roof Tiles',
      category: 'Roofing',
      unit: 'pcs',
      defaultQuantity: 40,
      qtyPerSqm: 1.2,
    );

    final qty = BomQuantityEstimator.estimateQuantity(item: item, areaSqm: 40);
    final expected = (40 * 1.2 * 1.08).ceilToDouble();
    expect(qty, expected);
  });

  test('sandpaper pack is not washed-sand cubic meters', () {
    final item = RenovationTemplateItem(
      name: 'Sandpaper Pack',
      category: 'Tools & Supplies',
      unit: 'packs',
      defaultQuantity: 2,
    );

    final qty = BomQuantityEstimator.estimateQuantity(item: item, areaSqm: area);
    expect(qty, 2);
    expect(
      qty,
      isNot(PhRenovationRates.calculateTileBeddingMortar(area).sandCum),
    );
  });

  test('paint roller set is not paint gallons', () {
    final item = RenovationTemplateItem(
      name: 'Paint roller set',
      category: 'Tools & Supplies',
      unit: 'pcs',
      defaultQuantity: 1,
    );

    final qty = BomQuantityEstimator.estimateQuantity(item: item, areaSqm: area);
    expect(qty, 1);
    expect(
      qty,
      isNot(PhRenovationRates.calculatePaintWorks(area).totalGal),
    );
  });

  test('tile adhesive size recalc stays bag-based, not tile pieces', () {
    final adhesive = RenovationTemplateItem(
      name: 'Tile Adhesive',
      category: 'Floor Installation',
      unit: 'bags',
      defaultQuantity: 3,
    );

    final result = BomQuantityEstimator.recalculateForSize(
      item: adhesive,
      newSize: '300x300',
      areaSqm: area,
    );

    expect(
      result.newQty,
      PhRenovationRates.calculateTileAdhesiveBags(area),
    );
    expect(
      result.newQty,
      isNot(PhRenovationRates.calculateFloorTilePieces(area, '300x300')),
    );
  });

  test('ceramic floor tiles still use piece formulas', () {
    final item = RenovationTemplateItem(
      name: 'Ceramic Floor Tiles',
      category: 'Floor Surface',
      unit: 'pcs',
      defaultQuantity: 1,
      size: '600x600',
    );

    final qty = BomQuantityEstimator.estimateQuantity(item: item, areaSqm: area);
    expect(qty, PhRenovationRates.calculateFloorTilePieces(area, '600x600'));
  });
}

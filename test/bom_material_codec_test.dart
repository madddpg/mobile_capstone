import 'package:flutter_test/flutter_test.dart';
import 'package:iconstruct/features/project_creation/data/bom_material_codec.dart';

void main() {
  group('BomMaterialCodec', () {
    test('normalize keeps quantity/unit/size/category on structured rows', () {
      final normalized = BomMaterialCodec.normalize([
        {
          'name': 'Ceramic floor tiles',
          'quantity': 13.75,
          'unit': 'sqm',
          'size': '600x600',
          'category': 'Floor Surface',
          'kind': 'Flooring',
        },
        'Legacy plain name',
      ]);

      expect(normalized, hasLength(2));
      expect(normalized.first['name'], 'Ceramic floor tiles');
      expect(normalized.first['quantity'], 13.75);
      expect(normalized.first['unit'], 'sqm');
      expect(normalized.first['size'], '600x600');
      expect(normalized.first['category'], 'Floor Surface');
      expect(normalized.first['kind'], 'Flooring');

      expect(normalized.last['name'], 'Legacy plain name');
      expect(normalized.last['quantity'], 0);
      expect(normalized.last['category'], 'Material');
    });

    test('edit→save round-trip does not zero quantities', () {
      final original = [
        BomMaterialCodec.plumbingRow(
          categoryTitle: 'Fixtures',
          kind: 'Toilet',
          materialName: 'Toilet bowl set',
          unit: 'pcs',
          quantity: 2,
        ),
        BomMaterialCodec.tileRow(
          tileTypeName: 'Porcelain tile',
          tileSizeGroup: 'Floor',
          tileSizeName: '600x600',
          quantity: 40,
        ),
      ];

      final reloaded = BomMaterialCodec.normalize(original);
      final reserialized = BomMaterialCodec.serialize(
        looseNames: const [],
        tileRows: [
          for (final row in reloaded.where(
            (r) => BomMaterialCodec.isTilesCategory('${r['category']}'),
          ))
            BomMaterialCodec.tileRow(
              tileTypeName: '${row['name']}',
              tileSizeGroup: '${row['kind'] ?? ''}',
              tileSizeName: '${row['size'] ?? ''}',
              quantity: BomMaterialCodec.asQuantity(row['quantity']),
            ),
        ],
        plumbingRows: [
          for (final row in reloaded.where(
            (r) => !BomMaterialCodec.isTilesCategory('${r['category']}'),
          ))
            BomMaterialCodec.plumbingRow(
              categoryTitle: '${row['category']}',
              kind: '${row['kind'] ?? ''}',
              materialName: '${row['name']}',
              unit: '${row['unit'] ?? 'Qty.'}',
              quantity: BomMaterialCodec.asQuantity(row['quantity']),
              size: row['size']?.toString(),
            ),
        ],
      );

      expect(reserialized, hasLength(2));
      expect(
        reserialized.map((r) => BomMaterialCodec.asQuantity(r['quantity'])),
        containsAll([2, 40]),
      );
      expect(
        reserialized.any(
          (r) =>
              r['name'] == 'Toilet bowl set' &&
              BomMaterialCodec.asQuantity(r['quantity']) == 0,
        ),
        isFalse,
      );
    });

    test('serialize preserves tile size group and plumbing kind', () {
      final rows = BomMaterialCodec.serialize(
        looseNames: const ['Spare cement'],
        tileRows: [
          BomMaterialCodec.tileRow(
            tileTypeName: 'Tile A',
            tileSizeGroup: 'Wall',
            tileSizeName: '300x600',
            quantity: 12,
          ),
        ],
        plumbingRows: [
          BomMaterialCodec.plumbingRow(
            categoryTitle: 'Pipes',
            kind: 'PVC',
            materialName: 'Pipe 1/2',
            unit: 'meters',
            quantity: 8,
            size: '1/2"',
            length: '3m',
          ),
        ],
      );

      expect(rows, hasLength(3));
      expect(rows[0]['name'], 'Spare cement');
      expect(rows[0]['quantity'], 0);
      expect(rows[1]['kind'], 'Wall');
      expect(rows[1]['category'], 'Tiles');
      expect(rows[2]['kind'], 'PVC');
      expect(rows[2]['length'], '3m');
      expect(rows[2]['quantity'], 8);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:iconstruct/core/models/project_model.dart';

void main() {
  group('ProjectModel.fromMap', () {
    test('tolerates numeric strings and empty postId', () {
      final model = ProjectModel.fromMap('p1', {
        'projectName': 'Kitchen refresh',
        'projectType': 'Kitchen',
        'materialsCount': '4',
        'totalAreaSqm': '18.5',
        'costLevel': 'medium',
        'materials': [
          {'name': 'Tile', 'quantity': 10},
        ],
        'status': 'planning',
        'updatedAt': DateTime.utc(2026, 1, 2),
        'postId': '',
      });

      expect(model.id, 'p1');
      expect(model.materialCount, 4);
      expect(model.projectArea, 18.5);
      expect(model.postId, isNull);
      expect(model.lastUpdated, DateTime.utc(2026, 1, 2));
    });

    test('coerces double materialsCount without throwing', () {
      final model = ProjectModel.fromMap('p2', {
        'materialsCount': 3.0,
        'totalAreaSqm': 12,
        'materials': const <dynamic>[],
      });

      expect(model.materialCount, 3);
      expect(model.projectArea, 12);
    });
  });
}

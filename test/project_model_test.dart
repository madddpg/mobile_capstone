import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconstruct/core/models/project_model.dart';

class _FakeDoc implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDoc(this._id, this._data);

  final String _id;
  final Map<String, dynamic>? _data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProjectModel.fromDocument', () {
    test('tolerates numeric strings and empty postId', () {
      final model = ProjectModel.fromDocument(
        _FakeDoc('p1', {
          'projectName': 'Kitchen refresh',
          'projectType': 'Kitchen',
          'materialsCount': '4',
          'totalAreaSqm': '18.5',
          'costLevel': 'medium',
          'materials': [
            {'name': 'Tile', 'quantity': 10},
          ],
          'status': 'planning',
          'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
          'postId': '',
        }),
      );

      expect(model.id, 'p1');
      expect(model.materialCount, 4);
      expect(model.projectArea, 18.5);
      expect(model.postId, isNull);
      expect(model.lastUpdated, DateTime.utc(2026, 1, 2));
    });

    test('coerces double materialsCount without throwing', () {
      final model = ProjectModel.fromDocument(
        _FakeDoc('p2', {
          'materialsCount': 3.0,
          'totalAreaSqm': 12,
          'materials': const <dynamic>[],
        }),
      );

      expect(model.materialCount, 3);
      expect(model.projectArea, 12);
    });
  });
}

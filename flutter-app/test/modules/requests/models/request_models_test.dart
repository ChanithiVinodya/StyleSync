import 'package:flutter_test/flutter_test.dart';
import 'package:stylesync/modules/requests/models/request_models.dart';

void main() {
  group('RequestModels JSON parsing tests', () {
    test('RequestStatus enum parsing', () {
      expect(RequestStatus.fromJson('draft'), RequestStatus.draft);
      expect(RequestStatus.fromJson('SUBMITTED'), RequestStatus.submitted);
      expect(RequestStatus.fromJson('unknown_value'), RequestStatus.draft); // fallback
    });

    test('RoomType enum parsing', () {
      expect(RoomType.fromJson('livingRoom'), RoomType.livingRoom);
      expect(RoomType.fromJson('BATHROOM'), RoomType.bathroom);
      expect(RoomType.fromJson('weird_room'), RoomType.livingRoom); // fallback
    });

    test('PaletteColour parses correctly with missing fields', () {
      final model = PaletteColour.fromJson(const {});
      expect(model.hexValue, '');
      expect(model.position, 0);

      final fullModel = PaletteColour.fromJson(const {'hexValue': '#FFFFFF', 'position': 2});
      expect(fullModel.hexValue, '#FFFFFF');
      expect(fullModel.position, 2);
    });

    test('RequestSummary parses correctly with minimal missing fields', () {
      final json = {
        'id': 'req-123',
        'referenceNumber': 'REF-123',
        'status': 'Approved',
        // missing budget, createdAt, etc to test defaults
      };

      final model = RequestSummary.fromJson(json);
      expect(model.id, 'req-123');
      expect(model.referenceNumber, 'REF-123');
      expect(model.status, RequestStatus.approved);
      expect(model.budget, 0.0);
      expect(model.isFlagged, false);
      expect(model.roomType, RoomType.livingRoom); // Default fallback for empty
      expect(model.thumbnailUrl, isNull);
    });

    test('RequestDetail parses correctly with missing optional fields', () {
      final json = {
        'id': 'detail-1',
        'status': 'InProgress'
      };

      final model = RequestDetail.fromJson(json);
      expect(model.id, 'detail-1');
      expect(model.status, RequestStatus.inProgress);
      expect(model.budget, isNull);
      expect(model.roomType, isNull);
      expect(model.submittedAt, isNull);
      expect(model.palette, isEmpty);
      expect(model.moodboard, isEmpty);
      expect(model.isFlagged, false);
    });

    test('PagedResult parses correctly with unknown/missing fields', () {
      final json = <String, dynamic>{
        // missing items and paging data
      };

      final model = PagedResult<RequestSummary>.fromJson(json, (data) => RequestSummary.fromJson(data as Map<String, dynamic>));
      expect(model.items, isEmpty);
      expect(model.totalCount, 0);
      expect(model.page, 1);
      expect(model.pageSize, 10);
    });

    test('ApiProblem parses standard RFC problem details and array formats', () {
      final json1 = {
        'title': 'Error',
        'status': 400,
        'errors': {
          'Budget': ['Too low']
        }
      };

      final problem1 = ApiProblem.fromJson(json1);
      expect(problem1.errors.length, 1);
      expect(problem1.errors.first.field, 'Budget');
      expect(problem1.errors.first.message, 'Too low');
      expect(problem1.toString(), 'Too low');

      final json2 = {
        'title': 'Component2 custom error',
        'errors': [
          {'field': '', 'code': 'REQUEST_NOT_DRAFT', 'message': 'Must be draft'}
        ]
      };
      
      final problem2 = ApiProblem.fromJson(json2);
      expect(problem2.errors.length, 1);
      expect(problem2.errors.first.code, 'REQUEST_NOT_DRAFT');
    });
  });
}

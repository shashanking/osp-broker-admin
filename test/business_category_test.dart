import 'package:flutter_test/flutter_test.dart';
import 'package:osp_broker_admin/features/business_directories/domain/business_directories_model.dart';

void main() {
  group('BusinessCategory Model Tests', () {
    test('should create BusinessCategory with isDeleted field', () {
      final category = BusinessCategory(
        id: '123',
        name: 'Test Category',
        description: 'Test Description',
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        business: [],
      );
      
      expect(category.id, '123');
      expect(category.name, 'Test Category');
      expect(category.isDeleted, false);
      expect(category.isActive, true);
      expect(category.statusText, 'Active');
    });
    
    test('should handle deleted category correctly', () {
      final category = BusinessCategory(
        id: '123',
        name: 'Deleted Category',
        description: 'Test Description',
        isDeleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        business: [],
      );
      
      expect(category.isDeleted, true);
      expect(category.isActive, false);
      expect(category.statusText, 'Deleted');
    });
    
    test('should parse JSON with isDeleted field', () {
      final json = {
        'id': '686640a189be9b9268005883',
        'name': 'Hotel',
        'description': 'Businesses that serve food and beverages to customers.',
        'isDeleted': true,
        'createdAt': '2025-07-03T08:34:41.341Z',
        'updatedAt': '2025-08-11T06:45:58.157Z',
        'business': [
          {
            'id': '686641dea421f17f10f54f0b',
            'businessName': 'fintech  Pvt. ltd.'
          }
        ]
      };
      
      final category = BusinessCategory.fromJson(json);
      
      expect(category.id, '686640a189be9b9268005883');
      expect(category.name, 'Hotel');
      expect(category.isDeleted, true);
      expect(category.business.length, 1);
      expect(category.business[0].name, 'fintech  Pvt. ltd.');
    });
  });
}

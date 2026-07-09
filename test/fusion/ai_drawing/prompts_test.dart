import 'package:flutter_test/flutter_test.dart';
import 'package:math_anchor/fusion/ai_drawing/prompts/math_prompts.dart';
import 'package:math_anchor/fusion/models/ai_models.dart';

void main() {
  group('MathDrawingPrompts Tests', () {
    test('visualizeTemplate should contain expected placeholders', () {
      expect(MathDrawingPrompts.visualizeTemplate, contains('{description}'));
    });

    test('optimizeTemplate should contain expected placeholders', () {
      expect(MathDrawingPrompts.optimizeTemplate, contains('{current_code}'));
      expect(MathDrawingPrompts.optimizeTemplate, contains('{instruction}'));
    });

    test('repairTemplate should contain expected placeholders', () {
      expect(MathDrawingPrompts.repairTemplate, contains('{current_code}'));
      expect(MathDrawingPrompts.repairTemplate, contains('{error_text}'));
    });

    test('getPrompt should return correct template', () {
      expect(MathDrawingPrompts.getPrompt('visualize'), MathDrawingPrompts.visualizeTemplate);
      expect(MathDrawingPrompts.getPrompt('optimize'), MathDrawingPrompts.optimizeTemplate);
      expect(MathDrawingPrompts.getPrompt('repair'), MathDrawingPrompts.repairTemplate);
    });

    test('formatTemplate should replace placeholders', () {
      final result = MathDrawingPrompts.formatTemplate(
        'Hello {name}, you are {age} years old.',
        {'name': 'Alice', 'age': '30'},
      );

      expect(result, contains('Alice'));
      expect(result, contains('30'));
      expect(result, isNot(contains('{name}')));
      expect(result, isNot(contains('{age}')));
    });
  });

  group('AI Models Tests', () {
    test('AIGenerationResult.success should create successful result', () {
      final result = AIGenerationResult.success(
        code: 'test code',
        promptType: 'visualize',
      );

      expect(result.isSuccess, true);
      expect(result.code, 'test code');
      expect(result.promptType, 'visualize');
      expect(result.errorMessage, null);
    });

    test('AIGenerationResult.failure should create failed result', () {
      final result = AIGenerationResult.failure(
        errorMessage: 'test error',
        promptType: 'visualize',
      );

      expect(result.isSuccess, false);
      expect(result.code, isEmpty);
      expect(result.errorMessage, 'test error');
      expect(result.promptType, 'visualize');
    });

    test('AIGenerationResult serialization should work', () {
      final original = AIGenerationResult.success(
        code: 'test code',
        promptType: 'optimize',
      );

      final json = original.toJson();
      final restored = AIGenerationResult.fromJson(json);

      expect(restored.isSuccess, original.isSuccess);
      expect(restored.code, original.code);
      expect(restored.promptType, original.promptType);
    });

    test('VisualizationRequest should serialize correctly', () {
      final request = VisualizationRequest(
        description: 'test description',
        type: VisualizationType.function,
        parameters: {'key': 'value'},
      );

      final json = request.toJson();
      expect(json['description'], 'test description');
      expect(json['type'], contains('function'));
      expect(json['parameters'], {'key': 'value'});
    });

    test('VisualizationRecord should serialize correctly', () {
      final record = VisualizationRecord(
        id: 'test-id',
        description: 'test description',
        generatedCode: 'test code',
        type: VisualizationType.geometry,
        createdAt: DateTime(2024, 1, 1),
        tags: ['tag1', 'tag2'],
        isFavorite: true,
      );

      final json = record.toJson();
      expect(json['id'], 'test-id');
      expect(json['description'], 'test description');
      expect(json['generatedCode'], 'test code');
      expect(json['tags'], ['tag1', 'tag2']);
      expect(json['isFavorite'], true);
    });

    test('VisualizationRecord should deserialize correctly', () {
      final json = {
        'id': 'test-id',
        'description': 'test description',
        'generatedCode': 'test code',
        'renderedImagePath': '/path/to/image.png',
        'type': 'VisualizationType.function',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'tags': ['tag1'],
        'isFavorite': false,
      };

      final record = VisualizationRecord.fromJson(json);

      expect(record.id, 'test-id');
      expect(record.description, 'test description');
      expect(record.generatedCode, 'test code');
      expect(record.renderedImagePath, '/path/to/image.png');
      expect(record.type, VisualizationType.function);
      expect(record.tags, ['tag1']);
      expect(record.isFavorite, false);
    });
  });

  group('VisualizationType Tests', () {
    test('All VisualizationType values should be defined', () {
      expect(VisualizationType.values.length, 4);
      expect(VisualizationType.values, contains(VisualizationType.function));
      expect(VisualizationType.values, contains(VisualizationType.geometry));
      expect(VisualizationType.values, contains(VisualizationType.dataChart));
      expect(VisualizationType.values, contains(VisualizationType.general));
    });
  });
}
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'training_repository_test.dart' show MemoryContent, MemoryPreferences;

/// T85-S2: a lista do curso é lida uma vez por pacote e guardada no aparelho
/// para a próxima abertura.
void main() {
  final config = TrainingCourseConfig.pilares;
  late MemoryContent content;
  late MemoryPreferences preferences;

  TrainingRepositoryLocal build() => TrainingRepositoryLocal(
    preferences,
    LessonContentAssets(reader: content),
    installSeed: 'test',
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = MemoryPreferences();
    content = MemoryContent();
    content.files[config.indexSource] = jsonEncode({
      'partes': [
        {
          'id': 'p1',
          'titulo': 'Parte 1',
          'capitulos': [
            {
              'id': 'c1',
              'titulo': 'Capítulo 1',
              'aulas': [
                {'id': 'c1.a', 'tipo': 'tema', 'titulo': 'Aula A'},
              ],
            },
          ],
        },
      ],
    });
    content.files['assets/lessons/treino/c1.a.json'] = jsonEncode({
      'exercicios': <Object>[],
    });
  });

  test('chamadas seguidas leem os arquivos uma vez só', () async {
    final repository = build();
    addTearDown(repository.dispose);
    final first = await repository.resources(config.course);
    final reads = content.reads.length;
    expect(reads, greaterThan(0));
    final second = await repository.resources(config.course);
    expect(identical(first, second), isTrue);
    expect(content.reads.length, reads);
  });

  test('mudou o perfil de abertura: lê de novo', () async {
    final repository = build();
    addTearDown(repository.dispose);
    await repository.resources(config.course);
    final reads = content.reads.length;
    await repository.update(
      config.course,
      (s) => s.copyWith(openingProfile: 'agressivo'),
    );
    await repository.resources(config.course);
    expect(content.reads.length, greaterThan(reads));
  });

  test('pacote novo (cacheScope) também lê de novo', () async {
    final reader = _Scoped()..files.addAll(content.files);
    final repository = TrainingRepositoryLocal(
      preferences,
      LessonContentAssets(reader: reader),
      installSeed: 'test',
    );
    addTearDown(repository.dispose);
    await repository.resources(config.course);
    final reads = reader.reads.length;
    reader.scope = 'outro';
    await repository.resources(config.course);
    expect(reader.reads.length, greaterThan(reads));
  });

  test(
    'a lista fica guardada e volta na próxima abertura, sem bancos',
    () async {
      expect(await build().cachedOutline(config.course), isNull);
      final first = build();
      addTearDown(first.dispose);
      final full = await first.resources(config.course);
      await Future<void>.delayed(Duration.zero);
      final reopened = build();
      addTearDown(reopened.dispose);
      final outline = await reopened.cachedOutline(config.course);
      expect(outline, isNotNull);
      expect(
        [for (final l in outline!.lessons) l.id],
        [for (final l in full.lessons) l.id],
      );
      expect(outline.banks, isEmpty);
      // Sem tocar nos arquivos do curso.
      final reads = content.reads.length;
      await build().cachedOutline(config.course);
      expect(content.reads.length, reads);
    },
  );

  test('o guardado de outro perfil de abertura não vale', () async {
    final first = build();
    addTearDown(first.dispose);
    await first.resources(config.course);
    await Future<void>.delayed(Duration.zero);
    await first.update(
      config.course,
      (s) => s.copyWith(openingProfile: 'agressivo'),
    );
    expect(await build().cachedOutline(config.course), isNull);
  });
}

class _Scoped extends MemoryContent {
  Object scope = 'a';
  @override
  Object get cacheScope => scope;
}

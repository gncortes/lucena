import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/lesson_ad/course_access_repository.dart';
import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/use_cases/treinador/abertura_no_pilares.dart';

final class CursoDaAberturaState {
  const CursoDaAberturaState({
    this.carregando = true,
    this.temOCurso = false,
    this.abertura,
  });

  final bool carregando;

  /// Comprou o Pilares (e ainda tem): a ligação vai às metas de hoje; sem o
  /// curso, à abertura com cadeado e a oferta.
  final bool temOCurso;

  /// `null` = o curso não tem a abertura ou o conteúdo não carregou.
  final AberturaNoPilares? abertura;
}

/// A abertura do ponto fraco dentro do Pilares: as partes, a que fica em
/// evidência e se a pessoa tem o curso.
class CursoDaAberturaCubit extends Cubit<CursoDaAberturaState> {
  CursoDaAberturaCubit({
    required this._training,
    required this._access,
    required this.slot,
    this.parte,
  }) : super(const CursoDaAberturaState());

  final TrainingRepository _training;
  final CourseAccessRepository _access;
  final String slot;

  /// A parte que o servidor ligou à saída da teoria.
  final int? parte;

  final _subs = <StreamSubscription<Object?>>[];

  /// Lê o curso e passa a ouvir a compra e o progresso: comprar ou terminar
  /// uma parte já muda a tela, sem reabrir.
  Future<void> load() async {
    if (_subs.isEmpty) {
      _subs
        ..add(_access.changes.listen((_) => _ler(), onError: (Object _) {}))
        ..add(
          _training.changes
              .where((s) => s.course == TrainingCourse.pilares)
              .listen((_) => _ler(), onError: (Object _) {}),
        );
    }
    await _ler();
  }

  Future<void> _ler() async {
    final temOCurso = _access.access.hasFullCourse;
    AberturaNoPilares? abertura;
    try {
      final resources =
          await _training.cachedOutline(TrainingCourse.pilares) ??
          await _training.resources(TrainingCourse.pilares);
      final estado = temOCurso
          ? await _training.load(TrainingCourse.pilares)
          : null;
      abertura = aberturaNoPilares(
        slot: slot,
        resources: resources,
        estado: estado,
        parteDoServidor: parte,
      );
    } on Object {
      abertura = null;
    }
    if (isClosed) return;
    emit(
      CursoDaAberturaState(
        carregando: false,
        temOCurso: temOCurso,
        abertura: abertura,
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}

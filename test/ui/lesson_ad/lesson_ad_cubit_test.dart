import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/lesson_ad/view_models/lesson_ad_cubit.dart';

import '../../../testing/fakes/fake_lesson_ad_repositories.dart';
import '../../../testing/fakes/fake_now.dart';

void main() {
  late FakeNow now;
  late FakeDemoAdRepository ads;
  late LessonAdCubit cubit;

  setUp(() {
    now = FakeNow(DateTime(2026, 11, 4, 9));
    ads = FakeDemoAdRepository();
  });

  /// Anda o relógio e os timers juntos, de 100 em 100 ms.
  void elapse(FakeAsync async, Duration total) {
    for (
      var t = Duration.zero;
      t < total;
      t += const Duration(milliseconds: 100)
    ) {
      now.advance(const Duration(milliseconds: 100));
      async.elapse(const Duration(milliseconds: 100));
    }
  }

  test('conta 3, 2, 1 e libera o Fechar', () {
    fakeAsync((async) {
      cubit = LessonAdCubit(ads: ads, now: now);
      unawaited(cubit.load());
      async.flushMicrotasks();
      expect(cubit.state.phase, LessonAdPhase.ready);
      expect(cubit.state.secondsLeft, 3);
      expect(cubit.state.canClose, isFalse);
      elapse(async, const Duration(milliseconds: 1100));
      expect(cubit.state.secondsLeft, 2);
      elapse(async, const Duration(seconds: 1));
      expect(cubit.state.secondsLeft, 1);
      elapse(async, const Duration(seconds: 1));
      expect(cubit.state.secondsLeft, 0);
      expect(cubit.state.canClose, isTrue);
      unawaited(cubit.close());
    });
  });

  test('segundo plano pausa e retoma de onde parou', () {
    fakeAsync((async) {
      cubit = LessonAdCubit(ads: ads, now: now);
      unawaited(cubit.load());
      async.flushMicrotasks();
      elapse(async, const Duration(milliseconds: 1100));
      expect(cubit.state.secondsLeft, 2);
      cubit.pause();
      // 10 s em segundo plano não contam.
      now.advance(const Duration(seconds: 10));
      async.elapse(const Duration(seconds: 10));
      expect(cubit.state.secondsLeft, 2);
      cubit.resume();
      elapse(async, const Duration(milliseconds: 1000));
      expect(cubit.state.secondsLeft, 1);
      elapse(async, const Duration(seconds: 1));
      expect(cubit.state.canClose, isTrue);
      unawaited(cubit.close());
    });
  });

  test('falha ao carregar mostra a falha; tentar de novo recarrega', () {
    fakeAsync((async) {
      ads = FakeDemoAdRepository(loads: [false, true]);
      cubit = LessonAdCubit(ads: ads, now: now);
      unawaited(cubit.load());
      async.flushMicrotasks();
      expect(cubit.state.phase, LessonAdPhase.failed);
      unawaited(cubit.load(retry: true));
      async.flushMicrotasks();
      expect(ads.loadCalls, 2);
      expect(cubit.state.phase, LessonAdPhase.ready);
      unawaited(cubit.close());
    });
  });

  test('carregando antes de abrir', () {
    fakeAsync((async) {
      ads.gate = Completer<void>();
      cubit = LessonAdCubit(ads: ads, now: now);
      unawaited(cubit.load());
      async.flushMicrotasks();
      expect(cubit.state.phase, LessonAdPhase.loading);
      ads.gate!.complete();
      async.flushMicrotasks();
      expect(cubit.state.phase, LessonAdPhase.ready);
      unawaited(cubit.close());
    });
  });
}

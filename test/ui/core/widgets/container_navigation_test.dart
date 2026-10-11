import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/container_navigation.dart';

class _Marker {}

class _LifetimeCubit extends Cubit<int> {
  _LifetimeCubit(this.onClose) : super(42);
  final VoidCallback onClose;
  @override
  Future<void> close() {
    onClose();
    return super.close();
  }
}

class _Routes extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
}

void main() {
  for (final reduced in [false, true]) {
    testWidgets(
      'Android container reduced=$reduced: duplicate tap creates one destination/provider and closes once',
      (tester) async {
        tester.view
          ..physicalSize = const Size(360, 640)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final marker = _Marker();
        final observer = _Routes();
        var created = 0;
        var disposed = 0;
        var built = 0;
        var closed = 0;
        await tester.pumpWidget(
          RepositoryProvider<_Marker>.value(
            value: marker,
            child: MaterialApp(
              theme: ThemeData(platform: TargetPlatform.android),
              navigatorObservers: [observer],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: reduced,
                  textScaler: const TextScaler.linear(1.6),
                ),
                child: child!,
              ),
              home: Scaffold(
                body: ContainerNavigation(
                  color: Colors.white,
                  onFallback: () async {
                    fail('Android must use its container');
                  },
                  onClosed: () => closed++,
                  closedBuilder: (_, open) =>
                      TextButton(onPressed: open, child: const Text('open')),
                  openBuilder: (context) {
                    built++;
                    expect(context.read<_Marker>(), same(marker));
                    return BlocProvider(
                      create: (_) {
                        created++;
                        return _LifetimeCubit(() => disposed++);
                      },
                      child: Builder(
                        builder: (context) => Scaffold(
                          appBar: AppBar(title: const Text('destination')),
                          body: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'close ${context.watch<_LifetimeCubit>().state}',
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        Future<void> settle() async {
          if (reduced) {
            // Process insertion/removal frames without advancing animation time.
            await tester.pump();
            await tester.pump();
            expect(tester.binding.transientCallbackCount, 0);
          } else {
            await tester.pumpAndSettle();
          }
        }

        final initialPushes = observer.pushes;
        if (reduced) {
          expect(find.byType(OpenContainer<void>), findsNothing);
        } else {
          expect(
            tester
                .widget<OpenContainer<void>>(find.byType(OpenContainer<void>))
                .transitionDuration,
            greaterThan(Duration.zero),
          );
        }
        expect(find.text('open').hitTestable(), findsOneWidget);
        final open = tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'open'))
            .onPressed!;
        open();
        open();
        await settle();
        expect(built, 1);
        expect(created, 1);
        expect(observer.pushes, initialPushes + 1);
        expect(find.text('close 42').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'close 42'))
            .onPressed!();
        await settle();
        expect(closed, 1);
        expect(disposed, 1);
        expect(find.text('open').hitTestable(), findsOneWidget);
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'open'))
            .onPressed!();
        await settle();
        expect(created, 2);
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'close 42'))
            .onPressed!();
        await settle();
        expect(disposed, 2);
        expect(closed, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('other platforms use canonical callback once while pending', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    var closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: ContainerNavigation(
            color: Colors.white,
            onFallback: () {
              calls++;
              return pending.future;
            },
            onClosed: () => closed++,
            openBuilder: (_) => throw StateError('container not used on iOS'),
            closedBuilder: (_, open) =>
                TextButton(onPressed: open, child: const Text('open')),
          ),
        ),
      ),
    );
    expect(find.byType(OpenContainer<void>), findsNothing);
    await tester.tap(find.text('open'));
    await tester.tap(find.text('open'));
    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(closed, 1);
    expect(tester.takeException(), isNull);
  });
}

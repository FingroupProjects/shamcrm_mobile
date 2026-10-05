import 'dart:async';

import 'package:crm_task_manager/services/chat_read_marker.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatReadMarker', () {
    test('sends one request for a burst of the same message id', () {
      fakeAsync((async) {
        final sent = <int>[];
        final marker = ChatReadMarker(
          send: (id) async {
            sent.add(id);
          },
        );

        for (var i = 0; i < 48; i++) {
          marker.request(3344);
        }

        async.elapse(const Duration(milliseconds: 399));
        expect(sent, isEmpty);

        async.elapse(const Duration(milliseconds: 1));
        expect(sent, [3344]);

        for (var i = 0; i < 48; i++) {
          marker.request(3344);
        }
        async.elapse(const Duration(seconds: 2));
        expect(sent, [3344]);
      });
    });

    test('keeps the newest id from a short burst', () {
      fakeAsync((async) {
        final sent = <int>[];
        final marker = ChatReadMarker(
          send: (id) async {
            sent.add(id);
          },
        );

        marker.request(10);
        async.elapse(const Duration(milliseconds: 100));
        marker.request(11);
        marker.request(12);
        async.elapse(const Duration(milliseconds: 300));

        expect(sent, [12]);
      });
    });

    test('ignores local ids and an older id after a newer one was sent', () {
      fakeAsync((async) {
        final sent = <int>[];
        final marker = ChatReadMarker(
          send: (id) async {
            sent.add(id);
          },
        );

        marker.request(0);
        marker.request(-5);
        marker.request(20);
        async.elapse(const Duration(milliseconds: 400));
        marker.request(19);
        marker.request(20);
        async.elapse(const Duration(seconds: 1));

        expect(sent, [20]);
      });
    });

    test('sends a newer id only after the current request finishes', () {
      fakeAsync((async) {
        final sent = <int>[];
        final gates = <Completer<void>>[];
        final marker = ChatReadMarker(
          send: (id) {
            sent.add(id);
            final gate = Completer<void>();
            gates.add(gate);
            return gate.future;
          },
        );

        marker.request(1);
        async.elapse(const Duration(milliseconds: 400));
        expect(sent, [1]);

        marker.request(2);
        marker.request(2);
        expect(sent, [1]);

        gates.single.complete();
        async.flushMicrotasks();
        expect(sent, [1, 2]);
      });
    });

    test('retries the same id after a failed request', () {
      fakeAsync((async) {
        final sent = <int>[];
        var fail = true;
        final marker = ChatReadMarker(
          send: (id) async {
            sent.add(id);
            if (fail) throw Exception('offline');
          },
        );

        marker.request(5);
        async.elapse(const Duration(milliseconds: 400));
        expect(sent, [5]);
        expect(marker.covers(5), isFalse);

        fail = false;
        marker.request(5);
        async.elapse(const Duration(milliseconds: 400));
        expect(sent, [5, 5]);
        expect(marker.covers(5), isTrue);
      });
    });

    test('markNow does not wait for the debounce and skips a covered id', () {
      fakeAsync((async) {
        final sent = <int>[];
        final marker = ChatReadMarker(
          send: (id) async {
            sent.add(id);
          },
        );

        bool? first;
        marker.markNow(9).then((value) => first = value);
        async.flushMicrotasks();
        expect(first, isTrue);
        expect(sent, [9]);

        bool? second;
        marker.markNow(9).then((value) => second = value);
        async.flushMicrotasks();
        expect(second, isTrue);
        expect(sent, [9]);
      });
    });
  });
}

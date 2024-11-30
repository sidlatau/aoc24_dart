import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:test/fake.dart';

/// Calls a main function with [input] as first and only argument
/// and returns the output (stdout) of the program as full String
Future<String> testMain(
  FutureOr Function(String input) main, {
  required String input,
}) async {
  final ioStdout = io.stdout;
  final fakeStdout = FakeStdoutStream();

  await runZoned(
    () async => io.IOOverrides.runZoned(
      () async {
        await main(input!);
      },
      stdout: () => fakeStdout,
    ),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        ioStdout.writeln(line);

        // catch print calls and return them as result of the main function
        final override = io.IOOverrides.current;
        override?.stdout.writeln(line);
      },
    ),
  );
  return fakeStdout.lines.join('\n');
}

class FakeStdoutStream with Fake implements io.Stdout {
  final List<List<int>> _writes = <List<int>>[];

  List<String> get lines => _writes.map(utf8.decode).toList();

  @override
  void add(List<int> bytes) {
    _writes.add(bytes);
  }

  @override
  void writeln([Object? object = ""]) {
    _writes.add(utf8.encode('$object'));
  }

  @override
  void write(Object? object) {
    _writes.add(utf8.encode('$object'));
  }

  @override
  void writeAll(Iterable objects, [String sep = ""]) {
    _writes.add(utf8.encode(objects.join(sep)));
  }

  @override
  void writeCharCode(int charCode) {
    _writes.add(utf8.encode(String.fromCharCode(charCode)));
  }
}

import 'dart:convert';
import 'dart:io';

final Map<String, RegExp> _rules = <String, RegExp>{
  'raw_color_literal': RegExp(r'Color\s*\(\s*0x[a-fA-F0-9]{6,8}\s*\)'),
  'colors_white': RegExp(r'\bColors\.white\b'),
  'colors_black': RegExp(r'\bColors\.black\b'),
  'colors_red': RegExp(r'\bColors\.red\b'),
  'colors_green': RegExp(r'\bColors\.green\b'),
  'colors_orange': RegExp(r'\bColors\.orange\b'),
  'color_scheme_light': RegExp(r'\bColorScheme\.light\s*\('),
  'direct_font_family': RegExp(r'fontFamily\s*:'),
};

Future<void> main(List<String> args) async {
  final allFiles = args.contains('--all');
  final allowlist = await _loadAllowlist();
  final files = allFiles ? await _allDartFiles() : await _changedDartFiles();

  final filteredFiles =
      files.where((path) => !_isAllowed(path, allowlist)).toList()..sort();

  if (filteredFiles.isEmpty) {
    stdout.writeln('theme_audit: no files to inspect');
    exit(0);
  }

  final violations = <String>[];

  for (final path in filteredFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }

    final lines = const LineSplitter().convert(await file.readAsString());
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      for (final entry in _rules.entries) {
        if (entry.value.hasMatch(line)) {
          violations.add(
            '$path:${index + 1}: ${entry.key}: ${line.trim()}',
          );
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln(
      'theme_audit: no theming guardrail violations in ${filteredFiles.length} files',
    );
    exit(0);
  }

  stderr.writeln('theme_audit: found ${violations.length} violations');
  for (final violation in violations) {
    stderr.writeln(violation);
  }
  exit(1);
}

Future<List<String>> _allDartFiles() async {
  final results = await Process.run('rg', <String>['--files', '-g', '*.dart']);
  if (results.exitCode != 0) {
    throw Exception('Failed to enumerate Dart files: ${results.stderr}');
  }
  return const LineSplitter()
      .convert((results.stdout as String).trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

Future<List<String>> _changedDartFiles() async {
  final files = <String>{};

  final tracked = await Process.run(
    'git',
    <String>['diff', '--name-only', '--diff-filter=ACMRTUXB', 'HEAD'],
  );
  if (tracked.exitCode == 0) {
    files.addAll(
      const LineSplitter()
          .convert((tracked.stdout as String).trim())
          .where((line) => line.endsWith('.dart')),
    );
  }

  final untracked = await Process.run(
    'git',
    <String>['ls-files', '--others', '--exclude-standard'],
  );
  if (untracked.exitCode == 0) {
    files.addAll(
      const LineSplitter()
          .convert((untracked.stdout as String).trim())
          .where((line) => line.endsWith('.dart')),
    );
  }

  return files.toList();
}

Future<List<String>> _loadAllowlist() async {
  final file = File('tool/theme_audit_allowlist.txt');
  if (!file.existsSync()) {
    return const <String>[];
  }

  return const LineSplitter()
      .convert(await file.readAsString())
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toList();
}

bool _isAllowed(String path, List<String> allowlist) {
  for (final entry in allowlist) {
    if (path == entry || path.startsWith(entry)) {
      return true;
    }
  }
  return false;
}

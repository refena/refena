import 'dart:convert';

import 'package:meta/meta.dart';

final _jsonEncoder = JsonEncoder.withIndent('  ');

/// Regex to match the toString() output of a freezed class.
/// E.g. `Hell_oo(abc: 332, cd: Ab(a: 3))`
/// The first group will be the class name.
/// The second group will be the content inside the parenthesis.
final _regexParenthesis = RegExp(r'([\w<>, ]+)\((.*)\)');
final _regexBraces = RegExp(r'([\w<>, ]+)\{(.*)\}');

@internal
String formatValue(Object? o) {
  if (o == null) {
    return 'null';
  }

  if (o is Map<String, dynamic>) {
    try {
      return _jsonEncoder.convert(o);
    } catch (_) {}
  }

  final s = o.toString();
  try {
    // eagerly assume json
    final parsed = jsonDecode(s);
    return _jsonEncoder.convert(parsed);
  } catch (_) {}

  // We use while(true) to easily break out of the loop,
  // assuming that it is more performant than try/catch.
  while (true) {
    // eagerly assume freezed (or similar) format
    final s = o.toString();

    if (s.contains('\n')) {
      break;
    }

    final RegExp regex;
    final String endChar;
    if (s.endsWith(')')) {
      regex = _regexParenthesis;
      endChar = ')';
    } else if (s.endsWith('}')) {
      regex = _regexBraces;
      endChar = '}';
    } else {
      break;
    }

    final buffer = StringBuffer();
    final match = regex.firstMatch(s);
    if (match == null) {
      break;
    }

    final className = match.group(1)!;
    buffer.write(className);
    buffer.write('(\n$_tab');
    final content = match.group(2)!;
    try {
      final success = formatRegex(buffer, content, regex, endChar, 1);
      if (success) {
        buffer.write('\n)');
        return buffer.toString();
      }
    } catch (_) {}
    break;
  }

  return s;
}

const _tab = '  ';

/// Formats a string inside the brackets with a regex.
/// Returns true if the string was formatted correctly.
/// The [buffer] is used to write the formatted string.
bool formatRegex(
    StringBuffer buffer, String s, RegExp regex, String endChar, int depth) {
  int start = 0;
  while (true) {
    final commaIndex = s.indexOf(',', start);
    final endIndex = commaIndex == -1 ? s.length : commaIndex;

    final sub = s.substring(start, endIndex);

    final colonIndex = sub.indexOf(':');
    if (colonIndex == -1) {
      return false;
    }

    final key = sub.substring(0, colonIndex);
    if (start != 0) {
      buffer.write(',\n');
      for (int i = 0; i < depth; i++) {
        buffer.write(_tab);
      }
    }
    buffer.write(key.trim());
    buffer.write(': ');

    final value = sub.substring(colonIndex + 1);
    if (value.endsWith(endChar)) {
      // expect nested object
      final match = regex.firstMatch(value);
      if (match == null) {
        return false;
      }
      final className = match.group(1)!;
      buffer.write(className.trim());
      buffer.write('(\n');
      for (int i = 0; i < depth + 1; i++) {
        buffer.write(_tab);
      }
      final content = match.group(2)!;
      final success = formatRegex(buffer, content, regex, endChar, depth + 1);
      if (!success) {
        return false;
      }
      buffer.write('\n');
      for (int i = 0; i < depth; i++) {
        buffer.write(_tab);
      }
      buffer.write(')');
    } else {
      // expect primitive value
      buffer.write(value.trim());
    }

    if (commaIndex == -1) {
      break;
    }

    start = commaIndex + 1;
  }

  return true;
}

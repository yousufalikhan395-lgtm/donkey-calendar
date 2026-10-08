import 'dart:convert';

class ToolCall {
  final String name;
  final Map<String, dynamic> arguments;
  final String rawJson;

  ToolCall({required this.name, required this.arguments, required this.rawJson});
}

class ParseResult {
  final String visibleText;
  final List<ToolCall> calls;
  final String? error;

  ParseResult({required this.visibleText, required this.calls, this.error});
}

class ToolCallParser {
  static const _open = '<tool_call>';
  static const _close = '</tool_call>';

  ParseResult parse(String text) {
    final calls = <ToolCall>[];
    final buffer = StringBuffer();
    String? error;
    var i = 0;

    while (i < text.length) {
      final start = text.indexOf(_open, i);
      if (start == -1) {
        buffer.write(text.substring(i));
        break;
      }
      buffer.write(text.substring(i, start));
      final end = text.indexOf(_close, start);
      if (end == -1) {
        // Incomplete tool call at end of stream — drop it from visible text.
        error = 'The AI response was incomplete. Please try again.';
        break;
      }
      final jsonRaw = text.substring(start + _open.length, end).trim();
      final call = _parseCall(jsonRaw);
      if (call != null) {
        calls.add(call);
      } else {
        error ??= 'Could not understand the event data. Please try again.';
      }
      i = end + _close.length;
    }

    return ParseResult(
      visibleText: buffer.toString().trim(),
      calls: calls,
      error: error,
    );
  }

  ToolCall? _parseCall(String raw) {
    final jsonStr = _extractJson(raw);
    if (jsonStr == null) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) return null;
      final name = decoded['name']?.toString();
      final args = decoded['arguments'];
      if (name == null || args is! Map) return null;
      return ToolCall(
        name: name,
        arguments: Map<String, dynamic>.from(args),
        rawJson: raw,
      );
    } catch (_) {
      final repaired = _repair(jsonStr);
      if (repaired == null) return null;
      try {
        final decoded = jsonDecode(repaired);
        if (decoded is! Map) return null;
        final name = decoded['name']?.toString();
        final args = decoded['arguments'];
        if (name == null || args is! Map) return null;
        return ToolCall(
          name: name,
          arguments: Map<String, dynamic>.from(args),
          rawJson: raw,
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Brace-depth extraction of the first balanced JSON object.
  String? _extractJson(String raw) {
    final start = raw.indexOf('{');
    if (start == -1) return null;
    var depth = 0;
    var inString = false;
    var escape = false;
    for (var i = start; i < raw.length; i++) {
      final c = raw[i];
      if (inString) {
        if (escape) {
          escape = false;
        } else if (c == '\\') {
          escape = true;
        } else if (c == '"') {
          inString = false;
        }
        continue;
      }
      if (c == '"') {
        inString = true;
      } else if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) return raw.substring(start, i + 1);
      }
    }
    return null;
  }

  /// Remove trailing commas before } or ].
  String? _repair(String raw) {
    final repaired = raw.replaceAllMapped(
      RegExp(r',\s*([}\]])'),
      (m) => m.group(1)!,
    );
    return repaired == raw ? null : repaired;
  }
}

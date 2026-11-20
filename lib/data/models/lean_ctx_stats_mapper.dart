import 'dart:convert';

import 'package:claude_usage_widget/domain/models/lean_ctx_stats.dart';

/// Reads the output of `lean-ctx gain --json`.
///
/// Returns null when the text is not the expected shape, so a lean-ctx
/// release that changes its output hides the section instead of showing
/// wrong numbers.
LeanCtxStats? mapLeanCtxGain(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  final summary = decoded['summary'];
  if (summary is! Map<String, dynamic>) return null;
  final saved = summary['tokens_saved'];
  final percent = summary['effective_compression_pct'];
  final commands = summary['total_commands'];
  if (saved is! num || percent is! num || commands is! num) return null;
  if (saved < 0 || commands < 0 || !percent.isFinite) return null;
  return LeanCtxStats(
    tokensSaved: saved.toInt(),
    reductionPercent: percent.toDouble().clamp(0, 100),
    commands: commands.toInt(),
  );
}

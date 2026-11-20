import 'package:equatable/equatable.dart';

/// What lean-ctx has saved, as reported by `lean-ctx gain`.
class LeanCtxStats extends Equatable {
  /// Creates the figures.
  const LeanCtxStats({
    required this.tokensSaved,
    required this.reductionPercent,
    required this.commands,
  });

  /// Tokens kept out of the conversation.
  final int tokensSaved;

  /// Share of tokens saved, 0 to 100.
  final double reductionPercent;

  /// Commands lean-ctx has handled.
  final int commands;

  @override
  List<Object?> get props => [tokensSaved, reductionPercent, commands];
}

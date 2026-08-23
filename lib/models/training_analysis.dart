class ScoreItem {
  const ScoreItem({required this.label, required this.score});

  final String label;
  final int score;
}

class TrainingAnalysis {
  const TrainingAnalysis({
    required this.overallScore,
    required this.strokeName,
    required this.summary,
    required this.scores,
    required this.strengths,
    required this.suggestions,
  });

  final int overallScore;
  final String strokeName;
  final String summary;
  final List<ScoreItem> scores;
  final List<String> strengths;
  final List<String> suggestions;
}

class TrainingRecord {
  const TrainingRecord({
    required this.id,
    required this.date,
    required this.duration,
    required this.analysis,
    this.videoPath,
  });

  final String id;
  final DateTime date;
  final Duration duration;
  final TrainingAnalysis analysis;
  final String? videoPath;
}

import '../models/training_analysis.dart';

/// Replace this service with a backend call that runs pose estimation and a
/// table-tennis-specific scoring model. The UI depends only on the returned
/// [TrainingAnalysis], so the rest of the app does not need to change.
class MockAiAnalysisService {
  Future<TrainingAnalysis> analyze(String videoPath) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const TrainingAnalysis(
      overallScore: 86,
      strokeName: '正手攻球',
      summary: '动作节奏稳定，击球点清晰。重心转移和收拍方向还有提升空间。',
      scores: [
        ScoreItem(label: '准备姿势', score: 91),
        ScoreItem(label: '引拍幅度', score: 84),
        ScoreItem(label: '重心转移', score: 78),
        ScoreItem(label: '击球时机', score: 89),
      ],
      strengths: ['击球点保持在身体右前方，空间感很好', '前臂加速连贯，触球阶段没有明显停顿'],
      suggestions: [
        '引拍时右膝再下沉约 5–8 cm，让重心更充分落在右脚',
        '触球后球拍向左眉方向收拍，避免横向甩臂过多',
        '下一组练习采用 60% 力量，重点保持腰髋先于手臂启动',
      ],
    );
  }
}

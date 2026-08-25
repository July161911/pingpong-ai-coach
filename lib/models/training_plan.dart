import 'dart:convert';

enum TrainingPlanOrigin { ai, user }

class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.title,
    required this.detail,
    required this.origin,
    this.completed = false,
  });

  final String id;
  final String title;
  final String detail;
  final TrainingPlanOrigin origin;
  final bool completed;

  TrainingPlan copyWith({bool? completed}) => TrainingPlan(
    id: id,
    title: title,
    detail: detail,
    origin: origin,
    completed: completed ?? this.completed,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'detail': detail,
    'origin': origin.name,
    'completed': completed,
  };

  factory TrainingPlan.fromJson(Map<String, dynamic> json) => TrainingPlan(
    id: json['id'] as String,
    title: json['title'] as String,
    detail: json['detail'] as String,
    origin: json['origin'] == 'user'
        ? TrainingPlanOrigin.user
        : TrainingPlanOrigin.ai,
    completed: json['completed'] as bool? ?? false,
  );

  static String encodeList(List<TrainingPlan> plans) =>
      jsonEncode(plans.map((plan) => plan.toJson()).toList());

  static List<TrainingPlan> decodeList(String source) =>
      (jsonDecode(source) as List<dynamic>)
          .map((item) => TrainingPlan.fromJson(item as Map<String, dynamic>))
          .toList();
}

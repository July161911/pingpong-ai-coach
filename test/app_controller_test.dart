import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpong_ai_coach/controllers/app_controller.dart';
import 'package:pingpong_ai_coach/models/training_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists local account, theme and user training plan', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController();
    await controller.initialize();

    expect(controller.signedIn, isFalse);
    expect(controller.displayName, 'MoMo');

    await controller.signIn(account: '13800138000', name: 'MoMo');
    await controller.setThemeMode(ThemeMode.dark);
    await controller.addPlan(
      const TrainingPlan(
        id: 'test-plan',
        title: '发球练习',
        detail: '5 组 × 20 球',
        origin: TrainingPlanOrigin.user,
      ),
    );

    final restored = AppController();
    await restored.initialize();
    expect(restored.signedIn, isTrue);
    expect(restored.identifier, '13800138000');
    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.plans.any((plan) => plan.id == 'test-plan'), isTrue);

    controller.dispose();
    restored.dispose();
  });
}

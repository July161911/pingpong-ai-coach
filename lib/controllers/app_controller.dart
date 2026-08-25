import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_plan.dart';

class AppController extends ChangeNotifier {
  static const _signedInKey = 'signed_in';
  static const _identifierKey = 'user_identifier';
  static const _displayNameKey = 'display_name';
  static const _themeKey = 'theme_mode';
  static const _plansKey = 'training_plans';

  bool initialized = false;
  bool signedIn = false;
  String identifier = '';
  String displayName = 'MoMo';
  ThemeMode themeMode = ThemeMode.system;
  List<TrainingPlan> plans = const [];

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    signedIn = preferences.getBool(_signedInKey) ?? false;
    identifier = preferences.getString(_identifierKey) ?? '';
    displayName = preferences.getString(_displayNameKey) ?? 'MoMo';
    themeMode = switch (preferences.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final savedPlans = preferences.getString(_plansKey);
    if (savedPlans != null) {
      try {
        plans = TrainingPlan.decodeList(savedPlans);
      } catch (_) {
        plans = _defaultPlans;
      }
    } else {
      plans = _defaultPlans;
    }
    initialized = true;
    notifyListeners();
  }

  Future<void> signIn({required String account, String? name}) async {
    identifier = account.trim();
    displayName = name?.trim().isNotEmpty == true ? name!.trim() : 'MoMo';
    signedIn = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_signedInKey, true);
    await preferences.setString(_identifierKey, identifier);
    await preferences.setString(_displayNameKey, displayName);
    notifyListeners();
  }

  Future<void> signOut() async {
    signedIn = false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_signedInKey, false);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, value.name);
    notifyListeners();
  }

  Future<void> addPlan(TrainingPlan plan) async {
    plans = [plan, ...plans];
    await _savePlans();
    notifyListeners();
  }

  Future<void> addRecommendedPlan({
    required String title,
    required String detail,
  }) async {
    if (plans.any((plan) => plan.title == title && !plan.completed)) return;
    await addPlan(
      TrainingPlan(
        id: 'ai-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        detail: detail,
        origin: TrainingPlanOrigin.ai,
      ),
    );
  }

  Future<void> togglePlan(String id) async {
    plans = [
      for (final plan in plans)
        if (plan.id == id) plan.copyWith(completed: !plan.completed) else plan,
    ];
    await _savePlans();
    notifyListeners();
  }

  Future<void> _savePlans() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_plansKey, TrainingPlan.encodeList(plans));
  }

  static const _defaultPlans = [
    TrainingPlan(
      id: 'default-ai-1',
      title: '正手定点攻球',
      detail: '5 组 × 30 球 · 重点保持节奏稳定',
      origin: TrainingPlanOrigin.ai,
    ),
    TrainingPlan(
      id: 'default-user-1',
      title: '正反手转换',
      detail: '4 组 × 2 分钟',
      origin: TrainingPlanOrigin.user,
    ),
  ];
}

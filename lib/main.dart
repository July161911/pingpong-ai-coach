import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'controllers/app_controller.dart';
import 'models/training_plan.dart';
import 'models/training_analysis.dart';
import 'services/mock_ai_analysis_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PingPongCoachApp());
}

const _background = Color(0xFFF4F6F8);
const _ink = Color(0xFF15191E);
const _muted = Color(0xFF68727E);
const _blue = Color(0xFF0878F9);
const _green = Color(0xFF20B868);
const _orange = Color(0xFFFF6B35);

class PingPongCoachApp extends StatefulWidget {
  const PingPongCoachApp({super.key});

  @override
  State<PingPongCoachApp> createState() => _PingPongCoachAppState();
}

class _PingPongCoachAppState extends State<PingPongCoachApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController()..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => MaterialApp(
        title: 'iTT',
        debugShowCheckedModeBanner: false,
        themeMode: _controller.themeMode,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: !_controller.initialized
            ? const AppLaunchScreen()
            : _controller.signedIn
            ? AppShell(controller: _controller)
            : AuthPage(controller: _controller),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: dark ? const Color(0xFF0E1115) : _background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _blue,
        brightness: brightness,
        surface: dark ? const Color(0xFF1B2026) : Colors.white,
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: dark ? const Color(0xFFF2F4F6) : _ink,
        displayColor: dark ? const Color(0xFFF2F4F6) : _ink,
        fontFamily: '.SF Pro Display',
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}

class AppLaunchScreen extends StatelessWidget {
  const AppLaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 76),
            SizedBox(height: 18),
            Text(
              'iTT',
              style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 24),
            CupertinoActivityIndicator(radius: 13),
          ],
        ),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.controller});
  final AppController controller;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _accountController = TextEditingController();
  final _nameController = TextEditingController(text: 'MoMo');
  bool _registering = false;
  String? _error;

  @override
  void dispose() {
    _accountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool demo = false}) async {
    final account = demo ? 'demo@itt.local' : _accountController.text.trim();
    final digits = account.replaceAll(RegExp(r'\D'), '');
    if (account.isEmpty || (!account.contains('@') && digits.length < 6)) {
      setState(() => _error = '请输入手机号或邮箱号');
      return;
    }
    await widget.controller.signIn(
      account: account,
      name: _registering ? _nameController.text : 'MoMo',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 58, 28, 32),
          children: [
            const Center(child: BrandMark(size: 92)),
            const SizedBox(height: 22),
            const Center(
              child: Text(
                'iTT',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _registering ? '创建你的本地训练档案' : '登录以继续训练',
                style: const TextStyle(color: _muted, fontSize: 16),
              ),
            ),
            const SizedBox(height: 38),
            if (_registering) ...[
              AuthTextField(
                controller: _nameController,
                placeholder: '用户名',
                icon: CupertinoIcons.person_fill,
              ),
              const SizedBox(height: 12),
            ],
            AuthTextField(
              controller: _accountController,
              placeholder: '手机号或邮箱号',
              icon: CupertinoIcons.mail_solid,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: _orange, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: _registering ? '直接注册并使用' : '登录',
              icon: CupertinoIcons.arrow_right_circle_fill,
              onTap: _submit,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: _registering ? '已有账号，去登录' : '没有账号，直接注册',
              icon: CupertinoIcons.person_badge_plus,
              onTap: () => setState(() {
                _registering = !_registering;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: () => _submit(demo: true),
              child: const Text('以 MoMo 身份快速体验'),
            ),
            const SizedBox(height: 8),
            const Text(
              '当前版本不连接账号服务器，不发送验证码。账号和训练计划只保存在本机。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.icon,
  });
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Icon(icon, color: _muted, size: 20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: .18),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<CoachPageState> _coachKey = GlobalKey<CoachPageState>();
  int _selectedIndex = 0;
  final List<TrainingRecord> _records = [
    TrainingRecord(
      id: 'sample-1',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      duration: const Duration(minutes: 1, seconds: 18),
      analysis: const TrainingAnalysis(
        overallScore: 82,
        strokeName: '反手拨球',
        summary: '连续性不错，板形控制较稳定。',
        scores: [
          ScoreItem(label: '准备姿势', score: 88),
          ScoreItem(label: '板形控制', score: 84),
          ScoreItem(label: '击球时机', score: 79),
          ScoreItem(label: '还原速度', score: 77),
        ],
        strengths: ['板形稳定，出球线路集中'],
        suggestions: ['触球后更快回到身体中线', '降低抬肘幅度'],
      ),
    ),
  ];

  void _openCoach({bool capture = false}) {
    setState(() => _selectedIndex = 3);
    if (capture) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _coachKey.currentState?.pickVideo(ImageSource.camera);
      });
    }
  }

  void _addRecord(TrainingRecord record) {
    setState(() => _records.insert(0, record));
    final isForehand = record.analysis.strokeName.contains('正手');
    widget.controller.addRecommendedPlan(
      title: isForehand ? '正手稳定性强化' : '动作还原专项',
      detail: 'AI 推荐 · ${record.analysis.suggestions.first}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        controller: widget.controller,
        records: _records,
        onStartTraining: () => _openCoach(capture: true),
        onOpenCoach: _openCoach,
        onOpenRecords: () => setState(() => _selectedIndex = 1),
      ),
      RecordsPage(records: _records),
      const DiscoverPage(),
      CoachPage(key: _coachKey, onAnalysisSaved: _addRecord),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: GlassBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (value) => setState(() => _selectedIndex = value),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.records,
    required this.onStartTraining,
    required this.onOpenCoach,
    required this.onOpenRecords,
  });

  final AppController controller;
  final List<TrainingRecord> records;
  final VoidCallback onStartTraining;
  final VoidCallback onOpenCoach;
  final VoidCallback onOpenRecords;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 130),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (context) =>
                        UserProfilePage(controller: controller),
                  ),
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/user.JPG', fit: BoxFit.cover),
                ),
              ),
              const Spacer(),
              RoundIconButton(
                icon: CupertinoIcons.gear_alt_fill,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (context) => SettingsPage(controller: controller),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          const Text(
            '今天，练什么？',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '让每一次挥拍都有看得见的进步',
            style: TextStyle(
              fontSize: 16,
              color: _muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onStartTraining,
            child: Container(
              height: 236,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF16212F), Color(0xFF273C50)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x28151D28),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    top: -36,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CaptureIcon(),
                      Spacer(),
                      Text(
                        '开始一次训练分析',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        '拍摄动作，AI 即时拆解',
                        style: TextStyle(
                          color: Color(0xFFC7D1DB),
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 17),
                      Row(
                        children: [
                          Text(
                            '开始拍摄',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            CupertinoIcons.arrow_right,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const SectionHeader(title: '本周表现', trailing: '查看趋势'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '${records.length + 2}',
                  label: '训练次数',
                  color: _blue,
                  icon: CupertinoIcons.flame_fill,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: StatCard(
                  value: '86',
                  label: '平均得分',
                  color: _green,
                  icon: CupertinoIcons.chart_bar_alt_fill,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SectionHeader(title: '最近分析', trailing: '全部记录', onTap: onOpenRecords),
          const SizedBox(height: 14),
          if (records.isNotEmpty)
            AnalysisSummaryCard(record: records.first, onTap: onOpenRecords)
          else
            EmptyCard(onTap: onStartTraining),
          const SizedBox(height: 30),
          SectionHeader(
            title: '今日训练计划',
            trailing: '新建',
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (context) =>
                    CreateTrainingPlanPage(controller: controller),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < controller.plans.length;
                  index++
                ) ...[
                  TrainingPlanRow(
                    color:
                        controller.plans[index].origin == TrainingPlanOrigin.ai
                        ? const Color(0xFFE9F4FF)
                        : const Color(0xFFFFF0E8),
                    iconColor:
                        controller.plans[index].origin == TrainingPlanOrigin.ai
                        ? _blue
                        : _orange,
                    icon:
                        controller.plans[index].origin == TrainingPlanOrigin.ai
                        ? CupertinoIcons.sparkles
                        : CupertinoIcons.pencil,
                    title: controller.plans[index].title,
                    subtitle: controller.plans[index].detail,
                    done: controller.plans[index].completed,
                    onTap: () =>
                        controller.togglePlan(controller.plans[index].id),
                  ),
                  if (index != controller.plans.length - 1)
                    const Divider(
                      height: 1,
                      indent: 58,
                      color: Color(0xFFE9ECF0),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
          children: [
            SubpageHeader(title: '用户', onBack: () => Navigator.pop(context)),
            const SizedBox(height: 28),
            Center(
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 22,
                      offset: Offset(0, 9),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/user.JPG', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                controller.displayName,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Center(
              child: Text('用数据看见每一次进步', style: TextStyle(color: _muted)),
            ),
            const SizedBox(height: 30),
            const AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: ProfileStat(value: '3', label: '训练次数'),
                  ),
                  SizedBox(
                    height: 46,
                    child: VerticalDivider(color: Color(0xFFE5E9ED)),
                  ),
                  Expanded(
                    child: ProfileStat(value: '84', label: '平均得分'),
                  ),
                  SizedBox(
                    height: 46,
                    child: VerticalDivider(color: Color(0xFFE5E9ED)),
                  ),
                  Expanded(
                    child: ProfileStat(value: '2', label: '连续天数'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SectionHeader(title: '训练档案'),
            const SizedBox(height: 14),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ProfileInfoRow(
                    icon: CupertinoIcons.mail_solid,
                    title: '账号',
                    value: controller.identifier,
                  ),
                  const Divider(
                    height: 1,
                    indent: 68,
                    color: Color(0xFFE9ECF0),
                  ),
                  const ProfileInfoRow(
                    icon: CupertinoIcons.person_fill,
                    title: '持拍方式',
                    value: '右手横拍',
                  ),
                  Divider(height: 1, indent: 68, color: Color(0xFFE9ECF0)),
                  ProfileInfoRow(
                    icon: CupertinoIcons.sportscourt_fill,
                    title: '主要打法',
                    value: '弧圈结合快攻',
                  ),
                  Divider(height: 1, indent: 68, color: Color(0xFFE9ECF0)),
                  ProfileInfoRow(
                    icon: CupertinoIcons.scope,
                    title: '当前目标',
                    value: '提升正手稳定性',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});
  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _saveVideos = true;
  bool _cellularAnalysis = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
          children: [
            SubpageHeader(title: '设置', onBack: () => Navigator.pop(context)),
            const SizedBox(height: 28),
            const SectionHeader(title: '外观'),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '显示模式',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<ThemeMode>(
                      groupValue: widget.controller.themeMode,
                      children: const {
                        ThemeMode.light: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          child: Text('白天'),
                        ),
                        ThemeMode.dark: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          child: Text('黑夜'),
                        ),
                        ThemeMode.system: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          child: Text('跟随系统'),
                        ),
                      },
                      onValueChanged: (value) {
                        if (value != null) {
                          widget.controller.setThemeMode(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SectionHeader(title: '训练与分析'),
            const SizedBox(height: 14),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SettingsSwitchRow(
                    icon: CupertinoIcons.bell_fill,
                    color: _orange,
                    title: '训练提醒',
                    value: _notifications,
                    onChanged: (value) =>
                        setState(() => _notifications = value),
                  ),
                  const Divider(
                    height: 1,
                    indent: 68,
                    color: Color(0xFFE9ECF0),
                  ),
                  SettingsSwitchRow(
                    icon: CupertinoIcons.video_camera_solid,
                    color: _blue,
                    title: '保留原始视频',
                    value: _saveVideos,
                    onChanged: (value) => setState(() => _saveVideos = value),
                  ),
                  const Divider(
                    height: 1,
                    indent: 68,
                    color: Color(0xFFE9ECF0),
                  ),
                  SettingsSwitchRow(
                    icon: CupertinoIcons.antenna_radiowaves_left_right,
                    color: _green,
                    title: '使用蜂窝网络分析',
                    value: _cellularAnalysis,
                    onChanged: (value) =>
                        setState(() => _cellularAnalysis = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SectionHeader(title: '通用'),
            const SizedBox(height: 14),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const SettingsLinkRow(
                    icon: CupertinoIcons.lock_shield_fill,
                    color: Color(0xFF7758E8),
                    title: '隐私与数据',
                  ),
                  const Divider(
                    height: 1,
                    indent: 68,
                    color: Color(0xFFE9ECF0),
                  ),
                  const SettingsLinkRow(
                    icon: CupertinoIcons.question_circle_fill,
                    color: _blue,
                    title: '帮助与反馈',
                  ),
                  const Divider(
                    height: 1,
                    indent: 68,
                    color: Color(0xFFE9ECF0),
                  ),
                  SettingsLinkRow(
                    icon: CupertinoIcons.info_circle_fill,
                    color: _muted,
                    title: '关于 iTT',
                    value: '1.0.0',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const AboutIttPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SecondaryButton(
              label: '退出当前账号',
              icon: CupertinoIcons.square_arrow_left,
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                widget.controller.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AboutIttPage extends StatelessWidget {
  const AboutIttPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
        children: [
          SubpageHeader(title: '关于 iTT', onBack: () => Navigator.pop(context)),
          const SizedBox(height: 28),
          const AppCard(
            child: Column(
              children: [
                Icon(CupertinoIcons.sportscourt_fill, size: 52, color: _blue),
                SizedBox(height: 14),
                Text(
                  'iTT 乒乓球智能训练',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text('版本 1.0.0', style: TextStyle(color: _muted)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeader(title: '法律与许可'),
          const SizedBox(height: 14),
          AppCard(
            padding: EdgeInsets.zero,
            child: SettingsLinkRow(
              icon: CupertinoIcons.chevron_left_slash_chevron_right,
              color: _blue,
              title: '开源软件许可',
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'iTT',
                applicationVersion: '1.0.0',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class CreateTrainingPlanPage extends StatefulWidget {
  const CreateTrainingPlanPage({super.key, required this.controller});
  final AppController controller;

  @override
  State<CreateTrainingPlanPage> createState() => _CreateTrainingPlanPageState();
}

class _CreateTrainingPlanPageState extends State<CreateTrainingPlanPage> {
  final _titleController = TextEditingController();
  final _detailController = TextEditingController(text: '4 组 × 2 分钟');
  int _category = 0;

  static const _categories = ['正手', '反手', '发球', '步法'];

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    await widget.controller.addPlan(
      TrainingPlan(
        id: 'user-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        detail: '${_categories[_category]} · ${_detailController.text.trim()}',
        origin: TrainingPlanOrigin.user,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
        children: [
          SubpageHeader(title: '新建计划', onBack: () => Navigator.pop(context)),
          const SizedBox(height: 30),
          const Text(
            '训练名称',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          AuthTextField(
            controller: _titleController,
            placeholder: '例如：反手拧拉强化',
            icon: CupertinoIcons.pencil,
          ),
          const SizedBox(height: 22),
          const Text(
            '训练类型',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          CupertinoSlidingSegmentedControl<int>(
            groupValue: _category,
            children: {
              for (var i = 0; i < _categories.length; i++)
                i: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_categories[i]),
                ),
            },
            onValueChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 22),
          const Text(
            '训练量',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          AuthTextField(
            controller: _detailController,
            placeholder: '例如：5 组 × 30 球',
            icon: CupertinoIcons.timer,
          ),
          const SizedBox(height: 30),
          PrimaryButton(
            label: '保存训练计划',
            icon: CupertinoIcons.check_mark_circled_solid,
            onTap: _save,
          ),
          const SizedBox(height: 14),
          const AppCard(
            color: Color(0xFFEAF5FF),
            child: Text(
              '自建计划会保存在本机。完成新的动作分析后，AI 推荐计划也会自动加入首页。',
              style: TextStyle(color: _muted, height: 1.5),
            ),
          ),
        ],
      ),
    ),
  );
}

class SubpageHeader extends StatelessWidget {
  const SubpageHeader({super.key, required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      RoundIconButton(icon: CupertinoIcons.chevron_left, onTap: onBack),
      const SizedBox(width: 14),
      Text(
        title,
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
    ],
  );
}

class ProfileStat extends StatelessWidget {
  const ProfileStat({super.key, required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: _muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    child: Row(
      children: [
        Icon(icon, color: _blue, size: 24),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color color;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _SettingsRowLayout(
    icon: icon,
    color: color,
    title: title,
    trailing: CupertinoSwitch(
      value: value,
      activeTrackColor: _green,
      onChanged: onChanged,
    ),
  );
}

class SettingsLinkRow extends StatelessWidget {
  const SettingsLinkRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.value,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: _SettingsRowLayout(
      icon: icon,
      color: color,
      title: title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(value!, style: const TextStyle(color: _muted)),
          const SizedBox(width: 7),
          const Icon(
            CupertinoIcons.chevron_right,
            color: Color(0xFFAAB1B8),
            size: 17,
          ),
        ],
      ),
    ),
  );
}

class _SettingsRowLayout extends StatelessWidget {
  const _SettingsRowLayout({
    required this.icon,
    required this.color,
    required this.title,
    required this.trailing,
  });
  final IconData icon;
  final Color color;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        trailing,
      ],
    ),
  );
}

class _CaptureIcon extends StatelessWidget {
  const _CaptureIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 62,
    height: 62,
    decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
    child: const Icon(
      CupertinoIcons.video_camera_solid,
      color: Colors.white,
      size: 29,
    ),
  );
}

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key, required this.records});
  final List<TrainingRecord> records;

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 34, 22, 130),
        children: [
          const Text(
            '训练记录',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(4, (index) {
                const labels = ['全部', '正手', '反手', '发球'];
                return Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: FilterPill(
                    label: labels[index],
                    selected: _filter == index,
                    onTap: () => setState(() => _filter = index),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Text(
                '8 月',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${widget.records.length} 次训练',
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.records.isEmpty)
            const RecordsEmptyState()
          else
            ...widget.records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: RecordCard(record: record),
              ),
            ),
          const SizedBox(height: 18),
          const AppCard(
            color: Color(0xFFEAF5FF),
            child: Row(
              children: [
                _TrendIcon(),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '坚持正在发生',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '相比上周，你的击球时机提升了 6%',
                        style: TextStyle(fontSize: 14, color: _muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendIcon extends StatelessWidget {
  const _TrendIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      shape: BoxShape.circle,
    ),
    child: const Icon(CupertinoIcons.chart_bar_square_fill, color: _blue),
  );
}

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 130),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  '发现',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
              RoundIconButton(icon: CupertinoIcons.search, onTap: () {}),
            ],
          ),
          const SizedBox(height: 30),
          const SectionHeader(title: '专项训练'),
          const SizedBox(height: 14),
          const AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                DiscoveryRow(
                  color: Color(0xFF8C62FF),
                  icon: CupertinoIcons.bolt_fill,
                  title: '爆发力与步法',
                  subtitle: '12 个练习',
                ),
                Divider(height: 1, indent: 78, color: Color(0xFFE9ECF0)),
                DiscoveryRow(
                  color: Color(0xFFFF4D5D),
                  icon: CupertinoIcons.scope,
                  title: '正手进阶',
                  subtitle: '8 个练习',
                ),
                Divider(height: 1, indent: 78, color: Color(0xFFE9ECF0)),
                DiscoveryRow(
                  color: Color(0xFF1EB86A),
                  icon: CupertinoIcons.hand_raised_fill,
                  title: '发球变化',
                  subtitle: '10 个练习',
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const SectionHeader(title: '教练精选', trailing: '更多'),
          const SizedBox(height: 14),
          Container(
            height: 226,
            decoration: BoxDecoration(
              color: const Color(0xFF151D27),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 24,
                  top: 20,
                  child: CustomPaint(
                    size: const Size(138, 138),
                    painter: RacketPainter(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '本周精选',
                        style: TextStyle(
                          color: Color(0xFF99A8B7),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Spacer(),
                      SizedBox(
                        width: 220,
                        child: Text(
                          '如何找到最舒服的击球点？',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '国家级教练 · 6 分钟',
                        style: TextStyle(
                          color: Color(0xFFC6D0DA),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const SectionHeader(title: '训练小贴士'),
          const SizedBox(height: 14),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“先到位，再出手”',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 10),
                Text(
                  '步法不到位时，手臂会被迫补偿。练习中先降低球速，把注意力放在每次击球前的小碎步。',
                  style: TextStyle(fontSize: 15, color: _muted, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CoachPage extends StatefulWidget {
  const CoachPage({super.key, required this.onAnalysisSaved});
  final ValueChanged<TrainingRecord> onAnalysisSaved;

  @override
  State<CoachPage> createState() => CoachPageState();
}

class CoachPageState extends State<CoachPage> {
  final ImagePicker _picker = ImagePicker();
  final MockAiAnalysisService _analysisService = MockAiAnalysisService();
  VideoPlayerController? _videoController;
  XFile? _video;
  TrainingAnalysis? _analysis;
  bool _analyzing = false;
  int _analysisStep = 0;

  static const _steps = ['读取视频帧', '识别人体关键点', '分析挥拍轨迹', '生成训练建议'];

  Future<void> pickVideo(ImageSource source) async {
    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 10),
      );
      if (picked == null || !mounted) return;
      await _videoController?.dispose();
      final controller = VideoPlayerController.file(File(picked.path));
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _video = picked;
        _videoController = controller;
        _analysis = null;
        _analysisStep = 0;
      });
    } catch (_) {
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('无法读取视频'),
          content: const Text('请检查相机和相册权限后重试。'),
          actions: [
            CupertinoDialogAction(
              child: const Text('知道了'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _startAnalysis() async {
    if (_video == null || _analyzing) return;
    setState(() {
      _analyzing = true;
      _analysis = null;
      _analysisStep = 0;
    });
    for (var step = 0; step < _steps.length; step++) {
      if (!mounted) return;
      setState(() => _analysisStep = step);
      await Future<void>.delayed(const Duration(milliseconds: 650));
    }
    final result = await _analysisService.analyze(_video!.path);
    if (!mounted) return;
    setState(() {
      _analysis = result;
      _analyzing = false;
    });
    widget.onAnalysisSaved(
      TrainingRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: DateTime.now(),
        duration: _videoController?.value.duration ?? Duration.zero,
        analysis: result,
        videoPath: _video!.path,
      ),
    );
  }

  void _clearVideo() {
    _videoController?.pause();
    setState(() {
      _video = null;
      _analysis = null;
      _analyzing = false;
    });
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 130),
        children: [
          const Text(
            'AI 教练',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '上传一段视频，发现动作里的每个细节',
            style: TextStyle(fontSize: 16, color: _muted),
          ),
          const SizedBox(height: 26),
          if (_video == null) _buildEmptyState() else _buildVideoState(),
          if (_analyzing) ...[
            const SizedBox(height: 18),
            AnalysisProgress(step: _analysisStep, steps: _steps),
          ],
          if (_analysis != null) ...[
            const SizedBox(height: 26),
            AnalysisResultView(analysis: _analysis!),
          ],
          if (_video == null) ...[
            const SizedBox(height: 30),
            const SectionHeader(title: '拍摄建议'),
            const SizedBox(height: 14),
            const AppCard(
              child: Column(
                children: [
                  TipRow(number: '01', text: '手机横向放置，镜头与球台高度接近'),
                  Divider(height: 24, color: Color(0xFFE9ECF0)),
                  TipRow(number: '02', text: '确保全身和球台近端都在画面内'),
                  Divider(height: 24, color: Color(0xFFE9ECF0)),
                  TipRow(number: '03', text: '建议拍摄 20–60 秒连续多球训练'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
      child: Column(
        children: [
          SizedBox(
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(-34, 0),
                  child: const FeatureBubble(
                    color: Color(0xFFE9EDF1),
                    iconColor: _muted,
                    icon: CupertinoIcons.video_camera_solid,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(34, 0),
                  child: const FeatureBubble(
                    color: Color(0xFFE0F2FF),
                    iconColor: _blue,
                    icon: CupertinoIcons.sparkles,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '开始动作分析',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI 会识别身体关键点、挥拍轨迹与击球节奏',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: '拍摄训练视频',
            icon: CupertinoIcons.video_camera_solid,
            onTap: () => pickVideo(ImageSource.camera),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: '从相册选择',
            icon: CupertinoIcons.photo_on_rectangle,
            onTap: () => pickVideo(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoState() {
    final controller = _videoController!;
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(26),
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio == 0
                ? 16 / 9
                : controller.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VideoPlayer(controller),
                GestureDetector(
                  onTap: () => setState(
                    () => controller.value.isPlaying
                        ? controller.pause()
                        : controller.play(),
                  ),
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: controller.value.isPlaying ? 0 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.play_fill,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: GestureDetector(
                    onTap: _clearVideo,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (!_analyzing && _analysis == null)
          PrimaryButton(
            label: '开始 AI 分析',
            icon: CupertinoIcons.sparkles,
            onTap: _startAnalysis,
          ),
        if (_analysis != null)
          SecondaryButton(
            label: '分析另一段视频',
            icon: CupertinoIcons.arrow_2_circlepath,
            onTap: _clearVideo,
          ),
      ],
    );
  }
}

class AnalysisResultView extends StatelessWidget {
  const AnalysisResultView({super.key, required this.analysis});
  final TrainingAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '分析完成'),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  ScoreRing(score: analysis.overallScore),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analysis.strokeName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          analysis.summary,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...analysis.scores.map((item) => ScoreBar(item: item)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    color: _green,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '做得很好',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ...analysis.strengths.map(
                (text) => AdviceRow(text: text, color: _green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.lightbulb_fill, color: _orange, size: 22),
                  SizedBox(width: 8),
                  Text(
                    '教练建议',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ...analysis.suggestions.asMap().entries.map(
                (entry) =>
                    NumberedAdvice(number: entry.key + 1, text: entry.value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GlassBottomNavigation extends StatelessWidget {
  const GlassBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (CupertinoIcons.house_fill, '训练'),
      (CupertinoIcons.chart_bar_alt_fill, '记录'),
      (CupertinoIcons.compass_fill, '发现'),
      (CupertinoIcons.sparkles, '教练'),
    ];
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 76,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface
                  .withValues(alpha: .94),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F26313C),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final selected = selectedIndex == index;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        color: selected
                            ? _blue.withValues(alpha: .12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            items[index].$1,
                            color: selected
                                ? _blue
                                : Theme.of(context).colorScheme.onSurface,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[index].$2,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? _blue
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: child,
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 50});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_orange, Color(0xFFFFA93D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * .48,
            height: size * .48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: size * .34,
            height: size * .34,
            decoration: const BoxDecoration(
              color: _orange,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 24,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              trailing!,
              style: const TextStyle(
                color: _blue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisSummaryCard extends StatelessWidget {
  const AnalysisSummaryCard({
    super.key,
    required this.record,
    required this.onTap,
  });
  final TrainingRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Row(
          children: [
            ScoreRing(score: record.analysis.overallScore, size: 74),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.analysis.strokeName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _relativeDate(record.date),
                    style: const TextStyle(color: _muted, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '查看完整报告  →',
                    style: TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const FeatureBubble(
            color: Color(0xFFEAF5FF),
            iconColor: _blue,
            icon: CupertinoIcons.video_camera_solid,
            size: 54,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              '还没有分析记录\n拍一段训练视频试试',
              style: TextStyle(
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: const Icon(CupertinoIcons.chevron_right, color: _muted),
          ),
        ],
      ),
    );
  }
}

class TrainingPlanRow extends StatelessWidget {
  const TrainingPlanRow({
    super.key,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.done = false,
    this.onTap,
  });
  final Color color;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              done
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.chevron_right,
              color: done ? _green : const Color(0xFFB1B8BF),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _muted,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class RecordCard extends StatelessWidget {
  const RecordCard({super.key, required this.record});
  final TrainingRecord record;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RecordDetailSheet(record: record),
      ),
      child: AppCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEE7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.sportscourt_fill,
                    color: _orange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.analysis.strokeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_date(record.date)} · ${_duration(record.duration)}',
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${record.analysis.overallScore}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: record.analysis.scores
                  .take(3)
                  .map(
                    (item) => Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${item.score}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordsEmptyState extends StatelessWidget {
  const RecordsEmptyState({super.key});
  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 56),
        child: Column(
          children: [
            FeatureBubble(
              color: Color(0xFFEAF5FF),
              iconColor: _blue,
              icon: CupertinoIcons.chart_bar_alt_fill,
            ),
            SizedBox(height: 18),
            Text(
              '暂无训练记录',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              '完成第一次视频分析后，报告会出现在这里',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class DiscoveryRow extends StatelessWidget {
  const DiscoveryRow({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_right,
            color: Color(0xFFAAB1B8),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class FeatureBubble extends StatelessWidget {
  const FeatureBubble({
    super.key,
    required this.color,
    required this.iconColor,
    required this.icon,
    this.size = 68,
  });
  final Color color;
  final Color iconColor;
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x16000000),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Icon(icon, color: iconColor, size: size * .4),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        color: onTap == null ? const Color(0xFFB8C0C8) : _blue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 21),
          const SizedBox(width: 9),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFE9F3FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _blue, size: 20),
          const SizedBox(width: 9),
          Text(
            label,
            style: const TextStyle(
              color: _blue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class AnalysisProgress extends StatelessWidget {
  const AnalysisProgress({super.key, required this.step, required this.steps});
  final int step;
  final List<String> steps;
  @override
  Widget build(BuildContext context) => AppCard(
    color: const Color(0xFFEAF5FF),
    child: Row(
      children: [
        const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 3, color: _blue),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI 正在分析',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                steps[step],
                style: const TextStyle(color: _muted, fontSize: 14),
              ),
            ],
          ),
        ),
        Text(
          '${step + 1}/${steps.length}',
          style: const TextStyle(color: _blue, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 88});
  final int score;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 7,
            backgroundColor: const Color(0xFFE7ECF0),
            color: score >= 85 ? _green : _blue,
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          '$score',
          style: TextStyle(fontSize: size * .31, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key, required this.item});
  final ScoreItem item;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${item.score}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: item.score / 100,
            minHeight: 7,
            backgroundColor: const Color(0xFFE9EDF1),
            color: item.score >= 85 ? _green : _blue,
          ),
        ),
      ],
    ),
  );
}

class AdviceRow extends StatelessWidget {
  const AdviceRow({super.key, required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 7),
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15, height: 1.5)),
        ),
      ],
    ),
  );
}

class NumberedAdvice extends StatelessWidget {
  const NumberedAdvice({super.key, required this.number, required this.text});
  final int number;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEE7),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              color: _orange,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15, height: 1.5)),
        ),
      ],
    ),
  );
}

class TipRow extends StatelessWidget {
  const TipRow({super.key, required this.number, required this.text});
  final String number;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        number,
        style: const TextStyle(
          color: _blue,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(text, style: const TextStyle(fontSize: 15, height: 1.45)),
      ),
    ],
  );
}

class RecordDetailSheet extends StatelessWidget {
  const RecordDetailSheet({super.key, required this.record});
  final TrainingRecord record;
  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .72,
    maxChildSize: .92,
    minChildSize: .55,
    builder: (context, controller) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 38),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFC9CED3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnalysisResultView(analysis: record.analysis),
        ],
      ),
    ),
  );
}

class RacketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _orange;
    canvas.save();
    canvas.rotate(-.34);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .13,
        size.height * .05,
        size.width * .58,
        size.height * .72,
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .36,
          size.height * .65,
          size.width * .16,
          size.height * .35,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFFFB06D),
    );
    canvas.restore();
    canvas.drawCircle(
      Offset(size.width * .82, size.height * .22),
      size.width * .1,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _relativeDate(DateTime date) {
  final days = DateTime.now().difference(date).inDays;
  if (days == 0) return '今天';
  if (days == 1) return '昨天';
  return '$days 天前';
}

String _date(DateTime date) => '${date.month} 月 ${date.day} 日';

String _duration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

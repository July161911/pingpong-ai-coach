# iTT

一款面向 iOS 与 Android 的乒乓球训练动作分析应用。用户可以拍摄或选择训练视频，查看动作评分、分项表现与针对性训练建议。

## 功能

- iOS 风格的四标签页界面：训练、记录、发现、AI 教练
- 相机录像与相册视频选择
- 训练视频预览与播放
- AI 分析进度展示
- 准备姿势、引拍幅度、重心转移和击球时机评分
- 动作优点、改进建议与历史训练记录
- 手机号/邮箱本地注册登录（无验证码、无后端）
- 白天、黑夜和跟随系统三种显示模式
- 根据报告自动生成推荐计划，并支持用户自主新建计划
- iOS 和 Android 权限配置

## 当前状态

完整页面框架、本地账号、训练计划、训练记录、发现页和视频分析流程均已保留。当前 `MockAiAnalysisService` 返回演示报告；接入正式视频姿态估计与评分服务后即可替换，不需要改动页面流程。

## 运行

```bash
flutter pub get
flutter run
```

## 验证

```bash
flutter analyze
flutter test
flutter build ios --simulator --no-codesign
flutter build apk --debug
```

项目使用 Flutter 3.47.1 开发。


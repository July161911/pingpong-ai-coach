# 卓练 AI（PingPong AI Coach）

一款面向 iOS 与 Android 的乒乓球训练动作分析应用。用户可以拍摄或选择训练视频，查看动作评分、分项表现与针对性训练建议。

## 功能

- iOS 风格的四标签页界面：训练、记录、发现、AI 教练
- 相机录像与相册视频选择
- 训练视频预览与播放
- AI 分析进度展示
- 准备姿势、引拍幅度、重心转移和击球时机评分
- 动作优点、改进建议与历史训练记录
- iOS 和 Android 权限配置

## 当前状态

界面和完整交互流程已实现。当前 `MockAiAnalysisService` 返回演示分析结果，后续可替换为姿态识别模型或云端视频分析 API。

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

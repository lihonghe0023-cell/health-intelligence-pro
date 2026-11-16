# 健康中枢 · Health Intelligence Pro 2.0

**iPhone + Apple Watch 原生 SwiftUI 源码、正式视觉规范与竞品对标交付包**

> **真实发布状态：Source Release Candidate 2.0（源码工程候选），不是已签名/真机安装正式包。** 该包在 Linux 环境编制，仅执行 Swift 核心单元测试与全量 Swift 语法解析；**未**在 macOS Xcode 中做 SDK 类型检查，尚无 IPA / Watch 安装证据。不能将“界面效果图”认作原生 App 运行截图。

## 产品定位

全面覆盖 Apple Watch Series 12 的公开 HealthKit 可读取健康数据，并把症状、用药、手动血压/血糖、体检档案、长期趋势、可信分析、报告与隐私防护整合为健康优先的个人应用。运动保留但不主导界面。

## 本工程已经实际编写的内容

| 范围 | 代码现状 |
|---|---|
| iPhone 原生 UI | 今日、心脏、睡眠、健康库、报告、设置，深浅主题、指标详情、搜索、首次隐私与授权引导 |
| 健康基础 | `HealthCatalog` 35 项 HealthKit 数量样本定义与按需读取；高/低心率及不规则心律系统事件目录 |
| ECG | 苹果原生 ECG 已保存样本的分类、日期和波形只读查看；不能主动触发 ECG |
| Sleep | REM、核心、深睡、清醒区间去重与实际时长汇总；Watch 端睡眠摘要 |
| 趋势与基线 | HealthKit 日粒度聚合、7/30/90 天切换、本机稳健中位数基线，至少 7 个不同日期历史记录才能比较 |
| 录入与日志 | 用户主动录入体重、血糖、收缩/舒张压；症状、用药和健康笔记，本地文件保护 |
| 报告 | 规则解释和本地 PDF 健康摘要，主动分享，不含外部 AI 服务 |
| Watch App | 原生 SwiftUI 页面、五项核心读取类型、睡眠摘要、主动刷新、仅传同步状态的 WatchConnectivity |
| 工程 | XcodeGen 双 Target + HealthCore Swift Package、基本 GitHub macOS CI、Swift 核心单测 |
| 视觉 | 1024px 品牌 App Icon、双模式设计预览图、独立网页多屏视觉样稿、医疗级 Design System v2 |

核心源码 `HealthCore` 现有 **13 项测试通过**；所有 `iOS/` 与 `Watch/` Swift 文件通过 Linux `swiftc -frontend -parse`（语法阶段，不是 Apple SDK 编译）。

## 本工程尚未完成的部分（不可虚报）

全面健康能力需求共 **168 条**，并不等于已实现 168 条。系统高血压通知、呼吸暂停系统事件、定时服药提醒、完整临床资料接入、OCR、外置 CGM/血压计、全周期 Sleep Trends、NAS 加密同步、远程 AI、Widget/Complication、完整 UI 自动化、真机签名安装，仍需根据 `Docs/ALL_HEALTH_CAPABILITIES.md` 逐项实现、测试。

正式发布需要 Mac/Xcode、Apple SDK、真机 HealthKit 授权、用户当前的第三方分发签名是否包含 Watch 安装权限的独立审核。此源码包**不含** P12、mobileprovision、密码、密钥或个人健康记录。

## 如何查看设计

- `VisualPreview/index.html` — 用浏览器打开；可以点击右上角切换浅色 / 深色，**所有显示数值为明确标注的 UI 演示数据**。
- `Design/HealthIntelligence_Light.png` / `Design/HealthIntelligence_Dark.png` — 五个手机主屏与 Watch 的版式基线。
- `Design/Concept/Product_Vision_Concept.png` — 视觉概念氛围海报，不能替代真机 UI 截图。
- `Design/Concept/Logo_Concept.png` — 品牌图标源参考。实际 AppIcon 位于 iOS/Watch 对应的 `.xcassets` 中。

## 工程结构

```
Core/                 可在 Linux / macOS 测试的纯 Swift 健康算法
Configuration/        iOS/watchOS entitlement 样例（不含证书）
iOS/                  iPhone 原生 App、HealthKit、PDF、UI
Watch/                watchOS 原生 App、HealthKit、连接状态
Design/               正式视觉参考与概念图
VisualPreview/        HTML 多屏预览（不触发健康权限）
Docs/                 市场对标、168 项覆盖矩阵、视觉规范、Muse 指令、验收门禁
Scripts/              XcodeGen 工程生成、结构核验
.github/workflows/     无签名双端编译/单元测试工作流
```

## 编译（仅 macOS + 兼容 Xcode）

```bash
brew install xcodegen
./Scripts/generate_xcode_project.sh
cd Core && swift test && cd ..
xcodebuild -project HealthIntelligence.xcodeproj -scheme HealthIntelligence \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project HealthIntelligence.xcodeproj -scheme HealthWatch \
  -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

模拟器构建正常后，才可以处理个人证书对应的 iPhone IPA 和 Watch App 签名。第三方 P12 + iPhone mobileprovision 不保证 Watch 包可安装；Watch 仍需独立 ID、UDID、profile 和实机确认。

## Muse 从哪开始

**请把整个 ZIP 和 `Docs/MUSE_PRO_FINAL_EXECUTION_PROMPT.md` 一起交给 Muse。** 它必须先做 Xcode 实际编译修复，再逐条验收 168 项功能，然后做截图与发布门禁，最后交付可安装版本。

## 原始依据

Apple HealthKit：https://developer.apple.com/documentation/healthkit

watchOS 27：https://developer.apple.com/watchos/whats-new/

竞品及开源对照：`Docs/Research/COMPETITOR_BENCHMARK_2026-11-16.md`

**声明：** 该应用是健康记录与个人趋势辅助工具，不是医疗器械，不用于确诊疾病或急救监护。存在严重症状时优先联系急救/医护。

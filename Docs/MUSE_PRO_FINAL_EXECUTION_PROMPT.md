# 直接发给 Muse 的执行总提示词（健康中枢 Pro）

你是我的资深 iOS/watchOS 工程执行负责人，GPT 负责最终产品设计、架构规范、视觉稿和验收原则，你负责**实际编码、修复、真机 CI、打包和交付**。用户已有 Apple Watch Series 12（watchOS 27.2.1），iPhone 使用 iOS 27，主目标是**健康功能最大覆盖，运动为次要**。用户仅有第三方购买的 P12 + mobileprovision，不要要求其另购 Apple Developer Program，也不要未经授权提交第三方 Apple 签名证书到 GitHub。

## 0 · 本轮交付的不可回避条件

1. 已提供 `HealthIntelligence_Pro_2_0_ReleaseCandidate.zip`。先解压，对照目录 `README.md`、`Docs/Research/COMPETITOR_BENCHMARK_2026-11-16.md`、`Docs/ALL_HEALTH_CAPABILITIES.md`（168 项矩阵）、`Docs/DESIGN_SYSTEM_V2.md`、`Docs/DELIVERY_GATES.md`、`VisualPreview/index.html` 与 `Design/Concept/Product_Vision_Concept.png` 完整阅读。
2. 现有项目包括 iPhone SwiftUI App、独立 watchOS App、HealthCore、HealthKit 接口、ECG 只读、趋势、PDF、健康日志、Watch 通信和测试。禁止推倒重做、删除真实功能或靠漂亮截图替代实际实现。
3. 各次结果必须基于**实际证据**。没跑过 Xcode Build 就写“未验证”；没真机安装就写“未安装”；缺失第三方 Watch 签名就写“受阻”，不能谎称正式交付成功。
4. 所有可以通过公开接口、外部合规设备或明确授权实现的健康需求都纳入路线图，逐项开发直到通过门禁。对系统禁止的能力不要绕过安全或签名机制，可采用公开 HealthKit 数据、外置血压计、CGM 等合法替代。
5. 本工程默认离线；任何 AI / NAS / 外部服务都须单独开启且明确告知处理的数据范围、第三方服务、保留与删除方式。不上传 P12、密码、密钥、健康数据到公开仓库、CI 日志或在线图像生成器。

## 1 · 编译主线（比增加功能更先）

- 在支持 iOS 27 与 watchOS 27 的最新合规 Xcode 上运行 `./Scripts/generate_xcode_project.sh`。
- 执行 `swift test` 并确认所有单测，包括 `BaselineAnalyzerTests`。
- `xcodebuild` 分别编译 iOS Simulator 与 watchOS Simulator；遇到 SDK API 不兼容需**实际定位错误并修改代码**，不允许跳过 Watch Target。
- 验证 iPhone bundle id 与 watch bundle id、`WKCompanionAppBundleIdentifier`、embed phase、`Info.plist`、HealthKit entitlement、隐私用途说明、最低部署版本。
- 跑完整 UI 回归：浅色/深色、动态字号 A11y XXXL、Reduce Motion、VoiceOver、42/46mm Watch、断网、空状态、授权拒绝、超时、存储损坏、PDF 分享、卸载恢复。

## 2 · 必须完成的健康功能

按 `Docs/ALL_HEALTH_CAPABILITIES.md` 的 168 条逐项创建任务（每条需来源、数据结构、真实采样、显示入口、异常与空态、测试证据）。所有功能纳入完整产品范围，不可因为实现困难自动取消。核心模块：

- 心脏：当前/历史心率、RHR、HRV、Recovery HRV 可用性探测、系统高低心率/不规则心律事件、房颤负荷、ECG 已完成样本/波形/PDF、血压、VO₂max、个人基线与症状关联。系统没有提供新建 ECG API 时跳转或提示使用苹果原生 ECG App。
- 睡眠：所有阶段、夜间体征、睡眠时间与规律、觉醒、30/90 天趋势，识别来源冲突并按正式算法去重，不伪造苹果睡眠评分。
- 呼吸与体征：血氧、呼吸频率、腕温、呼吸扰动、体温、血压、血糖、体重、体脂、代谢；缺少设备直接说明并支持外部测量仪的数据桥接。
- 生活与心理：症状日记、用药清单/剂量/提醒、健康记录、经期、情绪与正念、饮水、营养、环境/听力、步态和基础活动。
- 医疗资料：临床记录（地区/医院/授权允许时）、检查单、OCR、结构化信息，上传照片识别必须经用户确认、医疗数据默认本地。
- AI 与报告：离线可解释规则、确定性的基线、每日/每周/每月/就诊 PDF、CSV/JSON 导出。AI 远程 API 是明确 opt-in，不向用户返回诊断结论或无依据的风险百分比。
- Watch：原生可操作应用、关键生命体征、睡眠摘要、点击刷新、手腕提示、Complications/Smart Stack/App Intents 在签名与 OS 支持下接入，遵守后台和电池规则。

## 3 · UI/UX 一次性定版规则

GPT 提供的 `Docs/DESIGN_SYSTEM_V2.md` 是不可自行偏离的 Design System。取材于 Apple、Bevel、Athlytic、AutoSleep、HeartWatch、Gentler Streak 的**功能和交互设计原则**，不得复制竞品素材、商标、代码或专有算法。

- 医疗级易读、暖白深青浅色界面、OLED 深色模式、语义色彩、统一 SF Symbols、统一圆角卡片和主要按钮。
- 首页、心脏、睡眠、健康数据库、报告、设置、Watch 界面必须各有设计稿和对应真实 SwiftUI 实现；允许为更多功能扩展二级页面，但不能把一切塞入首页。
- 逐页检查点击目标与导航一致性、按钮六态、空态、错误态、无障碍、Reduce Motion 和 Dynamic Type。绝不显示“死按钮”和不可操作功能入口。
- 比视觉稿更优先的是**数据来源明确和有证据的健康描述**。概念稿中的分数 92、健康稳定、疾病风险等均是示意，生产页面除有真实输入与明确可靠算法外不得显示。
- 每页交付截图和 UI 自动化证据，统一深浅双模式；真机截图需与设计 token 比对。

## 4 · 医疗安全与隐私

- **不可实现**的功能包括：Apple Watch 单独无创测量血糖、直接输出袖带式血压数值、通过非公开 API 激活 ECG、绕过后台权限持续采样、伪造高血压或呼吸暂停检测。只通过合法来源/外部设备解决，不要修改系统或使用禁用的越狱/私有框架。
- 健康样本的读取授权状态并非总能被精确判断；“无数据”≠“正常”。
- 数据按来源和日期去重、保留单位和时间区、提供缺失数据原因；个人评分不可冒充医疗器械的诊断/治疗建议。
- NAS/外部数据流的威胁模型、加密、恢复演练、数据删除和密钥轮换是发布前必做项；分享 PDF 需显式提示包含个人健康信息。

## 5 · 第三方 P12 签名路线（不强迫购新证书）

1. 仅从用户提供的安全渠道读取证书；验证 P12 与描述文件是否匹配、是否过期、真实 App ID、HealthKit entitlement 和 iPhone UDID。
2. 独立核对 Watch UDID、Watch 专属 App ID、Watch 专属描述文件和签名授权；已有 iPhone provisioning profile 不能自动证明 Watch 可装。
3. iPhone IPA 与 Watch 配套安装分别运行真实安装测试，逐项记录系统版本、Bundle ID、签名摘要、SHA256、安装日志。
4. 不具备 Watch 授权时，继续交付完整 Watch 源码和 unsigned build 证据；明确指出阻塞来自第三方授权，不允许伪造“手表安装成功”。
5. 对私钥、P12 密码与手机设备编号保密；所有日志脱敏，严禁打印敏感信息。

## 6 · 交付门禁及最终输出

最终交付需包含：`*.xcodeproj` 或完整生成脚本、全部 iOS/watchOS/Core 源码、所有 UI assets（AppIcon 1024、浅深设计参考）、完整 README、所有测试/截图/模拟器录像、CI 日志、功能矩阵逐项证据、签名审计、APK/IPA?（仅 IPA，非 Android）、配套 Watch 安装验证、SHA256/SBOM、备份回滚方案、完整缺陷列表。

**必须按以下格式汇报每次进度：**
```
当前 commit：<sha>
iOS build：PASS/FAIL/NOT RUN（日志/链接）
watchOS build：PASS/FAIL/NOT RUN（日志/链接）
已证实可用的健康功能：<实际功能+真机证据>
未完成/受限：<逐项>
视觉通过页数：<分母/分子 + 截图>
签名：iPhone <状态> | Apple Watch <状态>
下一项具体代码任务：<一件可验证的改动>
```

用户要求极致成品，请尽力做满已公开可实现功能，但不能用“完美、全部支持、正式可安装”掩盖任何没有跑过的验收。**开始立即读取源码，先修复 iOS + watchOS 的 Xcode 实际构建，再逐条实现 168 项覆盖矩阵，最后取得真实签名安装证据。**

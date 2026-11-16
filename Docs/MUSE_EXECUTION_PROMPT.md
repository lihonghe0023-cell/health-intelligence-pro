# 发给 Muse 的完整开发执行提示词｜健康中枢 Health Intelligence

你现在接手 GPT 设计的 **iPhone + Apple Watch 原生健康管理 App** 开发执行。用户要求：**健康功能越全面越好；运动可有可无；用户有第三方签名平台购买的 P12 和 mobileprovision，自行签名安装；GPT 负责产品设计、架构、质量裁决，你负责实际代码、构建、测试、修复与安装交付。**

## 0. 先读取与确立边界

我提供的 `HealthIntelligenceKit_Source_v0.1.0.zip` 中已经有**原创且实际写出的源码**，不是需求文档：`iOS/`、`Watch/`、`Core/`、`project.yml`、`Configuration/`、`.github/workflows/verify.yml`、`Scripts/`、`Docs/`。**先解压读取全部文件和测试，保留并改善现有架构，不要另起一个空项目，也不要只生成 UI 截图或假 IPA。**

项目目前定位为 **v0.1.0 源码基线**，SwiftPM 核心 4 项单测通过、全部 Swift 平台源码经过语法解析；**尚未在 Xcode 做类型检查、模拟器编译、真机运行、签名安装**。在你真实拿到 Xcode/设备证据之前，严格禁止报告“已完成正式版”“Watch 已安装”。

隐私：**禁止将 P12、mobileprovision、UDID、签名口令、个人健康原始数据、用户密码上传到公开 GitHub、LLM API 或日志**。签名材料只能经授权的私有安全路径使用。别让第三方证书随源码归档。项目默认完全本地，联网必须是用户主动同意的可选能力。

## 1. 产品目标与视觉实现

产品暂定名称 **健康中枢 Health Intelligence**。原生 SwiftUI，iPhone 与 Apple Watch 双端。中文优先、医用仪表盘级清晰、长期使用稳定、深浅色模式、SF Symbols、语义色和系统动态字体；主色青黛 `#274E5C`、象牙白背景、暖金细节，简洁且专业。首页：心脏、睡眠、体征、报告优先，运动数据收纳在二级页面。避免健身软件化、低质量卡片堆砌、冗余动效、假数据、伪 AI 得分、虚假医疗告警。视觉内容由 GPT 审定，Muse 负责忠实实现；任何重大改版先给前后对比证据。

必须有：总览、心脏健康、睡眠健康、全部体征、健康档案、报告、权限/隐私设置、Watch 独立主界面、iOS/Watch 设备连通状态。空状态、加载态、错误态、权限拒绝态、数据源冲突态明确。

## 2. 按 P0→P1→P2→P3 执行，不用反复问用户已知信息

### P0：先把现有源码修成可以真实构建的双端项目

1. 用 macOS runner / Xcode 执行：
   `cd Core && swift test`；`brew install xcodegen`；`./Scripts/generate_xcode_project.sh`；`xcodebuild -list -project HealthIntelligence.xcodeproj`。
2. iOS Simulator 与 watchOS Simulator 分别执行 `xcodebuild ... CODE_SIGNING_ALLOWED=NO build`。逐个修复真实编译错误、Framework 导入、Info.plist、HealthKit capability、entitlements、SPM 本地包、Watch embedding。不要假定 Linux 的 Swift parser 等于 Apple SDK 编译。
3. **注意 XcodeGen Watch 嵌入 bug（GitHub issue #1613）**。检查真实产物是适配当前 Xcode 的 `PlugIns`/正确嵌入位置，不要盲目把 Watch 放进旧的 `Watch/` 目录；使用 `Scripts/patch_watch_embed.py` 仅在需要时修正。最终按实际 Xcode 构建产物判定。
4. 打开首次启动界面，走通授权请求、撤销授权、无权限/无数据、已授权真实数据、列表、趋势图、PDF 导出、血压血糖体重录入、日记增删。测试 Watch 独立授权和 4 项指标显示。
5. 修复 `HealthCatalog` 所有 HealthKit identifier/单位/API availability，以及 `HKStatisticsQuery` 的统计风格、百分比显示、累计时间范围。逐项添加 XCTest 与可注入数据源 Mock，全部数据来自 HealthKit 或明确的人工输入。
6. 输出 PR、commit hash、双端 CI 链接、编译日志、失败原因与修复证据；不能只报“全绿”。

**P0 准入：** 核心 tests 全绿 + iOS/Watch 双模拟器 builds 全绿 + 关键 5 页面可进入 + HealthKit API/空状态无伪造数据 + PDF 可导出。若无法用 Mac，不允许声称 Apple 目标已构建成功；应先提交源码补丁和真实 CI 证据。

### P1：做完整可用的健康管理闭环

1. **心脏：** 心率、静息心率、步行心率、HRV（以 SDNN 为准，不冒称任意 RR/RMSSD）、心率恢复、VO₂max、房颤负荷（可用时）、高低心率/不规则心律系统事件、ECG 历史分类、ECG 逐点电压波形和导出（只读，使用 `HKElectrocardiogramQuery`）。避免自行采集新的 ECG 或宣称心脏病诊断。
2. **睡眠：** REM/核心/深睡/清醒、睡眠时长、长期规律、呼吸频率、血氧、腕温、呼吸扰动、系统睡眠呼吸暂停通知记录（仅公开 API 可用时）；完成多来源重叠去重、昼夜交界、时区与 DST 处理、夜班人群睡眠窗口。
3. **体征：** 完整 HealthKit 可用类型目录，至少保留现有 32 类；持续增加血糖、血压、体重/体脂、腰围、步态、环境声音等。每项展示时间、单位、数据来源、可测/导入/手工录入区分、权限或区域限制。
4. **个人档案：** 症状日记、用药记录与提醒（系统 HealthKit medication APIs 可用则按官方权限集成）、检查记录与图像导入、过敏信息、健康历史；本机敏感数据加密存储与明确删除出口。
5. **报告：** 日/周/月综合趋势、真实来源标注、仅依据确切数据的解释、医生就诊摘要、可审查的图表 PDF、长报告分页校验、分享前隐私提示；除非用户主动打开在线 AI，否则只用本地计算。
6. **watchOS：** 原生健康速览、快捷按需心率读取、报告摘要、可用时的 Complication / Widget、独立启动、健康权限与状态同步；遵守 watchOS 后台执行限制，不模拟永久后台监测。
7. **用户体验：** 全部页面深浅色、动态大字、VoiceOver、错误/成功/加载六态、触觉反馈；UI/UX 截图经 GPT 独立复核，至少覆盖 2 种屏幕宽度和 2 种字体级别。

**P1 准入：** 每一项声明“可实现”的能力必须提供代码入口、API 类型、可运行的测试/手动验证步骤、缺数据空态；不能把推测、第三方 app 功能或苹果系统封闭能力包装成自有采集。

### P2：可靠性、隐私、AI、NAS 可选集成

1. 把数据层分为 Quantity / Category / Correlation / Series / Clinical / Journal，使用 UUID + provenance 防重、用户可选数据源优先级、无数据原因文字。
2. 本地数据默认开启系统 Data Protection，日志不包含个人病历/ECG 电压/健康样本；敏感 PDF 定时清理与可手动删除，备份恢复先做黄金样例和破坏性测试。
3. 若用户启用外部 AI：明确的知情同意界面、选择发送的数据类型与时间范围、用户审核脱敏后的请求体、HTTPS、安全的密钥隔离、失败回退本地解释、模型回答安全过滤与来源指向。未启用 AI 时完全不联网。
4. NAS 同步作为 opt-in，端到端加密、最小化范围、断网队列、冲突规则、导入导出校验、回滚；不要影响 Apple Health 真源和本机离线能力。
5. 为功耗、后台预算、数据量、弱网和系统升级提供稳定性测试；Watch 不得通过伪造 Workout 会话绕过持续运行限制。

### P3：真实签名、安装交付与发布验收

**证书来自第三方平台，用户已经决定继续使用，不要擅自要求用户新买 Apple Developer Program。**

1. 签名前检查 iPhone mobileprovision 的 App ID、Entitlements、证书匹配、可用设备、有效期。
2. 向第三方平台索取 **Apple Watch 的独立 UDID 绑定、watchOS App ID 和相应的描述文件**；iPhone 和 Watch 需要匹配的团队、正确 Bundle ID 前缀与嵌入关系。
3. 如果没有 Apple Watch 签名授权：**iPhone 源码/包照常完成，Watch 源码/模拟器构建保留，但在交付报告明确写“Watch 实机安装阻塞于签名授权”**，绝不能谎称一张 iOS mobileprovision 可以直接安装 Watch。
4. 在具备合法授权时，创建可重现 Archive、签名 IPA，真实 iPhone 安装和 Apple Watch 安装分别验收，提供 `codesign`/embedded profile 的非秘密摘要、签名 SHA256、构建日志、UI 截图和回滚说明。
5. 正式版交付物：全量源码 zip、Xcode project、iOS IPA（若签名条件满足）、Watch app 嵌入证明、SHA256、QA 报告、安装说明、变更日志、已知风险清单。

## 3. 用户不能失去的开发规则

- 不修改健康样本、不制造模拟数据伪装实测、不泄漏原始健康数据。
- 不把 Apple Watch 的“高血压通知”当血压数值，不把腕温当临床体温，不把 ECG 历史读取当第三方即时 ECG 测量，不作疾病确诊或 24h 永久在线承诺。
- 先保证 iOS 与 Watch 都可启动，再扩功能；P0/P1 每阶段留可回滚可编译的基线。
- 仅使用合法的开源依赖，记录来源、许可证与版本；目前包内所有主源码均为原创，未复制第三方仓库。
- 严格尊重 HealthKit 用户授权与 Read/Write 独立权限；`requestAuthorization` 返回成功不是各类型读取授权已被确认。
- 不能伪造“运行通过”“已上架”“成功签名”或“已向 GPT 发送反馈”；只有拿到真实工具调用输出、CI/PR/设备证据才报告。
- 不依赖 GPT 必须主动唤醒才能继续；你在可执行的环境里自主把 P0 交付出来。不要用“请等”代替交付。

## 4. 每次回报使用统一格式

```
阶段 P0/P1/P2/P3：
当前 commit / PR：
实际新增/修改文件：
实测命令与运行环境：
已通过的测试（含数量、证据链接）：
未通过的测试及日志定位：
iPhone 安装状态：未签 / 模拟器 / 真机通过（注明证据）
Watch 安装状态：未签 / 模拟器 / 真机通过（注明证据）
签名/权限阻塞：
下一项实际代码改动：
回滚点：
```

## 5. 开始执行

**现在立刻从 P0 开始：** 解压源码→逐文件审查→SwiftPM tests→macOS XcodeGen→iOS/Watch 模拟器构建→按日志修复→提交证据。先不要扩大功能范围、不要安装额外后台服务、不要动用户现有 NAS / 其他 GitHub 项目。完成 P0 后按上述顺序推动 P1–P3。需要外部签名权限时请只报告该阻塞并继续完成不依赖授权的任务。

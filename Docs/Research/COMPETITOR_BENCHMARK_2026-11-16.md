# 健康中枢 Pro · 2026-11-16 竞品与开源基线

**调研范围：** Apple Watch Series 12 + iOS / watchOS 健康数据管理；以厂商官网、App Store 和项目 README 为一手证据。市场“最佳”没有唯一公认标准；以下为功能对标，不表示独立购买或完整真机测试过所有竞品。

## 商业产品实际可借鉴的能力

| 产品 | 一手来源 | 确认的能力 | 我们的改进方向 |
|---|---|---|---|
| Apple Health / Series 12 | https://www.apple.com/apple-watch-series-12/ | 更高频心率/HRV、Readiness、Vitals、Sleep Score、ECG、睡眠、系统通知 | 提供跨域数据解释、透明来源与本地报告，而非假装获取所有系统内部评分 |
| Bevel | https://help.bevel.health/en/articles/11583937 | 恢复、睡眠、压力、能量、营养、健康监测、Watch、Widget、日记和 AI | 增加对就诊有用的结构化报告与中文证据解释；医疗数据优先于健身 |
| Athlytic | https://apps.apple.com/us/app/athlytic-fitness-recovery/id1543571755 | HRV+RHR 恢复、基线、睡眠、训练负荷、健康趋势、Siri、Watch complications | 采用可测试的独立基线机制，无样本时明确不足，绝不复刻其专有公式 |
| AutoSleep | https://autosleepapp.tantsissa.com/home/overview | 睡眠阶段、睡眠债、智能闹钟、Readiness、历史记录、隐私 | 避免多来源睡眠重复计时，显示数据来源；睡眠债算法仅作辅助 |
| HeartWatch | https://apps.apple.com/us/app/heartwatch-heart-rate-monitor/id1062745479 | 心率分场景分析、趋势、ECG、血压/血糖记录、导出 | 心脏总览与原始 ECG 历史波形；每张卡片附时间和来源 |
| Gentler Streak | https://apps.apple.com/us/app/gentler-streak-workout-tracker/id1576857102 | 恢复友好建议、睡眠、趋势、Watch 小屏 UI、系统无障碍适配 | 以健康管理为重心；不过度强调每天冲成绩，休息是正常结果 |
| Apple Health + 外部器械 | https://developer.apple.com/documentation/healthkit | 血压、血糖、体重等第三方写入与读取 | 不声称手表具备无创血糖或可输出具体血压 |

## 开源项目验证与合理复用

| 项目 | 地址 | 仓库说明中的许可 | 可复用的设计思想 | 风险与门禁 |
|---|---|---|---|---|
| HealthCards | https://github.com/halilozel1903/HealthCards | MIT | 健康数据来源抽象、Swift Charts、跨 iPhone/Watch UI、样本模式显式标注 | 小型项目，必须自行编译和安全审计；测试数据不可进入生产流程 |
| HealthHub | https://github.com/matybrennan/HealthHub | MIT | Swift 6.4 依赖注入、HealthKit 读写、临床工作流、单测 | 其 iOS 27 优先版本与当前工程 iOS 18 基线兼容性须实测 |
| HealthBridge | https://github.com/Polinss3/HealthBridge | Apache-2.0 | 本地优先、FastAPI/SQLite NAS、自托管与敏感 API Key 存储 | NAS 后端必须默认关闭，单独威胁建模与端到端加密，网络失败不得丢数据 |
| bearing-ios | https://github.com/eugenity92/bearing-ios | 以仓库 LICENSE 为准 | HealthKit 个人基线、纯 Swift 核心可测试算法 | 不照抄未验证权重、医疗阈值 |
| Whoordan | https://github.com/W4rd2/whoordan | Apache-2.0 | 原始分数与数据来源可追踪、隐私优先实现 | 不纳入 Supabase 或账号要求；只借鉴模式 |

**复用方式：** 当前源码只独立实现，无直接拷入以上第三方仓库代码或素材。Muse 可在许可证审计、版本固定、依赖 SBOM、安全检查后决定是否引入。品牌、专有算法、截图及受版权保护的素材均不能复制。

## 比竞品更可靠的具体定义

1. **缺少数据就明确说明缺少数据。** 所有指标显示采集时间、采集来源、单位、数据是否陈旧。绝不生成“正常、稳定、健康评分 92”之类的虚假评价。
2. **跨域报告可以追溯。** 心脏、睡眠、症状、用药、血压/血糖、体检资料沿时间轴归档；任何自动化解读列出输入窗口和可能的限制。
3. **离线模式是默认状态。** App 不要求服务器、不要求注册、不收集广告标识；可选 AI 和 NAS 是明确许可后开启。
4. **医患沟通优先。** 趋势图与 PDF 可供就诊时核对，而不是仅追求训练评分。
5. **完整无障碍。** 中文、动态字号、VoiceOver、Reduce Motion、44pt+ 触控区域、最大文字缩放、低对比度修正。
6. **Apple Watch 原生。** 手腕端只展示最有用的少量指标，避免把手机界面机械缩放到手表。
7. **真实可靠的边界。** 不规避地区限制、医疗安全门禁、第三方签名设备授权，也不冒充原生 ECG 采集和测血糖。

## 官方 API 边界

- Series 12 官方技术规格：https://www.apple.com/apple-watch-series-12/specs/
- watchOS 27 新 API：https://developer.apple.com/watchos/whats-new/
- HealthKit：https://developer.apple.com/documentation/healthkit
- ECG 电压只读：https://developer.apple.com/documentation/healthkit/hkelectrocardiogramquery
- HealthKit 后台更新：https://developer.apple.com/documentation/xcode/configuring-healthkit-access
- watchOS 功能可用地区：https://www.apple.com/watchos/feature-availability/

**注意：** Apple 自有 Readiness、Sleep Score、Health Age 等系统体验未必有公开的完整原始评分 API；若不可读取，只能使用公开样本构建我们自己明确命名、透明解释的非医疗趋势，而不是声称获取苹果官方分值。

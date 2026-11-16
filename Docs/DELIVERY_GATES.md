# Release 2.0 · 不可跳过的正式安装门禁

当前环境为 Linux，只有 Swift 6.2.1，可完成 SwiftPM Core 单测及 Swift 源码解析，无法调用 Apple SDK 或 Xcode。因此**正式编译、模拟器与真机结论全部待 Muse 运行**。

## 一、构建

```bash
brew install xcodegen
./Scripts/generate_xcode_project.sh
cd Core && swift test && cd ..
xcodebuild -version
set -o pipefail
xcodebuild -project HealthIntelligence.xcodeproj -scheme HealthIntelligence -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build | tee ios-build.log
xcodebuild -project HealthIntelligence.xcodeproj -scheme HealthWatch -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO build | tee watch-build.log
```

- 对应 2026 系统环境选择正确 Xcode SDK，不因 CI macOS runner 版本变化虚报 PASS。
- 证书签名之前先确认证书与 provision 匹配，HealthKit entitlement 受授权允许，Watch 独立设备注册。
- XcodeGen Watch 嵌入必须检查 `Payload/<App>.app/Watch/<Watch>.app` 的实际结构，不仅检查“iOS build green”。

## 二、真实数据和隐私

- **真机授权**：包括正常、部分授权、没有数据、撤回授权、锁屏、切换设备。
- **准确性**：原始值/单位/来源/时间区与苹果健康 App 一一对比；睡眠分期跨设备去重。
- **分类**：ECG 只读，不能新增采样；高血压和睡眠呼吸暂停系统通知只展示已有记录。
- **本地文件**：掉电/写入中断/损坏 JSON/卸载/备份/恢复、iPhone 迁移。
- **导出**：PDF 所有文字可读、无数据不生成虚构指标、清理临时 PDF；分享前提示敏感性。
- **可选联网**：无用户显式 opt-in 时网络抓包不得发现健康数据上传。

## 三、视觉与无障碍

- 5 主 Tab + 设置 + 首次引导 + ECG/指标详情 + 手表屏幕。
- iPhone 16 Pro Max 以及小屏 iPhone、Watch 42mm/46mm、深浅主题、中文超长文案、横竖屏边界。
- 字号可访问级别、VoiceOver、Contrast、Reduce Motion、切换系统字体、低电量/离线性能。
- 图表要带可访问的摘要和数据单位、错误提示可恢复、按钮无死链。

## 四、认证与安装

- 当前用户的 P12 来源为第三方，不是 Apple Developer Program 本人账号的全权限授权。
- 签名类型及权限以**实际证书 / profile 内容**为准，当前项目不含私钥。
- iPhone 和 Watch 需独立证明：相关 Bundle ID、设备注册、Watch embed、安装日志、运行截图、HealthKit 授权截图。
- 私钥密码绝不上传任何公共 CI。若使用 CI signing，必须先由用户明确许可在安全密钥存储中配置并核实权限。

## 五、发布状态定义

| 状态 | 标准 |
|---|---|
| 设计冻结 | 设计规范和布局预览一致、视觉清单签字 |
| 源码候选 | 代码可检视，核心单测与语法检查通过 |
| 构建候选 | iOS + Watch 的 Xcode 无签名构建确实通过 |
| 安装候选 | 用户 iPhone + Watch 实际安装、健康授权和数据读取通过 |
| 正式交付 | 上述全部通过，完成回归、隐私与性能审计，输出签名包、SHA256、回滚包 |

**当前：源码候选（非安装候选）**。签名和真机测试无法用 CLI 语法解析替代。

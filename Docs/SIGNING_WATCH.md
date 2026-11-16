# 第三方 P12 证书与 Apple Watch 安装门禁

## 已知情况

- 用户持有从第三方平台购买的分发 P12 和 iPhone mobileprovision。
- 用户希望自行签名安装 iOS App，且希望 Apple Watch 原生运行。
- **本源码包不包含 P12、密码、UDID、Provisioning Profile 或任何个人敏感材料。**
- 第三方 iPhone 签名 ≠ 已授权 Watch App；不能绕过 Apple 签名链。

## 卖家必须确认

1. Apple Watch 本身的 UDID 是否已注册在对应团队。
2. `com.卖家实际授权的iPhoneAppID.watchkitapp` 是否已创建并启用相应权限。
3. 能否签发可用于 watchOS App 的描述文件，与 iPhone App 的签名团队及嵌入关系一致。
4. HealthKit entitlement 是否同时获准（iOS、Watch 各自签名）。
5. 证书和描述文件是否过期、是否已被撤销、设备数量是否满足要求。
6. 安装方式能否真正部署 Watch App，而不是侧载工具只安装 iPhone 本体。

## 拿到签名材料后 Muse 的工作

- 扫描 provisioning 内容，提取 app ID、平台、TeamIdentifier、授权 UDID、entitlements、到期时间（**只输出非敏感摘要**）。
- 使用 `security cms -D -i`（macOS）读取 profile，`codesign` 与 `security` 验证 P12 身份匹配；不显示私钥。
- 替换 `project.yml` 中两个示例 Bundle ID，并确保 Watch ID 具有 iOS ID 前缀。
- 先做无签名 simulator 构建，后做有授权设备的签名 archive；检查 `PlugIns/` 中 Watch App 嵌入位置。
- 生成 IPA、SHA256、签名验收日志、安装步骤；在手表真的出现 App 后才标记 Watch 门禁通过。
- 如果平台不给 Watch 独立授权：交付可安装的 iPhone 版本和完整 Watch 源码，明确写“Watch 未安装”，不制造假完成记录。

## 用户可发给证书平台

> 我购买了你们的 iPhone P12/mobileprovision，现在要开发 iPhone＋Apple Watch 的原生配套健康 App。请确认是否能新增我的 Watch UDID，提供 Watch App ID 与 watchOS 对应 mobileprovision，并支持 HealthKit entitlement、Watch App 嵌入签名以及真实手表安装。若不能，请明确告知可支持的分发方式。

## 官方资料

- https://developer.apple.com/documentation/technotes/tn3157-updating-your-watchos-project-for-swiftui-and-widgetkit
- https://developer.apple.com/documentation/watchos-apps/setting-up-a-watchos-project

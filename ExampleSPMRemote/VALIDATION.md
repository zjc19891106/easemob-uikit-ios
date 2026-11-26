# 远程 Swift Package 集成验证

验证日期：2026-10-30。工程：`EaseChatUIKitSPMRemoteExample.xcodeproj`，scheme：`EaseChatUIKitSPMRemoteExample`。

## 依赖来源

Xcode 从 `https://github.com/zjc19891106/easemob-uikit-ios.git` 获取精确版本 `4.26.0`。远程标签、`Package.resolved` 及实际检出 HEAD 均为 `208d80283bd4167c696f2b475cc200da1b61b556`。

本次使用新建的 `SourcePackages` 和 `DerivedData` 目录。SDK 的编译输入来自 `SourcePackages/checkouts/easemob-uikit-ios/Sources`，远程检出保持干净。工程中只有远程 package reference；App、测试及宿主测试资源均位于示例目录内，SDK 源码和 AMR 二进制由 SPM 提供。

| Package | 实际解析版本 |
| --- | --- |
| EaseChatUIKit | 4.26.0 |
| HyphenateChat | 4.26.0 |
| FLAnimatedImage | 1.0.17 |
| ShengwangInfra_iOS | 1.3.16 |

## 已完成验证

环境：Xcode 26.0.1（17A400），iPhone 17 / iOS 26.2 / arm64 模拟器。

| 检查 | 结果 |
| --- | --- |
| 远程依赖解析 | 成功，包含 EaseChatUIKit 4.26.0 |
| Debug 构建及宿主 XCTest | 12 通过、0 失败、0 跳过 |
| 资源测试（9 项） | 330 张 PNG 解码；Unicode、主题、语音帧和 @2x/@3x；中英文；宿主图片及文案覆盖；自定义 bundle 和重置；既有语言回退行为均通过 |
| AMR 测试（3 项） | 8 kHz NB、16 kHz WB 编解码往返及无效输入检查通过 |
| 模拟器安装、启动 | 成功；截图确认头像、表情、语音图、宿主图片、中文文案、GIF 画面及 AMR 编码输出 |
| iOS arm64 Release 无签名归档 | `ARCHIVE SUCCEEDED` |
| Debug App / Release 归档产物检查 | 使用远程标签自带的 `scripts/verify_integration_artifacts.py`，两者均通过 |
| AMR 动态库 | 归档内包含 arm64 `Frameworks/AMRCodec.framework/AMRCodec`；App 链接 `@rpath/AMRCodec.framework/AMRCodec` |

产物检查逐份核对了全部 PNG 内容、两种语言字符串、隐私清单及 AMR 嵌入。Debug App 内有两份由 Xcode 放置的资源 bundle，Release 归档中有一份，内容均通过检查。

## 复现与本次证据

日常构建、测试及归档命令见 [README](README.md)。本次在这些命令中另行指定：

```text
-clonedSourcePackagesDirPath /private/tmp/easechatuikit-spm-remote-4.26.0/SourcePackages
-derivedDataPath /private/tmp/easechatuikit-spm-remote-4.26.0/DerivedData
-disableAutomaticPackageResolution
```

首次解析不加 `-disableAutomaticPackageResolution`。测试使用 `-resultBundlePath` 保存结果，再用 `xcrun xcresulttool get test-results summary --path <结果路径>` 核实通过与跳过数量。

本机证据保存在 `/private/tmp/easechatuikit-spm-remote-4.26.0/`：

- `resolve.log`：实际远程依赖解析记录。
- `hosted-tests.log`、`HostedTests.xcresult`：构建及 12 项测试结果。
- `archive.log`、`EaseChatUIKitSPMRemoteExample.xcarchive`：Release 归档结果。
- `example-launch.png`：模拟器启动截图。

该临时目录不随仓库提交；复现时可选择自己的输出目录。

## 验证范围

本次没有执行签名真机安装、麦克风录音及扬声器播放，也未运行 iOS 15 或 Intel 模拟器。示例不需要登录，因此不涵盖联网登录、发消息等业务流程。本次验证的是上述 fork 的 `4.26.0`；upstream 合入后应针对其发布版本再验证一次。

构建存在 HyphenateChat 头文件的 nullability、umbrella header 警告，以及未使用 AppIntents 的元数据提示；它们未阻止测试和归档。本次未修改发布标签中的 SDK 源码。

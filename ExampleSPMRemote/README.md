# EaseChatUIKit 4.26.0 远程 SPM 示例

这个目录是可单独复制、打开和构建的 iOS 示例。项目通过 Swift Package Manager 从 [easemob-uikit-ios](https://github.com/zjc19891106/easemob-uikit-ios/releases/tag/4.26.0) 获取 **4.26.0 精确版本**，不依赖父目录的 Package.swift、源码、测试或 AMR 二进制文件。

用 Xcode 打开 `EaseChatUIKitSPMRemoteExample.xcodeproj`，等待依赖解析完成，选择 `EaseChatUIKitSPMRemoteExample` scheme 和 iOS 15 及以上模拟器，运行应用或按 `⌘U` 执行测试。首次解析需要网络；启动后资源和编码检查无需登录、App Key 或麦克风权限。真机运行需设置自己的签名团队。

应用展示 SDK 图片、Unicode 表情、语音图片、宿主图片及中英文文案覆盖、GIF 动画，以及 AMR 8 kHz/16 kHz 编码和动态库嵌入状态。目录内的 12 个 hosted XCTest 进一步验证资源完整性、自定义 bundle、语言回退和 AMR 编解码往返。

命令行验证示例（在本目录运行，将 `<UDID>` 替换为本机模拟器 ID）：

```sh
xcodebuild -resolvePackageDependencies \
  -project EaseChatUIKitSPMRemoteExample.xcodeproj \
  -scheme EaseChatUIKitSPMRemoteExample

xcodebuild test \
  -project EaseChatUIKitSPMRemoteExample.xcodeproj \
  -scheme EaseChatUIKitSPMRemoteExample \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO

xcodebuild archive \
  -project EaseChatUIKitSPMRemoteExample.xcodeproj \
  -scheme EaseChatUIKitSPMRemoteExample \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath /tmp/EaseChatUIKitSPMRemoteExample.xcarchive \
  CODE_SIGNING_ALLOWED=NO
```

Xcode 生成的 `project.xcworkspace/xcshareddata/swiftpm/Package.resolved` 用于记录包括传递依赖在内的真实解析结果；更新依赖后应一并提交。应用与测试 target 使用同一个远程 `EaseChatUIKit` product，所有测试素材都包含在本目录中。

实际测试结果及适用范围见 [验证记录](VALIDATION.md)。

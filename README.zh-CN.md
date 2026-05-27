> **语言**：[English](README.md) · **简体中文**

# trace

> 极简的个人跑步与运动记录 iOS App —— 单用户、无社交、iCloud 同步。

`trace` 是一款用于记录户外跑步、室内/跑步机跑步、骑行与步行的 iOS App。
它会记录 GPS 轨迹、配速、心率、分段配速与海拔，通过 iCloud（CloudKit）在
你自己的设备间同步，并把完成的运动写回 Apple "健康" App。

它**有意做成单用户**：不需要账号、没有社交动态、没有排行榜、没有广告、
没有第三方分析 SDK。只有你和你的跑步记录。

## 功能

**运动记录**
- 户外 GPS 轨迹追踪（CoreLocation，支持后台持续记录）
- 室内 / 跑步机：CoreMotion 计步估算距离，详情页可手动校正
- 实时数据：时长、距离、当前配速（骑行显示速度）、心率
- 暂停 / 继续 / 结束（结束需二次确认，防误触）
- 中文语音播报：开始 / 每公里 / 结束

**历史回看**
- 地图轨迹回放（MapKit）、每公里配速柱状图与海拔曲线（Swift Charts）
- 分段配速表、备注编辑、记录删除

**数据统计**
- 周 / 月 / 年汇总：总距离、时长、次数、平均配速
- 趋势图与个人最佳（最快 1 km / 5 K / 10 K、单次最长距离与时长）
- 成就系统：累计里程、连续打卡（streak）

**目标管理**
- 周 / 月 距离或次数目标，配进度环

**系统集成**
- Apple 健康：读取心率与体重，写入运动、轨迹、能量
- iCloud（CloudKit）多设备同步

完整功能规划见 [`docs/ROADMAP.md`](docs/ROADMAP.md)。

## 技术栈

- **Swift 5**（在可行处采用 Swift 6 并发），**SwiftUI**
- **SwiftData** + **CloudKit** 同步（私有数据库）
- **iOS 18.0+**，使用 Xcode 26.1 的 iOS 26 SDK 构建
- CoreLocation · MapKit · HealthKit · CoreMotion · Swift Charts · AVFoundation

## 项目结构

```
trace/                         # 仓库根目录
├── docs/ROADMAP.md            # 功能规划
└── trace/                     # Xcode 项目
    ├── Config/                # xcconfig（Team ID 放这，不写在 pbxproj 里）
    ├── trace.xcodeproj
    └── trace/                 # App 源码
        ├── App/               # 入口、RootView、OnboardingView
        ├── Shared/            # Models / Services / Components / Common
        └── Features/          # Record / History / Stats / Goals / Profile（每个 feature MVC 分层）
```

源码按**业务优先**组织，每个 feature 内部按 MVC 拆分。Xcode 工程使用
**file-system synchronized groups** —— 文件在磁盘上放好即可，无需手动
编辑 `project.pbxproj`。

## 构建与运行

### 1. 首次配置 —— 你的 Apple Developer Team ID

仓库不携带任何 Team ID。本地建立你自己的覆盖文件：

```bash
cp trace/Config/Local.xcconfig.example trace/Config/Local.xcconfig
# 然后编辑 trace/Config/Local.xcconfig，把 DEVELOPMENT_TEAM 填成你自己的 Team ID
```

`Local.xcconfig` 已被 gitignore，不会被提交。Team ID 可以在
<https://developer.apple.com/account> → Membership 查看，
或者 Xcode → Settings → Accounts → 你的 Apple ID → Team。

### 2. Bundle ID 与 CloudKit 容器

如果你 fork 后想跑在真机上，还需要修改：

- `trace/trace.xcodeproj/project.pbxproj` 里的 `PRODUCT_BUNDLE_IDENTIFIER`（当前是 `net.kolbe.app.trace`）
- `trace/trace/trace.entitlements` 里的 iCloud container（当前是 `iCloud.net.kolbe.app.trace`）

把两者改成你自己拥有的标识符。

### 3. 构建

日常开发：直接用 Xcode 打开 `trace/trace.xcodeproj`，按 ⌘R 即可。

命令行（注意：`xcode-select` 通常指向 Command Line Tools，需要把
`DEVELOPER_DIR` 指向真正的 Xcode）：

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodebuild -project trace/trace.xcodeproj -scheme trace \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

模拟器可以跑通大部分流程，但**心率与基于计步的室内距离需要真机**
（心率最好搭配 Apple Watch）。

## 架构说明

- **每个 feature 内部 MVC 分层**：`Features/<Name>/` 下分
  `Model/`（feature 局部的展示类型）、`View/`（薄的 SwiftUI 视图）、
  `Controller/`（`@Observable` 类，承担 SwiftUI 中 ViewModel 的角色，
  持有屏幕状态与逻辑）。
- 持久化的 SwiftData 实体（`Workout`、`RouteSample`、`Split`、`Goal`、
  `UserProfile`）放在 `Shared/Models/`，跨 feature 共享。
- `WorkoutRecorder` 持有进行中的会话，可在后台存活；只在结束时一次性
  写入 SwiftData（运动期间样本缓存在内存里）。
- 所有距离以米存储、时长以秒存储；公里 / 英里 的换算只在显示层做，
  按用户偏好读取。

### SwiftData schema 在 CloudKit 下的约束

下面任一条违反，运行时同步会直接失败：

- 所有存储属性必须可选 **或** 有默认值
- 不能用 `@Attribute(.unique)` —— CloudKit 不支持唯一约束
- 关系必须可选，并且永远要设置 inverse

## 许可证

[MIT](LICENSE) —— 随便用。

## 致谢

灵感来自 [Keep](https://www.gotokeep.com/) 极简的记录体验，去掉了所有社交元素。

> **语言**：**简体中文** · [English](README.en.md)

<div align="center">

# 🏃 trace

**一款只属于你自己的跑步记录 App**

无需账号 · 无社交 · 无广告 · 数据永远是你的

</div>

---

## 为什么会有 trace

我是一个普通的跑步爱好者。这些年换过好几款运动 App，每次换都像搬一次家——
**而且是那种「旧房子钥匙直接被收走」的搬家**：

- 🗂️ **数据带不走。** 跑了几百公里、攒了一年多的轨迹和配速，想导出来留个底，
  发现根本没有导出入口。换一个 App，过去的一切归零，像从没跑过一样。
- 📣 **社交味太重。** 打开 App 想看自己今天的配速，先要刷过一堆动态、点赞、
  挑战赛、好友排行榜。我只想安静地跑步，不想经营一个「运动朋友圈」。
- 📺 **广告太多。** 开屏广告、信息流广告、跳来跳去的会员引导，
  把一个「记录工具」做成了「内容平台」。
- 📡 **离不开网。** 到了山里、地下、信号差的地方，本该最需要记录的时候，
  App 却转着圈加载，甚至直接记不上。

这些问题单拎出来都不致命，凑在一起，却让「记录运动」这件最朴素的事变得很累。
我想要的其实很简单：**一个安静、可靠、数据属于自己的记录本。**

于是有了 trace。

## trace 想解决什么

trace 的设计原则只有一句话——**记录工具就该回归记录本身**：

| 痛点 | trace 的答案 |
| --- | --- |
| 数据被锁死、换 App 就丢 | 数据存在**你自己的 iCloud 私有库**里；同时完整写回 Apple「健康」App，从源头上不绑架你的数据 |
| 社交干扰 | **默认单用户、无需注册**：没有动态、好友、排行榜、挑战赛；开箱即用 |
| 广告满天飞 | **零广告、零第三方分析 SDK**，不收集、不上报任何数据 |
| 离线就罢工 | GPS / 气压计 / 计步全部**本地运行**，没网照样记录，回家自动同步 |

> trace 是个人自用项目，开源出来给同样有这些困扰的朋友。
> 它不追求大而全，只追求**把记录这件事做扎实**。

**关于换设备和账号：** 换新 iPhone 时，用同一 Apple ID 登录即可自动同步全部记录，
**无需任何导入导出**——这正是用 iCloud 私有库（而非纯本地存储）的原因。真正给「数据
属于你」上保险的是**数据导出（GPX / CSV）**，跨平台、永久、零依赖。
trace 当前不需要、也不强制任何账号；但**未来若有跨平台或账号绑定的真实需求，会保留
一个「可选」的登录入口（优先 Sign in with Apple）**，作为锦上添花，而非前置门槛。

## ✨ 功能一览

**🏃 运动记录**
- 四种运动类型：户外跑 / 室内跑（跑步机）/ 骑行 / 步行
- 户外实时 GPS 轨迹追踪，支持**后台与锁屏持续记录**
- 室内跑用 CoreMotion 计步估算距离，详情页可手动校正
- 实时数据面板：时长、距离、当前配速（骑行显示速度）、心率，结束时算卡路里
- 暂停 / 继续 / 结束，结束需二次确认防误触
- 爬升估算：优先**气压计**（比 GPS 海拔精确得多），死区滤波消除噪声虚高
- **中文语音播报**：开始 / 每公里（配速 + 心率）/ 结束；锁屏后台也能出声，
  音色经过优化，播报时压低音乐、播完立即恢复

**📖 历史回看**
- 地图轨迹回放（MapKit）+ 汇总 + 分段配速表
- 每公里配速柱状图 + 海拔曲线（Swift Charts）
- 记录删除、备注编辑

**📊 数据统计**
- 周 / 月 / 年汇总：总距离、时长、次数、平均配速
- 趋势图 + 个人最佳 PR：最快单公里 / 5K / 10K、单次最长距离与时长
- 成就系统：累计里程、连续打卡（streak）

**🎯 目标管理**
- 周 / 月 距离或次数目标，配进度环

**📤 数据导出**
- 详情页单条导出：GPX 轨迹（含海拔 + 心率）/ 逐点明细 CSV
- 「我的 → 数据导出」批量导出：全部运动的汇总 CSV + 全部 GPX
- GPX 用标准 WGS-84 坐标，可导入 Strava / Garmin 等；CSV 用 SI 原始单位 +
  ISO8601 时间，便于归档与再导入——**数据永远带得走**

**🔗 系统集成**
- Apple 健康：读心率与体重，写运动 / 轨迹路线 / 能量 / 距离
- iCloud（CloudKit）私有库多设备同步

**🇨🇳 中国大陆地图适配**
- 自动做 WGS-84 → GCJ-02 坐标转换：大陆底图用的是 GCJ-02 火星坐标，
  原始 GPS 是 WGS-84，不转换轨迹会整体偏移数百米。trace 存储层保留原始
  WGS-84，只在喂给地图时转换，境外自动跳过——轨迹始终贴合道路。

## 🗺️ 功能规划

### ✅ 已完成（v1.0.0）

- 四种运动类型的完整记录闭环（GPS / 计步 / 气压计爬升）
- 历史列表、详情、地图、图表、分段配速
- 周 / 月 / 年统计、个人最佳、成就打卡
- 周 / 月 目标与进度环
- 中文语音播报（音色优化 + 智能音乐压低恢复）
- HealthKit 读写、iCloud 多端同步
- 中国大陆地图坐标本地化
- **数据导出（GPX / CSV）** —— 单条导出轨迹，或在「我的」批量导出全部；
  GPX 标准 WGS-84，可导入其它运动 App。毕竟「数据带得走」是 trace 的初心

### 🚧 计划中

- 真机 / Apple Watch 实时心率链路验证（模拟器无心率源）
- 天气记录（WeatherKit）
- Live Activity / 灵动岛锁屏实时数据
- 主屏 Widget：本周距离 / 最近一次运动
- Apple Watch 独立记录 App
- 训练计划：间歇跑 / 长距离计划与提醒
- 运动中拍照贴到轨迹时间点

完整分期规划见 [`docs/ROADMAP.md`](docs/ROADMAP.md)，需求清单见 [`docs/REQUIREMENTS.md`](docs/REQUIREMENTS.md)。

## 🏛️ 技术架构

| 层面 | 选型 |
| --- | --- |
| 语言 | Swift 5（可行处采用 Swift 6 并发） |
| UI | SwiftUI |
| 持久化 | SwiftData + CloudKit 同步（私有数据库） |
| 最低系统 | iOS 18.0+，使用 Xcode 26.1 的 iOS 26 SDK 构建 |
| 关键框架 | CoreLocation · MapKit · HealthKit · CoreMotion（计步 / 气压计）· Swift Charts · AVFoundation（语音）· ActivityKit · WidgetKit |

**几条贯穿全局的工程约定：**

- 视图保持「薄」，记录 / 追踪逻辑下沉到 `Services/` 的 `@Observable` 类型。
- `WorkoutRecorder` 独占进行中的会话，可在后台存活，**只在结束时一次性**
  写入 SwiftData（运动期间样本缓存在内存里）。
- 距离统一以**米**存储、时长以**秒**存储，公里 / 英里换算只在显示层做，
  按用户偏好读取，绝不硬编码单位。
- SwiftData schema 受 CloudKit 约束：所有存储属性可选或带默认值、
  不能用 `@Attribute(.unique)`、关系必须可选且设 inverse——违反任一条
  运行时同步会直接失败。

## 🧭 业务架构

源码按**业务优先**组织，每个业务内部再按 MVC 分层：

```
trace/                         # 仓库根目录
├── docs/                      # ROADMAP / REQUIREMENTS
└── trace/                     # Xcode 项目
    ├── Config/                # xcconfig（Team ID 放这，不写进 pbxproj）
    ├── trace.xcodeproj
    └── trace/                 # App 源码
        ├── App/               # 入口、RootView（5 个 Tab）、OnboardingView
        ├── Shared/            # 跨业务层
        │   ├── Models/        # SwiftData @Model：Workout / RouteSample / Split / Goal / UserProfile
        │   ├── Services/      # LocationManager / HealthKitManager / PedometerManager
        │   │                  #   AltimeterManager / AudioCoach / WorkoutRecorder
        │   ├── Components/    # 可复用 SwiftUI 视图（RouteMapView）
        │   └── Common/        # 单位偏好、地图样式、格式化、卡路里计算
        └── Features/          # 每个业务一个包，内部 MVC 分层
            ├── Record/   {Model, View, Controller}
            ├── History/  {Model, View, Controller}
            ├── Stats/    {Model, View, Controller}
            ├── Goals/    {Model, View, Controller}
            └── Profile/  {Model, View, Controller}
```

- **Controller** = 持有屏幕逻辑与状态的 `@Observable` 类（即 SwiftUI 里
  ViewModel 的角色），View 用 `@State private var controller = ...` 持有它。
- **View** = 薄的 SwiftUI 视图，逻辑尽量下沉到 Controller。
- **Model**（feature 级）= 该业务专属的展示类型（`RecordMetrics`、
  `StatsSummary`、`GoalProgress`…）；**持久化实体**统一放 `Shared/Models`，
  跨业务共享，不在各 feature 里重复定义。

Xcode 工程使用 **file-system synchronized groups**——文件在磁盘上放好即可
自动纳入 target，无需手动编辑 `project.pbxproj`。

## 🚀 构建与运行

### 1. 首次配置：你的 Apple Developer Team ID

仓库不携带任何 Team ID，本地建立你自己的覆盖文件：

```bash
cp trace/Config/Local.xcconfig.example trace/Config/Local.xcconfig
# 然后编辑 trace/Config/Local.xcconfig，把 DEVELOPMENT_TEAM 填成你自己的 Team ID
```

`Local.xcconfig` 已被 gitignore，不会被提交。Team ID 可在
<https://developer.apple.com/account> → Membership 查看，
或 Xcode → Settings → Accounts → 你的 Apple ID → Team。

### 2. Bundle ID 与 CloudKit 容器（fork 后跑真机才需要）

- 改 `trace/trace.xcodeproj/project.pbxproj` 里的 `PRODUCT_BUNDLE_IDENTIFIER`
  （当前 `net.kolbe.app.trace`）
- 改 `trace/trace/trace.entitlements` 里的 iCloud container
  （当前 `iCloud.net.kolbe.app.trace`）

两者都改成你自己拥有的标识符。

### 3. 构建

日常开发直接用 Xcode 打开 `trace/trace.xcodeproj`，按 ⌘R。

命令行（`xcode-select` 通常指向 Command Line Tools，需把 `DEVELOPER_DIR`
指向真正的 Xcode）：

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodebuild -project trace/trace.xcodeproj -scheme trace \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

模拟器可跑通大部分流程，但**心率与基于计步的室内距离需要真机**
（心率最好搭配 Apple Watch）。

## 📄 许可证

[MIT](LICENSE) —— 随便用。

## 🌟 欢迎参与

trace 虽是个人自用项目，但如果它也戳中了你——

- ⭐ 点个 **Star**，是对作者最直接的鼓励
- 🍴 欢迎 **Fork** 改成你自己的样子
- 🐛 有 bug、有想法，欢迎提 **Issue / PR**
- 💬 哪怕只是分享一句「我也被这些问题烦过」，也很开心

愿你跑得开心，数据始终在自己手里。🏃💨

# trace — 功能规划 / Feature Roadmap

定位：**个人**跑步/运动记录 App（类 Keep，但去掉社交、社区、强制账号体系）。
支持运动类型：户外跑步、室内跑步/跑步机、骑行、步行。
数据通过 iCloud 在自己的设备间同步，深度集成 Apple 健康 (HealthKit)。

---

## Phase 1 — MVP（先把"记录 + 回看"跑通）

### 1. 运动记录 Record
- [x] 选择运动类型（户外跑 / 室内跑 / 骑行 / 步行）
- [x] 户外：实时 GPS 轨迹追踪（CoreLocation），后台持续记录
- [x] 室内跑：CoreMotion 计步估算距离（PedometerManager，需真机）；详情页可手动校正距离
- [x] 实时数据面板：时长、距离、当前配速（骑行显示速度）、心率；卡路里在结束时算
- [x] 暂停 / 继续 / 结束，结束后保存为一条 Workout（含 samples / splits / 卡路里）
- [x] 防误触：结束需二次确认（先暂停，再点结束弹确认框）
- [x] 爬升估算：优先气压计（CMAltimeter / AltimeterManager），GPS 高度兜底
- [x] GPS 高度滑动窗口平滑 + 滞后过滤（ElevationCalculator），修正高估的爬升

### 2. 历史记录 History
- [x] 运动列表（按时间倒序，显示类型/距离/日期）
- [x] 详情页：地图轨迹（MapKit）+ 汇总 + 分段配速 (splits)
- [x] 详情页补充：每公里配速柱状图 + 海拔曲线（Swift Charts）
- [x] 详情页打开时用新平滑算法回算历史爬升数据
- [x] 删除记录
- [x] 编辑备注

### 3. 数据统计 Stats
- [x] 周 / 月 / 年汇总：按周期过滤时间范围（总距离/时长/次数/平均配速）
- [x] 趋势图表：Swift Charts 距离柱状图（周→按天，月→按天，年→按月）
- [x] 个人最佳 PR：最快单公里 / 5K / 10K 配速、单次最长距离、最长时长（全期跑步）

### 4. 我的 Profile
- [x] 个人信息：身高、体重、性别、生日（用于卡路里计算）
- [x] 设置：单位（公里/英里）—— 全 App 距离/配速显示已读此偏好
- [x] 设置：地图样式（标准/混合/卫星）—— 记录页与详情页地图已读此偏好
- [x] 设置：语音播报开关（@AppStorage，配合 AudioCoach）

### 5. 健康集成 HealthKit
- [x] 授权（读心率/体重，写运动/能量/距离/心率/路线）
- [x] 读取心率：anchored query 订阅，运动中展示并写入 RouteSample（需手表等心率源）
- [x] 读取体重：「我的」页可从健康同步体重，改善卡路里估算
- [x] 结束后将 Workout 写入"健康"App（HKWorkoutBuilder + 轨迹路线 HKWorkoutRoute）
- [ ] 待真机/手表验证实时心率链路（模拟器无心率源）

### 6. 数据层 Data
- [x] SwiftData 模型 + CloudKit 同步（见 CLAUDE.md 的约束）
- [x] iCloud 容器配置
- [x] 定位权限文案 + 后台定位模式（Info.plist）
- [x] 首次启动权限引导页（OnboardingView，说明用途并请求定位/健康授权）

---

## Phase 2 — 体验增强

- [x] 语音播报 AudioCoach：开始 / 每公里（配速+心率）/ 结束中文播报；「我的」可开关（@AppStorage）；
  锁屏/后台可发声，优选 premium/enhanced 女声音色，播报时压低其它音频、播完即恢复（per-utterance ducking）
- [x] 目标 Goals：周/月 距离或次数目标 + 进度环（Gauge）+ 新建/删除
- [x] 成就 / 里程碑：累计里程、连续打卡（streak）—— 统计页「成就」区
- [ ] 天气记录：保存运动时的天气（WeatherKit）—— 需开 WeatherKit 能力（同 HealthKit 那样注册到 App ID）
- [x] Live Activity / 灵动岛：锁屏实时显示运动数据 —— 已建 `TraceWidgets` 扩展 target，
  `TraceLiveActivity` 提供锁屏卡片 + 灵动岛 expanded/compact/minimal 三态；时长用
  `effectiveStartDate` 在锁屏侧自走秒，距离/配速/心率由 `WorkoutRecorder` 每 2s 节流推送，
  暂停冻结、结束即移除。共享类型 `TraceActivityAttributes` 在 app/扩展两个 target 同时编译。
- [ ] 主屏 Widget：本周距离 / 最近一次运动 —— **需在 Xcode 新建 Widget Extension target**

## 横切：地图本地化 Map Localization

- [x] 中国大陆地图坐标系适配（WGS-84 → GCJ-02）：MapKit 在大陆使用 GCJ-02 火星坐标，
  原始 GPS 是 WGS-84，画轨迹/标记不转换会整体偏移数百米。存储层保留 WGS-84，
  仅在喂给 MapKit 时转换；境外自动跳过。详见 `RouteMapView.swift` 的 `ChinaCoordinate`。

---

## Phase 3 — 进阶（按需）

- [ ] Apple Watch App：手表端独立记录 + 心率
- [ ] 训练计划：简单的间歇跑 / 长距离计划与提醒
- [ ] 运动中拍照并贴到轨迹时间点
- [x] 数据导出（GPX / CSV）：详情页单条导出 GPX 轨迹 + 明细 CSV；「我的 → 数据导出」
  批量导出汇总 CSV + 全部 GPX。GPX 用标准 WGS-84 坐标（含海拔与心率扩展），可导入
  Strava / Garmin 等；CSV 用 SI 原始单位 + ISO8601 时间，便于归档与再导入。
- [ ] 可选账号登录（按需）：默认仍是 iCloud 私有库同步、零账号；仅当出现跨平台
  （iOS↔Android）或换 Apple ID 等真实需求时，再加一个**可选**登录入口（优先
  Sign in with Apple），作为锦上添花而非前置门槛。届时需自建后端 + 鉴权 +
  数据存储；微信登录因会重新引入社交生态 / 第三方 SDK，与定位冲突，暂不考虑。

---

## 暂不做（保持简单）
社交动态/好友/排行榜、广告、第三方分析 SDK、付费墙。
个人自用，遇到需要再加。

> 注：**强制**账号体系不做；**可选**账号登录见 Phase 3，按需引入。

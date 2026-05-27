import SwiftUI
import MapKit

/// 复用的轨迹地图：传入坐标点画 polyline。
/// - `live = true`：跟随用户当前位置（记录页用）。
/// - `live = false`：按整条轨迹自动取景（详情页用）。
struct RouteMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    var live: Bool = false
    var style: MapStylePreference = .standard

    @State private var camera: MapCameraPosition = .automatic

    /// 存储为 WGS-84；中国大陆地图底图是 GCJ-02，画线/标记前需加偏对齐。
    /// 蓝点（UserAnnotation）由 MapKit 自动纠偏，这里不处理。
    private var displayCoordinates: [CLLocationCoordinate2D] {
        coordinates.map { ChinaCoordinate.gcj02(from: $0) }
    }

    var body: some View {
        let coords = displayCoordinates
        Map(position: $camera) {
            if live { UserAnnotation() }

            if coords.count > 1 {
                MapPolyline(coordinates: coords)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
            if let start = coords.first {
                Marker("起点", systemImage: "flag.fill", coordinate: start).tint(.green)
            }
            if !live, coords.count > 1, let end = coords.last {
                Marker("终点", systemImage: "flag.checkered", coordinate: end).tint(.red)
            }
        }
        .mapStyle(resolvedStyle)
        .onAppear(perform: setupCamera)
        .onChange(of: coordinates.count) { _, _ in
            if live { camera = .userLocation(fallback: .automatic) }
        }
    }

    private var resolvedStyle: MapStyle {
        switch style {
        case .standard:  .standard
        case .hybrid:    .hybrid
        case .satellite: .imagery
        }
    }

    private func setupCamera() {
        if live {
            camera = .userLocation(fallback: .automatic)
        } else if let region = Self.region(for: displayCoordinates) {
            camera = .region(region)
        }
    }

    /// 由坐标点算出带边距的取景区域
    static func region(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard let first = coordinates.first else { return nil }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for c in coordinates {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.005),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.005)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

/// 中国大陆坐标加偏（GCJ-02）转换 —— 仅用于显示层。
///
/// 设备 GPS（CoreLocation）返回真实 WGS-84 坐标，而中国大陆地图底图（Apple Maps / MapKit）
/// 采用国家强制的 GCJ-02「火星坐标」加偏体系。MapKit 对自身蓝点 `UserAnnotation` 会内部纠偏，
/// 但 App 自己绘制的 polyline / Marker 用原始 WGS-84 画在 GCJ-02 底图上会整体偏移数百米。
///
/// 约定：存储层始终保留原始 WGS-84（见 `RouteSample`），只在喂给 MapKit 时转成 GCJ-02。
/// 境外坐标（含港澳台与海外）不加偏，原样返回。
enum ChinaCoordinate {
    private static let a = 6_378_245.0                     // 克拉索夫斯基椭球长半轴
    private static let ee = 0.006_693_421_622_965_943      // 第一偏心率平方

    /// WGS-84 → GCJ-02。仅中国大陆境内加偏，境外原样返回。
    static func gcj02(from wgs: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard !isOutOfChina(wgs) else { return wgs }

        let x = wgs.longitude - 105.0
        let y = wgs.latitude - 35.0
        var dLat = transformLat(x: x, y: y)
        var dLon = transformLon(x: x, y: y)

        let radLat = wgs.latitude / 180.0 * .pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * .pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * .pi)

        return CLLocationCoordinate2D(
            latitude: wgs.latitude + dLat,
            longitude: wgs.longitude + dLon
        )
    }

    /// 标准「是否在中国境外」判断：境外（含港澳台、海外）不加偏。
    private static func isOutOfChina(_ c: CLLocationCoordinate2D) -> Bool {
        if c.longitude < 72.004 || c.longitude > 137.8347 { return true }
        if c.latitude < 0.8293 || c.latitude > 55.8271 { return true }
        return false
    }

    private static func transformLat(x: Double, y: Double) -> Double {
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * .pi) + 40.0 * sin(y / 3.0 * .pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * .pi) + 320.0 * sin(y * .pi / 30.0)) * 2.0 / 3.0
        return ret
    }

    private static func transformLon(x: Double, y: Double) -> Double {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * .pi) + 40.0 * sin(x / 3.0 * .pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * .pi) + 300.0 * sin(x / 30.0 * .pi)) * 2.0 / 3.0
        return ret
    }
}

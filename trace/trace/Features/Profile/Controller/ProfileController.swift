import Foundation
import SwiftData
import Observation

/// 我的页控制器：取/建唯一的用户档案。
@Observable
final class ProfileController {
    /// 返回唯一档案，没有则新建一条插入。
    func currentProfile(in context: ModelContext) -> UserProfile {
        if let existing = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            return existing
        }
        let profile = UserProfile()
        context.insert(profile)
        return profile
    }
}

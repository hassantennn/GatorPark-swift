import Foundation

/// Manages the "refer a friend" promotion.
/// Tracks referral counts and exposes helper methods to
/// determine the contest winner for the first month after launch.
class ReferralManager {
    private let launchDate: Date
    private let contestDuration: TimeInterval
    private let defaults: UserDefaults
    private let referralsKey = "referrals"

    /// Description of the reward for the top referrer.
    let rewardDescription = "One month of gas paid for"

    init(launchDate: Date = Date(),
         contestDuration: TimeInterval = 30 * 24 * 60 * 60,
         defaults: UserDefaults = .standard) {
        self.launchDate = launchDate
        self.contestDuration = contestDuration
        self.defaults = defaults
    }

    /// Records a successful referral made by a user.
    func addReferral(from userID: String) {
        var counts = defaults.dictionary(forKey: referralsKey) as? [String: Int] ?? [:]
        counts[userID, default: 0] += 1
        defaults.set(counts, forKey: referralsKey)
    }

    /// Indicates whether the referral contest is still active.
    var isContestActive: Bool {
        Date().timeIntervalSince(launchDate) < contestDuration
    }

    /// Returns the current top referrer and their count, if any.
    func topReferrer() -> (userID: String, count: Int)? {
        let counts = defaults.dictionary(forKey: referralsKey) as? [String: Int] ?? [:]
        return counts.max { $0.value < $1.value }
    }

    /// Removes all stored referral data. Useful for testing.
    func reset() {
        defaults.removeObject(forKey: referralsKey)
    }
}


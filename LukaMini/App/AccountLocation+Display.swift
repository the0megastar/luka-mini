//
//  AccountLocation+Display.swift
//  LukaMini
//

import Dexcom
import Foundation

extension AccountLocation: @retroactive Identifiable, @retroactive CaseIterable {
    public static var allCases: [AccountLocation] { [.usa, .worldwide, .apac] }
    public var id: Self { self }

    var displayName: String {
        switch self {
        case .usa: "United States"
        case .apac: "Japan"
        case .worldwide: "Anywhere Else"
        }
    }
}

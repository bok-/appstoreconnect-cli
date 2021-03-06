// Copyright 2020 Itty Bitty Apps Pty Ltd

import ArgumentParser
import AppStoreConnect_Swift_SDK
import Foundation

extension Profiles.Sort: Codable, ExpressibleByArgument, CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

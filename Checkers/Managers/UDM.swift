//
//  UDM.swift
//  Checkers
//
//  Created by Gabriel Casanova on 12/22/23.
//

import Foundation

class UDM {
    // "UserDefaultsManager"
    static let shared = UDM()
    let defaults = UserDefaults(suiteName: "com.gabriel")!
}

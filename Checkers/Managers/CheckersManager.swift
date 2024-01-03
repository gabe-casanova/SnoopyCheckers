//
//  CheckersManager.swift
//  Checkers
//
//  Created by Gabriel Casanova on 12/20/23.
//

import Foundation

class CheckersManager {
    
    static let shared = CheckersManager()
    var checkersEngine: CheckersEngine
    
    private init() {
        checkersEngine = CheckersEngine()
    }
}

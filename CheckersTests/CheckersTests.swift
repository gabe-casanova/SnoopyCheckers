//
//  CheckersTests.swift
//  CheckersTests
//
//  Created by Gabriel Casanova on 12/9/23.
//

import XCTest
@testable import Checkers

final class CheckersTests: XCTestCase {

    func testPrintingEmptyGameBoard() {
        var game = GameEngine()
        game.initializeGame()
        print(game)
    }
    
    func testPieceNotAllowedToGoOutOfBoard() {
        var game = GameEngine()
        game.initializeGame()
        XCTAssertFalse(game.canMovePiece(fromCol: 0, fromRow: 7, toCol: -1, toRow: 8))
    }
    
    
}

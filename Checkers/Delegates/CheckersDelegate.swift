//
//  CheckersDelegate.swift
//  Checkers
//
//  Created by Gabriel Casanova on 12/5/23.
//

import Foundation

protocol CheckersDelegate {
    func movePiece(fromCol: Int, fromRow: Int, toCol: Int, toRow: Int)
    func pieceAt(col: Int, row: Int) -> CheckerPiece?
}

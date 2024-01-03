//
//  GameEngine.swift
//  Checkers
//
//  Created by Gabriel Casanova on 12/4/23.
//

import Foundation
import UIKit

struct CheckersEngine {
    
    var pieces = Set<CheckerPiece>()
    var player1Turn: Bool = true
    
    // double jump variables
    var doubleJumper: CheckerPiece? = nil
    var lastCapturedPiece: CheckerPiece? = nil
    var skipDoubleJump: Bool? = nil
    
    mutating func movePiece(fromCol: Int, fromRow: Int, toCol: Int, toRow: Int) -> Bool {
        if let doubleJumper = doubleJumper {
            if doubleJumper.col != fromCol || doubleJumper.row != fromRow {
                // an incorrect piece was attempted to be moved
                return false
            } else if fromCol == toCol && fromRow == toRow {
                skipDoubleJump = true
                return true
            }
        }
        
        if !validMove(fromCol: fromCol, fromRow: fromRow, toCol: toCol, toRow: toRow) {
            return false
        }
        
        let oldPiece = pieceAt(col: fromCol, row: fromRow)!
        
        var type: CheckerType = .king
        if oldPiece.type != .king {
            switch oldPiece.player {
            case .player1:
                if toRow != 0 { type = .regular }
            case .player2:
                if toRow != 7 { type = .regular }
            }
        }
        
        var source: ImageSource
        if UDM.shared.defaults.bool(forKey: Consts.snoopyImagesOnOffKey) {
            if type == .king {
                source = (oldPiece.player == .player1) ? .image(UIImage(named: Consts.snoopyKing)!) : .image(UIImage(named: Consts.woodstockKing)!)
            } else {
                source = oldPiece.source
            }
        } else {
            source = (type == .king) ? .systemName(Consts.king) : oldPiece.source
        }
        
        pieces.remove(oldPiece)
        
        let newPiece = CheckerPiece(col: toCol, row: toRow, color: oldPiece.color, type: type, source: source, player: oldPiece.player)
        pieces.insert(newPiece)
        
        return true
    }
    
    /* Game Rules:
        1. piece found at (fromCol, fromRow)
        2. correct player's piece selected
        3. destination is in-bounds of board
        4. original location != destination
        5. destination is unoccupied at (toCol, toRow)
        6. piece movement is diagonal
        7. piece moving in correct direction
        8. piece movement spans a maximum of 2 spots
             a) if 2, piece must be jumping over opponent piece
    */
    mutating func validMove(fromCol: Int, fromRow: Int, toCol: Int, toRow: Int) -> Bool {
        
        guard let candidate = pieceAt(col: fromCol, row: fromRow),
              (candidate.player == .player1) == player1Turn,
              (0...7).contains(toCol),
              (0...7).contains(toRow),
              fromCol != toCol || fromRow != toRow,
              pieceAt(col: toCol, row: toRow) == nil,
              abs(toCol - fromCol) == abs(toRow - fromRow)
        else {
            return false
        }

        if candidate.type == .regular {
            let movingDown: Bool = toRow > fromRow
            if (candidate.player == .player1) == movingDown {
                return false
            }
        }
        
        let delta: Int = abs(toCol - fromCol)
        if delta > 2 {
            return false
        } else if delta == 2 {
            // only allowed if jumping over opponent's piece
            let jumpedCol = (fromCol + toCol) / 2
            let jumpedRow = (fromRow + toRow) / 2
            guard let jumpedPiece = pieceAt(col: jumpedCol, row: jumpedRow),
                  (jumpedPiece.player == .player1) != (candidate.player == .player1)
            else {
                return false
            }
            pieces.remove(jumpedPiece)
            lastCapturedPiece = jumpedPiece
        } else {
            lastCapturedPiece = nil
        }
    
        return true
    }
    
    func gameOver() -> Bool {
        let player1PiecesExist = pieces.contains { $0.player == .player1 }
        let player2PiecesExist = pieces.contains { $0.player == .player2 }
        return !player1PiecesExist || !player2PiecesExist
    }
    
    func pieceAt(col: Int, row: Int) -> CheckerPiece? {
        for piece in pieces {
            if col == piece.col && row == piece.row { return piece }
        }
        return nil
    }
    
    mutating func canDoubleJump(using piece: CheckerPiece) -> Bool {
       
        // ensure that the player's last move was an opponent capture
        guard let lastCapturedPiece = lastCapturedPiece,
              lastCapturedPiece.player != piece.player,
              abs(lastCapturedPiece.col - piece.col) == 1,
              abs(lastCapturedPiece.row - piece.row) == 1
        else {
            return false
        }
                
        let possibleMoves: [(Int, Int)] = getPossibleMoves(for: piece)
        
        for (dx, dy) in possibleMoves {
            
            let jumpOverCol = piece.col + dx
            let jumpOverRow = piece.row + dy
            
            if withinBounds(col: jumpOverCol, row: jumpOverRow),
               let opponentPiece = pieceAt(col: jumpOverCol, row: jumpOverRow),
               opponentPiece.player != piece.player {
                
                let toCol = piece.col + (2 * dx)
                let toRow = piece.row + (2 * dy)
                
                if withinBounds(col: toCol, row: toRow),
                   pieceAt(col: toCol, row: toRow) == nil {
                    
                    doubleJumper = piece
                    return true
                }
            }
        }
        
        doubleJumper = nil
        return false
    }
    
    private func getPossibleMoves(for piece: CheckerPiece) -> [(Int, Int)] {
        
        var possibleMoves: [(Int, Int)] = []
        
        switch piece.type {
        case .king:
            possibleMoves = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
        case .regular:
            switch piece.player {
            case .player1:
                possibleMoves = [(-1, -1), (1, -1)]  // "up the board"
            case .player2:
                possibleMoves = [(-1, 1), (1, 1)]    // "down the board"
            }
        }
        
        return possibleMoves
    }
        
    private func withinBounds(col: Int, row: Int) -> Bool {
        return (col >= 0 && col < 8) && (row >= 0 && row < 8)
    }
    
    mutating func resetDoubleJumpVariables() {
        doubleJumper = nil
        skipDoubleJump = nil
        lastCapturedPiece = nil
    }
    
    mutating func initializeGame() {
        
        let positionsPlayer1 = [
            (0,7), (2,7), (4,7), (6,7),  // row 1 (starting from bottom row - home base)
            (1,6), (3,6), (5,6), (7,6),
            (0,5), (2,5), (4,5), (6,5)
        ]
        
        let positionsPlayer2 = [
            (1,0), (3,0), (5,0), (7,0),  // row 1 (starting from top row - home base)
            (0,1), (2,1), (4,1), (6,1),
            (1,2), (3,2), (5,2), (7,2)
        ]
        
        resetDoubleJumpVariables()
            
        player1Turn = true
        pieces.removeAll()
        
        let systemName1 = UDM.shared.defaults.string(forKey: Consts.selectedRedButtonNameKey)!
        let systemName2 = UDM.shared.defaults.string(forKey: Consts.selectedBlueButtonNameKey)!
        
        for i in 0...23 {
            //
            let idx = i % 12
            let col = (i < 12) ? positionsPlayer1[idx].0 : positionsPlayer2[idx].0
            let row = (i < 12) ? positionsPlayer1[idx].1 : positionsPlayer2[idx].1
            let color = (i < 12) ? Consts.red : Consts.blue
            let player: Player = (i < 12) ? .player1 : .player2
            
            // figure out correct ImageSource values
            var imageName: String
            var source: ImageSource
            if UDM.shared.defaults.bool(forKey: Consts.snoopyImagesOnOffKey) {
                switch player {
                case .player1: 
                    imageName = Consts.snoopyRegular
                case .player2: 
                    imageName = Consts.woodstockRegular
                }
                source = .image(UIImage(named: imageName)!)
            } else {
                imageName = (player == .player1) ? systemName1 : systemName2
                source = .systemName(imageName)
            }
            pieces.insert(CheckerPiece(col: col, row: row, color: color, type: .regular, source: source, player: player))
        }
    }
}

extension CheckersEngine: CustomStringConvertible {
    var description: String {
        var desc = ""
        desc += "  0 1 2 3 4 5 6 7\n"
        for row in 0...7 {
            desc += "\(row)"
            
            for col in 0...7 {
                if let piece = pieceAt(col: col, row: row) {
                    switch piece.type {
                    case .regular:
                        desc += (piece.player == .player1) ? " r" : " b"
                    case .king:
                        desc += (piece.player == .player1) ? " R" : " B"
                    }
                } else {
                    desc += " ."
                }
            }
            desc += "\n"
        }
        return desc
    }
}

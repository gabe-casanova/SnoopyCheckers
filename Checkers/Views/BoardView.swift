//
//  BoardView.swift
//  Checkers
//
//  Created by Gabriel Casanova on 12/4/23.
//

import UIKit

class BoardView: UIView {
    
    let ratio: CGFloat = 1.0
    var originX: CGFloat = 0
    var originY: CGFloat = 0
    var cellSize: CGFloat = 0
    
    var shadowPieces = Set<CheckerPiece>()
    var checkersDelegate: CheckersDelegate? = nil
    
    // touchesBegan global variables
    var fromCol: Int? = nil
    var fromRow: Int? = nil
    
    // touchesMoved global variables
    var movingImage: UIImage? = nil
    var movingPieceX: CGFloat = -1
    var movingPieceY: CGFloat = -1
        
    override func draw(_ rect: CGRect) {
        // calculate proportions
        cellSize = (bounds.width * ratio) / 8
        originX = bounds.width * (1 - ratio) / 2
        originY = bounds.height * (1 - ratio) / 2
        
        // time to draw
        drawBoard()
        drawPieces()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let first = touches.first!  // guaranteed that first is not nil
        let fingerLocation = first.location(in: self)
        fromCol = p2p(Int((fingerLocation.x - originX) / cellSize))
        fromRow = p2p(Int((fingerLocation.y - originY) / cellSize))
        
        // store `movingImage` via delegate
        if let fromCol = fromCol, let fromRow = fromRow,
           let movingPiece = checkersDelegate?.pieceAt(col: fromCol, row: fromRow) {
            
            switch movingPiece.source {
            case .systemName(let systemName):
                movingImage = UIImage(systemName: systemName)
                movingImage = movingImage?.withTintColor(movingPiece.color)
            case .image(let image):
                movingImage = image
            }
            
            let oppositeEndsOn = UDM.shared.defaults.bool(forKey: Consts.oppositeEndsOnOffKey)
            if oppositeEndsOn && movingPiece.player == .player2 {
                movingImage = movingImage?.rotated180Degrees()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let first = touches.first!
        let fingerLocation = first.location(in: self)
        movingPieceX = fingerLocation.x
        movingPieceY = fingerLocation.y
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let first = touches.first!
        let fingerLocation = first.location(in: self)
        
        let toCol: Int = p2p(Int((fingerLocation.x - originX) / cellSize))
        let toRow: Int = p2p(Int((fingerLocation.y - originY) / cellSize))
        
        // trigger the delegate to actually move the piece
        if let fromCol = fromCol, let fromRow = fromRow {
            checkersDelegate?.movePiece(fromCol: fromCol, fromRow: fromRow, toCol: toCol, toRow: toRow)
        }
        
        // set `movingImage` back to nil to hide it after we've placed moving piece down
        movingImage = nil
        fromCol = nil
        fromRow = nil
        setNeedsDisplay()
    }
    
    func drawPieces() {
        // iterate over all pieces, skipping over the one corresponding to `movingPiece`
        for piece in shadowPieces where !(fromCol == piece.col && fromRow == piece.row) {
            
            var pieceImage: UIImage?
            switch piece.source {
            case .systemName(let systemName):
                pieceImage = UIImage(systemName: systemName)
                pieceImage = pieceImage?.withTintColor(piece.color)
            case .image(let image):
                pieceImage = image
            }
            
            let oppositeEndsOn = UDM.shared.defaults.bool(forKey: Consts.oppositeEndsOnOffKey)
            if oppositeEndsOn && piece.player == .player2 {
                pieceImage = pieceImage?.rotated180Degrees()
            }
            
            pieceImage?.draw(in: CGRect(x: originX + CGFloat(p2p(piece.col)) * cellSize,
                                        y: originY + CGFloat(p2p(piece.row)) * cellSize,
                                        width: cellSize, height: cellSize))
        }
        
        // render the moving piece as you drag it with your finger
        movingImage?.draw(in: CGRect(x: movingPieceX - (cellSize / 2),
                                     y: movingPieceY - (cellSize / 2),
                                     width: cellSize, height: cellSize))
    }
    
    func drawBoard() {
        var CONTRAST_COLOR: UIColor
        if UITraitCollection.current.userInterfaceStyle == .dark {
            CONTRAST_COLOR = UIColor(.black)
        } else {
            CONTRAST_COLOR = Consts.green
        }
        for row in 0...3 {
            for col in 0...3 {
                // row i
                drawSquare(col: col * 2, row: row * 2, color: .white)
                drawSquare(col: (col * 2) + 1, row: row * 2, color: CONTRAST_COLOR)
                // row i+1
                drawSquare(col: col * 2,  row: (row * 2) + 1, color: CONTRAST_COLOR)
                drawSquare(col: (col * 2) + 1, row: (row * 2) + 1, color: .white)
            }
        }
    }
    
    func drawSquare(col: Int, row: Int, color: UIColor) {
        let path = UIBezierPath(rect: CGRect(x: originX + CGFloat(col) * cellSize,
                                             y: originY + CGFloat(row) * cellSize,
                                             width: cellSize, height: cellSize))
        color.setFill()
        path.fill()
    }
    
    // determines if we'll need to render the board flipped or not
    func p2p(_ coordinate: Int) -> Int {  // p2p: peer 2 peer
        let flipBoardOn = UDM.shared.defaults.bool(forKey: Consts.flipBoardOnOffKey)
        guard flipBoardOn else {
            return coordinate
        }
        let currPlayer = UDM.shared.defaults.string(forKey: Consts.currentPlayerKey)!
        return (currPlayer == Consts.player1) ? coordinate : 7 - coordinate
    }
}

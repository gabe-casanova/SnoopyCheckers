//
//  CheckerPiece.swift
//  Checkers
//
//  Created by Gabriel Casanova on 12/4/23.
//

import Foundation
import UIKit

struct CheckerPiece: Hashable {
    let col: Int
    let row: Int
    let color: UIColor
    let type: CheckerType
    let source: ImageSource
    let player: Player
}

//
//  Consts.swift
//  Checkers
//
//  Created by Gabriel Casanova on 12/21/23.
//

import Foundation
import UIKit

public enum Consts {
    
    /* Colors */
    static let red = UIColor(rgb: 0xff6969)
    static let blue = UIColor(rgb: 0x79aaf7)
    static let green = UIColor(rgb: 0x00644c)
    
    /* Default Checker Buttons */
    static let king = "crown.fill"
    static let heart = "heart.circle.fill"
    static let swirl = "swirl.circle.righthalf.filled"
    static let moon = "moon.stars.circle.fill"
    static let flower = "camera.macro.circle.fill"
    static let turtle = "tortoise.circle.fill"
    
    /* Snoopy Checker Images */
    static let snoopyRegular = "regular-snoopy"
    static let snoopyKing = "king-snoopy"
    static let woodstockRegular = "regular-woodstock"
    static let woodstockKing = "king-woodstock"
    
    /* Keys used for UserDefaults */
    static let nameKeyPlayer1 = "nameKeyPlayer1"
    static let nameKeyPlayer2 = "nameKeyPlayer2"
    static let currentPlayerKey = "currentPlayerKey"

    static let flipBoardOnOffKey = "flipBoardOnOffKey"
    static let oppositeEndsOnOffKey = "oppositeEndsOnOffKey"
    static let timerOnOffKey = "timerOnOffKey"
    static let snoopyImagesOnOffKey = "snoopyImagesOnOffKey"
    
    static let selectedRedButtonNameKey = "selectedRedButtonNameKey"
    static let selectedBlueButtonNameKey = "selectedButtonNameKey2"
    
    /* Miscellaneous */
    static let settings = "gearshape.fill"
    static let musicPlay = "play.fill"
    static let musicPause = "play.slash.fill"
    static let player1 = "player1"
    static let player2 = "player2"
}

extension UIColor {
   convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255)
       assert(green >= 0 && green <= 255)
       assert(blue >= 0 && blue <= 255)

       self.init(red: CGFloat(red) / 255.0,
                 green: CGFloat(green) / 255.0,
                 blue: CGFloat(blue) / 255.0,
                 alpha: 1.0)
   }

   convenience init(rgb: Int) {
       self.init(
           red: (rgb >> 16) & 0xFF,
           green: (rgb >> 8) & 0xFF,
           blue: rgb & 0xFF
       )
   }
}

extension UIImage {
    func rotated180Degrees() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.translateBy(x: size.width / 2, y: size.height / 2)
        context.rotate(by: CGFloat.pi)
        context.translateBy(x: -size.width / 2, y: -size.height / 2)

        self.draw(at: .zero)

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return rotatedImage
    }
}

//
//  ImageSource.swift
//  Checkers
//
//  Created by Gabriel Casanova on 12/20/23.
//

import Foundation
import UIKit

enum ImageSource: Hashable {
    case systemName(String)
    case image(UIImage)
}

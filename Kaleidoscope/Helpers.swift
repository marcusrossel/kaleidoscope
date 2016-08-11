//
//  Helpers.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 11.08.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import Foundation

extension String {
  subscript(offset offset: Int) -> Character {
    return self[index(startIndex, offsetBy: offset)]
  }
}

extension Character {
  func belongs(to characterSet: CharacterSet) -> Bool {
    return String(self).rangeOfCharacter(from: characterSet) != nil
  }
}

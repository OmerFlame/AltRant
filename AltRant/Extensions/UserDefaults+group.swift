//
//  UserDefaults+group.swift
//  AltRant
//
//  Created by Omer Shamai on 2/18/21.
//

import Foundation

/*extension Data {
    mutating func copy(data: Data, offset: Int = 0, size: Int) {
        let srcStart = data.index(data.startIndex, offsetBy: offset)
        let srcEnd = srcStart + size
        let dstStart = self.startIndex
        let dstEnd = dstStart + size
        self[dstStart..<dstEnd] = data[srcStart..<srcEnd]
    }
}*/

extension UserDefaults {
    static let group = UserDefaults(suiteName: "group.com.cracksoftware.AltGroup")!
}

//
//  Item.swift
//  Frame tvOS
//
//  Created by Noah Hall on 6/6/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

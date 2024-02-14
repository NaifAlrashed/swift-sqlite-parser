//
//  File.swift
//  
//
//  Created by Naif Alrashed on 14/02/2024.
//

import Foundation
import Parsing

let numericLiteralParser = Parse {
    Double.parser(of: Substring.self)
}

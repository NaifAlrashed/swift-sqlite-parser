//
//  File.swift
//  
//
//  Created by Naif Alrashed on 14/02/2024.
//

import Foundation
import Parsing

let numericLiteralParser = Parse(input: Substring.self) {
    Double.parser()
}

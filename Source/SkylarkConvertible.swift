//
//  SkylarkConvertible.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/19/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

// SkylarkConvertible is a higher level representation of types within Skylark
public protocol SkylarkConvertible {
    func toSkylark() -> [SkylarkNode]
}

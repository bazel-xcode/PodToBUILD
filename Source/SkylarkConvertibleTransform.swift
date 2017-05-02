//
//  SkylarkConvertibleTransform.swift
//  PodSpecToBUILD
//
//  Created by jerry on 5/2/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

public protocol SkylarkConvertibleTransform {
    /// Apply a transform to skylark convertibles
    static func transform(convertibles: [SkylarkConvertible], options: BuildOptions) -> [SkylarkConvertible]
}

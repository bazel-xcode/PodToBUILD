//
//  MagmasTests.swift
//  PodSpecToBUILD
//
//  Created by Brandon Kase on 5/1/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation
import SwiftCheck
import XCTest

class MagmasTests: XCTestCase {
    func testArrayExtensions() {
        property("Array semigroup associative") <- forAll { (xs: ArrayOf<Int>, ys: ArrayOf<Int>, zs: ArrayOf<Int>) in
            return ((xs.getArray <> ys.getArray) <> zs.getArray) ==
                    (xs.getArray <> (ys.getArray <> zs.getArray))
        }
        
        property("Array monoid identity") <- forAll { (xs: ArrayOf<Int>) in
            return (xs.getArray <> Array.empty == xs.getArray) <?> "Right identity"
                ^&&^
                (Array.empty <> xs.getArray == xs.getArray) <?> "Left identity"
        }
    }
    
    func testStringExtensions() {
        property("String semigroup associative") <- forAll { (x: String, y: String, z: String) in
            return ((x <> y) <> z) == (x <> (y <> z))
        }
        
        property("String monoid identity") <- forAll { (x: String) in
            return (x <> String.empty == x) <?> "Right identity"
                ^&&^
                (String.empty <> x == x) <?> "Left identity"
        }
    }
    
    func testDictionaryExtensions() {
        property("Dict semigroup associative") <- forAll { (x: DictionaryOf<String, Int>, y: DictionaryOf<String, Int>, z: DictionaryOf<String, Int>) in
            return ((x.getDictionary <> y.getDictionary) <> z.getDictionary) ==
                (x.getDictionary <> (y.getDictionary <> z.getDictionary))
        }
        
        property("Dict monoid identity") <- forAll { (x: DictionaryOf<String, Int>) in
            return (x.getDictionary <> Dictionary.empty == x.getDictionary) <?> "Right identity"
                ^&&^
                (Dictionary.empty <> x.getDictionary == x.getDictionary) <?> "Left identity"
        }
    }
    
    func testNormalizeOptions() {
        property("Never admit an empty after normalizing") <- forAll { (x: OptionalOf<String>) in
            return x.getOptional.normalize() != .some(String.empty)
        }
    }
}

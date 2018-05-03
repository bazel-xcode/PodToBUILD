//
//  MagmasTests.swift
//  PodToBUILD
//
//  Created by Brandon Kase on 5/1/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation
import SwiftCheck
import XCTest
@testable import PodToBUILD

class MagmasTests: XCTestCase {
    func testArrayExtensions() {
        property("Array semigroup associative") <- forAll { (xs: Array<Int>, ys: Array<Int>, zs: Array<Int>) in
            return ((xs <> ys) <> zs) ==
                    (xs <> (ys <> zs))
        }
        
        property("Array monoid identity") <- forAll { (xs: Array<Int>) in
            return (xs <> Array.empty == xs) <?> "Right identity"
                ^&&^
                (Array.empty <> xs == xs) <?> "Left identity"
        }
        
        property("Array empty awareness sound") <- forAll { (xs: Array<Int>) in
            return xs.isEmpty ?
                xs == Array.empty :
                xs != Array.empty
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
        
        property("String empty awareness sound") <- forAll { (x: String) in
            return x.isEmpty ?
                x == String.empty :
                x != String.empty
        }
    }
    
    func testDictionaryExtensions() {
        property("Dict semigroup associative") <- forAll { (x: Dictionary<String, Int>, y: Dictionary<String, Int>, z: Dictionary<String, Int>) in
            return ((x <> y) <> z) ==
                (x <> (y <> z))
        }
        
        property("Dict monoid identity") <- forAll { (x: Dictionary<String, Int>) in
            return (x <> Dictionary.empty == x) <?> "Right identity"
                ^&&^
                (Dictionary.empty <> x == x) <?> "Left identity"
        }
        
        property("Dict empty awareness sound") <- forAll { (x: Dictionary<String, Int>) in
            return x.isEmpty ?
                x == Dictionary.empty :
                x != Dictionary.empty
        }
    }
    
    func testNormalizeOptions() {
        property("Never admit an empty after normalizing") <- forAll { (x: Optional<String>) in
            return x.normalize() != .some(String.empty)
        }
    }

    func testOptionalCompositionExtension() {
        property("composition of optionals using <>") <- forAll { (x: Optional<String>, y: Optional<String>) in
            return x <> Optional.empty == x
        }
    }
}

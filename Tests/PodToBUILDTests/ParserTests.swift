//
//  ParserTests.swift
//  PodToBUILD
//
//  Created by Brandon Kase on 9/12/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation
import SwiftCheck
import XCTest
@testable import PodToBUILD

struct Average: Monoid {
    let count: Int
    let sum: Int
    
    init(value: Int) {
        self.count = 1
        self.sum = value
    }
    init(count: Int, sum: Int) {
        self.count = count
        self.sum = sum
    }
    
    static var empty: Average {
        return Average(count: 0, sum: 0)
    }
    static func <>(lhs: Average, rhs: Average) -> Average {
        return Average(count: lhs.count + rhs.count, sum: lhs.sum + rhs.sum)
    }
    
    var avg: Double {
        return count == 0 ? 0 : Double(sum) / Double(count)
    }
}

class ParserTests: XCTestCase {
    func testParseOneCharacter() {
        property("Parsing a character with anyChar is the identity") <- forAll { (c: Character) in
            Parsers.anyChar.parseFully([c]) == c
        }
    }
    
    func testFailParserFails() {
        property("Using a failure parser never succeeds") <- forAll { (cs: Array<Character>) in
            Parser<()>.fail().parseFully(cs) == nil
        }
    }
    
    func testTrivialParserSucceeds() {
        property("Using a trivial parser always succeeds and consumes nothing") <- forAll { (cs: Array<Character>) in
            if let (_, rest) = Parser<()>.trivial(()).run(cs) {
                return rest == cs
            } else {
                return false
            }
        }
    }
    
    func testButNot() {
        let notBang = Character.arbitrary.suchThat{ $0 != "!" }

        property("AnyChar but not ! matches anything except !") <- forAll(notBang) { (x: Character) in
            (Parsers.anyChar.butNot("!").parseFully([x]) != nil) <?> "Matches anything but not !"
            ^&&^
            (Parsers.anyChar.butNot("!").parseFully(["!"]) == nil) <?> "Doesn't match !"
        }
    }
    
    func testParseMany() {
        property("Many matches zero or more times") <- forAll { (cs: Array<Character>) in
            Parsers.anyChar.many().parseFully(cs) != nil
        }
        
        let dot = Parsers.just(".")
        XCTAssertEqual(
            // parser anything zero or more times until a dot
            (Parsers.anyChar.butNot(".").many() <>
                // then consume the dot, but don't return it
                dot.map{ _ in [] })
                    .parseFully(Array("abcde.")) ?? [],
            Array("abcde")
        )
    }
    
    func testParseRep() {
        let chunks = Character.arbitrary.suchThat{ $0 != "," }.proliferateNonEmpty.map{ cs in String(cs) }
        
        property("Repeated strings separated by commas") <- forAll(chunks, chunks, chunks) { (xs: String, ys: String, zs: String)  in
            let reps = Array([xs, ys, zs].joined(separator: ","))
            let parseComma = Parsers.just(",")
            let chunks = Parsers.anyChar.butNot(",").many().rep(separatedBy: parseComma.forget).parseFully(reps) ?? []
            return (chunks.count == 3) &&
                String(chunks[0]) == xs &&
                String(chunks[1]) == ys &&
                String(chunks[2]) == zs
        }
    }
    
    func testParseIntoMonoidalStructure() {
        let nums: Gen<Array<Int>> = Int.arbitrary.resize(20).proliferateNonEmpty.map{ Array($0) }
        
        property("Average stream of numbers into one number") <- forAll(nums) { (nums: Array<Int>) in
            let baselineAverage = mfold(nums.map{ Average(value: $0) }).avg
            
            let inputStream = nums.map{ String($0) }.joined(separator: ",")
            
            let parseComma = Parsers.just(",")
            let parsedAvgs = Parsers.anyChar.butNot(",")
                .many()
                .map{ cs in Average(value: Int(String(cs))!) }
                .rep(separatedBy: parseComma.forget)
                .parseFully(Array(inputStream)) ?? []
            let parsedAverage = mfold(parsedAvgs).avg
            return baselineAverage == parsedAverage
        }
    }
}

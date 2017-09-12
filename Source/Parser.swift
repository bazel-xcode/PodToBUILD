//
//  Parser.swift
//  PodSpecToBUILD
//
//  Created by Brandon Kase on 9/8/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

import Foundation

// A simple Parser combinator library

/** A Parser is a wrapper around a function:
 *      `let run: ([Character]) -> (A, [Character])?`
 * in English: Given a stream of input, try to parse an A:
 *      either fail (return nil);
 *      or succeed and provide the A and the stream that hasn't been consumed
 */
struct Parser<A> {
    let run: ([Character]) -> (A, [Character])?
    
    /// Run the parser; ensure that the result stream is empty or else fail
    func parseFully(_ s: [Character]) -> A? {
        if let (a, rest) = self.run(s), rest.count == 0 {
            return a
        } else {
            return nil
        }
    }
    
    func map<B>(_ f: @escaping (A) -> B) -> Parser<B> {
        return Parser<B>{ s in
            if let (a, rest) = self.run(s) {
                return (f(a), rest)
            } else {
                return nil
            }
        }
    }
    
    func flatMap<B>(_ f: @escaping (A) -> Parser<B>) -> Parser<B> {
        return Parser<B> { s in
            if let (a, rest) = self.run(s) {
                return f(a).run(rest)
            } else {
                return nil
            }
        }
    }
    
    /// flatMap but ignore your input
    func andThen<B>(_ next: @escaping () -> Parser<B>) -> Parser<B> {
        return self.flatMap { _ in next() }
    }
    
    /// A Parser that always fails
    static func fail() -> Parser<A> {
        return Parser<A> { _ in nil }
    }
    
    /// A Parser that always succeeds and returns `x`
    static func trivial(_ x: A) -> Parser<A> {
        return Parser<A> { s in (x, s) }
    }
    
    /// Forget the data structure you've parsed
    var forget: Parser<()> {
        return self.map{ _ in () }
    }
    
    /// Try this parser, but if it fails, try `p` before truly failing
    func orElse(_ p: Parser<A>) -> Parser<A> {
        return Parser<A> { s in
            if let (a, rest) = self.run(s) {
                return (a, rest)
            } else {
                return p.run(s)
            }
        }
    }
    
    /// Try each parser in `ps` in order, take the result of the first that succeeds
    static func first<S: Sequence>(_ ps: S) -> Parser<A> where S.Iterator.Element == Parser<A> {
        return ps.reduce(Parser.fail()) { (acc, p) in
            return acc.orElse(p)
        }
    }
    
    /// Make a parser that parses your data zero or more times
    func many() -> Parser<[A]> {
        return manyUntil(terminator: Parser<()>.fail())
    }
    
    /// Make a parser that wraps this parser with two characters
    /// Note: Make sure you don't greedily parse the endingWith character in `self`
    func wrapped(startingWith: Character, endingWith: Character) -> Parser<A> {
        return Parsers.just(startingWith).andThen{ _ in self }.flatMap{ x in
            return Parsers.just(endingWith).map{ _ in x }
        }
    }
    
    /// Make a parser that looks for data repeated separated by `separatedBy`
    /// and return all the data (excluding the separatedBy bit)
    /// Note: Make sure you don't greedily parse the `separatedBy` character in `self`
    func rep(separatedBy: Parser<()>) -> Parser<[A]> {
        return self.flatMap{ a in
            return Parser<[A]>.trivial([a]) <> (separatedBy.andThen{ _ in self}).many()
        }
    }
    
    /// Make a parser that is like this parser but always fails when encountering `char`
    func butNot(_ char: Character) -> Parser<A> {
        return Parser<A> { s in
            if let (a, rest) = self.run(s), s[0] != char {
                return (a, rest)
            } else {
                return nil
            }
        }
    }
    
    /// Make a parser that parses many times until hitting a `terminator` and there are
    /// `atLeast` successfuly pieces of data parsed.
    func manyUntil(terminator: Parser<()>, atLeast: Int = 0) -> Parser<[A]> {
        func checkedReturn(_ t: ([A], [Character])) -> ([A], [Character])? {
            return t.0.count >= atLeast ? t : nil
        }
        func loop(_ next: [Character], _ build: [A]) -> ([A], [Character])? {
            if let (_, _) = terminator.run(next) {
                return checkedReturn((build, next))
            }
            
            if let (a, rest) = self.run(next) {
                return loop(rest, build + [a])
            } else {
                return checkedReturn((build, next))
            }
        }
        
        return Parser<[A]> { s in
            return loop(s, [])
        }
    }
}

/// Combining two parsers when the we're making a semigroup
/// can automatically combine the inner bits in a single parser
/// that tries `lhs` and then `rhs` in sequence.
/// This means Parser is a semigroup homomorphism.
extension Parser where A: Semigroup {
    static func <>(lhs: Parser, rhs: Parser) -> Parser {
        return lhs.flatMap{ (l: A) -> Parser<A> in
            rhs.map{ (r: A) -> A in
                l <> r
            }
        }
    }
}

enum Parsers {
    /// As long as the input stream is non-empty this will pass with the first character
    static let anyChar: Parser<Character> = Parser<Character> { cs in
        if cs.count > 0 {
            return (cs[0], Array(cs[1..<cs.count]))
        } else {
            return nil
        }
    }

    /// Any whitespace character is accepted
    static let whitespace: Parser<Character> = Parser<Character> { cs in
        if cs.count > 0, cs[0] == " " || cs[0] == "\t" {
            return (cs[0], Array(cs[1..<cs.count]))
        } else {
            return nil
        }
    }
    
    /// Make a parser to parse just one character `x`
    static func just(_ x: Character) -> Parser<Character> {
        return Parsers.prefix([x]).map{ cs in cs[0] }
    }
    
    /// Make a parser to parse a sequence of characters `prefix`
    static func prefix(_ prefix: [Character]) -> Parser<[Character]> {
        return Parser<[Character]> { s in
            if (prefix.count <= s.count && zip(prefix, s[0..<prefix.count]).filter{ $0 != $1 }.count == 0) {
                return (prefix, Array(s[prefix.count..<s.count]))
            } else {
                return nil
            }
        }
    }
}

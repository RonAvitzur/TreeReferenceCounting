//  Expr.swift Created by Ron Avitzur on 9/12/20.
//
// Is there a way to use IteratorProtocol to iterate over nodes in a tree class without retain/release at every step?

import Foundation

final class Expr : Sequence {
    var value: Double
    weak var parent: Expr?
    var args: [Expr] { didSet { for arg in args { arg.parent = self } } }

    init(_ args:Expr...) {
        self.value = 1
        self.args = args
        for arg in args { arg.parent = self }
    }
    
    var numberOfArgs: Int { args.count }
    subscript(index:Int) -> Expr { get { args[index] } }
    func index(of arg: Expr) -> Int { return args.firstIndex{$0 === arg}! }

    var opnum: Int { parent?.index(of: self) ?? -1 } // self must be in parent.args. ok to crash if untrue
    var leftMost:  Expr { numberOfArgs == 0 ? self : args[0].leftMost   }
    var nextBottomUp: Expr? {
        guard let parent = parent else { return nil }
        return self === parent[parent.numberOfArgs - 1] ? parent : parent[opnum + 1].leftMost
    }

    /// **for node in expr** iterates in bottom-up left-to-right order starting at the leftmost leaf
    func makeIterator() -> ExprIterator { ExprIterator(self) } // iterate nodes in bottom up order    
    struct ExprIterator : IteratorProtocol {
        typealias Element = Expr
        
        let top: Expr
        var nextNode: Expr?
        
        init(_ top: Expr) {
            self.top = top
            self.nextNode = top.leftMost
        }
        
        mutating
        func next() -> Expr? {
            let expr = nextNode;
            nextNode = (nextNode === top) ? nil : nextNode?.nextBottomUp
            return expr
        }
    }
    
    // Unmanaged version
    var opnumUnmanaged: Int {
        guard let parent = parent else { return -1 }
        //return Unmanaged.passUnretained(parent)._withUnsafeGuaranteedRef{ $0.args.firstIndex{$0 === self}! } // self must be in parent.args. ok to crash if untrue
        return Unmanaged.passUnretained(parent)._withUnsafeGuaranteedRef{$0.index(of: self)} // self must be in parent.args. ok to crash if untrue
    }

    var leftMostUnmanaged: Expr { return numberOfArgs == 0 ? self : Unmanaged.passUnretained(args[0])._withUnsafeGuaranteedRef{$0.leftMostUnmanaged} }

    var nextBottomUpUnmanaged: Expr? {
        guard let parent = parent else { return nil }
        return Unmanaged.passUnretained(parent)._withUnsafeGuaranteedRef {
            if self === $0[$0.numberOfArgs - 1] { return $0 }
            else {
                return Unmanaged.passUnretained($0[opnumUnmanaged + 1])._withUnsafeGuaranteedRef { $0.leftMostUnmanaged }
            }
        }
    }
    
    struct ExprUnmanagedIterator : IteratorProtocol {
        typealias Element = Expr
        
        let top: Unmanaged<Expr>
        var nextNode: Unmanaged<Expr>?
        
        init(_ top: Expr) {
            self.top = Unmanaged.passUnretained(top)
            self.nextNode = Unmanaged.passUnretained(top.leftMostUnmanaged)
        }
        
        mutating func next() -> Expr? {
            guard let nextNode = nextNode else { return nil }
            return nextNode._withUnsafeGuaranteedRef {
                expr in self.nextNode = top._withUnsafeGuaranteedRef{$0 === expr} ? nil : Unmanaged.passUnretained(expr.nextBottomUpUnmanaged!)
                return expr
            }
        }
    }
    
    struct UnmanagedSequence: Sequence {
        var expr: Expr
        init(_ expr: Expr) { self.expr = expr }
        func makeIterator() -> ExprUnmanagedIterator { return ExprUnmanagedIterator(expr) }
    }

    var sumRecursive: Double { value + args.reduce(0){$0 + $1.sumRecursive} }
    var sumLoop: Double { var count = 0.0; for expr in self { count += expr.value}; return count }
    var sumUnmanagedLoop: Double { var count = 0.0; for expr in UnmanagedSequence(self) { count += expr.value}; return count }
}



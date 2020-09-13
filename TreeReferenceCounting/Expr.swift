//  Expr.swift Created by Ron Avitzur on 9/12/20.
//
// Is there a way to use IteratorProtocol to iterate over nodes in a tree class without retain/release at every step?

import Foundation

final class Expr : Sequence {
    var value: Double = 0
    weak var parent: Expr? = nil
    var args: [Expr] = [] { didSet { setArgParents() } }
    
    init(_ value: Double, _ args:Expr...) {
        self.value = value
        self.args = args
        setArgParents()
    }
    
    func setArgParents() { for arg in args { arg.parent = self } }
    var numberOfArgs: Int { args.count }
    subscript(index:Int) -> Expr { get { args[index] } }
    var opnum: Int {
        guard let parent = parent else { return -1 }
        return parent.args.firstIndex(where: {self === $0})! // self must be in parent.args. ok to crash if untrue
    }

    var leftMost: Expr { args.first?.leftMost ?? self }
    var nextBottomUp: Expr? {
        guard let parent = parent else      { return nil }
        if opnum == parent.numberOfArgs - 1 { return parent }
        else                                { return parent[opnum + 1].leftMost }
    }
    
    func makeIterator() -> ExprBottomUpIterator { ExprBottomUpIterator(self) } // iterate nodes in bottom up order
    
    /// **for node in expr** iterates in bottom-up left-to-right order starting at the leftmost leaf
    struct ExprBottomUpIterator : IteratorProtocol {
        typealias Element = Expr
        
        let top: Expr
        var nextNode: Expr?
        
        init(_ top: Expr) {
            self.top = top
            self.nextNode = top.leftMost
        }
        
        mutating func next() -> Expr? {
            let expr = nextNode;
            nextNode = (nextNode === top) ? nil : nextNode?.nextBottomUp
            return expr
        }
    }
}


// another iterator to walk nodes in top down order
extension Expr {
    var rightMost: Expr { args.last?.rightMost ?? self }
    var nextTopDown: Expr? { numberOfArgs == 0 ? nextOperand : args[0] }
    var nextOperand: Expr? {
        var expr = self
        while true {
            guard let parent = expr.parent else { return nil }
            if expr.opnum != parent.numberOfArgs - 1 { return parent[expr.opnum + 1] }
            else { expr = parent }
        }
    }

    struct ExprTopDown: Sequence {
        var expr: Expr
        init(_ expr: Expr) { self.expr = expr }
        func makeIterator() -> ExprTopDownIterator { return ExprTopDownIterator(expr) }
    }

    var topDown: ExprTopDown { ExprTopDown(self) }
}

struct ExprTopDownIterator : IteratorProtocol {
    typealias Element = Expr
    
    let stop: Expr
    var nextNode: Expr?
    
    init(_ top: Expr) {
        self.stop = top.rightMost
        self.nextNode = top
    }
    
    mutating func next() -> Expr? {
        let expr = nextNode;
        nextNode = (nextNode === stop) ? nil : nextNode?.nextTopDown
        return expr
    }
}

// Is there any way to use Unmanaged<Expr> to iterate without retain/release? This attempt is flawed.
struct ExprTopDownUnsafeIterator : IteratorProtocol {
    typealias Element = Expr
    
    let stop: Unmanaged<Expr>
    var nextNode:  Unmanaged<Expr>?
    
    init(_ top: Expr) {
        self.stop = Unmanaged.passUnretained(top.rightMost)
        self.nextNode = Unmanaged.passUnretained(top)
    }
    
    mutating func next() -> Expr? {
        guard let nextNode = nextNode else { return nil }
        return nextNode._withUnsafeGuaranteedRef {
            let expr = $0;
            self.nextNode = stop._withUnsafeGuaranteedRef{expr === $0} ? nil : Unmanaged.passUnretained($0.nextTopDown!)
            return expr
        }
    }
}


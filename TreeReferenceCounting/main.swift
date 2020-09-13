//  main.swift
//  TreeReferenceCounting

import Foundation

func makeBigTree(_ depth: Int) -> Expr {
    return depth == 0 ?
        Expr(1)
        : Expr(
            1,
            makeBigTree(depth - 1),
            makeBigTree(depth - 1),
            makeBigTree(depth - 1),
            makeBigTree(depth - 1))
    }

func measure(_ title: String, block: () -> ()) {
    
    let startTime = CFAbsoluteTimeGetCurrent()
    block()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print(" \(title): " + String(format:"%.2g", timeElapsed)  + " seconds")
}


let expr = makeBigTree(11)

measure("reduce")    { let _ = expr.reduce(0.0){ $0 + $1.value } }
measure("contains")  { let _ = expr.contains{$0.value == 2} }
measure("for node in expr") {
    var count = 0.0
    for node in expr { count += node.value }
}
measure("for node in expr.topDown") {
    var count = 0.0
    for node in expr.topDown { count += node.value}
}

extension Expr {
    var recursiveTopDownSum: Double {
        var count = value
        for arg in args { count += arg.recursiveTopDownSum }
        return count
    }

    var recursivBottomUpSum: Double {
        var count = 0.0
        for arg in args { count += arg.recursivBottomUpSum }
        return count + value
    }
}

measure("recursiveTopDownSum") { let _ = expr.recursiveTopDownSum }
measure("recursivBottomUpSum") { let _ = expr.recursivBottomUpSum }


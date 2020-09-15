//  main.swift
//  TreeReferenceCounting

import Foundation

func makeBigTree(_ depth: Int) -> Expr {
    return depth == 0 ? Expr() : Expr(makeBigTree(depth - 1), makeBigTree(depth - 1))
}

func measure(_ title: String = "", block: () -> ()) {
    let startTime = CFAbsoluteTimeGetCurrent()
    block()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print(" \(title): " + String(format:"%.2g", timeElapsed)  + " seconds")
}

let bigExpr = makeBigTree(22)
measure("recursive") { print(bigExpr.sumRecursive) }
measure("loop") { print(bigExpr.sumLoop) }
measure("unmanaged loop") { print(bigExpr.sumUnmanagedLoop) }

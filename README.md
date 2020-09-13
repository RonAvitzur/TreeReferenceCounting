# TreeReferenceCounting

Translating Graphing Calculator's algebraic simplification into Swift, 
3,600 lines of C++ reduced to 1,200 lines of Swift, largely due to ARC and collections. 

In one test case which takes 5 seconds in the C++ code and 28 seconds in the Swift version,
the time is mostly in ARC. Wonder how to write an iterator to walk the expression tree without
unecessary retain/release.

In main we create a large tree, then count the nodes in a variety of ways.

/*
* Copyright (C) 2015 47 Degrees, LLC http://47deg.com hello@47deg.com
*
* Licensed under the Apache License, Version 2.0 (the "License"); you may
* not use this file except in compliance with the License. You may obtain
* a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import UIKit
import SecondBridge
import Swiftz

/*:
# Lists

SecondBridge includes additions to Swiftz's implementation of the singly-linked list to give users the option
of using a syntax more closer to Scala's, that you can access by using the ListT struct. We've also implemented
both **Traversable** and **Iterable** protocols, so you can use all the functions available to them (as our other
implemented data types, ListT includes accessors for those methods in its own struct).
*/

//: `==` tests for equality (same content)
var a : ListT<Int> = [1,2,3,4]
var b : ListT<Int> = [1,2,3,4]
println(a)
a == b

//: Nil lists are identical, even if declared when specifying different generic types
var ab : ListT<String>  = []
var ba : ListT<Int>  = []
ab == ba

//: You can create Lists using ArrayLiterals:
var d : ListT<Int> = [1,2,3,4]

//: Lists can be accessed via head and tail
d.head() == 1
let dTail : ListT<Int> = [2,3,4]
d.tail() == dTail

//: and can also be accessed by position
var e : ListT<Int> = [1,3,5,7,9]
e[0] == 1
e[2] == 5
e[4] == 9

//: Lists are immutable
var f : ListT<Int> = [1,3,5,7,9]
println(f)
var g : ListT<Int> = f.filterNot({$0 == 1})
println(g)

//: Lists have many useful methods
var h : ListT<Int> = [1,3,5,7,9]

//: You can get the length of the list
h.length() == 5

//: And also reverse the list
let reverseList : ListT<Int> = [9,7,5,3,1]
h.reverse() == reverseList

//: Or map a function to double the numbers over the list
var hMap = h.map({$0 * 2})
println(hMap)

//: Or filter any values divisible by 3 in the list
var hFilter = h.filter({$0 % 3 == 0})
println(hFilter)

//: Lists can be reduced with a mathematical operation
var i : ListT<Int> = [1,3,5,7]
var iReduce = i.reduce({$0+$1})
println(iReduce)
var iReduceMul = i.reduce({$0*$1})
println(iReduceMul)

//: Foldleft is like reduce, but with an explicit starting value
var j : ListT<Int> = [1,3,5,7]
var jReduce = i.reduce(0, combine: {$0+$1})
println(jReduce)
var jReduceIn = i.reduce(10, combine: {$0+$1})
println(jReduceIn)

var jReduceM = i.reduce(1, combine: {$0*$1})
println(jReduceM)
var jReduceInM = i.reduce(0, combine: {$0*$1})
println(jReduceInM)

//: Remember that you can take a look at our test classes to see more functions available to Lists and other data types available in SecondBridge!

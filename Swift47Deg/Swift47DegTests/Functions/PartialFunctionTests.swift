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
import XCTest
import Swiftz

class PartialFunctionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPartialFunctions() {
        let doubleEvens = Function.arr({ $0 % 2 == 0 }) => Function.arr({ $0 * 2 })
        let tripleOdds = Function.arr({ $0 % 2 != 0 }) => Function.arr({ $0 * 3 })
        let addFive = Function.arr(+5)
        
        let opOrElseOp = doubleEvens ||-> tripleOdds
        let opOrElseAndThenOp = doubleEvens ||-> tripleOdds &&-> addFive
        
        XCTAssertEqual(opOrElseOp.apply(3), 9, "Partial functions should be attachable with orElse conditionals")
        XCTAssertEqual(opOrElseOp.apply(4), 8, "Partial functions should be attachable with orElse conditionals")
        
        XCTAssertEqual(opOrElseAndThenOp.apply(3), 14, "Partial functions should be attachable with orElse and andThen conditionals")
        XCTAssertEqual(opOrElseAndThenOp.apply(4), 13, "Partial functions should be attachable with orElse and andThen conditionals")
        
        let printEven = Function<Int, Bool>.arr({ (value : Int) -> Bool in value % 2 == 0}) => Function<Int, String>.arr({ (Int) -> String in return "Even"})
        let printOdd = Function<Int, Bool>.arr({ (value : Int) -> Bool in value % 2 != 0}) => Function<Int, String>.arr({ (Int) -> String in return "Odd"})
        
        let complexOp = doubleEvens ||-> tripleOdds &&-> (printEven ||-> printOdd)
        XCTAssertEqual(complexOp.apply(3), "Odd", "Partial functions should be attachable with orElse and andThen conditionals")
        XCTAssertEqual(complexOp.apply(4), "Even", "Partial functions should be attachable with orElse and andThen conditionals")
    }
}
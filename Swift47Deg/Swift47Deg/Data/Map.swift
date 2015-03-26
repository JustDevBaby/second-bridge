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

import Foundation

// MARK: - Map declaration and protocol implementations

/// Map | An immutable iterable collection containing pairs of keys and values. Each key is of type HashableAny to allow to have keys with different types (currently supported types are Int, Float, and String). Each value is of a type T. If you need to store values of different types, make an instance of Map<Any>.
public struct Map<T> {
    private var internalDict : Dictionary<Key, Value>
    
    public subscript(key: Key) -> Value? {
        get {
            return internalDict[key]
        }
        set {
            internalDict[key] = newValue
        }
    }
    
    public var size : Int {
        return self.internalDict.count
    }
}

extension Map : DictionaryLiteralConvertible {
    public typealias Key = HashableAny
    public typealias Value = T
    
    public init(dictionaryLiteral elements: (Key, Value)...) {
        var tempDict = Dictionary<Key, Value>()
        for element in elements {
            tempDict[element.0] = element.1
        }
        internalDict = tempDict
    }
}

extension Map : SequenceType {
    public typealias Generator = GeneratorOf<(Key, Value)>
    
    public func generate() -> Generator {
        var index : Int = 0
        
        return Generator {
            if index < self.internalDict.count {
                let key = Array(self.internalDict.keys)[index]
                index++
                return (key, self.internalDict[key]!)
            }
            return nil
        }
    }
}

extension Map : Traversable {
    typealias ItemType = (Key, Value)
    public func foreach(f: ((Key, T)) -> ()) {
        for (key, value) in self.internalDict {
            f((key, value))
        }
    }
    
    /**
    Build a new Map instance with the elements contained in the `elements` array.
    */
    public func build(elements: [ItemType]) -> Map {
        return Map(elements)
    }
    
    /**
    Build a new Map instance with the elements contained in the provided Traversable instance. If the items contained belong to another Map with the same type (key, value), it simply adds it, and if it finds only values of the same type it fills the keys with the available indices. 
    */
    public func buildFromTraversable<U where U : Traversable>(traversable: U) -> Map {
        var result : Map = Map()
        var index = 0
        traversable.foreach { (item) -> () in
            switch item {
            case let sameTypeItem as ItemType: result = result + sameTypeItem
            case let sameTypeValue as Value: let key = HashableAny(intValue: index); result = result + (key, sameTypeValue)
            default: break
            }
            index++
        }
        return result
    }
}

// MARK: Higher-order functions

extension Map {
    public init(_ arrayOfGenerators: [Generator.Element]) {
        self = Map() + arrayOfGenerators
    }
    
    /**
    Returns a new map containing all the keys from the current map that satisfy the `includeElement` closure. Only takes into account values, not keys.
    */
    public func filter(includeElement: (Value) -> Bool) -> Map {
        return self.filter { (item) -> Bool in
            includeElement(item.1)
        }
    }
    
    /**
    Returns a new map containing all the keys/value pairs from the current one that satisfy the `includeElement` closure. Takes into account both values AND keys.
    */
    public func filter(includeElement: ((Key, Value)) -> Bool) -> Map {
        return Map(travFilter(self, { (item) -> Bool in
            return includeElement(item)
        }))
    }
    
    /**
    Returns a new map containing all the keys from the current one that satisfy the `includeElement` closure.
    */
    public func filterKeys(includeElement: (Key) -> Bool) -> Map {
        return self.filter({ (item: (key: Key, value: Value)) -> Bool in
            includeElement(item.key)
        })
    }
    
    /**
    Returns a new map obtained by removing all key/value pairs for which the `removeElement` closure returns true.
    */
    public func filterNot(removeElement: ((Key, Value)) -> Bool) -> Map {
        let itemsToExclude = self.filter(removeElement)
        return self -- itemsToExclude.keys
    }
    
    /**
    Returns a new map containing the results of mapping `transform` over its elements.
    */
    public func map<U>(transform: (Value) -> U) -> Map<U> {
        return Map<U>(travMap(self, { return ($0.0, transform($0.1)) }))
    }
    
    /**
    Returns the result of repeatedly calling combine with an accumulated value initialized to `initial` and each element's value of the current map.
    */
    public func reduceByValue<U>(initialValue: U, combine: (U, Value) -> U) -> U {
        return self.reduce(initialValue, combine: { (currentTotal, currentElement) -> U in
            return combine(currentTotal, currentElement.1)
        })
    }
    
    /**
    Returns the result of repeatedly calling combine with an accumulated value initialized to `initial` and each element (taking also into account the key) of the current map.
    */
    public func reduce<U>(initialValue: U, combine: (U, (Key, Value)) -> U) -> U {
         return travReduce(self, initialValue, combine)
    }
    
    /**
    Returns the first element of the map satisfying a predicate, if any. Note: might return different results for different runs, as the underlying collection type is unordered.
    
    :param: predicate The predicate to check the map items against
    */
    public func find(predicate: ((Key, Value) -> Bool)) -> (Key, Value)? {
        let result = self.filter(predicate)
        if result.size > 0 {
            let key = result.keys[0]
            return (key, result[key]!)
        }
        return nil
    }
    
    /**
    Returns the result of applying `transform` on each element of the map, and then flattening the results into an array.
    */
    public func flatMapValues(transform: (Value) -> [Value]) -> [Value] {
        return travFlatMap(self, { transform($0.1) })
    }
    
    /**
    Returns the result of repeatedly calling combine with an accumulated value initialized to `initial` and each element (taking also into account the key) of the current map. Iteration is done in reverse order to reduce/foldRight.
    */
    public func foldLeft<U>(initialValue: U, combine: (U, (Key, Value)) -> U) -> U {
        return travFoldLeft(self, initialValue, combine)
    }
    
    /**
    Returns the result of repeatedly calling combine with an accumulated value initialized to `initial` and each element (taking also into account the key) of the current map. Iteration is done in the same order as reduce/foldRight.
    */
    public func foldRight<U>(initialValue: U, combine: (U, (Key, Value)) -> U) -> U {
        return travFoldRight(self, initialValue, combine)
    }
    
    /**
    Returns an array containing the results of mapping the partial function `f` over a set of this map's elements that match the condition defined in `f`'s `isDefinedAt`.
    */
    public func collect<U>(f: PartialFunction<ItemType, (HashableAny, U)>) -> Map<U> {
        return Map<U>(travCollect(self, f))
    }
}

// MARK: Basic functions

extension Map {
    /**
    :returns: An array containing all the keys from the current map. Note: might return different results for different runs, as the underlying collection type is unordered.
    */
    public var keys : [Key] {
        return Array(internalDict.keys)
    }
    
    /**
    :returns: True if the map doesn't contain any element.
    */
    public func isEmpty() -> Bool {
        return internalDict.keys.isEmpty
    }
    
    /**
    :returns: An array containing the different values from the current map. Note: might return different results for different runs, as the underlying collection type is unordered.
    */
    public func values() -> [Value] {
        return Array(internalDict.values)
    }
    
    /**
    Checks if a certain key is binded to a value in the current map.
    
    :param: key The key to be checked.
    
    :returns: True if the map contains an element binded to the key.
    */
    public func contains(key: Key) -> Bool {
        return internalDict[key] != nil
    }
    
    /**
    Tests whether a predicate holds for some of the elements of this map.
    
    :param: p Predicate to check against the elements of this map
    */
    public func exists(p: ((Key, Value)) -> Bool) -> Bool {
        return self.filter(p).size > 0
    }
    
    
    /**
    Counts the number of elements in the map which satisfy a predicate.
    */
    public func count(p: ((Key, Value)) -> Bool) -> Int {
        return self.filter(p).size
    }
}

// MARK: - addition/removal/modification of elements in the map

extension Map {
    /**
    Selects all elements except the first n ones. Note: might return different results for different runs, as the underlying collection type is unordered.
    
    :param: n Number of elements to be excluded from the selection
    
    :returns: A new map containing the elements from the selection
    */
    public func drop(n: Int) -> Map {
        let keys = self.keys
        let keysToExclude = keys.filter({ Swift.find(keys, $0) < n })
        return self -- keysToExclude
    }
    
    /**
    Selects all elements except the last n ones. Note: might return different results for different runs, as the underlying collection type is unordered.
    
    :param: n Number of elements to be excluded from the selection
    
    :returns: A new map containing the elements from the selection
    */
    public func dropRight(n: Int) -> Map {
        let keys = self.keys
        let keysToExclude = keys.filter({ Swift.find(keys, $0) >= self.size - n })
        return self -- keysToExclude
    }
    
    private func findFirstIndexToNotSatisfyPredicate(p: (Key, Value) -> Bool) -> Int? {
        var count = 0
        for key in self.keys {
            if let value = self[key] {
                if !p(key, value) {
                    return count
                }
            }
            count++
        }
        return nil
    }
    
    /**
    Drops longest prefix of elements that satisfy a predicate. Note: might return different results for different runs, as the underlying collection type is unordered.
    
    :param: n Number of elements to be excluded from the selection
    
    :returns: The longest suffix of this map whose first element does not satisfy the predicate p.
    */
    public func dropWhile(p: (Key, Value) -> Bool) -> Map {
        if let firstIndex = findFirstIndexToNotSatisfyPredicate(p) {
            return self.drop(firstIndex)
        }
        return self
    }
    
    /**
    :returns: Returns the first element of this map (if there are any). Note: might return different results for different runs, as the underlying collection type is unordered.
    */
    public func head() -> (Key, Value)? {
        if let headKey = self.internalDict.keys.first {
            return (headKey, self[headKey]!)
        }
        return nil
    }
    
    /**
    :returns: Returns all elements except the last (equivalent to Scala's init()). Note: might return different results for different runs, as the underlying collection type is unordered.
    */
    public func initSegment() -> Map {
        return self.dropRight(1)
    }
    
    /**
    :returns: Returns the last element as an optional value, or nil if any. Note: might return different results for different runs, as the underlying collection type is unordered.
    */
    public func last() -> (Key, Value)? {
        if let lastKey = self.keys.last {
            return (lastKey, self[lastKey]!)
        }
        return nil
    }
    
    /**
    Removes the provided key from the current map, and returns a new map without that key/value binding. Also an optional containing the value bound to the key.
    
    :param: key The key to remove
    */
    public func remove(key: HashableAny) -> (Map, Value?) {
        let map = self
        let value = self[key]
        return (map - key, value)
    }
    
    /**
    Removes the provided key from the current map, and returns an optional containing the value bound to that key.
    
    :param: key The key to remove
    */
    public mutating func remove(key: HashableAny) -> Value? {
        let value = self[key]
        self = self - key
        return value
    }
    
    /** 
    :returns: A map containing all the elements of the current one except the last.
    */
    public func tail() -> Map {
        return self.dropRight(1)
    }
    
    /**
    :returns: A map containing the first n elements.
    */
    public func take(n: Int) -> Map {
        return self.dropRight(self.size - n)
    }
    
    /**
    :returns: A map containing the last n elements.
    */
    public func takeRight(n: Int) -> Map {
        return self.drop(self.size - n)
    }
    
    /**
    :returns: A map containing the longest prefix of elements that satisfy a predicate.
    */
    public func takeWhile(p: (Key, Value) -> Bool) -> Map {
        if let firstIndex = findFirstIndexToNotSatisfyPredicate(p) {
            return self.dropRight(firstIndex)
        }
        return self
    }
    
    /**
    :returns: An array of tuples containing each key and value for every element in the map.
    */
    public func toArray() -> [(Key, Value)] {
        return travToArray(self)
    }
}

// MARK: - numeric operations
extension Map {
    private func convertValueToNumber(value: Value) -> Double? {
        switch value {
        case let number as Double: return number
        case let number as Int: return Double(number)
        case let numberString as String:
            if let number = NSNumberFormatter().numberFromString(numberString) {
                return number.doubleValue
            }
            return nil
        default: return nil
        }
    }
    
    /**
    Applies a binary numeric operation to each value contained in the map, if it's castable to a number. If a value contains a String representation of a number, its content will be converted to a Double value suitable for the multiplication. Any other value will be ignored.
    */
    public func applyNumericOperation(initialValue: Double, f: (Double, Double) -> Double) -> Double {
        return self.reduce(initialValue, combine: { (currentTotal: Double, currentItem: (Key, Value)) -> Double in
            if let number = self.convertValueToNumber(currentItem.1) {
                return f(currentTotal, number)
            }
            return currentTotal
        })
    }
    
    /**
    :returns: The product of the multiplication of each value contained in the map, if it's castable to a number. If a value contains a String representation of a number, its content will be converted to a Double value suitable for the multiplication. Any other value will be ignored.
    */
    public func product() -> Double {
        return self.applyNumericOperation(1, *)
    }
    
    /**
    :returns: The product of the sum of each value contained in the map, if it's castable to a number. If a value contains a String representation of a number, its content will be converted to a Double value suitable for the multiplication. Any other value will be ignored.
    */
    public func sum() -> Double {
        return self.applyNumericOperation(0, +)
    }
    
    /**
    :returns: Returns the maximum value of the results of applying the function `f` to each element of the map as an optional value, or nil if the map is empty. The result type of `f` is expected to return a type conforming to the Comparable protocol.
    */
    public func maxBy<U: Comparable>(f: (Value) -> U) -> (Key, Value)? {
        return comparisonBy(f, compareFunction: { $1 > $0 })
    }
    
    /**
    :returns: Returns the minimum value of the results of applying the function `f` to each element of the map as an optional value, or nil if the map is empty. The result type of `f` is expected to return a type conforming to the Comparable protocol.
    */
    public func minBy<U: Comparable>(f: (Value) -> U) -> (Key, Value)? {
        return comparisonBy(f, compareFunction: { $1 < $0 })
    }
    
    private func comparisonBy<U: Comparable>(f: (Value) -> U, compareFunction: (x: U, y: U) -> Bool) -> (Key, Value)? {
        if !self.isEmpty() {
            let keys = self.keys
            if let firstKey = keys.first {
                return self.reduce((firstKey, self[firstKey]!), combine: { (currentMax: (Key, Value), currentItem: (Key, Value)) -> (Key, Value) in
                    if compareFunction(x: f(currentMax.1), y: f(currentItem.1)) {
                        return currentItem
                    }
                    return currentMax
                })
            }
        }
        return nil
    }
}

// MARK: - string operations
extension Map {
    /**
    Generate a string composed by the different values contained in the map, concatenated.
    
    :param: separator A string used to separate each element to be concatenated. If it's a nil, the different strings are not separated.
    
    :returns: A string containing all the different values contained in the map. If the map contains String values, they'll be concatenated as such. If not, addString relies on String interpolation to perform the concatenation.
    */
    public func addString(separator: String?) -> String {
        let separatorToUse = (separator == nil) ? "" : separator!
        let result = self.reduceByValue("", combine: { (result: String, currentValue: T) -> String in
            switch currentValue {
            case let stringValue as String: return result + stringValue + separatorToUse
            default: return result + "\(currentValue)" + separatorToUse
            }
        })
        if separatorToUse == "" {
            return result
        }
        return result.substringToIndex(result.endIndex.predecessor())
    }
}

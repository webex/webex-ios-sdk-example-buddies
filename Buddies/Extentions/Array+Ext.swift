// Copyright 2016-2019 Cisco Systems Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

extension Array {
    
    mutating func push(newElement: Element) {
        self.append(newElement)
    }
    
    mutating func pop() -> Element? {
        if (self.isEmpty) {
            return nil;
        }
        return self.removeLast()
    }
    
    func peek() -> Element? {
        return self.last;
    }
    
    func safeObjectAtIndex(_ index: Int) -> Element? {
        return index >= 0 && index < count ? self[index] : nil
    }
    
    func safeLastAtIndex(index: Int) -> Element? {
        return self.safeObjectAtIndex(self.count - index - 1);
    }
    
    func find(equality: (Element) -> Bool) -> Element? {
        for element in self {
            if equality(element) {
                return element
            }
        }
        return nil
    }
    
    func indexOfEquatable(_ equality: (Element) -> Bool) -> Int? {
        for (idx, element) in self.enumerated() {
            if equality(element) {
                return idx
            }
        }
        return nil
    }
    
    func indexOfEquatable <U: Equatable> (item: U) -> Int? {
        if item is Element {
            return self.index(where: { (object) -> Bool in
                return (object as! U) == item
            })
        }
        return nil
    }
    
    func lastIndexOf <U: Equatable> (item: U) -> Int? {
        if item is Element {
            for (index, value) in self.lazy.reversed().enumerated() {
                if value as! U == item {
                    return count - 1 - index
                }
            }
            return nil
        }
        return nil
    }
        
    func all (test: (Element) -> Bool) -> Bool {
        for item in self {
            if !test(item) {
                return false
            }
        }
        return true
    }
    
    func unique <T: Equatable> () -> [T] {
        var result = [T]()
        for item in self {
            if !result.contains(item as! T) {
                result.append(item as! T)
            }
        }
        return result
    }
    
    func objectAtCircleIndex(index: Int) -> Element {
        return self[self.superCircle(index, size: self.count)]
    }
    
    func superCircle(_ idx: Int, size maxSize: Int) -> Int {
        var index = idx;
        if index < 0 {
            index = index % maxSize
            index += maxSize
        }
        if index >= maxSize {
            index = index % maxSize
        }
        return index
    }
    
    mutating func moveObjectFromIndex(from: Int, toIndex to: Int) {
        if to != from {
            let obj: Element = self.safeObjectAtIndex(from)!
            self.remove(at: from)
            if to >= self.count {
                self.append(obj)
            }
            else {
                self.insert(obj, at: to)
            }
        }
    }
    
    mutating func removeObject<U: Equatable>(object: U) -> Bool {
        for (idx, objectToCompare) in self.enumerated() {  //in old swift use enumerate(self)
            if let to = objectToCompare as? U {
                if object == to {
                    self.remove(at: idx)
                    return true
                }
            }
        }
        return false
    }
    
    mutating func removeObject(equality: (Element) -> Bool) -> Element? {
        for (idx, element) in self.enumerated() {
            if equality(element) {
                return self.remove(at: idx);
            }
        }
        return nil
    }
    
    func objectsAtIndexes(indexes: NSIndexSet) -> [Element] {
        let elements: [Element] = indexes.map{ (idx) in
            if idx < self.count {
                return self[idx]
            }
            return nil
            }.flatMap{ $0 }
        return elements
    }
    
}

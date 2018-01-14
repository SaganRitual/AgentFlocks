//
// Created by Rob Bishop on 1/11/18
//
// Copyright © 2018 Rob Bishop
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//

class AFOrderedMap<KeyType: Hashable, ValueType: Equatable> {
    var keys = [KeyType]()
    var map = [KeyType : ValueType]()
    
    var count: Int { return keys.count }

    func append(key: KeyType, value: ValueType) {
        keys.append(key)
        map[key] = value
    }
    
    func contains(_ name: KeyType) -> Bool {
        return keys.contains(name)
    }
    
    func getIndexOf(_ key: KeyType) -> Int? {
        return keys.index(of: key)
    }
    
    func getIndexOf(_ value: ValueType) -> Int? {
        var index: Int?
        
        for (k, v) in map {
            if v == value {
                index = getIndexOf(k)
                break
            }
        }
        
        return index
    }

    func getValue(at index: Int) -> ValueType {
        let key = keys[index]
        return map[key]!
    }
    
    func getValue(for key: KeyType) -> ValueType {
        return map[key]!
    }
    
    func remove(at index: Int) {
        let key = keys[index]
        keys.remove(at: index)
        map.removeValue(forKey: key)
    }
    
    func remove(_ name: KeyType) {
        let ix = keys.index(of: name)!
        keys.remove(at: ix)
        map.removeValue(forKey: name)
    }
    
    func reversed() -> [ValueType] {
        var result = [ValueType]()
        keys.reversed().forEach { result.append(map[$0]!) }
        return result
    }
    
    subscript(_ ix: Int) -> ValueType { return getValue(at: ix) }
    subscript(_ key: KeyType) -> ValueType { return getValue(for: key) }
}

extension AFOrderedMap: Sequence {
    func makeIterator() -> AFOrderedMap.Iterator {
        return AFOrderedMap.Iterator(orderedMap: self, current: 0)
    }
    
    struct Iterator: IteratorProtocol {
        let orderedMap: AFOrderedMap<KeyType, ValueType>
        var current = 0
        
        mutating func next() -> ValueType? {
            guard current < orderedMap.keys.count else { return nil }

            defer { current += 1 }
            let key = orderedMap.keys[current]
            let value = orderedMap.map[key]!
            return orderedMap.keys.count > current ? value : nil
        }
    }
}


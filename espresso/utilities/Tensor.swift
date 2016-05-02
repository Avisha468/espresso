//
//  Tensor.swift
//  espresso
//
//  Created by Zhihao Li on 4/12/16.
//  Copyright © 2016 CMU. All rights reserved.
//

import Foundation
import Metal

/** @brief Basic storage class
 *  Tensor is a multidimensional matrix. This serves as the fundamental storage class.
 *  Tensor can take arbitrary type of data and when using, should be initialized with the dimension.
 */
public class Tensor {
  public typealias DataType = Float

  public var storage : [DataType] = []
  public var mtlStorage : MTLBuffer!

  public private(set) var dimensions : [Int] = []
  public private(set) var numel : Int = 0
  public var capacity : Int {
    // a better way may be storage.capacity, but how to?
    return self.storage.count
  }
  var indexAuxilary: [Int] = []

  /**
   * Initialize the Tensor with dimensionalities
   */
  public init() {}

  public init(dimensions: [Int]) {
    reshape(dimensions)
  }

  func index(idxs: [Int]) -> Int {
    var idx = 0
    for i in idxs.indices {
      idx += indexAuxilary[i] * idxs[i]
    }
    return idx
  }

  public func count(fromDimension fromDimension: Int = 0, toDimension: Int = -1) -> Int {
    guard fromDimension < dimensions.count else {
      return 1
    }
    var toDimension = toDimension
    if toDimension < 0 {
      toDimension = dimensions.count + toDimension
    }
    assert(fromDimension <= toDimension)

    return self.dimensions[fromDimension...toDimension].reduce(1, combine: {$0 * $1})
  }

  public func reshape(dimensions: [Int]) {
    if self.dimensions == dimensions {
      return
    }
    let numNewElements = dimensions.count == 0 ? 0 : dimensions.reduce(1, combine: {$0 * $1})
    if self.capacity < numNewElements {
      self.storage = Array(count: numNewElements, repeatedValue: 0)
    }
    self.dimensions = dimensions
    self.numel = numNewElements
    assert(self.numel >= 0)

    if self.numel != 0 {
      self.indexAuxilary = [1]
      for d in dimensions.reverse() {
        indexAuxilary.append(d * indexAuxilary.last!)
      }
      assert(indexAuxilary.last! == self.numel, "number of elements in Tensor doesn't match")
      indexAuxilary.removeLast()
      indexAuxilary = indexAuxilary.reverse()
    } else {
      // FIXME: bad hack?
      self.indexAuxilary = []
    }
  }

  public func reset(val: DataType) {
    for i in 0 ..< self.numel {
      self.storage[i] = val
    }
  }

  public subscript(idxs: Int...)->DataType {
    get {
      // May be exceptions
      return self.storage[index(idxs)]
    }

    set(newValue) {
      self.storage[index(idxs)] = newValue
    }
  }
  
}
//
//  ReluLayer.swift
//  espresso
//
//  Created by Jerry Zhang on 4/14/16.
//  Copyright © 2016 CMU. All rights reserved.
//

import Foundation
import Metal

/** @brief ReLU layer.
 */
public class ReluLayer: ForwardLayerProtocol, BackwardLayerProtocol {
  public var name : String {
    return parameters.name
  }

  public var dependencies: [String] {
    return self.parameters.dependencies
  }

  public var output: Tensor = Tensor()
  public var gradient: Tensor = Tensor()
  var parameters : ReLUParameters
  var forwardMethod: ForwardLayerMethodType? = nil
  var backwardMethod: BackwardLayerMethodType? = nil

  public init(parameters: ReLUParameters) {
    self.parameters = parameters
  }

  func layerSetUp(engine engine: NetworkProperties.NetworkEngine,
                         bottomDimensions: [[Int]]? = nil) {
    switch engine {
    case .CPU:
      self.forwardMethod = forwardCPU
    case .GPU:
      self.forwardMethod = forwardGPU
    }

    self.reshapeByBottomDimensions(bottomDimensions!) // may exception (should not)
  }

  func reshapeByBottomDimensions(bottomDimensions: [[Int]]) {
    let oneBottomDimensionsSample = bottomDimensions[0]

    self.output.reshape(oneBottomDimensionsSample)
//    self.gradient.reshape(oneBottomDimensionsSample)
  }

  func forwardCPU(bottom: [Tensor]?) {
    if let bottom = bottom where bottom.count > 0 {
      let bottom = bottom[0] // in softmax layer, bottom is really just a single Tensor

      for index in bottom.storage.indices {
        output.storage[index] = max(0, bottom.storage[index]) + self.parameters.negativeSlope * min(0, bottom.storage[index])
      }
    }
  }

  func forwardGPU(bottom: [Tensor]?) {
    forwardCPU(bottom)
  }
}

public struct ReLUParameters : LayerParameterProtocol {
  public let name : String
  public let dependencies: [String]
  public var negativeSlope : Tensor.DataType
  public init(name: String,
              dependencies: [String],
              negativeSlope: Tensor.DataType = 0) {
    self.negativeSlope = negativeSlope
    self.name = name
    self.dependencies = dependencies
  }
}
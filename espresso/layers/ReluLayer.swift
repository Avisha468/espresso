//
//  ReluLayer.swift
//  espresso
//
//  Created by Jerry Zhang on 4/14/16.
//  Copyright © 2016 CMU. All rights reserved.
//

import Foundation

/** @brief ReLU layer.
 */
public class ReluLayer: ForwardBackwardLayerProtocol {
  public var name : String
  var parameters : ReLUParameters
  var negativeSlope : Tensor.DataType
  public init(name: String = "relu", parameters: ReLUParameters) {
    self.name = name
    self.parameters = parameters
    self.negativeSlope = parameters.negativeSlope
  }
  // Implement protocols
}

public struct ReLUParameters : LayerParameterProtocol {
  public var negativeSlope : Tensor.DataType
  public init(negativeSlope: Tensor.DataType = 0) {
    self.negativeSlope = negativeSlope
  }
}
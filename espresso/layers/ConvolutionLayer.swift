//
//  ConvolutionLayer.swift
//  espresso
//
//  Created by Jerry Zhang on 4/14/16.
//  Copyright © 2016 CMU. All rights reserved.
//

import Foundation

/** @brief Convolution layer.
 */
public class ConvolutionLayer: ForwardLayerProtocol, BackwardLayerProtocol, TrainableLayerProtocol {
  public var name : String
  public var output : [Tensor]
  public var gradient : [Tensor]
  public var weights: Tensor
  var parameters: ConvolutionParameters

  public init(name : String = "conv", parameters: ConvolutionParameters) {
    self.name = name
    self.parameters = parameters
    self.weights = Tensor(dimensions: [parameters.numNeurons, /* TODO: #Channels, */ parameters.kernelSize, parameters.kernelSize])
    self.output = [] // Not initialized, needs to be resized
    self.gradient = []
  }

  public func reshape(bottomDimensions: [Int]?) {
    // Resize output and gradient
  }

  public func forward(bottom: [Tensor]?) {

  }

  public func backward(top: [Tensor]?) {

  }

  public func initWeights() {

  }

  public func updateWeights(weightGrad: Tensor) {

  }

  func forward_cpu(bottom: [Tensor]?) {

  }

  func forward_gpu(bottom: [Tensor]?) {
    forward_cpu(bottom)
  }

  func backward_cpu(top: [Tensor]?) {

  }

  func backward_gpu(top: [Tensor]?) {
    backward_cpu(top)
  }

}

public struct ConvolutionParameters: LayerParameterProtocol {
  public let numNeurons : Int
  public let kernelSize : Int
  public let stride : Int
  public let padSize : Int
  public let isBiasTerm : Bool
  public let biasLRMultiplier : Tensor.DataType // learning rate multiplier
  public let weightLRMultiplier : Tensor.DataType // learning rate multiplier
  public let weightFiller : WeightFiller
  public let biasFiller : WeightFiller
  public init(numNeurons: Int,
              kernelSize: Int,
              stride: Int = 1,
              padSize: Int = 0,
              isBiasTerm: Bool = true,
              biasLRMultiplier : Tensor.DataType = 1,
              weightLRMultiplier : Tensor.DataType = 1,
              weightFiller: WeightFiller = gaussianWeightFiller(mean: 0, std: 1),
              biasFiller: WeightFiller = gaussianWeightFiller(mean: 0, std: 1)) {
    self.numNeurons = numNeurons
    self.kernelSize = kernelSize
    self.stride = stride
    self.padSize = padSize
    self.isBiasTerm = isBiasTerm
    self.weightFiller = weightFiller
    self.biasFiller = biasFiller
    self.biasLRMultiplier = biasLRMultiplier
    self.weightLRMultiplier = weightLRMultiplier
  }
}
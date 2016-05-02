//
//  FullyConnectedLayer.swift
//  espresso
//
//  Created by Jerry Zhang on 4/14/16.
//  Copyright © 2016 CMU. All rights reserved.
//

import Foundation
import Metal

/** @brief Fully connected layer.
 */
public class FullyConnectedLayer: ForwardLayerProtocol, BackwardLayerProtocol, TrainableLayerProtocol {
  public var name : String {
    return parameters.name
  }

  public var dependencies: [String] {
    return self.parameters.dependencies
  }

  public var metalDevice: MTLDevice!
  public var metalCommandQueue: MTLCommandQueue!
  public var metalDefaultLibrary: MTLLibrary!


  public var output: Tensor = Tensor()
  public var gradient: Tensor = Tensor()
  public var weights: Tensor = Tensor()
  public var bias: Tensor = Tensor()
  var parameters : FullyConnectedParameters
  var forwardMethod: ForwardLayerMethodType? = nil
  var backwardMethod: BackwardLayerMethodType? = nil

  public init(parameters: FullyConnectedParameters) {
    self.parameters = parameters
  }

  func layerSetUp(engine engine: NetworkProperties.NetworkEngine,
                         bottomDimensions: [[Int]],
                         metalDevice: MTLDevice!,
                         metalDefaultLibrary: MTLLibrary!,
                         metalCommandQueue: MTLCommandQueue!) {
    switch engine {
    case .CPU:
      self.forwardMethod = forwardCPU
    case .GPU:
      self.forwardMethod = forwardGPU
    }
    self.metalDevice = metalDevice
    self.metalDefaultLibrary = metalDefaultLibrary
    self.metalCommandQueue = metalCommandQueue
    self.reshapeByBottomDimensions(bottomDimensions) // may exception (should not)
  }

  func reshapeByBottomDimensions(bottomDimensions: [[Int]]) {
    let oneBottomDimensionsSample = bottomDimensions[0]
    // subject to change, currently just 4 dimensions
    let batchSize = oneBottomDimensionsSample[0]
    let channels = self.parameters.numOutput

    var weightDimensions = oneBottomDimensionsSample
    weightDimensions[0] = channels // change batchSize to channels of current layer, hacky
    self.weights.reshape(weightDimensions)
    if (self.parameters.isBiasTerm) {
      self.bias.reshape([channels])
    }
    self.output.reshape([batchSize, channels])
//    self.gradient.reshape([batchSize, channels])
  }

  func forwardCPU(bottom: [Tensor]) {
    // Preprocess bottom to fit this layer
    if bottom.count > 0 {
      let bottom = bottom[0] // in fc layer, bottom is really just a single Tensor

      let batchSize = bottom.dimensions[0]
      let numOutput = parameters.numOutput

      let numElementsPerBatch = bottom.count(fromDimension: 1)
      assert(numElementsPerBatch == self.weights.count() / numOutput, "Num elements not match")

      for currentBatch in 0 ..< batchSize {
        for currentOutput in 0 ..< numOutput {
          var tmpResult : Tensor.DataType = 0
          // FIXME: bad API design
          for i in 0 ..< numElementsPerBatch {
            let index = currentOutput * numElementsPerBatch + i
            // FIXME: Hack
            tmpResult += self.weights.storage[index] * bottom.storage[currentBatch * numElementsPerBatch + i]
          }
          self.output[currentBatch, currentOutput] = tmpResult
        }
      }
    }
  }

  func forwardGPU(bottom: [Tensor]) {
    if (bottom.count > 0) {
      let bottom = bottom[0]
      let commandBuffer = self.metalCommandQueue.commandBuffer()

      let numOutput = parameters.numOutput
      let numElementsPerBatch = bottom.count(fromDimension: 1)
      // copy the parameters to metal
      let paramBuffer = createFullyConnectedParameter(MetalFullyConnectedParameter(numOutput: numOutput, numElementsPerBatch: numElementsPerBatch), metalDevice: self.metalDevice)
      // perform computation
      submitComputeJob("fullyConnectedForward", paramBuffer: paramBuffer, metalDefaultLibrary: self.metalDefaultLibrary, metalDevice: self.metalDevice, inputData: bottom, outputData: self.output, commandBuffer: commandBuffer)
      commandBuffer.waitUntilCompleted()
    }
  }
}

public struct FullyConnectedParameters : LayerParameterProtocol {
  public let name : String
  public let dependencies: [String]
  public let numOutput : Int
  public let isBiasTerm : Bool
  public let biasLRMultiplier : Tensor.DataType // learning rate multiplier
  public let weightLRMultiplier : Tensor.DataType // learning rate multiplier
  public let weightFiller : WeightFiller
  public let biasFiller : WeightFiller
  public init(name: String,
              dependencies: [String],
              numOutput: Int,
              isBiasTerm: Bool = true,
              biasLRMultiplier : Tensor.DataType = 1,
              weightLRMultiplier : Tensor.DataType = 1,
              weightFiller: WeightFiller = gaussianWeightFiller(mean: 0, std: 1),
              biasFiller: WeightFiller = gaussianWeightFiller(mean: 0, std: 1)) {
    self.name = name
    self.dependencies = dependencies
    self.numOutput = numOutput
    self.isBiasTerm = isBiasTerm
    self.weightFiller = weightFiller
    self.biasFiller = biasFiller
    self.biasLRMultiplier = biasLRMultiplier
    self.weightLRMultiplier = weightLRMultiplier
  }
}
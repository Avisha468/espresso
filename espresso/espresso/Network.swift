//
//  Net.swift
//  espresso
//
//  Created by Jerry Zhang on 4/14/16.
//  Copyright © 2016 CMU. All rights reserved.
//

import Foundation
import Metal


/** @brief Neural network.
 */
public class Network {
  var layers : [LayerProtocol]
  public var parameters : NetworkProperties
  var layerDependencyMapping : [Int : [Int]]
  var layerNameIndexMapping : [String : Int]
  var dependenciesOfLayer : [Int]
  // Metal
  public var metalDevice: MTLDevice!
  public var metalDefaultLibrary: MTLLibrary!
  public var metalCommandQueue: MTLCommandQueue!

  public init(parameters: NetworkProperties) {
    self.layers = []
    self.parameters = parameters
    self.layerDependencyMapping = [:]
    self.layerNameIndexMapping = [:]
    self.dependenciesOfLayer = []
    if parameters.engine == .GPU {
      // Initialize gpu
      metalDevice = MTLCreateSystemDefaultDevice()

      // Queue to handle an ordered list of command buffers
      metalCommandQueue = metalDevice.newCommandQueue()

      // Access to Metal functions that are stored in .metal file
      metalDefaultLibrary = metalDevice.newDefaultLibrary()
    }
  }

  public func add(layer: AnyObject) {
    var layer = layer as! LayerProtocol // make layer mutable
    var bottomDimensions : [[Int]] = []
    let currentLayerIndex = layers.count
    let currentLayerName = layer.name
    let currentLayerDependencies = layer.dependencies
    self.dependenciesOfLayer.append(0)

    layerNameIndexMapping[currentLayerName] = currentLayerIndex
    layerDependencyMapping[currentLayerIndex] = []
    for depName in currentLayerDependencies {
      let depIndex = layerNameIndexMapping[depName]!
      self.dependenciesOfLayer[depIndex] += 1
      layerDependencyMapping[currentLayerIndex]?.append(depIndex)
      bottomDimensions.appendContentsOf(((layers[depIndex] as! ForwardLayerProtocol).outputDimensions()))
    }

    self.layers.append(layer)
    layer.layerSetUp(engine: self.parameters.engine, bottomDimensions: bottomDimensions, metalDevice: self.metalDevice, metalDefaultLibrary: self.metalDefaultLibrary, metalCommandQueue: self.metalCommandQueue)
  }

  public func forward() -> Tensor {
    var unfulfilledDependencies = self.dependenciesOfLayer
    for index in self.layers.indices {
      var toBePurgedLayers : [ForwardLayerProtocol] = []
      var layer = self.layers[index] as! ForwardLayerProtocol // may exception, but should not

      var bottom : [Tensor] = []
      for dep in layerDependencyMapping[index]! {
        //bottom.append((layers[dep] as! ForwardLayerProtocol).output)
        let tmp = (layers[dep] as! ForwardLayerProtocol).output
        if (metalDevice != nil) {
          tmp.getFromMetal()
        }
        bottom.append(tmp)
      }
      layer.forward(bottom)

      for var dep in toBePurgedLayers {
        dep.purgeOutput()
      }
    }
    // FIXME: temp
    return (self.layers.last as! ForwardLayerProtocol).output
  }

  public func backward() {
    // TODO
  }

  public func update() {
    // Update all the learnable parameters
    /**
     *  In Caffe, Network stores pointers to all the learnable parameters, outputs and gradients.
     */
  }

}

public struct NetworkProperties {

  public enum NetworkEngine {
    case GPU
    case CPU
  }

  public let batchSize : Int
  public let engine : NetworkEngine
  public init(batchSize: Int = 1,
              engine: NetworkEngine = .CPU) {
    self.batchSize = batchSize
    self.engine = engine
  }
}
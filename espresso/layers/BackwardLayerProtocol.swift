//
//  ForwardBackwardLayer.swift
//  espresso
//
//  Created by Jerry Zhang on 4/14/16.
//  Copyright © 2016 CMU. All rights reserved.
//

import Foundation

/** @brief Protocol for Backward Layers
 */
protocol BackwardLayerProtocol : LayerProtocol {
  var gradient: [Tensor] { get set }

  func backward(topOpt: [Tensor]?)
  func backwardCPU(topOpt: [Tensor]?)
  func backwardGPU(topOpt: [Tensor]?)
}

extension BackwardLayerProtocol {
  func backward(topOpt: [Tensor]?) {
    switch engine {
    case .CPU:
      backwardCPU(topOpt)
    case .GPU:
      backwardGPU(topOpt)
    }
  }

  func backwardGPU(topOpt: [Tensor]?) {
    backwardCPU(topOpt)
  }
}
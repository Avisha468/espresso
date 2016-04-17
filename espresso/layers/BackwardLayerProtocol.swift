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

  func backward(top: [Tensor]?)
  func backward_cpu(top: [Tensor]?)
  func backward_gpu(top: [Tensor]?)
}

extension BackwardLayerProtocol {
  func backward(top: [Tensor]?) {
    switch engine {
    case .CPU:
      backward_cpu(top)
    case .GPU:
      backward_gpu(top)
    }
  }

  func backward_gpu(top: [Tensor]?) {
    backward_cpu(top)
  }
}
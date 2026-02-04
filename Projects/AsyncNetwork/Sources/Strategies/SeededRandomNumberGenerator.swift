//
//  SeededRandomNumberGenerator.swift
//  AsyncNetworkCore
//
//  Created by jimmy on 2026/02/03.
//

import Foundation

/// 시드(Seed)를 지원하는 난수 생성기.
///
/// 동일한 시드로 초기화하면 항상 동일한 난수 시퀀스를 생성합니다.
/// 테스트의 결정론적(Deterministic) 실행을 보장하기 위해 사용됩니다.
///
/// - Note: PCG (Permuted Congruential Generator) 또는 SplitMix64 알고리즘 등을 사용할 수 있으나,
///         여기서는 간단한 선형 합동 생성기(LCG)를 사용하여 구현합니다.
///         암호학적으로 안전하지 않으므로 테스트 목적으로만 사용해야 합니다.
public struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    public init(seed: Int) {
        self.state = UInt64(bitPattern: Int64(seed))
    }
    
    public mutating func next() -> UInt64 {
        // Linear Congruential Generator (LCG) constants
        // M = 2^64, A = 6364136223846793005, C = 1442695040888963407
        // Knuth's MMIX constants
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

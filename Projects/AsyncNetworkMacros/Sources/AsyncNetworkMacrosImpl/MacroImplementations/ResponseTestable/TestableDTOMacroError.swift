//
//  TestableDTOMacroError.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/29.
//

/// @ResponseTestable 매크로 에러 타입
enum TestableDTOMacroError: Error, CustomStringConvertible {
    case notAStruct
    case notCodable
    case invalidFixtureJSON

    var description: String {
        switch self {
        case .notAStruct:
            return "@ResponseTestable can only be applied to struct declarations"
        case .notCodable:
            return "@ResponseTestable requires the type to conform to Codable"
        case .invalidFixtureJSON:
            return "fixtureJSON must be a valid JSON string"
        }
    }
}

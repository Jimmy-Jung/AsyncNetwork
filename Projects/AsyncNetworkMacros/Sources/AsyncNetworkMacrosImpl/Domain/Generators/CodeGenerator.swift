//
//  CodeGenerator.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

import SwiftSyntax

/// 코드 생성을 위한 프로토콜
///
/// 이 프로토콜은 매크로에서 생성할 멤버 선언을 생성하는 인터페이스를 정의합니다.
/// 각 Generator는 특정 유형의 코드 생성에 대한 책임을 가지며,
/// 이를 통해 코드 생성 로직을 모듈화하고 테스트 가능하게 만듭니다.
///
/// ## 사용 예시
/// ```swift
/// let generator = PropertyGenerator(args: macroArguments)
/// let declarations = generator.generate()
/// ```
public protocol CodeGenerator {
    /// 멤버 선언을 생성합니다.
    ///
    /// - Returns: 생성된 선언 배열
    func generate() -> [DeclSyntax]
}

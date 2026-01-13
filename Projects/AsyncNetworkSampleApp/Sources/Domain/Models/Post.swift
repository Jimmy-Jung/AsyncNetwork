//
//  Post.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import Foundation

/// 포스트 도메인 모델
///
/// JSONPlaceholder API의 Post를 표현하는 도메인 엔티티입니다.
/// 비즈니스 로직에서 사용되며 외부 의존성이 없는 순수한 모델입니다.
struct Post: Sendable, Equatable, Identifiable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}


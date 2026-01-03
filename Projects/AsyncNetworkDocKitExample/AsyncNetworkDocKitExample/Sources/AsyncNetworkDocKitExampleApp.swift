//
//  AsyncNetworkDocKitExampleApp.swift
//  AsyncNetworkDocKitExample
//
//  Created by jimmy on 2026/01/01.
//

import AsyncNetworkDocKit
import SwiftUI

@main
@available(iOS 17.0, *)
struct AsyncNetworkDocKitExampleApp: App {
    let networkService = NetworkService()

    init() {
        // 모든 @DocumentedType 타입을 미리 등록
        // 이렇게 해야 중첩 타입들도 TypeRegistry에 등록되어 UI에서 펼쳐볼 수 있습니다
        registerAllTypes()
    }

    var body: some Scene {
        DocKitFactory.createDocApp(
            endpoints: [
                "Posts": [
                    GetAllPostsRequest.metadata,
                    GetPostByIdRequest.metadata,
                    CreatePostRequest.metadata,
                    UpdatePostRequest.metadata,
                    DeletePostRequest.metadata,
                ],
                "Users": [
                    GetAllUsersRequest.metadata,
                    GetUserByIdRequest.metadata,
                    CreateUserRequest.metadata,
                ],
                "Comments": [
                    GetPostCommentsRequest.metadata,
                    CreateCommentRequest.metadata,
                ],
                "Albums": [
                    GetUserAlbumsRequest.metadata,
                    GetAlbumPhotosRequest.metadata,
                ],
                "Orders": [
                    CreateOrderRequest.metadata,
                    GetOrderRequest.metadata,
                ],
                "Profile": [
                    UpdateProfileRequest.metadata,
                ],
                "Search": [
                    SearchRequest.metadata,
                ],
            ],
            networkService: networkService,
            appTitle: "AsyncNetwork API Documentation"
        )
    }

    /// 모든 @DocumentedType 타입을 등록합니다
    ///
    /// Swift의 제약으로 타입 이름만으로는 타입을 찾을 수 없어,
    /// 모든 타입의 typeStructure를 명시적으로 참조하여 등록을 트리거합니다.
    private func registerAllTypes() {
        _ = Post.typeStructure
        _ = PostBody.typeStructure
        _ = User.typeStructure
        _ = Address.typeStructure
        _ = Geo.typeStructure
        _ = Company.typeStructure
        _ = UserBody.typeStructure
        _ = Comment.typeStructure
        _ = CommentBody.typeStructure
        _ = Album.typeStructure
        _ = Photo.typeStructure
        _ = Order.typeStructure
        _ = OrderItem.typeStructure
        _ = ShippingAddress.typeStructure
        _ = PaymentMethod.typeStructure
        _ = CreateOrderBody.typeStructure
        _ = OrderItemInput.typeStructure
        _ = PaymentMethodInput.typeStructure
        _ = UserProfile.typeStructure
        _ = UserPreferences.typeStructure
        _ = NotificationSettings.typeStructure
        _ = PrivacySettings.typeStructure
        _ = SocialLinks.typeStructure
        _ = UserStats.typeStructure
        _ = Badge.typeStructure
        _ = UpdateProfileBody.typeStructure
        _ = SearchResult.typeStructure
        _ = SearchItem.typeStructure
        _ = Author.typeStructure
        _ = Facet.typeStructure
        _ = FacetValue.typeStructure
        _ = SearchFilterBody.typeStructure
        _ = SearchFilters.typeStructure
        _ = DateRange.typeStructure
        _ = PriceRange.typeStructure
        _ = SortOptions.typeStructure
        _ = PaginationOptions.typeStructure
    }
}

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
        // 모든 DocumentedType 타입들을 강제로 참조하여 TypeRegistry에 등록
        registerAllDocumentedTypes()
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

    private func registerAllDocumentedTypes() {
        // Response 타입들의 typeStructure를 호출하여 등록 강제 실행
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

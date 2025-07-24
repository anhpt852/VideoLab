//
//  VLEPickerFetchAssetManager.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/9/14.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import Foundation
import Photos

class VLEPickerFetchAssetManager: NSObject {

    class func fetchAlbums() -> VLEPickerAlbumListModel? {
        let option = PHFetchOptions()
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)

        var fallbackModel: VLEPickerAlbumListModel?
        var maxAssetCount = 0

        smartAlbums.enumerateObjects { collection, _, stop in
            let localizedTitle = collection.localizedTitle?.lowercased() ?? ""
            let result = PHAsset.fetchAssets(in: collection, options: option)

            // Cập nhật fallback nếu album hiện tại có nhiều ảnh hơn
            if result.count > maxAssetCount {
                maxAssetCount = result.count
                fallbackModel = VLEPickerAlbumListModel(
                    title: collection.localizedTitle ?? "默认",
                    result: result,
                    collection: collection,
                    option: option,
                    isCameraRoll: false
                )
            }

            // So sánh theo tiêu đề chứa từ khoá phổ biến
            if localizedTitle.contains("camera roll") ||
               localizedTitle.contains("all photos") ||
               localizedTitle.contains("tất cả ảnh") ||
               localizedTitle.contains("所有照片") ||
               localizedTitle.contains("recents") {

                let model = VLEPickerAlbumListModel(
                    title: collection.localizedTitle ?? "所有照片",
                    result: result,
                    collection: collection,
                    option: option,
                    isCameraRoll: true
                )
                stop.pointee = true
                fallbackModel = model
            }
        }

        return fallbackModel
    }


    class func fetchPhoto(in result: PHFetchResult<PHAsset>) -> [VLEPickerAssetModel] {
        var models: [VLEPickerAssetModel] = []
        result.enumerateObjects { asset, _, _ in
            models.append(VLEPickerAssetModel(asset: asset))
        }
        return models
    }
}

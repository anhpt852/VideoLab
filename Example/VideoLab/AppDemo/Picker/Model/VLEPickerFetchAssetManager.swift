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

        // Dùng subtype .smartAlbumUserLibrary trực tiếp
        let smartAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumUserLibrary,
            options: nil)

        guard let collection = smartAlbums.firstObject else {
            print("⚠️ Không tìm thấy smartAlbumUserLibrary trên iOS 18.5")
            return nil
        }

        let result = PHAsset.fetchAssets(in: collection, options: option)
        let albumModel = VLEPickerAlbumListModel(
            title: collection.localizedTitle ?? "所有照片",
            result: result,
            collection: collection,
            option: option,
            isCameraRoll: true)

        return albumModel
    }

    class func fetchPhoto(in result: PHFetchResult<PHAsset>) -> [VLEPickerAssetModel] {
        var models: [VLEPickerAssetModel] = []
        result.enumerateObjects { asset, _, _ in
            models.append(VLEPickerAssetModel(asset: asset))
        }
        return models
    }
}

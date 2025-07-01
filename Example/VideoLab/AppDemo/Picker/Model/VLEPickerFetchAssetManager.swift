//
//  VLEPickerFetchAssetManager.swift - Advanced Sort Options
//  VideoLab_Example
//

import Foundation
import Photos

enum VLEPhotoSortOrder {
    case newestFirst    // Mới → Cũ
    case oldestFirst    // Cũ → Mới
    case mediaType      // Video trước, Ảnh sau
}

class VLEPickerFetchAssetManager: NSObject {

    // ✅ PHƯƠNG THỨC CHÍNH VỚI TÙY CHỌN SORT
    class func fetchAlbums(sortOrder: VLEPhotoSortOrder = .newestFirst) -> VLEPickerAlbumListModel? {
        let option = PHFetchOptions()
        
        // ✅ THIẾT LẬP SORT THEO YÊU CẦU
        switch sortOrder {
        case .newestFirst:
            option.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false)
            ]
            print("📸 Sort: Newest → Oldest")
            
        case .oldestFirst:
            option.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: true)
            ]
            print("📸 Sort: Oldest → Newest")
            
        case .mediaType:
            option.sortDescriptors = [
                NSSortDescriptor(key: "mediaType", ascending: false), // Video trước
                NSSortDescriptor(key: "creationDate", ascending: false) // Trong cùng loại: mới trước
            ]
            print("📸 Sort: Videos first, then newest photos")
        }

        let smartAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumUserLibrary,
            options: nil)

        guard let collection = smartAlbums.firstObject else {
            print("⚠️ Không tìm thấy smartAlbumUserLibrary")
            return nil
        }

        let result = PHAsset.fetchAssets(in: collection, options: option)
        let albumModel = VLEPickerAlbumListModel(
            title: collection.localizedTitle ?? "All Photos",
            result: result,
            collection: collection,
            option: option,
            isCameraRoll: true)

        // ✅ VERIFY KẾT QUẢ
        logSortResult(result: result, sortOrder: sortOrder)
        return albumModel
    }
    
    // ✅ COMPATIBILITY: Giữ method cũ, default mới → cũ
    class func fetchAlbums() -> VLEPickerAlbumListModel? {
        return fetchAlbums(sortOrder: .newestFirst)
    }

    class func fetchPhoto(in result: PHFetchResult<PHAsset>) -> [VLEPickerAssetModel] {
        var models: [VLEPickerAssetModel] = []
        result.enumerateObjects { asset, _, _ in
            models.append(VLEPickerAssetModel(asset: asset))
        }
        return models
    }
    
    // ✅ HELPER: Log kết quả sort
    private class func logSortResult(result: PHFetchResult<PHAsset>, sortOrder: VLEPhotoSortOrder) {
        guard result.count > 0 else { return }
        
        let firstAsset = result.object(at: 0)
        let lastAsset = result.object(at: result.count - 1)
        
        print("📸 === SORT RESULT ===")
        print("📸 Total assets: \(result.count)")
        print("📸 First asset: \(firstAsset.mediaType.rawValue) - \(firstAsset.creationDate ?? Date())")
        print("📸 Last asset: \(lastAsset.mediaType.rawValue) - \(lastAsset.creationDate ?? Date())")
        print("📸 Sort order: \(sortOrder)")
        print("📸 ==================")
    }
}

//
//  CustomPhotoPickerView.swift
//  swiftuitest
//
//  Created by V8 on 11/11/22.
//

import Foundation
import Photos
import UIKit

extension Thread
{
    static func printCurrent()
    {
        print(" [Thread] - \(Thread.current) : \(OperationQueue.current?.underlyingQueue?.label ?? "None")")
    }
}

struct AlbumModel {
    let name: String
    let count: Int
    let collection: PHAssetCollection
    let localIdentifier: String
    
    init(collection: PHAssetCollection) {
        self.collection = collection
        self.name = collection.localizedTitle ?? ""
        self.localIdentifier = collection.localIdentifier
        self.count = collection.estimatedAssetCount
    }
}

class ResultModel
{
    var result = [AlbumModel]()
}

protocol PhotoPickerProtocol {
    func fetchAssets()
//    func fetchCollections()
    func requestAsset(asset: PHAsset, onComplete: @escaping (_ image:UIImage?) -> Void)
}

class CustomPhotoPicker : NSObject, PhotoPickerProtocol, ObservableObject
{
    var cachingSize : CGSize?
    var collections: [AlbumModel] = [AlbumModel]()
    var selectedAlbum: AlbumModel?
    var caching = PHCachingImageManager()
    let imageOptions = PHImageRequestOptions()
    private var permission : PHAuthorizationStatus = .notDetermined
    @Published var assets: [PHAsset] = [PHAsset]()
    @Published var test: [String] = [String]()
    
    override init()
    {
        imageOptions.deliveryMode = .fastFormat
        imageOptions.isNetworkAccessAllowed = false
        imageOptions.resizeMode = .fast
    }
    
    deinit {
        print("Deinit CustomPhotoPicker \n")
        caching.stopCachingImagesForAllAssets()
    }
    
    func grantPermission(onComplete: @escaping (_ permission: PHAuthorizationStatus) -> Void) {
        if #available(iOS 14, *)
        {
            permission = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch permission {
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: { [weak self] (status) in
                    self?.permission = status
                    onComplete(status)
                })
                break
            case .authorized, .limited:
                onComplete(permission)
                break
                
            default:
                onComplete(permission)
                break
            }
        }
        else
        {
            permission = PHPhotoLibrary.authorizationStatus()
            switch permission {
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { [weak self] (status) in
                    self?.permission = status
                    onComplete(status)
                }
                break
            case .authorized , .limited:
                onComplete(permission)
                break
            default:
                onComplete(permission)
                break
            }
        }
    }
    
    func requestAsset(asset: PHAsset, onComplete: @escaping (UIImage?) -> Void) {
        caching.requestImage(for: asset,
                             targetSize: cachingSize!,
                             contentMode: .aspectFit,
                             options: imageOptions) { (image, dict) in
            onComplete(image)
        }
    }
    
    func fetchAssets() {
        if (permission == .authorized)
        {
            fetchByCollection()
        } else if (permission == .limited)
        {
            fetchAll()
        }
    }
    
    private func fetchAll()
    {
        caching.stopCachingImagesForAllAssets()
        
        assets.removeAll()
        
        var result = [PHAsset]()
        let queue = DispatchQueue(label: "Asset", qos: .background, attributes: .concurrent)
        queue.async { [weak self] in
            guard let strongSelf = self else {return}
            
            let fetchOption = PHFetchOptions()
            fetchOption.includeAssetSourceTypes = .typeUserLibrary
            fetchOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let ret = PHAsset.fetchAssets(with: .image, options: fetchOption)
            ret.enumerateObjects { (asset, idx, _) in
                result.append(asset)
            }
            
//            if (strongSelf.selectedAlbum?.collection != nil)
//            {
//                let ret = PHAsset.fetchAssets(in: strongSelf.selectedAlbum!.collection, options: fetchOption)
//                strongSelf.caching.startCachingImages(for: strongSelf.assets,
//                                                      targetSize: strongSelf.cachingSize!,
//                                                      contentMode: .aspectFit,
//                                                      options: strongSelf.imageOptions)
//
//                ret.enumerateObjects { (asset, idx, _) in
//                    result.append(asset)
//                }
//            }
            
            DispatchQueue.main.async {
                strongSelf.assets.append(contentsOf: result)
//                let options = PHImageRequestOptions()
//                options.deliveryMode = .fastFormat
//                options.isNetworkAccessAllowed = false
//                options.resizeMode = .fast
                
                strongSelf.caching.startCachingImages(for: strongSelf.assets,
                                                      targetSize: strongSelf.cachingSize!,
                                                      contentMode: .aspectFit,
                                                      options: strongSelf.imageOptions)
            }
            
        }
    }
    
    private func fetchByCollection()
    {
        if (collections.isEmpty) {
            fetchCollections { [weak self] in
                guard let strongSelf = self else { return }
                if (strongSelf.selectedAlbum == nil)
                {
                    strongSelf.selectedAlbum = strongSelf.collections.first
                }
                
                strongSelf.doFetchAssets()
            }
        } else
        {
            if (selectedAlbum == nil)
            {
                selectedAlbum = collections.first
            }
            
            doFetchAssets()
        }
    }
    
    private func doFetchAssets()
    {
        caching.stopCachingImagesForAllAssets()
        
        assets.removeAll()
        
        var result = [PHAsset]()
        
        let queue = DispatchQueue(label: "Asset", qos: .background, attributes: .concurrent)
        queue.async { [weak self] in
            guard let strongSelf = self else {return}
            
            let fetchOption = PHFetchOptions()
            fetchOption.includeAssetSourceTypes = .typeUserLibrary
            fetchOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            if (strongSelf.selectedAlbum?.collection != nil)
            {
                let ret = PHAsset.fetchAssets(in: strongSelf.selectedAlbum!.collection, options: fetchOption)
                strongSelf.caching.startCachingImages(for: strongSelf.assets,
                                                      targetSize: strongSelf.cachingSize!,
                                                      contentMode: .aspectFit,
                                                      options: strongSelf.imageOptions)
                
                ret.enumerateObjects { (asset, idx, _) in
                    result.append(asset)
                }
            }
            
            DispatchQueue.main.async {
                strongSelf.assets.append(contentsOf: result)
//                let options = PHImageRequestOptions()
//                options.deliveryMode = .fastFormat
//                options.isNetworkAccessAllowed = false
//                options.resizeMode = .fast
                
                strongSelf.caching.startCachingImages(for: strongSelf.assets,
                                                      targetSize: strongSelf.cachingSize!,
                                                      contentMode: .aspectFit,
                                                      options: strongSelf.imageOptions)
            }
            
        }
    }
    
    func fetchCollections(completion: @escaping ()->Void) {
        var result = [AlbumModel]()
        
        let queue = DispatchQueue(label: "Test", qos: .background, attributes: .concurrent)
        let group = DispatchGroup()
        
        queue.async(group: group) { [weak self] in
            guard let strongSelf = self else { return }
            
            let ret = strongSelf.getAlbum(subType: .albumRegular)
            DispatchQueue.main.async {
                
                result.append(contentsOf: ret)
            }
        }
        
        queue.async(group: group) {[weak self] in
            guard let strongSelf = self else {return}
            
            let ret = strongSelf.getAlbum(subType: .albumImported)
            DispatchQueue.main.async {
                result.append(contentsOf: ret)
            }
        }
        
        queue.async(group:group) {[weak self] in
            guard let strongSelf  = self else {return}
            
            let ret = strongSelf.getSmartAlbum(subType: .smartAlbumFavorites)
            DispatchQueue.main.async {
                result.append(contentsOf: ret)
            }
        }
        
        queue.async(group: group) { [weak self] in
            guard let strongSelf = self else { return }
            
            let ret = strongSelf.getSmartAlbum(subType: .smartAlbumRecentlyAdded)
            DispatchQueue.main.async {
                result.append(contentsOf: ret)
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            print("All job dones")
            print("Result count: \(result.count)")
            guard let strongSelf = self else { return }
            strongSelf.collections = result
            completion()
        }
//        queue.async {[weak self] in
//            guard let strongSelf = self else {
//                return
//            }
//
//            let dispatchGroup = DispatchGroup()
//
//            for idx in 1 ... 1000 {
//                dispatchGroup.enter()
//                Thread.printCurrent()
//                let ret = strongSelf.getAlbum(subtype: .albumRegular)
//                DispatchQueue.main.async {
//                    print("\(idx)")
//                    result.append(contentsOf: ret)
//                }
//
//                dispatchGroup.leave()
//            }
            
//            dispatchGroup.notify(queue: DispatchQueue.main) {
//                Thread.printCurrent()
//                strongSelf.collections = result
//            }
//        }
        
        
    }
    
    private func getAlbum(subType: PHAssetCollectionSubtype) -> [AlbumModel] {
        let collectionOption = PHFetchOptions()
        collectionOption.includeAssetSourceTypes = .typeUserLibrary
        
        return getGenericAlbum(with: .album, subType: subType, option: collectionOption)
    }
    
    private func getSmartAlbum(subType: PHAssetCollectionSubtype) -> [AlbumModel] {
        let collectionOption = PHFetchOptions()
        collectionOption.includeAssetSourceTypes = .typeUserLibrary
        
        return getGenericAlbum(with: .smartAlbum, subType: subType, option: collectionOption)
    }
    
    private func getGenericAlbum(with: PHAssetCollectionType, subType: PHAssetCollectionSubtype, option: PHFetchOptions) -> [AlbumModel]
    {
        let fetchCollection = PHAssetCollection.fetchAssetCollections(with: with, subtype: subType, options: option)
        var result = [AlbumModel]()
        
        fetchCollection.enumerateObjects { (assetCollection, idx, _) in
            let album = AlbumModel(collection: assetCollection)
            result.append(album)
        }
        return result
    }
}

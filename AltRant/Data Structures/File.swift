//
//  File.swift
//  devRantAvatarEditor
//
//  Created by Omer Shamai on 10/12/20.
//

import UIKit
import QuickLook

/// - Tag: File
struct File {
    var url: URL
    var size: CGSize? = nil
    
    init(url: URL, size: CGSize) {
        self.url = url
        self.size = size
    }
    
    init(url: URL) {
        self.url = url
    }
    
    init() {
        self.url = URL(string: "")!
    }
    
    var name: String {
        "Picture"
    }
    
    var previewItemURL: URL {
        url
    }
    
    var previewItemTitle = "Picture"
}

// MARK: - QuickLookThumbnailing
extension File {
    func generateThumbnail(completion: @escaping (UIImage) -> Void) {
        //let size = CGSize(width: 384, height: 306)
        let scale = UIScreen.main.scale
        
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size!,
            scale: scale,
            representationTypes: .all
        )
        
        let generator = QLThumbnailGenerator.shared
        generator.generateRepresentations(for: request) { thumbnail, _, error in
            if let thumbnail = thumbnail {
                completion(thumbnail.uiImage)
            } else if let error = error {
                print(error)
            }
        }
    }
    
    func generateThumbnail(thumbnailSize: CGSize, completion: @escaping (UIImage) -> Void) {
        let scale = UIScreen.main.scale
        
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: thumbnailSize,
            scale: scale,
            representationTypes: .all
        )
        
        let generator = QLThumbnailGenerator.shared
        generator.generateRepresentations(for: request) { thumbnail, _, error in
            if let thumbnail = thumbnail {
                completion(thumbnail.uiImage)
            } else if let error = error {
                print(error)
            }
        }
    }
    
    func getThumbnail(size: CGSize) -> UIImage {
        let completionSempaphore = DispatchSemaphore(value: 0)
        
        let scale = UIScreen.main.scale
        
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail)
        
        let generator = QLThumbnailGenerator.shared
        
        var finalThumbnail: UIImage? = nil
        generator.generateRepresentations(for: request) { thumbnail, _, error in
            if let thumbnail = thumbnail {
                finalThumbnail = thumbnail.uiImage
                
                completionSempaphore.signal()
            }
        }
        
        completionSempaphore.wait()
        return finalThumbnail!
    }
}

// MARK: - Helper extension
extension File {
    static func loadFiles(images: [AttachedImage]) -> [File] {
        let completionSemaphore = DispatchSemaphore(value: 0)
        
        //let requestGroup = DispatchGroup()
        
        var finalArray = [File]()
        
        for (idx, image) in images.enumerated() {
            let innerCompletionSemaphore = DispatchSemaphore(value: 0)
            
            var receivedData: Data? = nil
            
            URLSession.shared.dataTask(with: URL(string: image.url!)!) { data, _, _ in
                receivedData = data
                
                innerCompletionSemaphore.signal()
            }.resume()
            
            innerCompletionSemaphore.wait()
            let filename = URL(string: image.url!)!.lastPathComponent
            
            let previewURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
            try! receivedData?.write(to: previewURL, options: .atomic)
            //previewURL.hasHiddenExtension = true
            
            let finalFile = File(url: previewURL, size: CGSize(width: image.width!, height: image.height!))
            
            finalArray.append(finalFile)
            
            if idx == images.endIndex - 1 {
                completionSemaphore.signal()
            }
        }
        
        completionSemaphore.wait()
        return finalArray
    }
    
    static func loadFile(image: AttachedImage, size: CGSize) -> File {
        let completionSemaphore = DispatchSemaphore(value: 0)
        var receivedData: Data? = nil
        
        URLSession.shared.dataTask(with: (URL(string: image.url!)!)) { data, _, _ in
            receivedData = data
            
            completionSemaphore.signal()
        }.resume()
        
        completionSemaphore.wait()
        let filename = URL(string: image.url!)!.lastPathComponent// + ".jpg"
        
        let previewURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        try! receivedData?.write(to: previewURL, options: .atomic)
        
        let finalFile = File(url: previewURL, size: size)
        return finalFile
    }
}

extension URL {
    var hasHiddenExtension: Bool {
        get { (try? resourceValues(forKeys: [.hasHiddenExtensionKey]))?.hasHiddenExtension == true }
        
        set {
            var resourceValues = URLResourceValues()
            resourceValues.hasHiddenExtension = newValue
            try? setResourceValues(resourceValues)
        }
    }
}

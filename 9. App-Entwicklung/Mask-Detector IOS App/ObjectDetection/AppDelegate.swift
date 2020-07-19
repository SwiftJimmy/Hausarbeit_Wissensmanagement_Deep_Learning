// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import Firebase
import FirebaseFirestore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    
    FirebaseApp.configure()
    // Copy model 
    copyFileToDocumentsFolder(nameForFile: "detect", extForFile: "tflite")
    copyFileToDocumentsFolder(nameForFile: "labelmap", extForFile: "txt")
    // Load Model if Wifi Connection is available
    if Reachability.isConnectedToNetwork(){
        downloadDataFromFirebaseToDocuments(FirebaseFilePath: "model/detect.tflite", fileName: "detect.tflite")
        downloadDataFromFirebaseToDocuments(FirebaseFilePath: "model/labelmap.txt", fileName: "labelmap.txt")
    }
    return true
  }
    
   
    func downloadDataFromFirebaseToDocuments(FirebaseFilePath: String, fileName: String){
       
    
       let pathReference = Storage.storage().reference(withPath: FirebaseFilePath)
       // Create a reference to the file you want to download
       let islandRef = pathReference
       
        // Create local filesystem URL
       let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
       let localURL = documentsURL.appendingPathComponent(fileName)

       // Download to the local filesystem
       let downloadTask = islandRef.write(toFile: localURL) { url, error in
         if let error = error {
           print("Someting went wrong")
           print(error.localizedDescription)
         } else {
           print("download success")
         }
       }
  }
    
    func copyFileToDocumentsFolder(nameForFile: String, extForFile: String) {

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let destURL = documentsURL!.appendingPathComponent(nameForFile).appendingPathExtension(extForFile)
        guard let sourceURL = Bundle.main.url(forResource: nameForFile, withExtension: extForFile)
            else {
                print("Source File not found.")
                return
        }
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destURL.path) == false {
            do {
                try fileManager.copyItem(at: sourceURL, to: destURL)
                } catch {
                   print(error)
                   print("Unable to copy file")
                }
        }
           
    }
    
 
}

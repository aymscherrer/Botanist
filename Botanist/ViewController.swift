//
//  ViewController.swift
//  Botanist
//
//  Created by Aymeric SCHERRER on 2/10/19.
//  Copyright © 2019 Aymeric SCHERRER. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let WIKIPEDIA_REST_API = "https://en.wikipedia.org/w/api.php"
    private let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var flowerTextLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    //MARK: - Image Picker Controller
    /***************************************************************/
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
//            imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert UIImage to CIImage.")
            }
            
            detect(flowerImage: ciimage)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Detect Image Function
    /***************************************************************/
    
    func detect(flowerImage: CIImage) {
        
        // Import CoreML Model FlowerClassifier
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model failed.")
        }
        
        // Creating a CoreML request
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image.")
            }
            
            if let flowerFound = results.first?.identifier.capitalized {
                self.navigationItem.title = flowerFound
                self.getWikipediaData(url: self.WIKIPEDIA_REST_API, flower: flowerFound)
            }
        }
        
        // Performing the Machine Learning Process
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    //MARK: - Networking to Wikipedia
    /***************************************************************/
    
    func getWikipediaData(url: String, flower: String) {
        let params: [String : String] = [
            "action" : "query",
            "format" : "json",
            "prop" : "extracts|pageimages",
            "pithumbsize" : "500",
            "exsentences" : "5",
            "formatversion" : "2",
            "explaintext" : "1",
            "redirects": "1",
            "titles" : flower
        ]
        
        Alamofire.request(url, method: .get, parameters: params).responseJSON {
            (response) in
            
            if response.result.isSuccess {
                print("Success, got the Wikipedia data!")
                let wikipediaJSON : JSON = JSON(response.result.value!)
                self.updateWikipediaData(json: wikipediaJSON)
            }
    
            if response.result.isFailure {
                print("Error \(String(describing: response.result.error))")
            }
        }
    }
    
    //MARK: - JSON Parsing
    /***************************************************************/
    
    func updateWikipediaData(json: JSON) {
        if let tempResult = json["query"]["pages"].array {
            print(tempResult)
            for items in tempResult {
                if let extract = items["extract"].string {
                    flowerTextLabel.text  = extract
                }
                
                if let flowerImageURL = items["thumbnail"]["source"].string {
                    print("IMAGE GOTTEN =====>")
                    print(flowerImageURL)
                    imageView.sd_setImage(with: URL(string: flowerImageURL))
                }
            }
        } else {
            print("Cannot fetch data from the Internet.")
        }
    }
    

    @IBAction func cameraAction(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}

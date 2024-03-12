//
//  ViewController.swift
//  SaveTheLocation
//
//  Created by Zülal Sarıoğlu on 12.03.2024.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController , MKMapViewDelegate  , CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var btnSave: UIButton!
    
    let locationManager = CLLocationManager()
    var chooseLatitude = Double()
    var chooseLongitude = Double()
    
    var getLocationName = ""
    var getLocationId : UUID?
    
    var annotationTitle = ""
    var annotationNote = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //basılı tutma işlemini algılamak için:
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gesture.minimumPressDuration = 3
        mapView.addGestureRecognizer(gesture)
        
        if getLocationName != ""{
            //Core data verileri gelmeli
            if let uuidString = getLocationId?.uuidString {
                btnSave.isHidden = true
                let appDelegte = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegte.persistentContainer.viewContext
               
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do{
                 let results = try context.fetch(fetchRequest)
                    if results.count > 0 {
                        for result in results as! [NSManagedObject] {
                            if let name = result.value(forKey: "locationName") as? String {
                                annotationTitle = name
                                if let note = result.value(forKey: "locationNote") as? String {
                                    annotationNote = note
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        if let latitude = result.value(forKey: "latitude") as? Double {
                                            annotationLatitude = latitude
                                            
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationNote
                                            let cootdinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = cootdinate
                                            mapView.addAnnotation(annotation)
                                            
                                            locationTextField.text = annotationTitle
                                            noteTextField.text = annotationNote
                                            
                                            
                                            locationManager.stopUpdatingLocation()
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: cootdinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }catch{
                    
                }
                
            }
        }
        else{
            //Yeni veri eklencek
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        //Core data ile verileri kaydetme
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newLocation = NSEntityDescription.insertNewObject(forEntityName: "Location", into: context)
        newLocation.setValue(locationTextField.text, forKey: "locationName")
        newLocation.setValue(noteTextField.text, forKey: "locationNote")
        newLocation.setValue(chooseLatitude, forKey: "latitude")
        newLocation.setValue(chooseLongitude, forKey: "longitude")
        newLocation.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("data kaydedildi")
        }catch{
            print("data kayıt olmadı")
            
        }
        NotificationCenter.default.post(name: NSNotification.Name("newLocationCreated"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == .began {
            
            let thouchedPoint = gestureRecognizer.location(in: mapView)
            let coordinatePoint = mapView.convert(thouchedPoint, toCoordinateFrom: mapView)
            chooseLatitude = coordinatePoint.latitude
            chooseLongitude = coordinatePoint.longitude
            
            //yer çubuğu
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinatePoint
            annotation.title = locationTextField.text
            annotation.subtitle = noteTextField.text
            mapView.addAnnotation(annotation)
    
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       /*
        CLLocationCoordinate2D -> Enlem ve boylam alarak kordinat oluşturmamıza yarar.
        MKCoordinateRegion -> Harita yüklendiği zaman kordinatı belli olan bölgeyi gösterir.
        MKCoordinateSpan -> Harita üzerinde işaretlenen noktanın kuş bakışı uzaklığını belirler.
        */
        
        if getLocationName == ""{
            let latitude = locations[0].coordinate.latitude
            let longitude = locations[0].coordinate.longitude
            let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
        
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let identifier = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pinView?.canShowCallout = true
            pinView?.tintColor = .purple
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else {
            pinView?.annotation = annotation
        }
        return pinView
    }


}


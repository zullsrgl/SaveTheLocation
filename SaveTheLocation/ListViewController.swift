//
//  ListViewController.swift
//  SaveTheLocation
//
//  Created by Zülal Sarıoğlu on 12.03.2024.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var locationNameArray = [String] ()
    var locationIdArray = [UUID]()
    
    var locationName = ""
    var locationID : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        //navigation item
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addNewLocationButton))

        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newLocationCreated"), object: nil)
    }
    
    
   @objc func addNewLocationButton(){
       locationName = ""
       performSegue(withIdentifier: "toMapVC", sender: nil)
        
    }
    
   @objc func getData(){
        //core data -> fetch
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        request.returnsObjectsAsFaults = false
        
        do{
           let results = try context.fetch(request)
            if results.count > 0 {
                locationIdArray.removeAll(keepingCapacity: false)
                locationNameArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject] {
                    if let name = result.value(forKey: "locationName") as? String{
                        locationNameArray.append(name)
                        
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        locationIdArray.append(id)
                    }
                }
                tableView.reloadData()
            }
            
            
        }catch{
            print("data getirlmedi")
        }
   }
  
    //MARK: TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locationNameArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = locationNameArray[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegat = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegat.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
            let uuidString = locationIdArray[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let id = result.value(forKey: "id") as? UUID {
                            if id == locationIdArray[indexPath.row] {
                                context.delete(result)
                                locationIdArray.remove(at: indexPath.row)
                                locationNameArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                do{
                                    try context.save()
                                }catch {
                                    print("hata")
                                    
                                }
                                break
                            }
                            
                        }
                    }
                }
                    
                
            }catch{
                print("data silinmedi")
            }
           
            
            
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        locationName = locationNameArray[indexPath.row]
        locationID = locationIdArray[indexPath.row]
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapVC" {
            let destinationVC = segue.destination as! MapsViewController
            destinationVC.getLocationName = locationName
            destinationVC.getLocationId = locationID
        }
        
    }
    
}


import UIKit
import Firebase
import FirebaseDatabase
import HandyJSON

let dictionary = [String: String]()

class SearchGroupsViewController: UIViewController, UISearchBarDelegate {

    var groups : [Group] = []
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        guard let nav = segue.destination as? UINavigationController else { return }
//        if let controller = nav.topViewController  as? CalendarController {
//            guard let index = sender as? Int else { return }
//            controller.group = groups[index]
//        }
//    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !groups.isEmpty {
            self.groups.remove(at: 0)
            self.tableView.reloadData()
        }
        guard let text = searchBar.text else {
            return
        }
        let ref = Database.database().reference()
        ref.child("group").observeSingleEvent(of: .value, with: { (snapshot) in
            let snapshots = snapshot.children.allObjects.flatMap { $0 as? DataSnapshot }
            
            let keys = snapshots.map { $0.key }
            
            var groups = (snapshots.flatMap { Group.deserialize(from: $0.value as? NSDictionary) })
                .enumerated()
                .flatMap { index, group -> Group in
                    group.key = keys[index]
                    return group
            }
            let group = groups.filter { $0.name! == text }.first
            if let group = group {
                self.groups.append(group)
                self.tableView.reloadData()
            }
        })
    }
    func addRequestToGroup(_ group : Group) {
        if (group.invites == nil) {
            group.invites = [(Firebase.Auth.auth().currentUser?.uid)!]
            let json = group.toJSON()
            Database.database().reference(withPath: "group").child(group.key!).updateChildValues(json!)
        } else {
            var array = group.invites!
            array.append((Firebase.Auth.auth().currentUser?.uid)!)
            group.invites = array
            let json = group.toJSON()
            Database.database().reference(withPath: "group").child(group.key!).updateChildValues(json!)
        }
    }
    
//    @objc func requestEntryButton(_ sender: Any) {
//        let alert = UIAlertController(title: "Request entry", message: "Do you confirm requesting entry into this group?", preferredStyle: UIAlertControllerStyle.alert)
//        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: nil))
//        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
//        self.present(alert, animated: true, completion: nil)
//    }
    
}
extension SearchGroupsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CellGroups
        cell.nameGroup.text = groups[indexPath.row].name
        let url = URL(string: groups[indexPath.row].image! )
        cell.imageGroup.sd_setImage(with: url, completed: nil)
        cell.imageGroup.layer.cornerRadius = cell.imageGroup.frame.size.width / 2
        cell.imageGroup.layer.masksToBounds = true
//        cell.entryButton.tag = indexPath.row
//        cell.entryButton.addTarget(self, action: #selector(SearchGroupsViewController.requestEntryButton(_:)), for: UIControlEvents.touchUpInside)
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return groups.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 126
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                let alert = UIAlertController(title: "OPTIONS", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
                alert.addAction(UIAlertAction(title: "Request group entry", style: UIAlertActionStyle.default, handler: { (_) -> Void in
                    let secondAlert = UIAlertController(title: "Request entry", message: "Do you confirm requesting entry into this group?", preferredStyle: UIAlertControllerStyle.alert)
                    secondAlert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: {(_) -> Void in self.addRequestToGroup(self.groups[indexPath.row])}))
                            secondAlert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
                            self.present(secondAlert, animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
        
    }
    
}

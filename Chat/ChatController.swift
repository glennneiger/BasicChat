//
// Re-written by Dan Park
// Copyright (C) 2017 Dan Park. All Rights Reserved.
//

import UIKit
import Firebase
import Photos

struct ChatMessage {
    var name: String!
    var message: String!
    var image: UIImage?
}

class ChatController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Outlets
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    // Useful app properties
    let imagePicker = UIImagePickerController()
    var messages: [ChatMessage]!
    var username: String? = nil
    var pushNotification = PushNotification.sharedInstance()
    
    // Firebase services
    var database: Database? = nil
    var auth: Auth!
    var storage: Storage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize navigation bar
        self.title = "Chat"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log in",
                                                            style: UIBarButtonItemStyle.plain,
                                                            target: self,
                                                            action: #selector(toggleAuthState))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.camera,
                                                           target: self,
                                                           action: #selector(selectImage))
        
        // Initialize UIImagePicker
        imagePicker.delegate = self
        
        // Initialize other properties
        messages = []
        username = "iOS"
        
        // Initialize UITableView
        tableView.delegate = self
        tableView.dataSource = self
        
        // Initialize Database, Auth, Storage
        database = Database.database()
        auth = Auth.auth()
        storage = Storage.storage()
        
        // Observe auth state change
        self.auth.addStateDidChangeListener { (auth, user) in
            if (user != nil) {
                if let displayName = user?.displayName {
                    self.username = displayName
                } else {
                    self.username = "none"
                }
                self.navigationItem.rightBarButtonItem?.title = "Log out"
            } else {
                self.username = "na"
                self.navigationItem.rightBarButtonItem?.title = "Log in"
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        FIRAuth.auth()?.signInAnonymously() { (user, error) in
//            if let error = error {
//                debugPrint(error.localizedDescription)
//            }
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.addObservers()
    }

    @IBAction func reload(sender: AnyObject) {
    }
    
    // Send a chat message
    @IBAction func notify(sender: AnyObject) {
        let timestamp = PushNotification.timestampString()
        self.notify(message: timestamp!)
    }
    
    func notify(message:String) {
        //        let token = Messaging.messaging().fcmToken
        let token = PushNotification.registeredToken()
        print("token: \(token ?? "")")
        
        PushNotification.notify(toToken: token, withMessage: message)
        //        PushNotification.sendNotificatino("1008")
    }
    
    @IBAction func sendMessage(sender: AnyObject) {
        let timestamp = PushNotification.timestampString()
        self.username = timestamp
        
        let chatMessage = ChatMessage(name: self.username, message: messageTextField.text!, image: nil)
        messageTextField.text = ""
        
        // Create a reference to our chat message
        let chatRef = database?.reference().child("chat")
        
        let token = Messaging.messaging().fcmToken
        print("FCM token: \(token ?? "")")
        
        let dictionary = ["name": chatMessage.name,
                          "t": token,
                          "timestamp": timestamp,
                          "message": chatMessage.message];
        // Push the chat message to the database
        chatRef?.childByAutoId().setValue(dictionary)
        self.notify(message: chatMessage.message)
    }
    
    // Show a popup when the user asks to sign in
    func toggleAuthState() {
        if (auth.currentUser != nil) {
            // Allow the user to sign out
            do {
                try auth.signOut()
            } catch {}
        } else {
            Auth.auth().signInAnonymously() { (user, error) in
                if let error = error {
                    debugPrint(error.localizedDescription)
                } else {
                    self.addObservers()
                }
            }
        }
    }
    
    func addObservers() {
        // Listen for when child nodes get added to the collection
        let chatRef = database?.reference().child("chat")
        chatRef?.observeSingleEvent(of: .childAdded, with: { (snapshot) -> Void in
            // Get the chat message from the snapshot and add it to the UI
            let data = snapshot.value as! Dictionary<String, String>
            guard let name = data["name"] as String! else { return }
            guard let message = data["message"] as String! else { return }
            let chatMessage = ChatMessage(name: name, message: message, image: nil)
            self.addMessage(chatMessage: chatMessage)
            
        })
        
        chatRef?.observe(.childAdded, with: { (snapshot) -> Void in
            // Get the chat message from the snapshot and add it to the UI
            let data = snapshot.value as! Dictionary<String, String>
            guard let name = data["name"] as String! else { return }
            guard let message = data["message"] as String! else { return }
            let chatMessage = ChatMessage(name: name, message: message, image: nil)
            self.addMessage(chatMessage: chatMessage)
        })
    }
    
    // Handle photo uploads button
    func selectImage() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: UIImagePickerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // Get local file URLs
        guard let image: UIImage = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        let imageData = UIImagePNGRepresentation(image)!
        guard let _: NSURL = info[UIImagePickerControllerReferenceURL] as? NSURL else { return }
        
        // Get a reference to the location where we'll store our photos
        let photosRef = storage.reference().child("chat_photos")
        
        // Get a reference to store the file at chat_photos/<FILENAME>
        let photoRef = photosRef.child("\(NSUUID().uuidString).png")
        
        // Upload file to Firebase Storage
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        photoRef.putData(imageData, metadata: metadata).observe(.success) { (snapshot) in
            // When the image has successfully uploaded, we get it's download URL
            let text = snapshot.metadata?.downloadURL()?.absoluteString
            // Set the download URL to the message box, so that the user can send it to the database
            self.messageTextField.text = text
        }
        
        // Clean up picker
        dismiss(animated: true, completion: nil)
    }
    
    func addMessage( chatMessage: ChatMessage) {
        // Handle remote image messages
        var chatMessage = chatMessage
        if (chatMessage.message.contains("https://firebasestorage.googleapis.com")) {
            self.storage.reference(forURL: chatMessage.message).getData(maxSize: 25 * 1024 * 1024, completion: { (data, error) -> Void in
                let image = UIImage(data: data!)
                chatMessage.image = image!
                self.messages.insert(chatMessage, at: 0)
                self.tableView.reloadData()
//                self.scrollToBottom()
            })
            // Handle asset library messages
        } else if (chatMessage.message.contains("assets-library://")) {
            let assetURL = NSURL(string: chatMessage.message)
            let assets = PHAsset.fetchAssets(withALAssetURLs: [assetURL! as URL], options: nil)
            let asset: PHAsset = assets.firstObject!
            
            let manager = PHImageManager.default()
            manager.requestImage(for: asset, targetSize: CGSize(width: 100.0, height: 100.0), contentMode: .aspectFit, options: nil, resultHandler: {(result, info)->Void in
                chatMessage.image = result!
                self.messages.insert(chatMessage, at: 0)
                self.tableView.reloadData()
//                self.scrollToBottom()
            })
            // Handle regular messages
        } else {
            self.messages.insert(chatMessage, at: 0)
            self.tableView.reloadData()
//            self.scrollToBottom()
        }
    }
    
    func scrollToBottom() {
        if (self.messages.count > 8) {
            let bottomOffset = CGPoint(x: 0, y: tableView.contentSize.height - tableView.bounds.size.height)
            tableView.setContentOffset(bottomOffset, animated: true)
        }
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RightDetailCellID", for: indexPath)
        let chatMessage = messages[indexPath.row]
        cell.textLabel?.text = chatMessage.message
        cell.detailTextLabel?.text = chatMessage.name
        cell.imageView?.image = chatMessage.image
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let chatMessage = messages[indexPath.row]
        if (chatMessage.image != nil) {
            return 345.0
        } else {
            return 58.0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)        
    }
    
    // Create a chat message from a FIRDataSnapshot
    func chatMessageFromSnapshot(snapshot: DataSnapshot) -> ChatMessage? {
        let data = snapshot.value as! Dictionary<String, String>
        guard let name = data["name"] as String! else { return nil }
        guard let message = data["message"] as String! else { return nil }
        let chatMessage = ChatMessage(name: name, message: message, image: nil)
        return chatMessage
    }
}

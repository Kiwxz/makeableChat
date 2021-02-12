import UIKit
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {

    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    var messages = [JSQMessage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Testdata - messages from random users
        DbConstants.dbChats.childByAutoId().setValue(["senderId": "2345", "senderDisplayName": "Bob", "messageContent": "Hello there!"])
        DbConstants.dbChats.childByAutoId().setValue(["senderId": "3456", "senderDisplayName": "Cleo", "messageContent": "Testmessage from another user"])
        
        let defaults = UserDefaults.standard
        
        // Checks if user already has given ID
        if let id = defaults.string(forKey: "defaultsId"),
           let name = defaults.string(forKey: "defaultsName") {
            senderId = id
            senderDisplayName = name
        } else {
            // If user doesn't have ID, a random ID is generated and nameDialog opens
            let randomNumber = Int.random(in: 1..<1000)
            senderId = String(randomNumber)
            senderDisplayName = ""
            
            defaults.set(senderId, forKey: "defaultsId")
            defaults.synchronize()
            
            displayNameDialog()
        }
       
        // If user wants to change name, tap navigationbar
        title = "Chat: \(senderDisplayName!)"
        let tap = UITapGestureRecognizer(target: self, action: #selector(displayNameDialog))
        navigationController?.navigationBar.addGestureRecognizer(tap)
        
        // Sets the avatar viewSize to zero
        inputToolbar.contentView.leftBarButtonItem = nil
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        let query = DbConstants.dbChats.queryLimited(toLast: 25)
        
        // Firebase observes query for changes
        _ = query.observe(.childAdded, with: {snapshot in
            if let dictionary = snapshot.value as? [String: String],
               let id   = dictionary["senderId"],
               let name = dictionary["senderDisplayName"],
               let text = dictionary["messageContent"],
               let message = JSQMessage(senderId: id, displayName: name, text: text) {
                self.messages.append(message)
                self.finishReceivingMessage()
            }
        })
        setupBubbles()
        automaticallyScrollsToMostRecentMessage = true
    }
    
    // Displays dialog where user enters name. Generates random ID and saves both in userDefaults
    @objc func displayNameDialog() {
        let defaults = UserDefaults.standard
        let alert = UIAlertController(title: "Enter name", message: "Please enter a display name", preferredStyle: .alert)
        
        alert.addTextField { nameTextField in
            if let name = defaults.string(forKey: "defaultsName") {
                nameTextField.text = name
                let randomNumber = Int.random(in: 1..<1000)
                self.senderId = String(randomNumber)        
                defaults.set(self.senderId, forKey: "defaultsId")
            } else {
                nameTextField.text = ""
            }
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self, weak alert] (_) in
            if let nameTextField = alert?.textFields?[0],
               !nameTextField.text!.isEmpty {
                
                self?.senderDisplayName = nameTextField.text
                self?.title = "Chat: \(self!.senderDisplayName!)"
                
                defaults.set(nameTextField.text, forKey: "defaultsName")
                defaults.synchronize()
            }
        }))
       
        automaticallyScrollsToMostRecentMessage = true
        present(alert, animated: true, completion: nil)
    }
    
    private func setupBubbles() {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        incomingBubbleImageView = bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    // Creates reference to chats, adds dictionary of messages to Firebase
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let dbRef = DbConstants.dbChats.childByAutoId()
        let message = ["senderId": senderId, "senderDisplayName": senderDisplayName, "messageContent": text]
        dbRef.setValue(message)
        finishSendingMessage()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        return messages[indexPath.item].senderId == senderId ? outgoingBubbleImageView : incomingBubbleImageView
    }
    
    // Hides avatars for message bubbles
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    // Display senders name in toplabel if senderId different from current user
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        return NSAttributedString(string: messages[indexPath.item].senderDisplayName)
    }
    
    // Has to be set in order for toplabel to show
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return messages[indexPath.item].senderId == senderId ? CGFloat(0.0) : kJSQMessagesCollectionViewCellLabelHeightDefault
    }
}

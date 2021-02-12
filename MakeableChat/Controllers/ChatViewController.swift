import UIKit
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {

    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    var messages = [JSQMessage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        senderId = "1010"
        senderDisplayName = "Kirsten"
        setupBubbles()
        automaticallyScrollsToMostRecentMessage = true
        
        messages.append(JSQMessage(senderId: "1011", displayName: "Bruger 2", text: "Testbesked fra bruger 2"))
        messages.append(JSQMessage(senderId: "1012", displayName: "Bruger 3", text: "Testbesked fra bruger 3"))
        
        // Sets the avatar viewSize to zero
        inputToolbar.contentView.leftBarButtonItem = nil
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        let query = DbConstants.dbChats.queryLimited(toLast: 5)
        // Firebase observes query for changes.
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
    }
    
    private func setupBubbles() {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        incomingBubbleImageView = bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
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
        return messages[indexPath.item].senderId == senderId ? nil : NSAttributedString(string: messages[indexPath.item].senderDisplayName)
    }
    
    // Creates reference to chats, adds dictionary of messages to Firebase
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let dbRef = DbConstants.dbChats.childByAutoId()
        let message = ["senderId": senderId, "senderDisplayName": senderDisplayName, "messageContent": text]
        dbRef.setValue(message)
        finishSendingMessage()
    }
}

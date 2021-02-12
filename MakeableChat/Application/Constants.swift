import Firebase

struct DbConstants {
    static let db = Database.database(url: "https://makeablechat-3ea75-default-rtdb.europe-west1.firebasedatabase.app")
    static let dbRef = db.reference()
    static let dbChats = dbRef.child("chats")
}

//
//  ComponentViewsActionHooker.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/7.
//

import UIKit

/**
 A class that handles action events for various component views in the application.
 
 - Note: This class is a singleton and can be accessed using the `shared` property.
 
 - Warning: Do not create instances of this class directly.
 
 - SeeAlso: `ComponentViewsActionHooker.Chat`, `ComponentViewsActionHooker.Contact`, `ComponentViewsActionHooker.Conversation`
 */
@objcMembers public class ComponentViewsActionHooker: NSObject {
    
    public static var shared = ComponentViewsActionHooker()
    
    public let chat = ComponentViewsActionHooker.Chat()
    
    public let contact = ComponentViewsActionHooker.Contact()
    
    public let conversation = ComponentViewsActionHooker.Conversation()
    
    /**
     A class representing a conversation in the chat UI.
     
     Use this class to handle swipe actions, long press events, and selection events for a conversation.
     */
    @objcMembers public class Conversation: NSObject {
        
        public var swipeAction: ((UIContextualActionType,ConversationInfo) -> Void)?
        
        public var longPressed: ((IndexPath,ConversationInfo) -> Void)?
        
        public var didSelected: ((IndexPath,ConversationInfo) -> Void)?
    }
    
    /**
     A class representing a contact.
     */
    @objcMembers public class Contact: NSObject {
        
        /**
         A closure that is called when a contact is selected.
         
         - Parameters:
         - indexPath: The index path of the selected contact.
         - profile: The profile of the selected contact conforming to EaseProfileProtocol.
         */
        public var didSelectedContact: ((IndexPath, EaseProfileProtocol) -> Void)?
        
        /**
         A closure that is called when a group is created with the selected contact.
         
         - Parameters:
         - indexPath: The index path of the selected contact.
         - profile: The profile of the selected contact conforming to EaseProfileProtocol.
         */
        public var groupWithSelected: ((IndexPath, EaseProfileProtocol) -> Void)?
    }
    
    /**
     A class representing a chat component.
     
     This class provides various closures for handling different chat events such as reply clicked, bubble clicked, bubble long pressed, avatar clicked, and avatar long pressed.
     */
    @objcMembers public class Chat: NSObject {
        
        public var replyClicked: ((MessageEntity) -> Void)?
        
        public var bubbleClicked: ((MessageEntity) -> Void)?
        
        public var bubbleLongPressed: ((MessageEntity) -> Void)?
        
        public var avatarClicked: ((EaseProfileProtocol) -> Void)?
        
        public var avatarLongPressed: ((EaseProfileProtocol) -> Void)?
    }
}

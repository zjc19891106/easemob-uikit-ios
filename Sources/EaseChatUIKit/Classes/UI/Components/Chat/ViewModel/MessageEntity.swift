import UIKit

/// Audio message `default` height.
public var audioHeight = CGFloat(36)

/// File message `default` height.
public var fileHeight = CGFloat(60)

/// Combine message `default` height.
public var combineHeight = CGFloat(70)

/// Location message `default` height.
public var locationHeight = CGFloat(70)

/// Custom contact card message `default` height.
public var contactCardHeight = CGFloat(90)

/// Alert message `default` height.
public var alertHeight = CGFloat(30)

/// Limit width of the message bubble.
public var limitBubbleWidth = CGFloat(ScreenWidth*(3/5.0))

/// Custom message `default` size exclude Alert&Contact.
public var extraCustomSize = CGSize(width: limitBubbleWidth, height: 36)

public let limitImageHeight = CGFloat((300/844)*ScreenHeight)

public let limitImageWidth = CGFloat((225/390)*ScreenWidth)

public let translationKey = "EaseChatUIKit_force_show_translation"

public let topicHeight = CGFloat(58)

public let reactionHeight = CGFloat(30)

public let reactionMaxWidth = Appearance.chat.contentStyle.contains(.withAvatar) ? ScreenWidth-48*2:40

@objcMembers open class MessageEntity: NSObject {
    
    required public override init() {
        super.init()
    }
    
    public var message: ChatMessage = ChatMessage()
    
    public var visibleReactionToIndex = 0
    
    /// Whether message show translations or not.
    public var showTranslation: Bool {
        set {
            if !newValue {
                self.message.ext?.removeValue(forKey: translationKey)
            } else {
                self.message.ext?[translationKey] = newValue
                ChatClient.shared().chatManager?.update(self.message)
            }
        }
        get {
            (self.message.ext?[translationKey] as? Bool) ?? false
        }
    }
        
    /// /// Message state.
    public var state: ChatMessageStatus = .sending
    
    /// Whether audio message playing or not.
    public var playing = false
    
    public var selected = false
    
    /// Message status image.
    public var stateImage: UIImage? {
        self.getStateImage()
    }
    
    open func getStateImage() -> UIImage? {
        switch self.state {
        case .sending:
            return UIImage(named: "message_status_spinner", in: .chatBundle, with: nil)
        case .succeed:
            return UIImage(named: "message_status_succeed", in: .chatBundle, with: nil)
        case .failure:
            return UIImage(named: "message_status_failure", in: .chatBundle, with: nil)
        case .delivered:
            return UIImage(named: "message_status_delivery", in: .chatBundle, with: nil)
        case .read:
            return UIImage(named: "message_status_read", in: .chatBundle, with: nil)
        }
    }
    
    /// Reply bubble size in the message.
    public private(set) lazy var replySize: CGSize = {
        self.updateReplySize()
    }()
    
    /// Bubble size of the message.
    public private(set) lazy var bubbleSize: CGSize = {
        self.updateBubbleSize()
    }()
    
    /// Height for row.
    public private(set) lazy var height: CGFloat = {
        self.cellHeight()
    }()
    
    open func cellHeight() -> CGFloat {
        if let body = self.message.body as? ChatCustomMessageBody,body.event == EaseChatUIKit_alert_message {
            return self.bubbleSize.height
        } else {
            return 8+(Appearance.chat.contentStyle.contains(.withNickName) ? 28:2)+(Appearance.chat.contentStyle.contains(.withReply) ? self.replySize.height:2)+self.bubbleSize.height+(Appearance.chat.contentStyle.contains(.withDateAndTime) ? 24:8)+self.topicContentHeight()+self.reactionContentHeight()
        }
    }
    
    open func reactionMenuWidth() -> CGFloat {
        if !Appearance.chat.contentStyle.contains(.withMessageReaction) {
            return 0
        }
        if let reactions = self.message.reactionList {
            if reactions.count > 0 {
                var width = CGFloat(0)
                for (index,reaction) in reactions.enumerated() {
                    let newWidth = width + CGFloat(reaction.reactionWidth+(index > 0 ? 4:0))
                    if newWidth < reactionMaxWidth - 30 {
                        width = newWidth
                        self.visibleReactionToIndex = index
                    } else {
                        self.visibleReactionToIndex = index
                        return width
                    }
                }
                return width
            }
            return 0;
        }
        return 0;
    }
    
    open func topicContentHeight() -> CGFloat {
        let realHeight = self.message.chatThread != nil ? topicHeight:CGFloat(0)
        let topic_height = Appearance.chat.contentStyle.contains(.withMessageTopic) ? realHeight:0
        return topic_height
    }
    
    open func reactionContentHeight() -> CGFloat {
        let realHeight = (self.message.reactionList?.count ?? 0) > 0 ? reactionHeight:CGFloat(0)
        let reaction_height = (Appearance.chat.contentStyle.contains(.withMessageReaction) ? realHeight:CGFloat(0))
        return reaction_height
    }
    
    /// Text message show content.
    public private(set) lazy var content: NSAttributedString? = {
        self.convertTextAttribute()
    }()
    
    public lazy var topicContent: NSAttributedString? = {
        self.convertTopicContent()
    }()
    
    /// Text message show translation
    public private(set) lazy var translation: NSAttributedString? = {
        if Appearance.chat.enableTranslation {
            return self.convertTextTranslationAttribute()
        } else {
            return nil
        }
    }()
    
    /// Reply title in bubble on current message.
    public private(set) lazy var replyTitle: NSAttributedString? = {
        self.convertReplyTitle()
    }()
    
    open func convertReplyTitle() -> NSAttributedString? {
        if let quoteMessage = self.message.quoteMessage {
            return NSAttributedString {
                AttributedText(quoteMessage.user?.nickname ?? quoteMessage.from).font(Font.theme.labelSmall).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralSpecialColor6:UIColor.theme.neutralSpecialColor5)
            }
        } else { return nil }
    }
    
    public private(set) lazy var replyContent: NSAttributedString? = {
        self.convertToReply()
    }()
            
    /// Calculate bubble size.
    /// - Returns: ``CGSize`` of bubble.
    open func updateBubbleSize() -> CGSize {
        switch self.message.body.type {
        case .text: return self.textSize()
        case .image: return self.thumbnailSize(video: false)
        case .voice: return self.audioSize()
        case .video: return self.thumbnailSize(video: true)
        case .file:  return CGSize(width: limitBubbleWidth, height: fileHeight)
        case .location: return self.message.contentSize
        case .combine: return self.message.contentSize
        case .custom: return self.customSize()
        default:
            return CGSize(width: limitBubbleWidth, height: 30)
        }
    }
    
    open func textSize() -> CGSize {
        let label = UILabel().numberOfLines(0).lineBreakMode(LanguageConvertor.chineseLanguage() ? .byCharWrapping:.byWordWrapping)
        label.attributedText = self.convertTextAttribute()
        let size = label.sizeThatFits(CGSize(width: limitBubbleWidth-24, height: 9999))
        let translateSize = Appearance.chat.enableTranslation ? self.translationSize():.zero
        return CGSize(width: size.width+24, height: size.height+14+(self.message.edited ? 24:0)+(self.showTranslation ? (translateSize.height > 0 ? (18+translateSize.height):0):0))
    }
    
    open func translationSize() -> CGSize {
        if self.showTranslation {
            let label = UILabel().numberOfLines(0).lineBreakMode(LanguageConvertor.chineseLanguage() ? .byCharWrapping:.byWordWrapping)
            label.attributedText = self.convertTextTranslationAttribute()
            let size = label.sizeThatFits(CGSize(width: limitBubbleWidth-24, height: 9999))
            return CGSize(width: size.width+24, height: size.height)
        } else {
            return .zero
        }
    }
    
    open func thumbnailSize(video: Bool) -> CGSize {
        let defaultSize = CGSize(width: 135, height: 135)
        var size = CGSize.zero
        if let body = self.message.body as? ChatImageMessageBody {
            size = body.size
        }
        if let body = self.message.body as? ChatVideoMessageBody {
            size = body.thumbnailSize
        }
        if size == .zero {
            if let body = self.message.body as? ChatImageMessageBody {
                size = body.size
            }
            if let body = self.message.body as? ChatVideoMessageBody {
                size = body.thumbnailSize
            }
            
            if size == .zero {
                if let path = (self.message.body as? ChatFileMessageBody)?.localPath {
                    size = UIImage(contentsOfFile: path)?.size ?? defaultSize
                } else {
                    size = defaultSize
                }
            }
        }
        let scale = size.width/size.height
        switch scale {
        case 0...0.1:
            return CGSize(width: limitImageHeight/10.0, height: limitImageHeight)
        case 0.1...0.75:
            return CGSize(width: limitImageHeight*(size.width/size.height), height: limitImageHeight)
        case 0.7501...10:
            return CGSize(width: limitImageWidth, height: limitImageWidth*(size.height/size.width))
        case 10...:
            return CGSize(width: limitImageWidth, height: limitImageWidth/10.0)
        default:
            return .zero
        }
    }
    
    open func audioSize() -> CGSize {
        switch Int((self.message.body as? ChatAudioMessageBody)?.duration ?? 1) {
        case 0...9:
            return CGSize(width: 75, height: audioHeight)
        case 10...19:
            return CGSize(width: 100, height: audioHeight)
        case 20...29:
            return CGSize(width: 125, height: audioHeight)
        case 30...39:
            return CGSize(width: 150, height: audioHeight)
        case 40...49:
            return CGSize(width: 175, height: audioHeight)
        case 50...Appearance.chat.audioDuration:
            return CGSize(width: limitBubbleWidth, height: audioHeight)
        default:
            return .zero
        }
    }
    
    open func customSize() -> CGSize {
        if let body = self.message.body as? ChatCustomMessageBody {
            if body.event == EaseChatUIKit_user_card_message {
                return CGSize(width: limitBubbleWidth, height: contactCardHeight)
            } else {
                if body.event == EaseChatUIKit_alert_message {
                    let label = UILabel().numberOfLines(0).lineBreakMode(LanguageConvertor.chineseLanguage() ? .byCharWrapping:.byWordWrapping)
                    label.attributedText = self.convertTextAttribute()
                    let size = label.sizeThatFits(CGSize(width: ScreenWidth, height: 9999))
                    return CGSize(width: ScreenWidth-32, height: size.height+50)
                } else {
                    return self.message.contentSize
                }
            }
        } else {
            return .zero
        }
    }
    
    /// Converts the message text into an attributed string, including the user's nickname, message text, and emojis.
    open func convertTextAttribute() -> NSAttributedString? {
        var text = NSMutableAttributedString()
        if self.message.body.type != .text, self.message.body.type != .custom {
            text.append(NSAttributedString {
                AttributedText(self.message.showType).foregroundColor(self.message.direction == .send ? Appearance.chat.sendTextColor:Appearance.chat.receiveTextColor).font(UIFont.theme.bodyLarge)
            })
            return text
        }
        if self.message.body.type == .custom,let body = self.message.body as? ChatCustomMessageBody {
            switch body.event {
            case EaseChatUIKit_alert_message:
                text.append(NSMutableAttributedString {
                    AttributedText(self.message.user?.nickname ?? self.message.from).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor7).font(UIFont.theme.labelSmall)
                })
                if let something = self.message.ext?["something"] as? String {
                    text.append(NSAttributedString {
                        AttributedText(" "+something).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor7).font(UIFont.theme.bodySmall)
                    })
                    
                    if let threadName = self.message.ext?["threadName"] as? String {
                        let range = something.chat.rangeOfString(threadName)
                        text.addAttribute(NSAttributedString.Key.foregroundColor, value: Theme.style == .dark ? Color.theme.primaryColor6:Color.theme.primaryColor5, range: range)
                    }
                }
            default:
                text.append(NSAttributedString {
                    AttributedText(self.message.showType).foregroundColor(self.message.direction == .send ? Appearance.chat.sendTextColor:Appearance.chat.receiveTextColor).font(UIFont.theme.bodyLarge)
                })
                break
            }
            
        } else {
            var result = self.message.showType
            for (key,value) in ChatEmojiConvertor.shared.oldEmojis {
                result = result.replacingOccurrences(of: key, with: value)
            }
            if self.message.mention.isEmpty {
                text.append(NSAttributedString {
                    AttributedText(result).foregroundColor(self.message.direction == .send ? Appearance.chat.sendTextColor:Appearance.chat.receiveTextColor).font(UIFont.theme.bodyLarge)
                })
            } else {
                let content = result
                let mentionRange = content.lowercased().chat.rangeOfString(self.message.mention.lowercased())
                let range = NSMakeRange(mentionRange.location-1, mentionRange.length+1)
                let mentionAttribute = NSMutableAttributedString {
                    AttributedText(content).foregroundColor(self.message.direction == .send ? Appearance.chat.sendTextColor:Appearance.chat.receiveTextColor).font(UIFont.theme.bodyLarge)
                }
                mentionAttribute.addAttribute(.foregroundColor, value: (Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5), range: range)
                text.append(mentionAttribute)
            }
            let string = text.string as NSString
            for symbol in ChatEmojiConvertor.shared.emojis {
                if string.range(of: symbol).location != NSNotFound {
                    let ranges = text.string.chat.rangesOfString(symbol)
                    text = ChatEmojiConvertor.shared.convertEmoji(input: text, ranges: ranges, symbol: symbol,imageBounds: CGRect(x: 0, y: -4, width: 18, height: 18))
                    text.addAttribute(.font, value: UIFont.theme.bodyLarge, range: NSMakeRange(0, text.length))
                    text.addAttribute(.foregroundColor, value: self.message.direction == .send ? Appearance.chat.sendTextColor:Appearance.chat.receiveTextColor, range: NSMakeRange(0, text.length))
                }
            }
        }
        return text
    }
    
    open func convertTopicContent() -> NSAttributedString? {
        guard let topicMessage = self.message.chatThread?.lastMessage else {
            return nil
        }
        var text = NSMutableAttributedString()
        let nickname = topicMessage.user?.nickname ?? topicMessage.from
        
        if topicMessage.body.type != .text {
            text.append(NSAttributedString {
                AttributedText(nickname+":"+topicMessage.showType).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5).font(UIFont.theme.labelSmall)
            })
            return text
        } else {
            var result = nickname+":"+topicMessage.showType
            for (key,value) in ChatEmojiConvertor.shared.oldEmojis {
                result = result.replacingOccurrences(of: key, with: value)
            }
            text.append(NSAttributedString {
                AttributedText(result).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5).font(UIFont.theme.labelSmall)
            })
            let string = text.string as NSString
            for symbol in ChatEmojiConvertor.shared.emojis {
                if string.range(of: symbol).location != NSNotFound {
                    let ranges = text.string.chat.rangesOfString(symbol)
                    text = ChatEmojiConvertor.shared.convertEmoji(input: text, ranges: ranges, symbol: symbol,imageBounds: CGRect(x: 0, y: -2, width: 14, height: 14))
                    text.addAttribute(.font, value: UIFont.theme.labelSmall, range: NSMakeRange(0, text.length))
                    text.addAttribute(.foregroundColor, value: Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5, range: NSMakeRange(0, text.length))
                }
            }
        }
        return text
    
    }
    
    open func convertTextTranslationAttribute() -> NSAttributedString? {
        var text = NSMutableAttributedString()
        if self.message.body.type != .text {
            text.append(NSAttributedString {
                AttributedText(self.message.showType).foregroundColor(self.message.direction == .send ? Appearance.chat.sendTranslationColor:Appearance.chat.receiveTranslationColor).font(UIFont.theme.bodyLarge)
            })
            return text
        } else {
            var result = self.message.translation ?? self.message.showType
            for (key,value) in ChatEmojiConvertor.shared.oldEmojis {
                result = result.replacingOccurrences(of: key, with: value)
            }
            text.append(NSAttributedString {
                AttributedText(result).foregroundColor(self.message.direction == .send ? Appearance.chat.sendTranslationColor:Appearance.chat.receiveTranslationColor).font(UIFont.theme.bodyLarge)
            })
            let string = text.string as NSString
            for symbol in ChatEmojiConvertor.shared.emojis {
                if string.range(of: symbol).location != NSNotFound {
                    let ranges = text.string.chat.rangesOfString(symbol)
                    text = ChatEmojiConvertor.shared.convertEmoji(input: text, ranges: ranges, symbol: symbol, imageBounds: CGRect(x: 0, y: -4, width: 18, height: 18))
                    text.addAttribute(.font, value: UIFont.theme.bodyLarge, range: NSMakeRange(0, text.length))
                    text.addAttribute(.foregroundColor, value: self.message.direction == .send ? Appearance.chat.sendTranslationColor:Appearance.chat.receiveTranslationColor, range: NSMakeRange(0, text.length))
                }
            }
            return text
        }
    }
    
    open func updateReplySize() -> CGSize {
        if let attributeContent = self.convertToReply(),let attributeTitle = self.replyTitle,attributeContent.length > 0 {
            let labelTitle = UILabel().numberOfLines(1).lineBreakMode(LanguageConvertor.chineseLanguage() ? .byCharWrapping:.byWordWrapping)
            let labelContent = UILabel().numberOfLines(2).lineBreakMode(LanguageConvertor.chineseLanguage() ? .byCharWrapping:.byWordWrapping)
            labelTitle.attributedText = attributeTitle
            labelContent.attributedText = attributeContent
            let titleSize = labelTitle.sizeThatFits(CGSize(width: limitBubbleWidth, height: 16))
            let contentSize = labelContent.sizeThatFits(CGSize(width: limitBubbleWidth, height: 36))
            if self.message.quoteMessage!.body.type == .image || self.message.quoteMessage!.body.type == .video {
                return CGSize(width: (titleSize.width > contentSize.width ? titleSize.width:contentSize.width)+78, height: 36+16)
            } else {
                return CGSize(width: (titleSize.width > contentSize.width ? titleSize.width:contentSize.width)+24, height: contentSize.height+34)
            }
        }
        return .zero
    }
        
    open func convertToReply() -> NSAttributedString? {
        if let quoteMessage = self.message.quoteMessage {
            if let msgSender = self.message.quoteMessage?.from,!msgSender.isEmpty  {
//                let showName = quoteMessage.user?.nickName ?? msgSender
                let reply = NSMutableAttributedString()
                if let icon = quoteMessage.replyIcon?.withTintColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5) {
                    reply.append(NSAttributedString {
                        ImageAttachment(icon, bounds: CGRect(x: 0, y: -4, width: 18, height: 18))
                    })
                }
                switch quoteMessage.body.type {
                case .text:
                    reply.append(NSAttributedString {
                        AttributedText(quoteMessage.showType).font(Font.theme.labelMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5)
                    })
                case .image,.video,.combine,.location:
                    reply.append(NSAttributedString {
                        AttributedText(quoteMessage.showType).font(Font.theme.labelMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5)
                    })
                case .file,.voice:
                    reply.append(NSAttributedString {
                        AttributedText(quoteMessage.showType).font(Font.theme.labelMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5)
                        AttributedText(quoteMessage.showContent).font(Font.theme.bodyMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5)
                    })
                case .custom:
                    if let body = quoteMessage.body as? ChatCustomMessageBody,body.event == EaseChatUIKit_user_card_message {
                        reply.append(NSAttributedString {
                            AttributedText(quoteMessage.showType).font(Font.theme.labelMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5)
                            AttributedText(quoteMessage.showContent).font(Font.theme.bodyMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5)
                        })
                    }
                default:
                    reply.append(NSAttributedString {
                        AttributedText(quoteMessage.showType).font(Font.theme.labelMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5)
                    })
                }
                return reply
            } else {
                return NSAttributedString {
                    AttributedText("message doesn't exist".chat.localize).font(Font.theme.bodyMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5)
                }
            }
        }
        return nil
    }
}


extension ChatMessage {
    
    /// ``EaseProfileProtocol``
    @objc public var user: EaseProfileProtocol? {
        EaseChatUIKitContext.shared?.chatCache?[self.from]
    }
    
    /// Whether message edited or not.
    @objc public var edited: Bool {
        if self.body.type != .text {
            return false
        } else {
            if let body = self.body as? ChatTextMessageBody {
                if body.operatorCount > 0,body.operationTime > 0 {
                    return true
                } else {
                    return false
                }
            }
            return false
        }
    }
    
    /// Message display date on conversation list cell.
    @objc open var showDate: String {
        let messageDate = Date(timeIntervalSince1970: TimeInterval(self.timestamp/1000))
        if messageDate.chat.compareDays() < 0 {
            return messageDate.chat.dateString(Appearance.conversation.dateFormatOtherDay)
        } else {
            return messageDate.chat.dateString(Appearance.conversation.dateFormatToday)
        }
    }
    
    /// Message display date on chat cell.
    @objc open var showDetailDate: String {
        let messageDate = Date(timeIntervalSince1970: TimeInterval(self.timestamp/1000))
        if messageDate.chat.compareDays() < 0 {
            return messageDate.chat.dateString(Appearance.chat.dateFormatOtherDay)
        } else {
            return messageDate.chat.dateString(Appearance.chat.dateFormatToday)
        }
    }
    
    /// Message show type on the conversation list.
    @objc open var showType: String {
        var text = "[unknown]".chat.localize
        switch self.body.type {
        case .text: text = (self.body as? ChatTextMessageBody)?.text ?? ""
        case .image: text = "[Image]".chat.localize
        case .voice: text = "[Audio]".chat.localize
        case .video: text = "[Video]".chat.localize
        case .file: text = "[File]".chat.localize
        case .location: text = "[Location]".chat.localize
        case .combine: text = "[Chat History]".chat.localize
        case .cmd: text = "[Transparent]".chat.localize
        case .custom:
            if let body = self.body as? ChatCustomMessageBody {
                if body.event == EaseChatUIKit_user_card_message {
                    text = "[Contact]".chat.localize
                }
                if body.event == EaseChatUIKit_alert_message {
                    text = self.from+":"+((self.ext?["something"] as? String) ?? "")
                }
            }
        default: break
        }
        return text.chat.localize
    }
    
    @objc open var replyIcon: UIImage? {
        switch self.body.type {
        case .image:
            return UIImage(named: "reply_image", in: .chatBundle, with: nil)
        case .voice:
            return UIImage(named: "reply_audio", in: .chatBundle, with: nil)
        case .video:
            return UIImage(named: "reply_video", in: .chatBundle, with: nil)
        case .file,.combine:
            return UIImage(named: "reply_file", in: .chatBundle, with: nil)
        case .location:
            return UIImage(named: "reply_location", in: .chatBundle, with: nil)
        case .custom:
            if let body = self.body as? ChatCustomMessageBody {
                if body.event == EaseChatUIKit_user_card_message {
                    return UIImage(named: "reply_card", in: .chatBundle, with: nil)
                }
            }
            return nil
        default:
            return nil
        }
    }
    
    /// Message show content.
    @objc open var showContent: String {
        var text = ""
        switch self.body.type {
        case .text: text = (self.body as? ChatTextMessageBody)?.text ?? ""
        case .voice: text = "\((self.body as? ChatAudioMessageBody)?.duration ?? 0)″"
        case .file: text = "\((self.body as? ChatFileMessageBody)?.displayName ?? "")"
        case .location: text = self.showType
        case .custom:
            if let body = self.body as? ChatCustomMessageBody {
                if body.event == EaseChatUIKit_user_card_message {
                    let userId = body.customExt["uid"] ?? ""
                    text = body.customExt["nickname"] ?? userId
                }
                if body.event == EaseChatUIKit_alert_message {
                    text = (self.ext?["something"] as? String) ?? ""
                }
            }
        default: break
        }
        return text
    }
    
    /// Text message if you were mentioned,the property isn't empty.
    @objc public var mention: String {
        if self.body.type == .text && self.direction == .receive,let conversation = ChatClient.shared().chatManager?.getConversation(self.conversationId, type: .groupChat, createIfNotExist: false) {
            if conversation.type == .groupChat {
                if let ext = self.ext, let atList = ext["em_at_list"] {
                    if let atListString = atList as? String {
                        if atListString == "All" {
                            return "All"
                        }
                    } else if let atListArray = atList as? [String] {
                        if ChatClient.shared().currentUsername?.count ?? 0 > 0 && atListArray.contains((ChatClient.shared().currentUsername ?? "").lowercased()) {
                            return (EaseChatUIKitContext.shared?.currentUser?.id ?? self.from).lowercased()
                        }
                    }
                }
            }
        }
        return ""
    }
    
    /// When you send a text message. Quote the message.
    @objc public var quoteMessage: ChatMessage? {
        guard let quoteInfo = self.ext?["msgQuote"] as? Dictionary<String,Any> else { return nil }
        guard let quoteMessageId = quoteInfo["msgID"] as? String else {
            return ChatMessage()
        }
        return ChatClient.shared().chatManager?.getMessageWithMessageId(quoteMessageId)
    }
    
    @objc open var contentSize: CGSize {
        switch self.body.type {
        case .custom:
            return extraCustomSize
        case .location:
            return CGSize(width: limitBubbleWidth, height: locationHeight)
        case .combine:
            return CGSize(width: limitBubbleWidth, height: combineHeight)
        default:
            return CGSize(width: limitBubbleWidth, height: 30)
        }
    }
    
    /// Translation of the text message.
    @objc public var translation: String? {
        (self.body as? ChatTextMessageBody)?.translations?.first?.value
    }
    
}



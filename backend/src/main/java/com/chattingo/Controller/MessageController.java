package com.chattingo.Controller;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.chattingo.Exception.ChatException;
import com.chattingo.Exception.MessageException;
import com.chattingo.Exception.UserException;
import com.chattingo.Model.Message;
import com.chattingo.Model.User;
import com.chattingo.Payload.ApiResponse;
import com.chattingo.Payload.SendMessageRequest;
import com.chattingo.ServiceImpl.MessageServiceImpl;
import com.chattingo.ServiceImpl.UserServiceImpl;
import com.chattingo.security.InputValidator;
import com.chattingo.util.LoggingUtil;

@RestController
@RequestMapping("/api/messages")
public class MessageController {

    private static final Logger logger = LoggerFactory.getLogger(MessageController.class);

    @Autowired
    private MessageServiceImpl messageService;

    @Autowired
    private UserServiceImpl userService;
    
    @Autowired
    private InputValidator inputValidator;

    @PostMapping("/create")
    public ResponseEntity<Message> sendMessageHandler(@RequestBody SendMessageRequest sendMessageRequest,
            @RequestHeader("Authorization") String jwt) throws UserException, ChatException, MessageException {

        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);

        try {
            User user = this.userService.findUserProfile(jwt);
            LoggingUtil.setUserContext(user.getId());
            LoggingUtil.setChatContext(sendMessageRequest.getChatId());

            // Enhanced input validation for message content
            String content = sendMessageRequest.getContent();
            if (!inputValidator.isValidMessageContent(content)) {
                logger.warn("Invalid message content from user: {}", user.getId());
                throw new MessageException("Invalid message content. Please check for harmful content or length limits.");
            }
            
            // Sanitize message content
            content = inputValidator.sanitizeInput(content);
            sendMessageRequest.setContent(content);

            logger.info("Sending message - User: {}, Chat: {}, Content Length: {}", 
                user.getId(), sendMessageRequest.getChatId(), 
                sendMessageRequest.getContent() != null ? sendMessageRequest.getContent().length() : 0);

            sendMessageRequest.setUserId(user.getId());

            Message message = this.messageService.sendMessage(sendMessageRequest);
            LoggingUtil.setMessageContext(message.getId());

            LoggingUtil.logMessageEvent(logger, "MESSAGE_SENT", message.getId(), 
                sendMessageRequest.getChatId(), user.getId(), "TEXT", 
                "Message sent successfully");

            logger.info("Message sent successfully - Message ID: {}, Chat: {}, User: {}", 
                message.getId(), sendMessageRequest.getChatId(), user.getId());

            return new ResponseEntity<Message>(message, HttpStatus.OK);

        } catch (Exception e) {
            LoggingUtil.logError(logger, "SEND_MESSAGE", e, 
                java.util.Map.of("chatId", sendMessageRequest.getChatId(),
                              "contentLength", sendMessageRequest.getContent() != null ? 
                                sendMessageRequest.getContent().length() : 0));
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }

    @GetMapping("/{chatId}")
    public ResponseEntity<List<Message>> getChatMessageHandler(@PathVariable Integer chatId,
            @RequestHeader("Authorization") String jwt) throws UserException, ChatException {

        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);
        LoggingUtil.setChatContext(chatId);

        try {
            User user = this.userService.findUserProfile(jwt);
            LoggingUtil.setUserContext(user.getId());

            logger.debug("Fetching messages for chat: {}, User: {}", chatId, user.getId());

            List<Message> messages = this.messageService.getChatsMessages(chatId, user);

            logger.info("Retrieved {} messages for chat: {}, User: {}", 
                messages.size(), chatId, user.getId());

            LoggingUtil.logChatEvent(logger, "MESSAGES_RETRIEVED", chatId, user.getId(),
                "Retrieved " + messages.size() + " messages from chat");

            return new ResponseEntity<List<Message>>(messages, HttpStatus.OK);

        } catch (Exception e) {
            LoggingUtil.logError(logger, "GET_CHAT_MESSAGES", e, 
                java.util.Map.of("chatId", chatId));
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }

    @DeleteMapping("/{messageId}")
    public ResponseEntity<ApiResponse> deleteMessageHandler(@PathVariable Integer messageId,
            @RequestHeader("Authorization") String jwt) throws UserException, ChatException, MessageException {

        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);
        LoggingUtil.setMessageContext(messageId);

        try {
            User user = this.userService.findUserProfile(jwt);
            LoggingUtil.setUserContext(user.getId());

            logger.info("Deleting message - Message ID: {}, User: {}", messageId, user.getId());

            this.messageService.deleteMessage(messageId, user);

            LoggingUtil.logMessageEvent(logger, "MESSAGE_DELETED", messageId, null, 
                user.getId(), "DELETE", "Message deleted by user");

            ApiResponse res = new ApiResponse("Deleted successfully......", false);

            logger.info("Message {} successfully deleted by user {}", messageId, user.getId());
            return new ResponseEntity<>(res, HttpStatus.OK);

        } catch (Exception e) {
            LoggingUtil.logError(logger, "DELETE_MESSAGE", e, 
                java.util.Map.of("messageId", messageId));
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }
}

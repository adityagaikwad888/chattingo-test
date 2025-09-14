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
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.chattingo.Exception.ChatException;
import com.chattingo.Exception.UserException;
import com.chattingo.Model.Chat;
import com.chattingo.Model.User;
import com.chattingo.Payload.ApiResponse;
import com.chattingo.Payload.GroupChatRequest;
import com.chattingo.Payload.SingleChatRequest;
import com.chattingo.ServiceImpl.ChatServiceImpl;
import com.chattingo.ServiceImpl.UserServiceImpl;
import com.chattingo.util.LoggingUtil;

@RestController
@RequestMapping("/api/chats")
public class ChatController {

    private static final Logger logger = LoggerFactory.getLogger(ChatController.class);

    @Autowired
    private ChatServiceImpl chatService;

    @Autowired
    private UserServiceImpl userService;

    @PostMapping("/single")
    public ResponseEntity<Chat> createChatHandler(@RequestBody SingleChatRequest singleChatRequest,
            @RequestHeader("Authorization") String jwt) throws UserException {

        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);

        try {
            User reqUser = this.userService.findUserProfile(jwt);
            LoggingUtil.setUserContext(reqUser.getId());

            logger.info("Creating single chat - Requester: {}, Target User: {}", 
                reqUser.getId(), singleChatRequest.getUserId());

            Chat chat = this.chatService.createChat(reqUser, singleChatRequest.getUserId());
            LoggingUtil.setChatContext(chat.getId());

            LoggingUtil.logChatEvent(logger, "SINGLE_CHAT_CREATED", chat.getId(), reqUser.getId(),
                "Single chat created between users: " + reqUser.getId() + " and " + singleChatRequest.getUserId());

            logger.info("Single chat created successfully - Chat ID: {}", chat.getId());
            return new ResponseEntity<Chat>(chat, HttpStatus.CREATED);

        } catch (Exception e) {
            LoggingUtil.logError(logger, "CREATE_SINGLE_CHAT", e, 
                java.util.Map.of("targetUserId", singleChatRequest.getUserId()));
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }

    @PostMapping("/group")
    public ResponseEntity<Chat> createGroupHandler(@RequestBody GroupChatRequest groupChatRequest,
            @RequestHeader("Authorization") String jwt) throws UserException {

        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);

        try {
            User reqUser = this.userService.findUserProfile(jwt);
            LoggingUtil.setUserContext(reqUser.getId());

            logger.info("Creating group chat - Requester: {}, Group Name: {}, User Count: {}", 
                reqUser.getId(), groupChatRequest.getChatName(), groupChatRequest.getUserIds().size());

            Chat chat = this.chatService.createGroup(groupChatRequest, reqUser);
            LoggingUtil.setChatContext(chat.getId());

            LoggingUtil.logChatEvent(logger, "GROUP_CHAT_CREATED", chat.getId(), reqUser.getId(),
                "Group chat created: " + groupChatRequest.getChatName() + " with " + 
                groupChatRequest.getUserIds().size() + " users");

            logger.info("Group chat created successfully - Chat ID: {}, Name: {}", 
                chat.getId(), chat.getChatName());
            return new ResponseEntity<Chat>(chat, HttpStatus.CREATED);

        } catch (Exception e) {
            LoggingUtil.logError(logger, "CREATE_GROUP_CHAT", e, 
                java.util.Map.of("chatName", groupChatRequest.getChatName(), 
                              "userCount", groupChatRequest.getUserIds().size()));
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }

    @GetMapping("/{chatId}")
    public ResponseEntity<Chat> findChatByIdHandler(@PathVariable int chatId) throws ChatException {

        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);
        LoggingUtil.setChatContext(chatId);

        try {
            logger.debug("Fetching chat by ID: {}", chatId);

            Chat chat = this.chatService.findChatById(chatId);

            logger.debug("Chat found - ID: {}, Type: {}", chat.getId(), 
                chat.isGroup() ? "GROUP" : "SINGLE");

            return new ResponseEntity<Chat>(chat, HttpStatus.OK);

        } catch (Exception e) {
            LoggingUtil.logError(logger, "FIND_CHAT_BY_ID", e, 
                java.util.Map.of("chatId", chatId));
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }

    @GetMapping("/user")
    public ResponseEntity<List<Chat>> findChatByUserIdHandler(@RequestHeader("Authorization") String jwt)
            throws UserException {

        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);

        try {
            User reqUser = this.userService.findUserProfile(jwt);
            LoggingUtil.setUserContext(reqUser.getId());

            logger.debug("Fetching chats for user: {}", reqUser.getId());

            List<Chat> chats = this.chatService.findAllChatByUserId(reqUser.getId());

            logger.info("Found {} chats for user: {}", chats.size(), reqUser.getId());

            return new ResponseEntity<List<Chat>>(chats, HttpStatus.OK);

        } catch (Exception e) {
            LoggingUtil.logError(logger, "FIND_USER_CHATS", e, java.util.Map.of());
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }

    @PutMapping("/{chatId}/add/{userId}")
    public ResponseEntity<Chat> addUserToGroupHandler(@PathVariable Integer chatId,
            @PathVariable Integer userId, @RequestHeader("Authorization") String jwt)
            throws UserException, ChatException {

        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);
        LoggingUtil.setChatContext(chatId);

        try {
            User reqUser = this.userService.findUserProfile(jwt);
            LoggingUtil.setUserContext(reqUser.getId());

            logger.info("Adding user to group - Chat: {}, User to add: {}, Requester: {}", 
                chatId, userId, reqUser.getId());

            Chat chat = this.chatService.addUserToGroup(userId, chatId, reqUser);

            LoggingUtil.logChatEvent(logger, "USER_ADDED_TO_GROUP", chatId, reqUser.getId(),
                "User " + userId + " added to group by " + reqUser.getId());

            logger.info("User {} successfully added to group chat {}", userId, chatId);
            return new ResponseEntity<>(chat, HttpStatus.OK);

        } catch (Exception e) {
            LoggingUtil.logError(logger, "ADD_USER_TO_GROUP", e, 
                java.util.Map.of("chatId", chatId, "userIdToAdd", userId));
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }

    @PutMapping("/{chatId}/remove/{userId}")
    public ResponseEntity<Chat> removeUserFromGroupHandler(@PathVariable Integer chatId,
            @PathVariable Integer userId, @RequestHeader("Authorization") String jwt)
            throws UserException, ChatException {

        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);
        LoggingUtil.setChatContext(chatId);

        try {
            User reqUser = this.userService.findUserProfile(jwt);
            LoggingUtil.setUserContext(reqUser.getId());

            logger.info("Removing user from group - Chat: {}, User to remove: {}, Requester: {}", 
                chatId, userId, reqUser.getId());

            Chat chat = this.chatService.removeFromGroup(userId, chatId, reqUser);

            LoggingUtil.logChatEvent(logger, "USER_REMOVED_FROM_GROUP", chatId, reqUser.getId(),
                "User " + userId + " removed from group by " + reqUser.getId());

            logger.info("User {} successfully removed from group chat {}", userId, chatId);
            return new ResponseEntity<>(chat, HttpStatus.OK);

        } catch (Exception e) {
            LoggingUtil.logError(logger, "REMOVE_USER_FROM_GROUP", e, 
                java.util.Map.of("chatId", chatId, "userIdToRemove", userId));
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }

    @DeleteMapping("/delete/{chatId}")
    public ResponseEntity<ApiResponse> deleteChatHandler(@PathVariable Integer chatId,
            @RequestHeader("Authorization") String jwt)
            throws UserException, ChatException {

        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);
        LoggingUtil.setChatContext(chatId);

        try {
            User reqUser = this.userService.findUserProfile(jwt);
            LoggingUtil.setUserContext(reqUser.getId());

            logger.info("Deleting chat - Chat ID: {}, Requester: {}", chatId, reqUser.getId());

            this.chatService.deleteChat(chatId, reqUser.getId());

            LoggingUtil.logChatEvent(logger, "CHAT_DELETED", chatId, reqUser.getId(),
                "Chat deleted by user " + reqUser.getId());

            ApiResponse res = new ApiResponse("Deleted Successfully...", false);

            logger.info("Chat {} successfully deleted by user {}", chatId, reqUser.getId());
            return new ResponseEntity<>(res, HttpStatus.OK);

        } catch (Exception e) {
            LoggingUtil.logError(logger, "DELETE_CHAT", e, 
                java.util.Map.of("chatId", chatId));
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }
}

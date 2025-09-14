package com.chattingo.Controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import com.chattingo.Model.Message;
import com.chattingo.util.LoggingUtil;

@Controller
public class RealTimeChat {

    private static final Logger logger = LoggerFactory.getLogger(RealTimeChat.class);

    @Autowired
    private SimpMessagingTemplate simpMessagingTemplate;

    @MessageMapping("/message")
    @SendTo("/group/public")
    public Message receiveMessage(@Payload Message message) {
        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);

        try {
            if (message.getChat() != null) {
                LoggingUtil.setChatContext(message.getChat().getId());
            }
            if (message.getUser() != null) {
                LoggingUtil.setUserContext(message.getUser().getId());
            }

            logger.info("WebSocket message received - Chat: {}, User: {}, Content Length: {}", 
                message.getChat() != null ? message.getChat().getId() : "unknown",
                message.getUser() != null ? message.getUser().getId() : "unknown",
                message.getContent() != null ? message.getContent().length() : 0);

            // Send message to specific chat group
            String destination = "/group/" + (message.getChat() != null ? message.getChat().getId().toString() : "unknown");
            simpMessagingTemplate.convertAndSend(destination, message);

            LoggingUtil.logWebSocketEvent(logger, "MESSAGE_BROADCAST", 
                correlationId, 
                message.getUser() != null ? message.getUser().getId() : null,
                "Message broadcasted to " + destination);

            logger.debug("WebSocket message broadcasted to: {}", destination);
            
            return message;

        } catch (Exception e) {
            LoggingUtil.logError(logger, "WEBSOCKET_MESSAGE_ERROR", e, 
                java.util.Map.of("chatId", message.getChat() != null ? message.getChat().getId() : "unknown",
                              "userId", message.getUser() != null ? message.getUser().getId() : "unknown"));
            logger.error("Error processing WebSocket message: {}", e.getMessage(), e);
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }
}

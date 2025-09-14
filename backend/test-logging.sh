#!/bin/bash

echo "=== Chattingo Logging System Test ==="
echo "Testing all log categories..."

# Function to add timestamp
get_timestamp() {
    date -u -Iseconds
}

# Test Application Logs
echo "1. Testing Application Logs..."
echo "{\"@timestamp\":\"$(get_timestamp)\",\"level\":\"INFO\",\"message\":\"Application health check performed\",\"service\":\"chattingo-backend\",\"category\":\"application\",\"component\":\"health-monitor\"}" >> /var/log/chattingo/app/application.log

# Test Authentication Logs  
echo "2. Testing Authentication Logs..."
echo "{\"@timestamp\":\"$(get_timestamp)\",\"level\":\"INFO\",\"message\":\"User login attempt\",\"service\":\"chattingo-backend\",\"category\":\"authentication\",\"email\":\"testuser@example.com\",\"success\":true,\"ip_address\":\"192.168.1.100\"}" >> /var/log/chattingo/auth/auth.log

# Test Chat Logs
echo "3. Testing Chat Logs..."
echo "{\"@timestamp\":\"$(get_timestamp)\",\"level\":\"INFO\",\"message\":\"New message sent in chat\",\"service\":\"chattingo-backend\",\"category\":\"chat\",\"chat_id\":1001,\"user_id\":12,\"message_type\":\"text\",\"message_length\":45}" >> /var/log/chattingo/chat/chat.log

# Test Error Logs
echo "4. Testing Error Logs..."
echo "{\"@timestamp\":\"$(get_timestamp)\",\"level\":\"ERROR\",\"message\":\"Database connection failed\",\"service\":\"chattingo-backend\",\"category\":\"error\",\"error_type\":\"ConnectionException\",\"retry_count\":3}" >> /var/log/chattingo/error/error.log

# Test System Logs
echo "5. Testing System Logs..."
echo "{\"@timestamp\":\"$(get_timestamp)\",\"level\":\"WARN\",\"message\":\"High CPU usage detected\",\"service\":\"chattingo-backend\",\"category\":\"system\",\"cpu_usage\":87,\"memory_usage\":65,\"active_connections\":250}" >> /var/log/chattingo/system/system.log

# Test WebSocket Logs
echo "6. Testing WebSocket Logs..."
echo "{\"@timestamp\":\"$(get_timestamp)\",\"level\":\"INFO\",\"message\":\"WebSocket connection established\",\"service\":\"chattingo-backend\",\"category\":\"websocket\",\"user_id\":15,\"session_id\":\"ws-session-12345\",\"connection_type\":\"upgrade\"}" >> /var/log/chattingo/websocket/websocket.log

echo "7. Generating realistic chat activity..."
for i in {1..5}; do
    echo "{\"@timestamp\":\"$(get_timestamp)\",\"level\":\"INFO\",\"message\":\"Chat message #$i sent\",\"service\":\"chattingo-backend\",\"category\":\"chat\",\"chat_id\":$((1000 + i)),\"user_id\":$((10 + i)),\"message_type\":\"text\",\"message_length\":$((20 + i * 5))}" >> /var/log/chattingo/chat/chat.log
    sleep 1
done

echo "8. Generating authentication events..."
for i in {1..3}; do
    echo "{\"@timestamp\":\"$(get_timestamp)\",\"level\":\"INFO\",\"message\":\"User authentication event #$i\",\"service\":\"chattingo-backend\",\"category\":\"authentication\",\"email\":\"user$i@test.com\",\"success\":true,\"auth_method\":\"jwt\"}" >> /var/log/chattingo/auth/auth.log
    sleep 1
done

echo "=== Log Generation Complete ==="
echo "Checking file sizes..."
for dir in app auth chat error system websocket; do
    size=$(wc -l < /var/log/chattingo/$dir/*.log 2>/dev/null || echo "0")
    echo "$dir: $size lines"
done

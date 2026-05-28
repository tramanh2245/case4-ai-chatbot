package com.case4.chatbot.controller;

import com.case4.chatbot.dto.ChatRequest;
import com.case4.chatbot.model.ChatMessage;
import com.case4.chatbot.service.ChatbotService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatbotService chatbotService;

    @PostMapping
    public ResponseEntity<Map<String, String>> chat(@Valid @RequestBody ChatRequest request) {
        Map<String, String> response = chatbotService.getResponse(
            request.getMessage(),
            request.getSessionId(),
            request.getApiKey()
        );
        return ResponseEntity.ok(response);
    }

    @GetMapping("/history/{sessionId}")
    public ResponseEntity<List<ChatMessage>> getHistory(@PathVariable String sessionId) {
        return ResponseEntity.ok(chatbotService.getHistory(sessionId));
    }

    @DeleteMapping("/history/{sessionId}")
    public ResponseEntity<Void> clearHistory(@PathVariable String sessionId) {
        chatbotService.clearHistory(sessionId);
        return ResponseEntity.noContent().build();
    }
}

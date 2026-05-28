package com.case4.chatbot.controller;

import com.case4.chatbot.dto.EmojiRequest;
import com.case4.chatbot.service.EmojiService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/emoji")
@RequiredArgsConstructor
public class EmojiController {

    private final EmojiService emojiService;

    @PostMapping("/suggest")
    public ResponseEntity<Map<String, Object>> suggest(@Valid @RequestBody EmojiRequest request) {
        return ResponseEntity.ok(emojiService.suggest(request.getText()));
    }
}

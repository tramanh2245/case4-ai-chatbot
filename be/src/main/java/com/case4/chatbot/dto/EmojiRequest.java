package com.case4.chatbot.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class EmojiRequest {
    @NotBlank(message = "Text is required")
    private String text;
}

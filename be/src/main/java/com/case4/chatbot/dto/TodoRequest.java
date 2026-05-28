package com.case4.chatbot.dto;

import com.case4.chatbot.model.Todo;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class TodoRequest {
    @NotBlank(message = "Title is required")
    private String title;
    private String category = "general";
    private Todo.Priority priority = Todo.Priority.MEDIUM;
}

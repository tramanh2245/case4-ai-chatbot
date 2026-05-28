package com.case4.chatbot.controller;

import com.case4.chatbot.dto.SuggestionDto;
import com.case4.chatbot.dto.TodoRequest;
import com.case4.chatbot.model.Todo;
import com.case4.chatbot.service.TodoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/todos")
@RequiredArgsConstructor
public class TodoController {

    private final TodoService todoService;

    @GetMapping
    public ResponseEntity<List<Todo>> getPending() {
        return ResponseEntity.ok(todoService.getPending());
    }

    @GetMapping("/completed")
    public ResponseEntity<List<Todo>> getCompleted() {
        return ResponseEntity.ok(todoService.getCompleted());
    }

    @PostMapping
    public ResponseEntity<Todo> addTask(@Valid @RequestBody TodoRequest request) {
        return ResponseEntity.ok(todoService.addTask(request));
    }

    @PutMapping("/{id}/complete")
    public ResponseEntity<Todo> completeTask(@PathVariable Long id) {
        return ResponseEntity.ok(todoService.completeTask(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(@PathVariable Long id) {
        todoService.deleteTask(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/suggestions")
    public ResponseEntity<List<SuggestionDto>> getSuggestions() {
        return ResponseEntity.ok(todoService.getSuggestions());
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStats() {
        return ResponseEntity.ok(todoService.getStats());
    }
}

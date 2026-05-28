package com.case4.chatbot.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "chat_messages")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(length = 5000)
    private String userMessage;

    @Column(length = 5000)
    private String botResponse;

    private String sessionId;

    @Builder.Default
    private LocalDateTime timestamp = LocalDateTime.now();
}

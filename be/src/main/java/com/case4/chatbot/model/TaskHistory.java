package com.case4.chatbot.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "task_history")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TaskHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String category;
    private Integer dayOfWeek;
    private Integer hourOfDay;

    @Enumerated(EnumType.STRING)
    private Todo.Priority priority;

    @Builder.Default
    private LocalDateTime completedAt = LocalDateTime.now();
}

package com.case4.chatbot.repository;

import com.case4.chatbot.model.Todo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TodoRepository extends JpaRepository<Todo, Long> {
    List<Todo> findByCompletedFalseOrderByCreatedAtDesc();
    List<Todo> findByCompletedTrueOrderByCompletedAtDesc();
}

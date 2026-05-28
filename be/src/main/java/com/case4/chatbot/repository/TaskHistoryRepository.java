package com.case4.chatbot.repository;

import com.case4.chatbot.model.TaskHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TaskHistoryRepository extends JpaRepository<TaskHistory, Long> {

    @Query("SELECT h FROM TaskHistory h WHERE h.dayOfWeek = :day ORDER BY h.completedAt DESC")
    List<TaskHistory> findByDayOfWeek(@Param("day") int dayOfWeek);

    @Query("SELECT h.title, COUNT(h) as cnt FROM TaskHistory h GROUP BY h.title ORDER BY cnt DESC")
    List<Object[]> findTopTitles();
}

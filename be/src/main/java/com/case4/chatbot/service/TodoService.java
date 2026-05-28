package com.case4.chatbot.service;

import com.case4.chatbot.dto.SuggestionDto;
import com.case4.chatbot.dto.TodoRequest;
import com.case4.chatbot.model.TaskHistory;
import com.case4.chatbot.model.Todo;
import com.case4.chatbot.repository.TaskHistoryRepository;
import com.case4.chatbot.repository.TodoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TodoService {

    private final TodoRepository todoRepository;
    private final TaskHistoryRepository historyRepository;

    private static final String[] DAY_NAMES = {
        "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm",
        "Thứ Sáu", "Thứ Bảy", "Chủ Nhật"
    };

    public Todo addTask(TodoRequest request) {
        LocalDateTime now = LocalDateTime.now();
        Todo todo = Todo.builder()
            .title(request.getTitle())
            .category(request.getCategory())
            .priority(request.getPriority())
            .dayOfWeek(now.getDayOfWeek().getValue() - 1)
            .hourOfDay(now.getHour())
            .build();
        return todoRepository.save(todo);
    }

    public List<Todo> getPending() {
        return todoRepository.findByCompletedFalseOrderByCreatedAtDesc();
    }

    public List<Todo> getCompleted() {
        return todoRepository.findByCompletedTrueOrderByCompletedAtDesc();
    }

    public Todo completeTask(Long id) {
        Todo todo = todoRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Task not found: " + id));

        todo.setCompleted(true);
        todo.setCompletedAt(LocalDateTime.now());
        todoRepository.save(todo);

        TaskHistory history = TaskHistory.builder()
            .title(todo.getTitle())
            .category(todo.getCategory())
            .priority(todo.getPriority())
            .dayOfWeek(todo.getDayOfWeek())
            .hourOfDay(todo.getHourOfDay())
            .build();
        historyRepository.save(history);

        return todo;
    }

    public void deleteTask(Long id) {
        todoRepository.deleteById(id);
    }

    public Map<String, Object> getStats() {
        long total = todoRepository.count();
        long completed = todoRepository.findByCompletedTrueOrderByCompletedAtDesc().size();
        Map<String, Object> stats = new HashMap<>();
        stats.put("total", total);
        stats.put("completed", completed);
        stats.put("pending", total - completed);
        stats.put("historyCount", historyRepository.count());
        return stats;
    }

    public List<SuggestionDto> getSuggestions() {
        LocalDateTime now = LocalDateTime.now();
        int currentDay = now.getDayOfWeek().getValue() - 1;
        int currentHour = now.getHour();

        long historyCount = historyRepository.count();
        if (historyCount < 2) {
            return getTimeSuggestions(currentHour);
        }

        List<TaskHistory> allHistory = historyRepository.findAll();
        Set<String> activeTitles = todoRepository.findByCompletedFalseOrderByCreatedAtDesc()
            .stream().map(Todo::getTitle).collect(Collectors.toSet());

        Map<String, Double> scoreMap = new HashMap<>();
        for (TaskHistory h : allHistory) {
            double dayBonus = (h.getDayOfWeek() != null && h.getDayOfWeek() == currentDay) ? 1.8 : 0.6;
            int hourDiff = Math.abs((h.getHourOfDay() != null ? h.getHourOfDay() : 12) - currentHour);
            double hourScore = Math.max(0, 1.0 - hourDiff / 8.0);
            double score = dayBonus * (0.5 + hourScore);
            scoreMap.merge(h.getTitle(), score, Double::sum);
        }

        double maxScore = scoreMap.values().stream().mapToDouble(Double::doubleValue).max().orElse(1.0);

        return scoreMap.entrySet().stream()
            .filter(e -> !activeTitles.contains(e.getKey()))
            .sorted(Map.Entry.<String, Double>comparingByValue().reversed())
            .limit(5)
            .map(e -> SuggestionDto.builder()
                .title(e.getKey())
                .confidence(Math.min((int) ((e.getValue() / maxScore) * 85) + 10, 95))
                .reason("Bạn thường làm vào " + DAY_NAMES[currentDay] + " lúc " + currentHour + "h")
                .build())
            .collect(Collectors.toList());
    }

    private List<SuggestionDto> getTimeSuggestions(int hour) {
        if (hour >= 5 && hour < 9) {
            return List.of(
                SuggestionDto.builder().title("Kiểm tra email buổi sáng").confidence(88).reason("Thói quen buổi sáng phổ biến").build(),
                SuggestionDto.builder().title("Lập kế hoạch ngày hôm nay").confidence(82).reason("Thời điểm tốt nhất để lên kế hoạch").build(),
                SuggestionDto.builder().title("Tập thể dục buổi sáng").confidence(70).reason("Khởi động ngày mới năng động").build()
            );
        } else if (hour >= 9 && hour < 12) {
            return List.of(
                SuggestionDto.builder().title("Xử lý công việc ưu tiên cao").confidence(90).reason("Buổi sáng – thời điểm năng suất nhất").build(),
                SuggestionDto.builder().title("Họp team / meeting").confidence(75).reason("Khung giờ họp phổ biến").build()
            );
        } else if (hour >= 12 && hour < 14) {
            return List.of(
                SuggestionDto.builder().title("Ăn trưa và nghỉ ngơi").confidence(95).reason("Giờ nghỉ trưa").build(),
                SuggestionDto.builder().title("Đọc tin tức / học hỏi").confidence(60).reason("Tận dụng thời gian nghỉ").build()
            );
        } else if (hour >= 14 && hour < 18) {
            return List.of(
                SuggestionDto.builder().title("Review tiến độ công việc").confidence(80).reason("Kiểm tra cuối buổi chiều").build(),
                SuggestionDto.builder().title("Trả lời email và tin nhắn").confidence(75).reason("Khung giờ giao tiếp hiệu quả").build()
            );
        } else {
            return List.of(
                SuggestionDto.builder().title("Tổng kết công việc trong ngày").confidence(78).reason("Thói quen review cuối ngày").build(),
                SuggestionDto.builder().title("Lên kế hoạch cho ngày mai").confidence(82).reason("Chuẩn bị trước một bước").build(),
                SuggestionDto.builder().title("Đọc sách / học kỹ năng mới").confidence(68).reason("Buổi tối – thời gian phát triển bản thân").build()
            );
        }
    }
}

package com.case4.chatbot.service;

import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class EmojiService {

    private static final Map<String, EmotionData> EMOTIONS = new LinkedHashMap<>();

    static {
        EMOTIONS.put("happy", new EmotionData(
            "Vui vẻ",
            new String[]{"vui", "hạnh phúc", "tuyệt", "tốt", "thích", "sướng", "phấn khởi", "tuyệt vời", "great", "happy", "joy", "good", "wonderful", "amazing"},
            new String[]{"😊", "😄", "🎉", "😁", "✨", "🌟", "🥳", "😃"}
        ));
        EMOTIONS.put("sad", new EmotionData(
            "Buồn bã",
            new String[]{"buồn", "khóc", "thất vọng", "chán", "mệt mỏi", "tệ", "khổ", "đau", "tiếc", "sad", "cry", "miss", "lonely", "disappoint"},
            new String[]{"😢", "😔", "💔", "😞", "🥺", "😭", "😿", "🫂"}
        ));
        EMOTIONS.put("angry", new EmotionData(
            "Tức giận",
            new String[]{"tức", "giận", "bực", "khó chịu", "ghét", "điên", "ức", "phẫn nộ", "angry", "mad", "hate", "furious", "rage"},
            new String[]{"😠", "😤", "🔥", "💢", "😡", "🤬", "👿", "⚡"}
        ));
        EMOTIONS.put("surprised", new EmotionData(
            "Ngạc nhiên",
            new String[]{"ồ", "wow", "thật không", "bất ngờ", "ngạc nhiên", "không tin", "trời ơi", "omg", "really", "shock", "whoa", "no way"},
            new String[]{"😮", "😲", "🤯", "😱", "👀", "🫢", "‼️", "❗"}
        ));
        EMOTIONS.put("love", new EmotionData(
            "Yêu thương",
            new String[]{"yêu", "thương", "nhớ", "trái tim", "crush", "đáng yêu", "dễ thương", "cute", "love", "heart", "adore", "sweet", "darling"},
            new String[]{"❤️", "😍", "🥰", "💕", "💖", "💝", "😘", "💗"}
        ));
        EMOTIONS.put("excited", new EmotionData(
            "Phấn khích",
            new String[]{"hứng khởi", "phấn khích", "háo hức", "không thể tin", "xịn", "quá đỉnh", "cháy", "excited", "cant wait", "finally", "lets go"},
            new String[]{"🚀", "🎊", "🎈", "⚡", "🌟", "💥", "🔥", "🙌"}
        ));
        EMOTIONS.put("tired", new EmotionData(
            "Mệt mỏi",
            new String[]{"mệt", "buồn ngủ", "kiệt sức", "ngủ", "căng thẳng", "tired", "sleepy", "exhausted", "sleep", "stress", "burnout"},
            new String[]{"😴", "😪", "💤", "🥱", "😫", "😩", "🛌", "☕"}
        ));
        EMOTIONS.put("funny", new EmotionData(
            "Hài hước",
            new String[]{"haha", "hehe", "hihi", "buồn cười", "hài", "lol", "funny", "hilarious", "laughing", "joke"},
            new String[]{"😂", "🤣", "😆", "😝", "🤭", "😹", "💀", "🤪"}
        ));
        EMOTIONS.put("cool", new EmotionData(
            "Cool/Ngầu",
            new String[]{"ngầu", "cool", "xịn", "đỉnh", "pro", "bá đạo", "awesome", "epic", "legend", "dope", "sick"},
            new String[]{"😎", "🤙", "👊", "✌️", "🤘", "💪", "🦁", "🔥"}
        ));
        EMOTIONS.put("thinking", new EmotionData(
            "Suy nghĩ",
            new String[]{"hmm", "nghĩ", "suy nghĩ", "không chắc", "có lẽ", "tự hỏi", "thắc mắc", "maybe", "perhaps", "wonder", "idk"},
            new String[]{"🤔", "💭", "🧐", "🤷", "❓", "🫤", "😶", "🙄"}
        ));
        EMOTIONS.put("celebrate", new EmotionData(
            "Chúc mừng",
            new String[]{"chúc mừng", "congratulations", "sinh nhật", "thành công", "đỗ", "chiến thắng", "giỏi", "congrats", "birthday", "win", "achievement"},
            new String[]{"🎉", "🎂", "🏆", "🥇", "🎊", "🌈", "🫶", "🎁"}
        ));
    }

    private static final Pattern EXCLAIM_PATTERN = Pattern.compile("[!]{2,}");
    private static final Pattern QUESTION_PATTERN = Pattern.compile("[?]{2,}");

    public Map<String, Object> suggest(String text) {
        if (text == null || text.isBlank()) {
            return neutralResponse();
        }

        String lower = text.toLowerCase();
        Map<String, Double> scores = new LinkedHashMap<>();

        for (Map.Entry<String, EmotionData> entry : EMOTIONS.entrySet()) {
            double score = 0;
            for (String keyword : entry.getValue().keywords) {
                if (lower.contains(keyword)) score += 1.0;
            }
            if (score > 0) scores.put(entry.getKey(), score);
        }

        if (EXCLAIM_PATTERN.matcher(text).find()) scores.merge("excited", 0.5, Double::sum);
        if (QUESTION_PATTERN.matcher(text).find()) scores.merge("surprised", 0.3, Double::sum);

        if (scores.isEmpty()) return neutralResponse();

        double total = scores.values().stream().mapToDouble(Double::doubleValue).sum();
        List<Map<String, Object>> emotions = scores.entrySet().stream()
            .sorted(Map.Entry.<String, Double>comparingByValue().reversed())
            .limit(3)
            .map(e -> {
                EmotionData data = EMOTIONS.get(e.getKey());
                Map<String, Object> em = new HashMap<>();
                em.put("name", e.getKey());
                em.put("label", data.label);
                em.put("score", (int) Math.round((e.getValue() / total) * 100));
                em.put("emojis", List.of(data.emojis));
                return em;
            })
            .collect(Collectors.toList());

        List<String> suggestions = new ArrayList<>();
        Set<String> seen = new LinkedHashSet<>();
        for (Map<String, Object> em : emotions) {
            @SuppressWarnings("unchecked")
            List<String> emojis = (List<String>) em.get("emojis");
            for (String emoji : emojis) {
                if (seen.add(emoji) && suggestions.size() < 8) suggestions.add(emoji);
            }
        }

        String primaryEmotion = (String) emotions.get(0).get("name");
        String primaryLabel = (String) emotions.get(0).get("label");
        int primaryScore = (int) emotions.get(0).get("score");

        Map<String, Object> result = new HashMap<>();
        result.put("emotions", emotions);
        result.put("suggestions", suggestions);
        result.put("primaryEmotion", primaryEmotion);
        result.put("analysis", "Cảm xúc chủ đạo: " + primaryLabel + " (" + primaryScore + "%)");
        return result;
    }

    private Map<String, Object> neutralResponse() {
        Map<String, Object> result = new HashMap<>();
        result.put("emotions", List.of(Map.of("name", "neutral", "label", "Trung tính", "score", 100)));
        result.put("suggestions", List.of("😊", "👍", "🤷", "😐", "🙂", "💭"));
        result.put("primaryEmotion", "neutral");
        result.put("analysis", "Không phát hiện cảm xúc rõ ràng trong văn bản.");
        return result;
    }

    private record EmotionData(String label, String[] keywords, String[] emojis) {}
}

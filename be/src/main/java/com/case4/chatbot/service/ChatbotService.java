package com.case4.chatbot.service;

import com.case4.chatbot.model.ChatMessage;
import com.case4.chatbot.repository.ChatMessageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatbotService {

    @Value("${gemini.api.key:}")
    private String defaultApiKey;

    @Value("${gemini.api.url}")
    private String geminiApiUrl;

    private final ChatMessageRepository chatMessageRepository;
    private final WebClient.Builder webClientBuilder;

    private static final String SYSTEM_PROMPT =
        "Bạn là trợ lý CSKH (Chăm Sóc Khách Hàng) thân thiện và chuyên nghiệp của một công ty thương mại điện tử Việt Nam. " +
        "Nhiệm vụ: trả lời câu hỏi về đơn hàng, giao hàng, đổi trả, khuyến mãi, tài khoản. " +
        "Phong cách: Thân thiện, nhiệt tình, chuyên nghiệp. Dùng tiếng Việt tự nhiên. " +
        "Luôn xưng hô 'bạn/mình' và hỏi thêm xem có cần hỗ trợ gì không.";

    private static final Map<String[], String> FAQ;

    static {
        FAQ = new LinkedHashMap<>();
        FAQ.put(new String[]{"đơn hàng", "order", "hóa đơn", "kiểm tra đơn", "trạng thái đơn", "mã đơn", "đơn của tôi", "chưa nhận được đơn"},
            "📦 Kiểm tra đơn hàng:\n" +
            "1️⃣ Đăng nhập vào tài khoản của bạn\n" +
            "2️⃣ Vào mục \"Đơn hàng của tôi\"\n" +
            "3️⃣ Nhập mã đơn hàng để tra cứu\n\n" +
            "📞 Cần hỗ trợ thêm? Hotline: 1900-xxxx (8h–22h)");
        FAQ.put(new String[]{"giao hàng", "ship", "vận chuyển", "nhận hàng", "chuyển phát", "mất bao lâu", "khi nào giao", "chưa giao", "đang giao", "phí ship", "phí vận chuyển"},
            "🚚 Thông tin giao hàng:\n" +
            "• Giao hàng tiêu chuẩn: 3–5 ngày làm việc\n" +
            "• Giao hàng nhanh: 1–2 ngày làm việc\n" +
            "• Miễn phí giao hàng cho đơn từ 300.000đ\n" +
            "• Theo dõi qua link trong email xác nhận đơn hàng");
        FAQ.put(new String[]{"đổi trả", "đổi hàng", "trả hàng", "hoàn tiền", "hoàn hàng", "refund", "return", "hàng lỗi", "hàng hỏng", "bị vỡ", "bị hỏng", "lỗi sản phẩm", "sai hàng", "hàng sai", "hàng không đúng"},
            "🔄 Chính sách đổi trả:\n" +
            "• Đổi trả trong vòng 30 ngày từ ngày mua\n" +
            "• Sản phẩm còn nguyên vẹn, chưa sử dụng\n" +
            "• Cần có hóa đơn mua hàng\n" +
            "• Hoàn tiền trong 3–5 ngày làm việc\n" +
            "• Liên hệ CSKH để được hướng dẫn chi tiết");
        FAQ.put(new String[]{"khuyến mãi", "giảm giá", "sale", "coupon", "voucher", "ưu đãi", "discount", "mã giảm giá", "flash sale", "deal", "chương trình"},
            "🎁 Khuyến mãi hiện có:\n" +
            "• Giảm đến 50% cho thành viên mới\n" +
            "• Flash sale hàng ngày lúc 12h và 20h\n" +
            "• Đăng ký email để nhận voucher độc quyền\n" +
            "• Follow fanpage để cập nhật deal mới nhất\n" +
            "• Tải app nhận thêm 10% giảm giá đơn đầu!");
        FAQ.put(new String[]{"tài khoản", "account", "đăng nhập", "mật khẩu", "password", "đăng ký tài khoản", "quên mật khẩu", "tài khoản bị khóa", "không đăng nhập được", "thay đổi thông tin"},
            "👤 Hỗ trợ tài khoản:\n" +
            "• Quên mật khẩu: Nhấn \"Quên mật khẩu\" → nhập email\n" +
            "• Đổi thông tin: Cài đặt → Thông tin cá nhân\n" +
            "• Tài khoản bị khóa: Liên hệ hotline ngay\n" +
            "• Đăng ký mới: Chỉ cần email và số điện thoại\n" +
            "• Hotline: 1900-xxxx (8h–22h hàng ngày)");
        FAQ.put(new String[]{"thanh toán bằng", "phương thức thanh toán", "trả bằng", "thẻ visa", "thẻ tín dụng", "chuyển khoản", "ví điện tử", "momo", "vnpay", "zalopay", "cod", "tiền mặt"},
            "💳 Phương thức thanh toán:\n" +
            "• Thẻ tín dụng/ghi nợ (Visa, Mastercard, JCB)\n" +
            "• Chuyển khoản ngân hàng\n" +
            "• Ví điện tử: MoMo, VNPay, ZaloPay\n" +
            "• Thanh toán khi nhận hàng (COD)\n" +
            "• Trả góp 0% qua thẻ tín dụng");
        FAQ.put(new String[]{"liên hệ cskh", "hotline", "số điện thoại hỗ trợ", "email hỗ trợ", "tư vấn viên", "chat với nhân viên", "gặp nhân viên"},
            "📞 Liên hệ CSKH:\n" +
            "• Hotline: 1900-xxxx (8h–22h, Thứ 2–CN)\n" +
            "• Email: support@shop.vn\n" +
            "• Chat trực tiếp tại website\n" +
            "• Thời gian phản hồi: trong vòng 2 giờ");
    }

    public Map<String, String> getResponse(String message, String sessionId, String clientApiKey) {
        String apiKey = (clientApiKey != null && !clientApiKey.isBlank()) ? clientApiKey : defaultApiKey;
        String response;

        if (apiKey != null && !apiKey.isBlank()) {
            try {
                response = callGeminiApi(message, apiKey);
            } catch (Exception e) {
                log.warn("Gemini API failed, using FAQ fallback: {}", e.getMessage());
                response = getFaqResponse(message);
            }
        } else {
            response = getFaqResponse(message);
        }

        ChatMessage saved = ChatMessage.builder()
            .userMessage(message)
            .botResponse(response)
            .sessionId(sessionId)
            .build();
        chatMessageRepository.save(saved);

        Map<String, String> result = new HashMap<>();
        result.put("response", response);
        result.put("sessionId", sessionId);
        result.put("source", (apiKey != null && !apiKey.isBlank()) ? "gemini" : "faq");
        return result;
    }

    @SuppressWarnings("unchecked")
    private String callGeminiApi(String message, String apiKey) {
        Map<String, Object> requestBody = new HashMap<>();

        Map<String, Object> systemInstruction = new HashMap<>();
        Map<String, String> sysPart = new HashMap<>();
        sysPart.put("text", SYSTEM_PROMPT);
        systemInstruction.put("parts", List.of(sysPart));
        requestBody.put("system_instruction", systemInstruction);

        Map<String, Object> userContent = new HashMap<>();
        userContent.put("role", "user");
        Map<String, String> userPart = new HashMap<>();
        userPart.put("text", message);
        userContent.put("parts", List.of(userPart));
        requestBody.put("contents", List.of(userContent));

        Map<String, Object> genConfig = new HashMap<>();
        genConfig.put("temperature", 0.7);
        genConfig.put("maxOutputTokens", 800);
        requestBody.put("generationConfig", genConfig);

        WebClient client = webClientBuilder.build();
        Map<?, ?> responseBody = client.post()
            .uri(geminiApiUrl + "?key=" + apiKey)
            .contentType(MediaType.APPLICATION_JSON)
            .bodyValue(requestBody)
            .retrieve()
            .bodyToMono(Map.class)
            .block();

        if (responseBody == null) throw new RuntimeException("Empty response from Gemini");

        List<?> candidates = (List<?>) responseBody.get("candidates");
        if (candidates == null || candidates.isEmpty()) throw new RuntimeException("No candidates in response");

        Map<?, ?> candidate = (Map<?, ?>) candidates.get(0);
        Map<?, ?> content = (Map<?, ?>) candidate.get("content");
        List<?> parts = (List<?>) content.get("parts");
        Map<?, ?> part = (Map<?, ?>) parts.get(0);
        return (String) part.get("text");
    }

    private String getFaqResponse(String message) {
        String lower = message.toLowerCase().trim();

        // Greetings
        if (lower.equals("hi") || lower.equals("hello") || lower.equals("chào") || lower.equals("hey")
                || lower.contains("xin chào") || lower.startsWith("chào ") || lower.startsWith("hello ")) {
            return "Xin chào! 👋 Tôi là trợ lý CSKH AI, sẵn sàng hỗ trợ bạn 24/7.\n" +
                "Bạn cần giúp đỡ gì hôm nay? 😊";
        }

        // Thanks
        if (lower.contains("cảm ơn") || lower.contains("cám ơn") || lower.contains("thank")) {
            return "Cảm ơn bạn đã liên hệ! 🎉 Rất vui được hỗ trợ bạn.\n" +
                "Nếu cần thêm hỗ trợ, đừng ngại nhắn tin nhé!";
        }

        // Score-based matching: pick FAQ with highest total keyword match length
        String bestResponse = null;
        int bestScore = 0;
        for (Map.Entry<String[], String> entry : FAQ.entrySet()) {
            int score = 0;
            for (String keyword : entry.getKey()) {
                if (lower.contains(keyword)) {
                    score += keyword.length(); // longer keyword = more specific = higher weight
                }
            }
            if (score > bestScore) {
                bestScore = score;
                bestResponse = entry.getValue();
            }
        }

        if (bestScore >= 3) return bestResponse;

        return "Xin lỗi, tôi chưa hiểu rõ câu hỏi của bạn. Tôi có thể hỗ trợ:\n\n" +
            "📦 Đơn hàng — kiểm tra, trạng thái\n" +
            "🚚 Giao hàng — thời gian, phí ship\n" +
            "🔄 Đổi trả — chính sách, hoàn tiền\n" +
            "🎁 Khuyến mãi — voucher, flash sale\n" +
            "👤 Tài khoản — đăng nhập, mật khẩu\n" +
            "💳 Thanh toán — MoMo, VNPay, COD\n" +
            "📞 Liên hệ — hotline, email CSKH\n\n" +
            "Bạn vui lòng mô tả rõ hơn vấn đề cần hỗ trợ nhé!";
    }

    public List<ChatMessage> getHistory(String sessionId) {
        return chatMessageRepository.findBySessionIdOrderByTimestampAsc(sessionId);
    }

    public void clearHistory(String sessionId) {
        List<ChatMessage> messages = chatMessageRepository.findBySessionIdOrderByTimestampAsc(sessionId);
        chatMessageRepository.deleteAll(messages);
    }
}

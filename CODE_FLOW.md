# Code Flow — Case Study 4: AI Chatbot

## Cách xem sơ đồ động
- **VS Code**: cài extension `Markdown Preview Mermaid Support` → mở file → Preview
- **Online**: copy từng block vào https://mermaid.live → export PNG/SVG
- **GitHub**: push lên GitHub → sơ đồ tự render trong README
- **Notion / Confluence**: paste trực tiếp, hỗ trợ Mermaid native
- **Draw.io**: import file `.drawio` (xem cuối file)
- **Obsidian**: hỗ trợ Mermaid native

---

## 1. Kiến trúc tổng quan

```mermaid
graph TB
    subgraph Flutter["📱 FLUTTER (FE)"]
        direction TB
        MAIN["main.dart\nrunApp + MultiProvider"]
        SPLASH["SplashScreen\n2s animation"]
        HOME["HomeScreen\nBottomNavigationBar"]

        subgraph Screens
            TODO_S["TodoScreen"]
            CHAT_S["ChatbotScreen"]
            EMOJI_S["EmojiScreen"]
        end

        subgraph Providers["State Management (Provider)"]
            TODO_P["TodoProvider\nChangeNotifier"]
            CHAT_P["ChatProvider\nChangeNotifier"]
        end

        API["ApiService\nHTTP Client"]
        CFG["AppConfig\nbaseUrl = localhost:8080"]
    end

    subgraph SpringBoot["☕ SPRING BOOT (BE)"]
        direction TB
        subgraph Controllers
            TODO_C["TodoController\n/api/todos"]
            CHAT_C["ChatController\n/api/chat"]
            EMOJI_C["EmojiController\n/api/emoji/suggest"]
        end

        subgraph Services
            TODO_SVC["TodoService"]
            CHAT_SVC["ChatbotService"]
            EMOJI_SVC["EmojiService"]
        end

        subgraph Repos["JPA Repositories"]
            TODO_R["TodoRepository"]
            HIST_R["TaskHistoryRepository"]
            CHAT_R["ChatMessageRepository"]
        end

        DB[("H2 In-Memory DB")]
    end

    GEMINI["🤖 Gemini 1.5 Flash API\nGoogle Cloud"]

    MAIN --> SPLASH --> HOME
    HOME --> TODO_S & CHAT_S & EMOJI_S
    TODO_S --> TODO_P
    CHAT_S --> CHAT_P
    TODO_P & CHAT_P --> API
    EMOJI_S --> API
    API -->|"HTTP REST (adb reverse / LAN IP)"| Controllers

    TODO_C --> TODO_SVC --> TODO_R & HIST_R --> DB
    CHAT_C --> CHAT_SVC --> CHAT_R --> DB
    CHAT_SVC -->|"POST key=xxx"| GEMINI
    EMOJI_C --> EMOJI_SVC
```

---

## 2. Luồng khởi động app

```mermaid
sequenceDiagram
    participant OS as Android OS
    participant App as main.dart
    participant MP as MultiProvider
    participant Splash as SplashScreen
    participant Home as HomeScreen
    participant TP as TodoProvider
    participant API as ApiService

    OS->>App: runApp()
    App->>MP: wrap(TodoProvider, ChatProvider)
    MP->>Splash: build()
    Splash->>Splash: AnimationController.forward() 1.2s fade-in
    Note over Splash: Future.delayed 2s
    Splash->>Home: Navigator.pushReplacement()
    Home->>Home: BottomNavigationBar index=0 (Todo)
    Home->>TP: context.read<TodoProvider>()
    TP->>TP: loadAll() via postFrameCallback
    TP->>API: getTodos() + getSuggestions() + getStats()
    API-->>TP: List<TodoModel>, List<SuggestionModel>, Map stats
    TP->>TP: notifyListeners()
    TP-->>Home: rebuild TodoScreen
```

---

## 3. Luồng Todo — Thêm task

```mermaid
sequenceDiagram
    participant U as User
    participant DF as _DateFolder (Widget)
    participant TS as TodoScreen
    participant TP as TodoProvider
    participant API as ApiService
    participant TC as TodoController
    participant TSvc as TodoService
    participant TR as TodoRepository
    participant DB as H2 DB

    U->>DF: tap folder icon (📁+)
    DF->>TS: onAddTask() callback
    TS->>TS: _showAddDialog(forDate: "Hôm nay")
    TS->>TS: showModalBottomSheet()
    U->>TS: nhập title, chọn category, priority
    U->>TS: nhấn "Thêm công việc"
    TS->>TP: addTodo(title, category, priority)
    TP->>API: ApiService.addTodo()
    API->>TC: POST /api/todos {title, category, priority}
    TC->>TC: @Valid TodoRequest
    TC->>TSvc: addTask(request)
    TSvc->>TSvc: LocalDateTime.now() → dayOfWeek, hourOfDay
    TSvc->>TR: todoRepository.save(todo)
    TR->>DB: INSERT INTO todos
    DB-->>TR: Todo(id=x)
    TR-->>TSvc: Todo saved
    TSvc-->>TC: Todo
    TC-->>API: 200 TodoModel JSON
    API-->>TP: TodoModel parsed
    TP->>TP: loadAll() → refresh toàn bộ
    TP->>TP: notifyListeners()
    TP-->>DF: rebuild → task xuất hiện trong thư mục
```

---

## 4. Luồng Todo — Hoàn thành task (AI học thói quen)

```mermaid
sequenceDiagram
    participant U as User
    participant TC_W as _TodoCard (Widget)
    participant TP as TodoProvider
    participant API as ApiService
    participant Ctrl as TodoController
    participant TSvc as TodoService
    participant TR as TodoRepository
    participant HR as TaskHistoryRepository
    participant DB as H2 DB

    U->>TC_W: tap circle check ✓
    TC_W->>TP: completeTodo(id)
    TP->>API: ApiService.completeTodo(id)
    API->>Ctrl: PUT /api/todos/{id}/complete
    Ctrl->>TSvc: completeTask(id)
    TSvc->>TR: findById(id)
    TR->>DB: SELECT * FROM todos WHERE id=?
    DB-->>TR: Todo
    TSvc->>TR: save(todo.completed=true, completedAt=now)
    TR->>DB: UPDATE todos SET completed=true
    Note over TSvc: Lưu vào lịch sử để AI học
    TSvc->>HR: historyRepository.save(TaskHistory)
    HR->>DB: INSERT INTO task_history (title, category, dayOfWeek, hourOfDay)
    TSvc-->>Ctrl: Todo updated
    Ctrl-->>API: 200 OK
    TP->>TP: loadAll() → notifyListeners()
```

---

## 5. Luồng AI gợi ý Todo

```mermaid
flowchart TD
    A["TodoProvider.loadAll()"] --> B["ApiService.getSuggestions()\nGET /api/todos/suggestions"]
    B --> C["TodoService.getSuggestions()"]
    C --> D{historyCount < 2?}
    D -->|Yes| E["getTimeSuggestions(currentHour)\nGợi ý theo giờ trong ngày"]
    D -->|No| F["historyRepository.findAll()"]
    F --> G["Tính score từng task\ntheo dayOfWeek + hourOfDay"]

    G --> H["dayBonus:\n• Đúng ngày hôm nay → 1.8\n• Ngày khác → 0.6"]
    G --> I["hourScore:\n1.0 - hourDiff/8.0\n(gần giờ hiện tại = cao hơn)"]
    H & I --> J["score = dayBonus × (0.5 + hourScore)"]
    J --> K["Lọc task đang active (chưa pending)"]
    K --> L["Sort giảm dần, limit 5"]
    L --> M["confidence = min((score/maxScore × 85) + 10, 95)"]

    E --> N["Trả về List<SuggestionDto>"]
    M --> N
    N --> O["TodoProvider.suggestions\n→ render _SuggestionCard"]

    style D fill:#6C63FF,color:#fff
    style H fill:#1A1A2E,color:#fff
    style I fill:#1A1A2E,color:#fff
```

---

## 6. Luồng CSKH Chatbot

```mermaid
sequenceDiagram
    participant U as User
    participant CS as ChatbotScreen
    participant CP as ChatProvider
    participant API as ApiService
    participant CC as ChatController
    participant CSvc as ChatbotService
    participant GEM as Gemini API
    participant CR as ChatMessageRepository
    participant DB as H2 DB

    U->>CS: gõ tin nhắn → send
    CS->>CS: _send() → _msgCtrl.text
    CS->>CP: sendMessage(text)
    CP->>CP: messages.add(userMsg) + loading=true
    CP->>CP: notifyListeners() → show typing indicator
    CP->>API: ApiService.sendMessage(text, sessionId, apiKey)
    API->>CC: POST /api/chat {message, sessionId, apiKey}
    CC->>CSvc: getResponse(message, sessionId, clientApiKey)

    alt apiKey có giá trị
        CSvc->>GEM: POST generateContent?key=xxx\n{system_instruction, contents, generationConfig}
        GEM-->>CSvc: {candidates[0].content.parts[0].text}
        CSvc-->>CC: response từ Gemini
    else không có apiKey
        CSvc->>CSvc: getFaqResponse(message)
        Note over CSvc: Score-based matching:\ncộng keyword.length() mỗi lần khớp\nchọn FAQ có tổng điểm cao nhất
        CSvc-->>CC: response từ FAQ
    end

    CC->>CR: chatMessageRepository.save(ChatMessage)
    CR->>DB: INSERT INTO chat_messages
    CC-->>API: {response, sessionId, source}
    API-->>CP: Map parsed
    CP->>CP: messages.add(botMsg) + loading=false
    CP->>CP: notifyListeners()
    CS->>CS: _scrollToBottom()
    CS-->>U: hiển thị _ChatBubble
```

---

## 7. Luồng FAQ Scoring (chi tiết)

```mermaid
flowchart TD
    A["getFaqResponse(message)"] --> B["lower = message.toLowerCase()"]
    B --> C{Là lời chào?\nxin chào / hi / hello}
    C -->|Yes| D["Trả về greeting response"]
    C -->|No| E{Là cảm ơn?\ncảm ơn / thank}
    E -->|Yes| F["Trả về thanks response"]
    E -->|No| G["Duyệt 7 FAQ entries"]

    G --> H["Với mỗi entry:\nloop qua keywords\nscore += keyword.length() nếu khớp"]
    H --> I["Chọn entry có score cao nhất\nbest-match thay vì first-match"]

    I --> J{bestScore >= 3?}
    J -->|Yes| K["Trả về FAQ response tương ứng"]
    J -->|No| L["Trả về fallback:\n'Xin lỗi chưa hiểu + menu 7 chủ đề'"]

    subgraph FAQ_ENTRIES["7 FAQ Categories"]
        F1["📦 Đơn hàng\nkeywords: đơn hàng, order, hóa đơn..."]
        F2["🚚 Giao hàng\nkeywords: giao hàng, ship, vận chuyển..."]
        F3["🔄 Đổi trả\nkeywords: đổi trả, hoàn tiền, hàng lỗi..."]
        F4["🎁 Khuyến mãi\nkeywords: khuyến mãi, voucher, sale..."]
        F5["👤 Tài khoản\nkeywords: tài khoản, mật khẩu, đăng nhập..."]
        F6["💳 Thanh toán\nkeywords: momo, vnpay, chuyển khoản..."]
        F7["📞 Liên hệ\nkeywords: hotline, liên hệ cskh..."]
    end

    style J fill:#6C63FF,color:#fff
    style K fill:#03DAC6,color:#000
    style L fill:#FF6584,color:#fff
```

---

## 8. Luồng Emoji AI

```mermaid
sequenceDiagram
    participant U as User
    participant ES as EmojiScreen
    participant API as ApiService
    participant EC as EmojiController
    participant ESvc as EmojiService

    U->>ES: nhập text / chọn example
    U->>ES: tap "Phân tích cảm xúc"
    ES->>ES: _analyze() → loading=true
    ES->>API: ApiService.suggestEmoji(text)
    API->>EC: POST /api/emoji/suggest {text}
    EC->>ESvc: suggest(text)

    Note over ESvc: 11 emotion categories:\nhappy/sad/angry/surprised/love\nexcited/tired/funny/cool/thinking/celebrate

    ESvc->>ESvc: lower = text.toLowerCase()
    ESvc->>ESvc: Loop 11 emotions:\n  score++ nếu keyword khớp
    ESvc->>ESvc: Bonus: !! → excited+0.5\n?? → surprised+0.3
    ESvc->>ESvc: Tính % = score/total × 100
    ESvc->>ESvc: Top 3 emotions + collect 8 emojis

    ESvc-->>EC: {emotions[], suggestions[], analysis}
    EC-->>API: 200 JSON
    API-->>ES: Map result
    ES->>ES: _result = res
    ES->>ES: _showResultDialog(res)
    ES-->>U: Dialog hiện:\n• Analysis text\n• Progress bar top emotion\n• Emoji grid để copy
```

---

## 9. Sơ đồ class/data flow tổng hợp

```mermaid
classDiagram
    class main_dart {
        +runApp()
        +MultiProvider
        +AIChatbotApp
        +SplashScreen → HomeScreen
    }

    class TodoProvider {
        +List todos
        +List suggestions
        +Map stats
        +bool loading
        +loadAll()
        +addTodo()
        +completeTodo()
        +deleteTodo()
        +addFromSuggestion()
    }

    class ChatProvider {
        +List messages
        +bool loading
        +String sessionId
        +String apiKey
        +sendMessage()
        +clearMessages()
        +setApiKey()
    }

    class ApiService {
        +getTodos()$
        +addTodo()$
        +completeTodo()$
        +deleteTodo()$
        +getSuggestions()$
        +getStats()$
        +sendMessage()$
        +clearChatHistory()$
        +suggestEmoji()$
    }

    class AppConfig {
        +baseUrl: String$
        +todosEndpoint$
        +chatEndpoint$
        +emojiEndpoint$
    }

    class TodoService {
        +addTask()
        +getPending()
        +getCompleted()
        +completeTask() → saves TaskHistory
        +deleteTask()
        +getStats()
        +getSuggestions() → AI scoring
    }

    class ChatbotService {
        +getResponse()
        -callGeminiApi()
        -getFaqResponse() scoring
        +getHistory()
        +clearHistory()
    }

    class EmojiService {
        +suggest() → 11 emotions
        -neutralResponse()
    }

    TodoProvider --> ApiService
    ChatProvider --> ApiService
    ApiService --> AppConfig
    TodoService --> TodoRepository
    TodoService --> TaskHistoryRepository
    ChatbotService --> ChatMessageRepository
    ChatbotService --> WebClient
```

---

## 10. Code Review — Điểm mạnh & cần cải thiện

### ✅ Điểm mạnh

| Phần | Nhận xét |
|------|----------|
| **Provider pattern** | Dùng đúng `ChangeNotifier`, tách state ra khỏi UI |
| **FAQ scoring** | Best-match theo keyword.length(), không bị first-match sai |
| **AI suggestions** | Scoring theo dayOfWeek + hourOfDay thực tế |
| **EmojiService** | 11 cảm xúc, xử lý `!!` và `??` pattern |
| **Gemini fallback** | Tự động fallback về FAQ khi API lỗi |
| **CORS config** | Cho phép mọi origin, phù hợp mobile dev |
| **Date folder UI** | Group theo ngày, today mặc định mở |

### ⚠️ Cần cải thiện

| Phần | Vấn đề | Gợi ý fix |
|------|--------|-----------|
| **H2 in-memory** | Mất data khi restart server | Dùng H2 file-based hoặc SQLite |
| **TodoProvider.loadAll()** | Gọi lại toàn bộ sau mỗi action (add/complete/delete) | Cập nhật local state thay vì refetch |
| **API key hardcode** | Key trong `application.properties` | Dùng env var khi deploy |
| **No error UI** | Lỗi mạng chỉ log, không hiện cho user | Thêm error banner/snackbar |
| **Chat history** | Không persist qua session | Dùng `shared_preferences` lưu local |
| **Todo no due date** | Không có deadline cho task | Thêm field `dueDate` vào model |

---

## Cách xuất file sơ đồ động

| Công cụ | Cách dùng | Output |
|---------|-----------|--------|
| **mermaid.live** | Copy từng block Mermaid → Edit | SVG, PNG, PDF |
| **VS Code** | Extension `Markdown Preview Mermaid Support` | Xem trực tiếp |
| **GitHub** | Push file .md lên repo | Tự render trong browser |
| **Draw.io** | File → Import → Mermaid | Kéo thả chỉnh sửa → export PNG/SVG/PDF |
| **Notion** | Tạo code block, chọn Mermaid | Render trong page |
| **PlantUML** | Chuyển sang PlantUML syntax | PNG/SVG/PDF/ASCII |
| **Lucidchart** | Import Mermaid | Chỉnh sửa drag-drop → export |
| **Excalidraw** | Vẽ tay từ sơ đồ | SVG/PNG style tay |

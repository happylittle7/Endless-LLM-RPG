
import SwiftUI

struct GameView: View {
    @Environment(\.openRouter) private var openRouter
    @State var shouldShowErrorMessage: Bool = false
    @State var isLoading: Bool = false
    
    
    var storySettings: StorySettings = .withStubSettings(name: "歐姆巴", gender: .male)
    let llmModel: OpenRouterModel = .geminiFlash
    @State var stories: [String] = []
    @State var options: [String] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(stories.indices, id: \.self) { index in
                    Text(stories[index])                    

                    Divider()
                        .padding(.vertical, 32)
                }
                .font(.title3)
                .lineSpacing(8)
                .transition(.blurReplace.combined(with: .move(edge: .trailing)))
                
                if !stories.isEmpty {
                    if isLoading {
                        ProgressView()
                            .controlSize(.extraLarge)
                            .frame(maxWidth: .infinity)
                    } else  {
                        VStack(alignment: .leading) {
                            Text("你現在要怎麼做呢？")
                                .font(.title.bold())
                            
                            ForEach(options.indices, id: \.self) { index in
                                let option = options[index]
                                optionButton(option)
                            }
                        }
                        .disabled(isLoading)
                        .transition(.blurReplace.combined(with: .opacity))
                    }
                }
            }
            .padding()
            .animation(.smooth, value: stories.count)
        }
        .overlay {
            initialLoadingView
        }
        .errorToast(isPresented: $shouldShowErrorMessage, message: "發生錯誤，請稍後再試")
    }
}


extension GameView {
    func appendNewContent(story: String, options: [String]) {
        self.stories.append(story)
        self.options = options
    }
    
    func sendRequest(
        prompt: String,
        temperature: Double,
        maxTokens: Int,
        stopTokens _: [String] = [],
        responseFormat: JSONSchema? = nil
    ) {
        Task {
            isLoading = true
            defer {
                isLoading = false
            }
            do {
                let response: String
                
                switch llmModel {
                    case .llama, .hermes:
                        let llamaPrompt = """
    <|begin_of_text|><|start_header_id|>system<|end_header_id|>

    When you receive a tool call response, use the output to format an answer to the orginal user question.

    You are a helpful assistant with tool calling capabilities.<|eot_id|><|start_header_id|>user<|end_header_id|>

    Given the following functions, please respond with a JSON for a function call with its proper arguments that best answers the given prompt.

    Respond in the format {"name": function name, "parameters": dictionary of argument name and its value}. Do not use variables.

    {
    "type": "function",
    "function": {
    "name": "write_story",
    "description": "Provide the needed story and options to play the game",
    "parameters": {
      "type": "object",
      "properties": {
        "story": {
          "type": "string",
          "description": "The narrative description for the next game scene."
        },
        "options": {
          "type": "array",
          "description": "A list of four action choices for the player to take.",
          "items": {
            "type": "string"
          }
        }
      },
      "required": [
        "story",
        "options"
      ]
    }
    }
    }

    Question: \(prompt)<|eot_id|><|start_header_id|>assistant<|end_header_id|>

    {"name": "write_story", "parameters": 
    """
                        response = try await openRouter.completion(
                            model: llmModel,
                            prompt: llamaPrompt,
                            temperature: temperature,
                            maxTokens: maxTokens
                        )
                        
                    case .geminiFlash, .gpt4oMini, .mistral:
                        response = try await openRouter.completion(
                            model: llmModel,
                            prompt: prompt,
                            temperature: temperature,
                            maxTokens: maxTokens,
                            responseFormat: responseFormat
                        )
                }

                processLLMResponse(response)
            } catch {
                print("❌ 發生非預期的錯誤: \(error)")
                shouldShowErrorMessage = true
            }
        }
    }
    
    var sharedBasicSettingPrompt: String {
        """
### 故事設定
- 主角名稱：\(storySettings.user.name)
- 性別: \(storySettings.user.gender.description)
- 故事類型：\(storySettings.genre.joined(separator: "、"))
- 世界背景：\(storySettings.world.joined(separator: "、"))
- 敘事風格：\(storySettings.narrativeStyle)
"""
    }
    
    func startStory() {
        let settingsPrompt = """
你是一個無盡選擇文字冒險遊戲的旁白，基於以下故事設定生成一段開場故事，以及接下來的四個行動選項供玩家選擇。
\(sharedBasicSettingPrompt)

### 生成要求
請直接生成內容就好，不用回答我
story:
請根據故事設定構思一個開場，請使用第二人稱口吻並遵循設定的敘事風格描述。
篇幅為在一個回合可以理解的長度。

options:
考慮目前故事發展、場景、出場角色、情緒，構思主角（玩家）接下來的行動或回答，生成四個明確且互不相同的選項。
選項必須簡潔，使用祈使句或直接寫對話。
"""
        
        sendRequest(
            prompt: settingsPrompt,
            temperature: 0.8,
            maxTokens: 4096,
            responseFormat: JSONSchema(
                name: "response_format",
                schema: [
                    "type": "object",
                    "additionalProperties": false,
                    "properties": [
                        "story": [
                            "type": "string",
                            "description": "The narrative description for the next game scene"
                        ],
                        "options": [
                            "type": "array",
                            "description": "A list of four action for players to take.",
                            "items": [
                                "type": "string"
                            ]
                        ]
                    ],
                    "required": [
                        "story",
                        "options"
                    ]
                ]
        ))
    }
    
    func continueStory(with option: String) {
        let settingsPrompt = """
你是一個無盡選擇文字冒險遊戲的旁白，基於以下故事設定以及前面的故事繼續產生劇情，以及接下來的四個行動選項供玩家選擇。請注意在產生新劇情和選想是，盡量不要和之前重複。
\(sharedBasicSettingPrompt)

### 前面的故事劇情
\(stories.joined(separator: "\n"))

### 玩家選擇
玩家在上一段故事中，有以下幾個選項
\(options.joined(separator: "\n"))
最後玩家選擇了\(option)。

### 生成要求
請直接生成內容就好，不用回答我
story:
請根據故事設定構思一個開場，請使用第二人稱口吻並遵循設定的敘事風格描述。
篇幅為在一個回合可以理解的長度。

options:
考慮目前故事發展、場景、出場角色、情緒，構思主角（玩家）接下來的行動或回答，生成四個明確且互不相同的選項。
選項必須簡潔，使用祈使句或直接寫對話。
"""
        
        sendRequest(
            prompt: settingsPrompt,
            temperature: 0.8,
            maxTokens: 4096,
            responseFormat: JSONSchema(
                name: "response_format",
                schema: [
                    "type": "object",
                    "additionalProperties": false,
                    "properties": [
                        "story": [
                            "type": "string",
                            "description": "The narrative description for the next game scene"
                        ],
                        "options": [
                            "type": "array",
                            "description": "A list of four action for players to take.",
                            "items": [
                                "type": "string"
                            ]
                        ]
                    ],
                    "required": [
                        "story",
                        "options"
                    ]
                ]
        ))
        
    }
}

#Preview {
    GameView()
}

extension GameView {
    struct StoryResponse: Decodable {
        let story: String
        let options: [String]
    }
    
    func processLLMResponse(_ text: String) {
        do {
            let regex = /"story":.+?"options":.+?]/.dotMatchesNewlines()
            
            var parsedText = text
            
            if let match = try? regex.firstMatch(in: text)?.output {
                parsedText = "{" + String(match) + "}"
            }
            
            guard let jsonData = parsedText.data(using: .utf8) else {
                throw GameError.unableToProcessResponse
            }
            let response = try JSONDecoder().decode(StoryResponse.self, from: jsonData)
            
            
            appendNewContent(story: response.story, options: response.options)
        } catch {
            print("❌ 無法解析收到的回傳：\n", text)
            print("❌ Error：\n", error)
            shouldShowErrorMessage = true
        }
    }
}

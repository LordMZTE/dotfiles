(local cc (require :codecompanion))
(local oai (require :codecompanion.adapters.http.openai))

(local llama-cpp-conf
       (let [url "http://127.0.0.1:11434"
             parse_message_meta (fn [self data]
                                  (local extra data.extra)
                                  (when (and extra extra.reasoning_content)
                                    (set data.output.reasoning
                                         {:content extra.reasoning_content})
                                    (when (= data.output.content "")
                                      (set data.output.content nil)))
                                  data)
             ;; This  fixes an issue with Qwen models that only support one single system
             ;; prompt. Adapted from:
             ;; https://github.com/olimorris/codecompanion.nvim/issues/2925#issuecomment-4175428086
             form_messages (fn [self messages]
                             (let [sys []
                                   other []
                                   final []]
                               ;; Separate system messages from others
                               (each [_ msg (ipairs messages)]
                                 (if (= msg.role :system)
                                     (table.insert sys msg.content)
                                     (table.insert other msg)))
                               ;; Collect system messages into one
                               (when (> (length sys) 0)
                                 (table.insert final
                                               {:role :system
                                                :content (table.concat sys
                                                                       "\n\n")}))
                               ;; Append other messages
                               (each [_ msg (ipairs other)]
                                 (table.insert final msg))
                               ;; Delegate to underlying handler
                               (oai.handlers.form_messages self final)))]
         {:env {:chat_url :/v1/chat/completions : url}
          :handlers {: parse_message_meta : form_messages}}))

(cc.setup {:adapters {:http {:llama.cpp #((. (require :codecompanion.adapters)
                                             :extend) :openai_compatible
                                                      llama-cpp-conf)}}
           :interactions {:chat {:adapter :llama.cpp}
                          :inline {:adapter :llama.cpp}
                          :cmd {:adapter :llama.cpp}}
           :mcp {:servers {:fetch {:cmd [:podman :run :-i :--rm :mcp/fetch]}
                           :ddg-search {:cmd [:podman
                                              :run
                                              :-i
                                              :--rm
                                              :mcp/duckduckgo]}
                           :nu {:cmd [:nu :--mcp]}}}})

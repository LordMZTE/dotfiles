(local mztenv (require :mzte_nv))
(local kmopts (. (require :mzte_nv) :utils :map_opt))
(local cc (require :codecompanion))
(local adapters (require :codecompanion.adapters))
(local oai (require :codecompanion.adapters.http.openai_compatible))

(fn llama-cpp-conf [url headers]
  (let [parse_message_meta (fn [self data]
                             (local extra data.extra)
                             (when (and extra extra.reasoning_content)
                               (set data.output.reasoning
                                    {:content extra.reasoning_content})
                               (when (= data.output.content "")
                                 (set data.output.content nil)))
                             data)
        ;; This fixes an issue with Qwen models that only support one single system
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
                                           :content (table.concat sys "\n\n")}))
                          ;; Append other messages
                          (each [_ msg (ipairs other)]
                            (table.insert final msg))
                          ;; Delegate to underlying handler
                          (oai.handlers.form_messages self final)))]
    {:env {:chat_url :/v1/chat/completions : url}
     :handlers {: parse_message_meta : form_messages}
     : headers}))

(local adapters
       (collect [_ ep (ipairs mztenv.reg.openai_endpoints)]
         (values ep.name
                 (if (= ep.name :openrouter)
                     #(adapters.extend :openrouter {:headers ep.headers})
                     #(adapters.extend :openai_compatible
                                       (llama-cpp-conf ep.base_url ep.headers))))))

(local def-adapter (. mztenv.reg.openai_endpoints 1 :name))

(cc.setup {:adapters {:http adapters}
           :interactions {:chat {:adapter def-adapter}
                          :inline {:adapter def-adapter}
                          :cmd {:adapter def-adapter}}
           :mcp {:servers {:fetch {:cmd [:podman
                                         :run
                                         :-i
                                         :--rm
                                         :docker.io/mcp/fetch]}
                           :ddg-search {:cmd [:podman
                                              :run
                                              :-i
                                              :--rm
                                              :docker.io/mcp/duckduckgo]}
                           :nu {:cmd [:nu :--mcp]}}}})

(vim.keymap.set :n :TC cc.chat kmopts)
(vim.keymap.set [:n :v] :TP #(cc.inline {}) kmopts)

(local cc (require :codecompanion))

(local llama-cpp-conf
       (let [url "http://127.0.0.1:11434"]
         {:env {:chat_url :/v1/chat/completions : url}
          :handlers {:parse_message_meta (fn [self data]
                                           (local extra data.extra)
                                           (when (and extra
                                                      extra.reasoning_content)
                                             (set data.output.reasoning
                                                  {:content extra.reasoning_content})
                                             (when (= data.output.content "")
                                               (set data.output.content nil)))
                                           data)}}))

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

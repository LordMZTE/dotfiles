(local mztenv (require :mzte_nv))
(local kmopts (. (require :mzte_nv) :utils :map_opt))
(local cmp-ai-cfg (require :cmp_ai.config))
(local adapters (require :codecompanion.adapters))
(local adapter-ui (require :codecompanion.adapters.ui))

(local default-endpoint (. mztenv.reg.openai_endpoints 1))

(cmp-ai-cfg:setup {:provider :llamacpp
                   :provider_options {:mzte_provider_name default-endpoint.name
                                      :base_url default-endpoint.base_url
                                      :model default-endpoint.default_model}
                   :run_on_every_keystroke false})

(fn select-model []
  (let [cnf (. (cmp-ai-cfg:get :provider) :params)
        on-model-choice (fn [name adapter-name adapter-url]
                          (tset cnf :mzte_provider_name adapter-name)
                          (tset cnf :base_url adapter-url)
                          (tset cnf :model name))
        on-adapter-choice (fn [name]
                            (when name
                              (local adapter (adapters.resolve name))
                              (adapter-ui.select_model {:on_choice #(on-model-choice $1
                                                                                     name
                                                                                     adapter.env.url)
                                                        : adapter})))]
    (adapter-ui.select_adapter {:current cnf.mzte_provider_name
                                :on_choice on-adapter-choice})))

(vim.keymap.set :n :TV select-model kmopts)

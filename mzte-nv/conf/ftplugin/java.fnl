;; Setup for JDTLS

(local (jdtls jdtls-setup mztenv)
       (values (require :jdtls) (require :jdtls.setup)
               (. (require :mzte_nv) :jdtls)))

(local caps
       ((. (require :cmp_nvim_lsp) :default_capabilities) (vim.lsp.protocol.make_client_capabilities)))

(local (bundle-info dirs) (values (mztenv.getBundleInfo) (mztenv.getDirs)))

(fn on-attach [client _]
  ;; formatting is handled by clang-format
  (set client.server_capabilities.documentFormattingProvider false)
  ;; java lsp has shit highlights
  (set client.server_capabilities.semanticTokensProvider false)
  (jdtls-setup.add_commands)
  (jdtls.setup_dap {:hotcodereplace :auto}))

(let [opts {:cmd [:jdtls :-configuration dirs.config :-data dirs.workspace]
            :capabilities caps
            :root_dir (jdtls-setup.find_root [:.git
                                              :mvnw
                                              :gradlew
                                              :build.grable])
            :settings {:java {:configuration {:runtimes (mztenv.findRuntimes)}
                              :contentProvider bundle-info.content_provider}}
            :init_options {:bundles bundle-info.bundles
                           :extendedClientCapabilities (let [cap jdtls.extendedClientCapabilities]
                                                         (set cap.resolveAdditionalTextEditsSupport
                                                              true)
                                                         cap)}
            :on_attach on-attach
            :handlers {;; deactivate spammy messages
                       :language/status (fn [])}}]
  (jdtls.start_or_attach opts))

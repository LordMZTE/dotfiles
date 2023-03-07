(local (mztenv dap dapui) (values (require :mzte_nv) (require :dap)
                                  (require :dapui)))

(dapui.setup {})

(tset dap :adapters :lldb {:type :executable
                           ;; included in lldb package
                           :command (mztenv.utils.findInPath :lldb-vscode)
                           :name :lldb})

(local configs (. dap :configurations))

;; TODO: this UI sucks
(tset configs :c [{:name :Launch
                   :type :lldb
                   :request :launch
                   :program #(vim.fn.input "Binary: ")
                   :cwd "${workspaceFolder}"
                   :stopOnEntry false
                   :args #(vim.split (vim.fn.input "Args: ") " ")
                   :runInTerminal true}])

(tset configs :cpp (. configs :c))
(tset configs :rust (. configs :c))
(tset configs :zig (. configs :c))

(tset configs :java [{:type :java
                      :request :attach
                      :name "Java attach"
                      :hostName :127.0.0.1
                      :port 5005}])

(let [mopt (. (require :mzte_nv) :utils :map_opt)]
  (vim.keymap.set :n :fu dapui.toggle mopt)
  (vim.keymap.set :n :fb dap.toggle_breakpoint mopt)
  (vim.keymap.set :n :fc dap.continue mopt)
  (vim.keymap.set :n :fn dap.step_over mopt)
  (vim.keymap.set :n :fi dap.step_into mopt)
  (vim.keymap.set :n :fo dap.step_out mopt))

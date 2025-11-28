(local ai (require :mini.ai))

(local custom_textobjects
       ;; This depends on nvim-treesitter-textobjects, hence why we have that plugin without having
       ;; a configuration for it.
       {:F (ai.gen_spec.treesitter {:a "@function.outer" :i "@function.inner"})
        :c (ai.gen_spec.treesitter {:a "@class.outer" :i "@class.inner"})
        ;; Typst
        :$ (ai.gen_spec.treesitter {:a "@math.outer" :i "@math.inner"})})

(ai.setup {: custom_textobjects})

(local colors ["#ff00be" "#ff7e00" "#64d200" "#00e6b6" "#00e1ff" "#9598ff"])

(each [i c (ipairs colors)]
  (vim.api.nvim_set_hl 0 (.. :TSRainbow i) {:fg c}))

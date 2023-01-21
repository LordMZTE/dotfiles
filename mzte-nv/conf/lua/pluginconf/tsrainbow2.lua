local colors = {
    "#ff00be",
    "#ff7e00",
    "#64d200",
    "#00e6b6",
    "#00e1ff",
    "#9598ff",
}

for i, c in ipairs(colors) do
    vim.api.nvim_set_hl(0, "TSRainbow" .. i, { fg = c })
end

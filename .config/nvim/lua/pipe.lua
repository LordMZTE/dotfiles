-- https://gist.github.com/ii14/c5d6c39c1bc7b8553afe76db3350c043
-- :! replacement that supports char-wise selection
-- from visual mode :Pipe <command>
vim.api.nvim_create_user_command('Pipe', function(ctx)
  local ms = vim.api.nvim_buf_get_mark(0, '<')
  local me = vim.api.nvim_buf_get_mark(0, '>')
  local mt = vim.fn.visualmode()
  if mt == '\22' then
    error 'blockwise selection not supported'
  end

  local lines = vim.api.nvim_buf_get_lines(0, ms[1] - 1, me[1], true)
  local input = vim.deepcopy(lines)
  if mt == 'v' then
    input[#input] = input[#input]:sub(1, me[2] + 1)
    input[1] = input[1]:sub(ms[2] + 1)
  end
  local output = vim.fn.systemlist(ctx.args, input)
  if #output == 0 then
    output = {''}
  end
  if mt == 'v' then
    output[#output] = output[#output] .. lines[#lines]:sub(me[2] + 2)
    output[1] = lines[#lines]:sub(1, ms[2]) .. output[1]
  end
  vim.api.nvim_buf_set_lines(0, ms[1] - 1, me[1], true, output)
end, { range = true, nargs = '+', complete = 'shellcmd' })

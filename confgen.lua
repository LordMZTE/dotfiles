cg.addPath ".config"
cg.addPath ".local"
cg.addPath ".ssh"
cg.addPath ".cargo"

for k, v in pairs(require "cg_opts") do
    cg.opt[k] = v
end

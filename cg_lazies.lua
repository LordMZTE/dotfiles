-- This file acts as a collection of shared lazy objects used in configuration files.

cg.opt.lazy = {}

cg.opt.lazy.unameORS = cg.lib.lazy(function() return cg.opt.system "uname -ors" end)
cg.opt.lazy.username = cg.lib.lazy(function() return cg.opt.system "whoami" end)
cg.opt.lazy.ncpus = cg.lib.lazy(function() return tonumber(cg.opt.system "nproc") end)

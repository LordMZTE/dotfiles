return {
  -- Here, we have yet another case of someone wanting "muh stability" while not understanding the
  -- concept that things *should* actually break when they're broken. Xplr mandates that the
  -- configuration file contains the xplr version such that any bugs, deprecations and
  -- incompatibilities remain undiscovered for as long as possible. We fix this by acquiring the
  -- most recent version and inserting that into the config file.
  version = cg.lib.lazy(function()
    local ver_raw = cg.opt.system "xplr --version"
    print(ver_raw)
    local _, _, ver = string.find(ver_raw, ".* (.*)")
    return ver
  end)
}

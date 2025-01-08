#!/usr/bin/env julia
import Pluto
import UUIDs
using ArgParse

settings = ArgParseSettings()
@add_arg_table settings begin
    "file"
    help = "Pluto notebook to open"
    required = true
end

file = parse_args(settings)["file"]

# Create empty notebook if it doesn't exist yet.
isfile(file) || open(file, "w") do f
    uuid = UUIDs.uuid1()
    write(
        f,
        """
        ### A Pluto.jl notebook ###
        # v0.20.4

        # ╔═╡ $uuid

        # ╔═╡ Cell order:
        # ╠═$uuid
        """
    )
end

Pluto.run(notebook=file, auto_reload_from_file=true)

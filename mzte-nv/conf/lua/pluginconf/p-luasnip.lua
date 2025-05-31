local ls = require "luasnip"

--local c = ls.choice_node
--local d = ls.dynamic_node
local i = ls.insert_node
--local r = ls.restore_node
local s = ls.snippet
--local sn = ls.snippet_node
local t = ls.text_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_snipmate").lazy_load()

ls.add_snippets("markdown", {
    s("shrug", {
        t [[¯\_(ツ)_/¯]],
    }),
})

ls.add_snippets("java", {
    s(
        "getDescriptionPacket",
        fmt(
            [[@Override
public Packet getDescriptionPacket() {{
    NBTTagCompound nbt = new NBTTagCompound();

    {content}

    return new S35PacketUpdateTileEntity(this.xCoord, this.yCoord, this.zCoord,
        this.getBlockMetadata(), nbt);
}}]],

            { content = i(1) }
        )
    ),
    s(
        "markForUpdate",
        t [[this.worldObj.markBlockForUpdate(this.xCoord, this.yCoord, this.zCoord);]]
    ),
})

ls.add_snippets("json", {
    s(
        "sound",
        fmt(
            [["{name0}": {{
    "category": "master",
    "sounds": [
        {{
            "name": "{name1}",
            "stream": false
        }}
    ]
}},]],
            {
                name0 = i(1),
                name1 = rep(1),
            }
        )
    ),
})

local racket_snippets = {
    s("lamb", {
        t [[(λ ]],
        i(1, "(args)"),
        t " ",
        i(2, "body..."),
        t ")",
    }),
}

ls.add_snippets("scheme", racket_snippets)
ls.add_snippets("racket", racket_snippets)

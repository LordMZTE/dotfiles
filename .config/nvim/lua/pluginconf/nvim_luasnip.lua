local ls = require "luasnip"

--local c = ls.choice_node
--local d = ls.dynamic_node
local i = ls.insert_node
--local r = ls.restore_node
local s = ls.snippet
--local sn = ls.snippet_node
local t = ls.text_node
local fmt = require("luasnip.extras.fmt").fmt

require("luasnip.loaders.from_vscode").load()
require("luasnip.loaders.from_snipmate").load()

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
}}]]         ,

            { content = i(1) }
        )
    ),
    s("markForUpdate", t [[this.worldObj.markBlockForUpdate(this.xCoord, this.yCoord, this.zCoord);]]),
})

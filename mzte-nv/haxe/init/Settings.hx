package init;

import lua.Os;
import ext.mzte_nv.MZTENv;
import ext.vim.Vim;

class Settings {
    public static function init() {
        // Update $PATH with nvim tools path
        final toolspath:Null<String> = MZTENv.reg.nvim_tools;
        if (toolspath != null) {
            Vim.env.PATH = '${toolspath}/bin:${Vim.env.PATH}';
        }

        // CPBuf command
        Vim.api.createUserCommand("CPBuf", MZTENv.cpbuf.copyBuf, {nargs: 0});

        // Compile Command
        Vim.api.createUserCommand("CompileConfig", () -> {
            MZTENv.compile.compilePath(Os.getenv("HOME") + "/.config/nvim");
        }, {nargs: 0});
    }
}

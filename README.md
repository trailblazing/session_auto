
# Session Auto

session_auto.vim:   Giving a file, automatically save the session to the
                    "session cache" root of the current project based on the
                    .git location the file belongs to and create a link at
                    "current cache" directory.
                    If the project root could not be determined, save the
                    session under the "session cache" directory corresponding
                    to the file (the graphics in the rationale part are more
                    convincing).
                    
Maintainer:         Tuo Jung <https://github.com/trailblazing>

Version:            0.0.1

Website:            https://github.com/trailblazing/session_auto

Dependency:         https://github.com/trailblazing/boot

License:            GPL v3 and later


## 1. Key feature

The goal is to minimize interaction and configuration. Basic functionality out
of the box.

Determine which project the current file belongs to based on the .git
directory. The session configurations is then automatically generated in the
"session cache" directory corresponding to the project root. And its anchor
is stored in the cache location corresponding to the current directory.
In this way, next time you start vim/nvim without parameters in the current
directory, you can automatically retrieve the last session.

## 2. Rationale

    current_cache[/.fiction.vim]  --> project_cache[/.session.vim]
          ^          ^                   |^
          |          |                   v|
    current_dir      |                project_dir       read stage
                     |                   |^
                     |                   v|
                 current_dir          target_dir/files  write stage

## 3. Installation

    cd ~/.vim/pack/*/start/
    git clone --recursive https://github.com/trailblazing/session_auto.git

    Or use plugin manager like vim-packager

    call s:packager_init(g:plugin_dir['vim'], g:package_manager['vim'])
    function! s:packager_init(plugin_dir, package_manager) abort
        ...
        call a:packager.add('trailblazing/session_auto', { 'type' : 'start' })
        ...
    endfunction

    For package management lazy.nvim
    {
        "trailblazing/session_auto",
        event = { "VimEnter", "VimLeavePre" },
        lazy = false,
    },

### 3.1 Session key maps

The plugin already provides command for make a session. But it's not necessary.
Because the design itself does not require any human intervention,
hotkeys are mainly used for debugging

    command! -bar -nargs=0 SA :call s:make(s:_environment)
    command! -bar -nargs=0 SL :call s:load(s:_environment)

    You could define a map like this in your .vimrc or init.vim/init.lua:

    map <leader><your preferred key> <Plug>SessionAuto

## 4. Configurables

### 4.1 Variables

This content is just a guide and is unnecessary in most cases
These are current global variables and implements might needed by session_auto.

    if(has("win32") || has("win95") || has("win64") || has("win16"))
        let g:is_windows  = 1
    else
        let g:is_windows  = 0
    endif

Optional list for the view files that don't need to be saved,

    let g:skipview_files = [
                \ '[EXAMPLE PLUGIN BUFFER]'
                \, '__Tagbar__'
                \ ]

### 4.2 Settings

In your [.vimrc, init.vim, or configs.lua](https://github.com/kissllm/dotconfig/blob/master/init/editor/nvim/init.vim):

This content is just a guide and is unnecessary in most cases

    set sessionoptions=blank,buffers,curdir,help,tabpages,winsize,terminal
    set sessionoptions-=options
    set sessionoptions-=tabpages
    set sessionoptions-=help
    set sessionoptions+=buffers

    set viewoptions=folds,cursor,unix,slash

    if has('nvim')
        silent! execute "set viminfo='5,f1,\"50,:20,%,n'" . stdpath('data') . "/viminfo"
        let &viminfofile = expand('$XDG_DATA_HOME/nvim/shada/main.shada')
    else
        silent! execute "set viminfo='5,f1,\"50,:20,%,n'" . g:plugin_dir['vim'] . "/viminfo"
    endif

    For status line in vimscript

    function! s:session_state(updating)
        if a:updating
            let g:statusline_session_flag = "S"
        else
            let g:statusline_session_flag = ""
        endif
        execute "redrawstatus!"
    endfunction

    augroup session_auto
        au!
        autocmd VimEnter * :call session_auto#setup(function("s:session_state"))
    augroup END

    For lua

    vim.cmd([[
    function! SessionState(updating)
        if a:updating
            let g:statusline_session_flag = "S"
        else
            let g:statusline_session_flag = ""
        endif
        execute "redrawstatus!"
    endfunction
    ]])

    local session_auto_setup = augroup("on_bufenter", { clear = true })
    autocmd("VimEnter", {
        callback = function()
            vim.cmd([[
            :call session_auto#setup(function("SessionState"))
            ]])
        end,
        desc = "Session status global variable updating",
        group = session_auto_setup,
        pattern = "*",
    })

### 4.3 Logs

Users may check logs to get feedback from session_auto.

    tail -30f $HOME/.vim.log

## 5. Development

Pull requests are very welcome.

## 6. References

[1] https://vim.fandom.com/wiki/Go_away_and_come_back

[2] https://github.com/trailblazing/session_auto

[3] https://github.com/trailblazing/cscope_auto

[4] https://github.com/trailblazing/boot

[5] https://bitbucket.org/ericgarver/cscope_dynamic

[6] http://www.vim.org/scripts/script.php?script_id=5098

[7] http://vim.wikia.com/wiki/Timer_to_execute_commands_periodically

[8] https://github.com/erig0/cscope_dynamic

[9] http://cscope.sourceforge.net/cscope_maps.vim



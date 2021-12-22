```
:::text

session_auto.vim:   Automatically save the session to the root of the current 
                    project based on the .git location and create a link at 
                    current directory. If the project root could not be 
                    determined, save the session under the current directory.
Maintainer:         Tuo Jung <https://github.com/trailblazing>
Version:            0.0.1
Website:            https://github.com/trailblazing/session_auto
Dependency:         https://github.com/trailblazing/boot
License:            GPL v3 and later


===============================================================================
===============================================================================

1. Key feature
2. Installation
2.1 Session key maps
3. Configurables
3.1 Variables
3.2 Settings
3.3 Logs
4. Development
5. References



1. Key feature

The goal is to minimize interaction and configuration. Basic functionality out 
of the box.

Determine which project the current file belongs to based on the .git 
directory. The session configurations is then automatically generated in the 
project directory.

2. Installation
===============================================================================
The plugin is only one file. So you can check out the repository[1][2] and drop
session_auto.vim into your ~/.vim/pack/*/start/ directory.

    cd ~/.vim/pack/*/start/
    git clone --recursive https://github.com/trailblazing/session_auto.git

    Or use plugin manager like vim-packager

    call s:packager_init(g:plugin_dir['vim'], g:package_manager['vim'])
    function! s:packager_init(plugin_dir, package_manager) abort
        ...
        call a:packager.add('trailblazing/session_auto', { 'type' : 'start' })
        ...
    endfunction


2.1 Session key maps
=======================================
The plugin already provides key maps for make a session. But it's not necessary.

    noremap <unique> <Plug>SessionAuto :call <SID>make(g:log_address
        \ , g:is_windows, g:log_verbose)<CR>

    You could define a map like this in your .vimrc or init.vim:

    map <leader>m <Plug>SessionAuto

3. Configurables
===============================================================================

3.1 Variables
=======================================
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

3.2 Settings
=======================================
In your .vimrc/init.vim:

set sessionoptions=blank,buffers,curdir,help,tabpages,winsize,terminal
set sessionoptions-=options
set sessionoptions-=tabpages
set sessionoptions-=help
set sessionoptions+=buffers

set viewoptions=folds,cursor,unix,slash

set viminfo='5,f1,\"50,:20,%,n~/.vim/viminfo

3.3 Logs
=======================================
Users may check logs to get feedback from session_auto.

    tail -30f g:vimrc_dir/.vim/vim.log

The g:vimrc_dir should be your nominal $MYVIMRC path

4. Development
===============================================================================
Pull requests are very welcome.

5. References
===============================================================================
[1] https://vim.fandom.com/wiki/Go_away_and_come_back
[2] https://github.com/trailblazing/session_auto
[3] https://github.com/trailblazing/cscope_auto
[4] https://github.com/trailblazing/boot
[5] https://bitbucket.org/ericgarver/cscope_dynamic
[6] http://www.vim.org/scripts/script.php?script_id=5098
[7] http://vim.wikia.com/wiki/Timer_to_execute_commands_periodically
[8] https://github.com/erig0/cscope_dynamic
[9] http://cscope.sourceforge.net/cscope_maps.vim

```

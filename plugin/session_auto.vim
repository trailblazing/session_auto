" session_auto.vim:   Automatically save the session to the root of the current
"                     project based on the .git location and create a link at
"                     current directory. If the project root could not be
"                     determined, save the session under the current directory.
" Maintainer:         Tuo Jung <https://github.com/trailblazing>
" Version:            0.0.1
" Website:            https://github.com/trailblazing/session_auto
" Dependency:         https://github.com/trailblazing/boot
" License:            GPL v3 and later

if exists("g:session_auto_loaded")
    finish
endif


if ! exists('g:log_address')
    let g:log_address   = $HOME . '/.vim.log'
endif
if ! exists("g:log_verbose")
    let g:log_verbose = 0
endif
if ! exists("g:fixed_tips_width")
    let g:fixed_tips_width = 40
endif

if ! exists("g:_session_auto_debug")
    let s:_session_auto_debug  = 0
else
    let s:_bootsession_auto_debug = g:_session_auto_debug
endif

if ! exists("g:session_auto_save_view")
    let s:_session_auto_save_view  = 0
else
    let s:_session_auto_save_view = g:session_auto_save_view
endif

" set sessionoptions+=buffers
if ! exists("g:restore_each_buffer_view")
    let s:_restore_each_buffer_view  = 0
else
    let s:_restore_each_buffer_view = g:restore_each_buffer_view
endif

let s:session_name = '.session.vim'

function! s:make_session_dir(log_address, is_windows, fixed_tips_width, log_verbose)
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))

    let l:user = boot#chomped_system('whoami')
    let l:group = boot#chomped_system('id ' . l:user . ' -g -n')
    let l:project = boot#project(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    let l:parent_dir_user =  boot#chomped_system('stat -c "%U" ' . l:project)
    let l:parent_dir_group =  boot#chomped_system('stat -c "%G" ' . l:project)
    let l:user_home = boot#chomped_system("awk -v FS=':' -v user=\"" . l:user . "\" '($1==user) {print $6}' \"/etc/passwd\"")
    let l:session_dir =  ""
    let l:current_dir = resolve(expand(getcwd()))

    function! s:home_session_storage(user_home, current_dir)
        if has('nvim')
            let l:project = a:user_home . '/.cache/nvim'
        else
            let l:project = a:user_home . '/.cache/vim'
        endif
        let l:sub_dir = substitute(a:current_dir, '\/', '', '')
        let l:session_dir = l:project . '/sessions/' . l:sub_dir
        return l:session_dir
    endfunction

    if filewritable(l:project) != 2 || l:project == ""
        if filewritable(l:current_dir) != 2
            let l:session_dir = s:home_session_storage(l:user_home, l:current_dir)
        else
            if l:user != l:parent_dir_user
                let l:session_dir = s:home_session_storage(l:user_home, l:current_dir)
            else
                let l:project = l:current_dir
                let l:session_dir = l:project . '/sessions'
            endif
        endif
        silent! exe '!mkdir -p ' l:session_dir
    else
        if l:project != l:current_dir
            if l:user != l:parent_dir_user
                let l:session_dir = s:home_session_storage(l:user_home, l:current_dir)
                silent! exe '!mkdir -p ' l:session_dir
            else
                if filewritable(l:current_dir) == 2
                    call boot#chomped_system('ln -sf ' . l:session_dir  . ' ' . l:current_dir . '/sessions')
                else
                    let l:session_dir = l:project . '/sessions'
                    silent! exe '!mkdir -p ' l:session_dir
                endif
            endif
        else
            if l:user != l:parent_dir_user
                let l:session_dir = s:home_session_storage(l:user_home, l:current_dir)
                silent! exe '!mkdir -p ' l:session_dir
            else
                let l:session_dir = l:current_dir . '/sessions'
                silent! exe '!mkdir -p ' l:session_dir
            endif
        endif
    endif

    let l:session_file = l:session_dir . '/' . s:session_name
    silent! exe '!touch ' l:session_file

    if l:user != l:parent_dir_user || l:group != l:parent_dir_group
        call boot#chomped_system('\chown -R --quiet ' . l:parent_dir_user . ':' . l:parent_dir_group . ' ' . l:session_dir)
    endif

    if ! filewritable(l:session_dir)
        call boot#log_silent(a:log_address, l:func_name, '::session_dir ' . l:session_dir, a:fixed_tips_width, a:log_verbose)
    endif
    return { 'session_file' : l:session_file, 'session_dir' : l:session_dir, 'user' : l:user, 'group' : l:group, 'user_home' :
                \ l:user_home, 'parent_dir_user' : l:parent_dir_user , 'parent_dir_group' : l:parent_dir_group}
endfunction

function! s:view_make(log_address, is_windows, fixed_tips_width, log_verbose)
    " let local_dir = resolve(expand(getcwd()))    " let l:session_dir = s:make_session_dir(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    let target_info = s:make_session_dir(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    silent! exe 'set viewdir=' . target_info['session_dir']
    " https://gist.github.com/mitry/813151
    " set viewoptions=folds,options,cursor,unix,slash " better unix/windows compatibility
    " set viewoptions-=options
    set viewoptions=folds,cursor,unix,slash " better unix/windows compatibility
    " let s:view_file = local_dir . '/' . s:view_name
    silent! mkview!    " silent! exe 'mkview! ' . s:view_name
    " call s:storage(target_info, a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    " silent! execute "!clear &" | redraw!
    " redraw!
endfunction

function! s:view_load(log_address, is_windows, fixed_tips_width, log_verbose)
    " let local_dir = resolve(expand(getcwd()))    " s:make_session_dir(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    let target_info = s:make_session_dir(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    silent! exe 'set viewdir=' . target_info['session_dir']
    " set viewoptions=folds,options,cursor,unix,slash " better unix/windows compatibility
    " set viewoptions-=options
    set viewoptions=folds,cursor,unix,slash " better unix/windows compatibility
    " let s:view_file = local_dir . '/' . s:view_name
    silent! loadview   " silent! exe 'loadview ' . s:view_name
    redraw!
endfunction

" https://vim.fandom.com/wiki/Go_away_and_come_back
" creates a session
function! s:make(log_address, is_windows, fixed_tips_width, log_verbose)
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    let target_info = s:make_session_dir(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    let l:session_file = target_info['session_file']
    set sessionoptions=blank,buffers,curdir,help,tabpages,winsize,terminal
    " set sessionoptions-=options
    set sessionoptions-=tabpages
    set sessionoptions-=help

    " set sessionoptions-=buffers
    " Buffer changes won't save until you have following settings in your .vimrc/init.vim
    " " https://stackoverflow.com/questions/2902048/vim-save-a-list-of-open-files-and-later-open-all-files/2902082
    " set viminfo='5,f1,\"50,:20,%,n~/.vim/viminfo

    silent! exe "mksession! " . l:session_file

    " let target_info['session_file'] = l:session_file
    " call s:storage(target_info, a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    " call boot#chomped_system("!clear & | redraw!")
    call s:view_make(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    " redraw!
    execute "redrawstatus!"
    echohl WarningMsg
    echom "Session saved in " . l:session_file
    echohl None
    call boot#log_silent(a:log_address, l:func_name, l:session_file, a:fixed_tips_width, a:log_verbose)
    silent! execute '!(printf ' . '"\n\%-"' . a:fixed_tips_width . '"s: \%s\n"' . ' "Session saved in " "'
                \ . l:session_file . '")' . ' >> ' . a:log_address . ' 2>&1 &'
endfunction

" https://stackoverflow.com/questions/5142099/how-to-auto-save-vim-session-on-quit-and-auto-reload-on-start-including-split-wi
function! s:save(log_address, is_windows, fixed_tips_width, log_verbose)
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    let target_info = s:make_session_dir(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    let l:session_file = target_info['session_file']
    set sessionoptions=blank,buffers,curdir,help,tabpages,winsize,terminal
    " set sessionoptions-=options
    set sessionoptions-=tabpages
    set sessionoptions-=help

    " set sessionoptions-=buffers
    " Buffer changes won't save until you have following settings in your .vimrc/init.vim
    " " https://stackoverflow.com/questions/2902048/vim-save-a-list-of-open-files-and-later-open-all-files/2902082
    " set viminfo='5,f1,\"50,:20,%,n~/.vim/viminfo

    silent! exe "mksession! " . l:session_file
    " call s:storage(target_info, a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    " call boot#chomped_system("!clear & | redraw!")
    " call s:view_make(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    " redraw!
    execute "redrawstatus!"
    echohl WarningMsg
    echom "Session saved in " . l:session_file
    echohl None
    call boot#log_silent(a:log_address, l:func_name, l:session_file, a:fixed_tips_width, a:log_verbose)
    silent! execute '!(printf ' . '"\n\%-"' . a:fixed_tips_width . '"s: \%s\n"' . ' "Session saved in" "'
                \ . l:session_file . '")' . ' >> ' . a:log_address . ' 2>&1 &'
endfunction

" updates a session, BUT ONLY IF IT ALREADY EXISTS
function! s:update(log_address, is_windows, fixed_tips_width, log_verbose)
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    let target_info = s:make_session_dir(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    let l:session_file = target_info['session_file']
    if filereadable(l:session_file)
        silent! exe "mksession! " . l:session_file
        " call s:storage(target_info, a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
        echo "updating session"
        " call boot#chomped_system("!clear & | redraw!")
        " call s:view_make(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
        " redraw!
        execute "redrawstatus!"
    endif
    call boot#log_silent(a:log_address, l:func_name, l:session_file, a:fixed_tips_width, a:log_verbose)
endfunction

" https://stackoverflow.com/questions/5142099/how-to-auto-save-vim-session-on-quit-and-auto-reload-on-start-including-split-wi
function! s:restore(log_address, is_windows, fixed_tips_width, log_verbose)
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    if bufexists(1)
        for l in range(1, bufnr('$'))
            if bufwinnr(l) == -1
                silent! exec 'sbuffer ' . l
            endif
        endfor
    endif
    call boot#log_silent(a:log_address, l:func_name, l:session_file, a:fixed_tips_width, a:log_verbose)
endfunction

" loads a session if it exists
function! s:load(log_address, is_windows, fixed_tips_width, log_verbose)
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    " if argc() == 0
    " if(1 == len(v:argv))
    let target_info = s:make_session_dir(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    let l:session_file = target_info['session_file']
    " call boot#log_silent(a:log_address, l:func_name, l:session_file, a:fixed_tips_width, a:log_verbose)
    if filereadable(l:session_file)
        " silent! echom "session to be loaded."
        silent! exe 'source ' . l:session_file
        " exe 'source ' l:session_file
        "
        if 1 == s:_restore_each_buffer_view
            call s:restore(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
        endif

        " silent! echo "session loaded."
        " call s:view_load(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
        " redraw!
        call boot#log_silent(a:log_address, l:func_name, l:session_file . " loaded", a:fixed_tips_width, a:log_verbose)
    else
        " silent! echo "No session loaded."
        call boot#log_silent(a:log_address, l:func_name, l:session_file . " does not load", a:fixed_tips_width, a:log_verbose)
    endif
    " endif
endfunction

" if(argc() == 0)
if(1 == len(v:argv))

    augroup load_session
        au!
        au VimEnter * nested :call s:load(g:log_address, g:is_windows, g:fixed_tips_width, g:log_verbose)
    augroup END
endif

if ! exists("g:session_auto_loaded")
    nnoremap <unique><silent> <Plug>(SessionAuto) :call <SID>make(g:log_address, g:is_windows, g:fixed_tips_width, g:log_verbose)<CR><CR>
    " map <leader>m :call <SID>make(g:log_address, g:is_windows, g:fixed_tips_width, g:log_verbose)<CR>
    command! -bar -nargs=0 SA :call s:make(g:log_address, g:is_windows, g:fixed_tips_width, g:log_verbose)
    let g:session_auto_loaded = 1
endif

augroup save_and_update_session
    au!
    au VimLeavePre * ++nested :call s:update(g:log_address, g:is_windows, g:fixed_tips_width, g:log_verbose)
    au VimLeavePre * ++nested :call s:save(g:log_address, g:is_windows, g:fixed_tips_width, g:log_verbose)
augroup END


" " ssop-=buffers
" autocmd BufEnter,VimLeavePre * call s:save(g:log_address, g:is_windows, g:fixed_tips_width, g:log_verbose)

if ! exists('g:skipview_files')
    " https://vim.fandom.com/wiki/Make_views_automatic
    let g:skipview_files = [
                \ '[EXAMPLE PLUGIN BUFFER]'
                \, '__Tagbar__'
                \ ]
else
    let g:skipview_files += [
                \ '[EXAMPLE PLUGIN BUFFER]'
                \, '__Tagbar__'
                \ ]
    :call uniq(sort(g:skipview_files))
endif

function! s:make_view_check(log_address, is_windows, fixed_tips_width, log_verbose)
    let result = 1
    if has('quickfix') && &buftype =~ 'nofile'
        " Buffer is marked as not a file
        let result = 0
    endif
    " https://github.com/airblade/vim-rooter/issues/122
    if empty(glob(escape(expand('%:p'), '?*[]')))
        " File does not exist on disk
        let result = 0
    endif
    if len($TEMP) && expand('%:p:h') == $TEMP
        " We're in a temp dir
        let result = 0
    endif
    if len($TMP) && expand('%:p:h') == $TMP
        " Also in temp dir
        let result = 0
    endif
    if index(g:skipview_files, expand('%')) >= 0
        " File is in skip list
        let result = 0
    endif

    let target_info = s:make_session_dir(a:log_address, a:is_windows, a:fixed_tips_width, a:log_verbose)
    let l:session_dir = target_info['session_dir']
    let l:session_file = target_info['session_file']  " l:session_dir . '/' . s:session_name
    let folder_writable = boot#chomped_system("if [ -w " . l:session_dir . " ] ; then echo '1' ; else echo '0' ; fi")
    if 0 == folder_writable || ! filewritable(l:session_dir) || ! filewritable(l:session_file)
        let result = 0
    endif
    " else
    "     let result = 0
    " endif
    return result
endfunction

if 1 == s:_session_auto_save_view
    " https://vim.fandom.com/wiki/Make_views_automatic
    augroup auto_view
        autocmd!
        " Autosave & Load Views.
        autocmd BufWinLeave,BufWritePost,BufLeave,WinLeave ?* if s:make_view_check(g:log_address, g:is_windows, g:fixed_tips_width, g:log_verbose) |
                    \ call s:view_make(g:log_address, g:is_windows, g:fixed_tips_width, g:log_verbose) | endif
        autocmd BufWinEnter ?* if s:make_view_check(g:log_address, g:is_windows, g:fixed_tips_width, g:log_verbose) |
                    \ silent! call s:view_load(g:log_address, g:is_windows, g:fixed_tips_width, g:log_verbose) | endif
    augroup end
endif




















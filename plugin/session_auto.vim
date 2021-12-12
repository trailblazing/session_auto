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

let s:session_name = '.session.vim'
let s:view_name    = '.view.vim'


function! s:session(log_address, is_windows, log_verbose)
    let l:project = boot#project(a:log_address, a:is_windows, a:log_verbose)
    if l:project != "" 
        let l:dir = l:project
    else
        let l:dir = resolve(expand(getcwd()))
    endif

    if filewritable(l:dir) != 2
        " exe 'silent !mkdir -p ' l:dir
        silent! exe '!mkdir -p ' l:dir
        redraw!
    endif

    return l:dir
endfunction

function! s:generate_link(target_file, log_address, is_windows, log_verbose)
    let local_dir = resolve(expand(getcwd()))
    if local_dir != s:session_dir
        call boot#chomped_system('ln -sf ' . s:session_dir . '/' . a:target_file . ' ' . local_dir  . '/' . a:target_file)
    endif
endfunction

function! s:view_make(log_address, is_windows, log_verbose)
    let s:session_dir = s:session(a:log_address, a:is_windows, a:log_verbose) . ""
    silent! exe 'set viewdir =' . s:session_dir
    let s:view_file = s:session_dir . '/' . s:view_name
    silent! exe 'mkview! ' . s:view_file
    call s:generate_link(s:view_name, a:log_address, a:is_windows, a:log_verbose)
    " silent! execute "!clear &" | redraw!
    silent! execute redraw!
endfunction

function! s:view_load(log_address, is_windows, log_verbose)
    let s:session_dir = resolve(expand(getcwd()))    " s:session(a:log_address, a:is_windows, a:log_verbose) . ""
    silent! exe 'set viewdir =' . s:session_dir
    let s:view_file = s:session_dir . '/' . s:view_name
    silent! exe 'loadview ' . s:view_file
    silent! execute redraw!
endfunction

" https://vim.fandom.com/wiki/Go_away_and_come_back
" creates a session
function! s:make(log_address, is_windows, log_verbose)
    " let s:session_dir = getcwd() . "" 
    let s:session_dir = s:session(a:log_address, a:is_windows, a:log_verbose) . ""
    let s:session_file = s:session_dir . '/' . s:session_name
    set sessionoptions=blank,buffers,curdir,help,tabpages,winsize,terminal
    set sessionoptions-=options
    set sessionoptions-=tabpages
    set sessionoptions-=help
    set sessionoptions-=buffers
    silent! exe "mksession! " . s:session_file
    call s:generate_link(s:session_name, a:log_address, a:is_windows, a:log_verbose)
    "   call boot#chomped_system("!clear & | redraw!")
    silent! execute redraw!
    execute "redrawstatus!"
    call boot#log_silent(a:log_address, "session::make", s:session_file, a:log_verbose)
endfunction

" https://stackoverflow.com/questions/5142099/how-to-auto-save-vim-session-on-quit-and-auto-reload-on-start-including-split-wi
fu! s:save(log_address, is_windows, log_verbose)
    let s:session_dir = s:session(a:log_address, a:is_windows, a:log_verbose) . ""
    let s:session_file = s:session_dir . '/'. s:session_name
    set sessionoptions=blank,buffers,curdir,help,tabpages,winsize,terminal
    set sessionoptions-=options
    set sessionoptions-=tabpages
    set sessionoptions-=help
    set sessionoptions-=buffers
    silent! exe "mksession! " . s:session_file
    call s:generate_link(s:session_name, a:log_address, a:is_windows, a:log_verbose)
    "   call boot#chomped_system("!clear & | redraw!")
    silent! execute redraw!
    execute "redrawstatus!"
    call boot#log_silent(a:log_address, "session::save", s:session_file, a:log_verbose)
    call boot#log_silent(a:log_address, "\n", "", a:log_verbose) 
endfunction

" updates a session, BUT ONLY IF IT ALREADY EXISTS
function! s:update(log_address, is_windows, log_verbose)
    " let s:session_dir = getcwd() . "" 
    let s:session_dir = s:session(a:log_address, a:is_windows, a:log_verbose) . ""
    let s:session_file = s:session_dir . '/' . s:session_name
    if filereadable(s:session_file)
        silent! exe "mksession! " . s:session_file
        call s:generate_link(s:session_name, a:log_address, a:is_windows, a:log_verbose)
        echo "updating session"
        " call boot#chomped_system("!clear & | redraw!")
        silent! execute redraw!
        execute "redrawstatus!"
    endif
    call boot#log_silent(a:log_address, "session::update", s:session_file, a:log_verbose)
endfunction

fu! s:restore(log_address, is_windows, log_verbose)
    if bufexists(1)
        for l in range(1, bufnr('$'))
            if bufwinnr(l) == -1
                silent! exec 'sbuffer ' . l
            endif
        endfor
    endif
    call boot#log_silent(a:log_address, "session::restore", s:session_file, a:log_verbose)
endfunction

" loads a session if it exists
function! s:load(log_address, is_windows, log_verbose)
    " if argc() == 0
    " if(1 == len(v:argv))
    " let s:session_dir = getcwd() . ""
    let s:session_dir = resolve(expand(getcwd()))    " s:session(a:log_address, a:is_windows, a:log_verbose) . ""
    let s:session_file = s:session_dir . '/' . s:session_name
    call boot#log_silent(a:log_address, "session::session_file", s:session_file . "", a:log_verbose)
    if filereadable(s:session_file)
        " silent! echom "session to be loaded."
        silent! exe 'source ' . s:session_file
        " exe 'source ' s:session_file
        :call s:restore(a:log_address, a:is_windows, a:log_verbose)
        " silent! echo "session loaded."
        silent! execute redraw!
        call boot#log_silent(a:log_address, "session::load", s:session_file . " loaded", a:log_verbose)
    else
        " silent! echo "No session loaded."
        call boot#log_silent(a:log_address, "session::load", s:session_file . " does not load", a:log_verbose)
    endif
    " else
    "     let s:session_file = ""
    "     let s:session_dir = ""
    " endif
endfunction

" if(argc() == 0)
if(1 == len(v:argv))

    augroup load_session
        au!
        au VimEnter * nested :call s:load(g:log_address, g:is_windows, g:log_verbose)
    augroup END
else
    let s:session_file = ""
    let s:session_dir = ""
endif

noremap <unique> <Plug>SessionAuto :call <SID>make(g:log_address, g:is_windows, g:log_verbose)<CR>
" map <leader>m :call <SID>make(g:log_address, g:is_windows, g:log_verbose)<CR>

augroup save_and_update_session
    au!
    au VimLeavePre * :call s:update(g:log_address, g:is_windows, g:log_verbose)
    au VimLeavePre * :call s:save(g:log_address, g:is_windows, g:log_verbose)
augroup END


" " ssop-=buffers
" autocmd BufEnter,VimLeavePre * call s:save(g:log_address, g:is_windows, g:log_verbose)

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

function! s:make_view_check(log_address, is_windows, log_verbose)
    if has('quickfix') && &buftype =~ 'nofile'
        " Buffer is marked as not a file
        return 0
    endif
    " https://github.com/airblade/vim-rooter/issues/122    
    if empty(glob(escape(expand('%:p'), '?*[]')))
        " File does not exist on disk
        return 0
    endif
    if len($TEMP) && expand('%:p:h') == $TEMP
        " We're in a temp dir
        return 0
    endif
    if len($TMP) && expand('%:p:h') == $TMP
        " Also in temp dir
        return 0
    endif
    if index(g:skipview_files, expand('%')) >= 0
        " File is in skip list
        return 0
    endif

    let s:session_dir = s:session(a:log_address, a:is_windows, a:log_verbose) . ""
    let s:session_file = s:session_dir . '/' . s:session_name
    let folder_writable = boot#chomped_system("if [ -w " . s:session_dir . " ] ; then echo '1' ; else echo '0' ; fi")
    if 0 == folder_writable || ! filewritable(s:session_dir) || ! filewritable(s:session_file)
        return 0
    endif

    return 1
endfunction

augroup auto_view
    autocmd!
    " Autosave & Load Views.
    autocmd BufWritePost,BufLeave,WinLeave ?* if s:make_view_check(g:log_address, g:is_windows, g:log_verbose) |
                \ call s:view_make(g:log_address, g:is_windows, g:log_verbose) | endif
    autocmd BufWinEnter ?* if s:make_view_check(g:log_address, g:is_windows, g:log_verbose) |
                \ silent call s:view_load(g:log_address, g:is_windows, g:log_verbose) | endif
augroup end


let g:session_auto_loaded = 1



















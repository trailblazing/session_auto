" session_auto.vim:   Automatically save the session to the root of the current
"                     project based on the .git location and create a link at
"                     current directory. If the project root could not be
"                     determined, save the session under the current directory.
" Maintainer:         Tuo Jung <https://github.com/trailblazing>
" Version:            0.0.1
" Website:            https://github.com/trailblazing/session_auto
" Dependency:         https://github.com/trailblazing/boot
" License:            GPL v3 and later

if exists("g:loaded_session_auto")
    finish
endif

let s:_init_value = {}
let s:_init_value._log_address      = $HOME . '/.vim.log'
let s:_init_value._fixed_tips_width = 27
let s:_init_value._log_verbose      = 0
let s:_init_value._is_windows       = 0
let s:_init_value._script_develop   = 0
let s:_init_value._log_one_line     = 1

if ! exists("g:_session_auto_develop")
    let s:_session_auto_develop = 0
    let g:_session_auto_develop = 0
else
    let s:_session_auto_develop = g:_session_auto_develop
endif

let s:environment = {}

if ! exists("s:_environment")
    let s:_environment = boot#environment(s:environment, '<sfile>',
        \ s:_session_auto_develop, s:_init_value)
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

" Rational
" current_cache[/.fiction.vim]  --> project_cache[/.session.vim]
"       ^          ^                   |^
"       |          |                   v|
" current_dir      |                project_dir         read stage
"                  |                   |^
"                  |                   v|
"              current_dir          target_dir/files    write stage

let s:session_name = '.session.vim'
let s:fake_session = '.fiction.vim'

let s:callback_update_setuped = 0

function! session_auto#setup(auto_update)
    let s:session_auto_update = a:auto_update
    let s:callback_update_setuped = 1
endfunction

" Might input current dir or target dir
function! s:to_session_cache(source_dir)
    let result = {}
    let l:session_user_home = $HOME
    if "" == l:session_user_home
        if has('nvim')
            let l:session_user  = boot#chomp(system(['whoami']))
        else
            let l:session_user  = boot#chomp(system('whoami'))
        endif
        if has('nvim')
            let s:session_user_home =
                \ system(['/usr/bin/awk',  '-v', 'FS=:', '-v', 'user=' .
                \ s:session_user, '{if ($1 == user) print $6}', '/etc/passwd'])
        else
            let s:session_user_home =
                \ boot#chomp(system('/usr/bin/awk -v FS=: -v user=' .
                \ s:session_user. ' "{if (\$1 == user) print \$6}" /etc/passwd'))
        endif
        echohl WarningMsg
        echom "Session \$HOME == " . l:session_user_home
        call feedkeys("\<CR>")
        echohl None
    endif
    if has('nvim')
        let l:cache_prefix = l:session_user_home . '/.cache/nvim'
    else
        let l:cache_prefix = l:session_user_home . '/.cache/vim'
    endif
    let result['session_prefix'] = l:cache_prefix
    let l:source_dir = boot#standardize(a:source_dir)
    if '/' == l:source_dir
        let l:session_dir = l:cache_prefix
    else
        let l:session_dir = l:cache_prefix . l:source_dir
    endif
    let result['session_dir'] = l:session_dir
    return result
endfunction

function! session_auto#read(_environment = g:_environment)
    let l:func_name = boot#function_name('#', expand('<sfile>'))
    let result = {}
    let l:current_dir = boot#standardize($PWD)
    let l:current_cache = s:to_session_cache(l:current_dir)
    let l:cache_link_dir = l:current_cache['session_dir']

    if has('nvim')
        let l:read_link = boot#chomp(system(['readlink', l:cache_link_dir
            \ . '/' . s:fake_session]))
        let l:target_dir = boot#chomp(system(['dirname', l:read_link]))
    else
        let l:read_link = boot#chomp(system('readlink ' . l:cache_link_dir
            \ . '/' . s:fake_session))
        let l:target_dir = boot#chomp(system('dirname ' . l:read_link))
    endif

    let result['session_file'] = l:read_link
    let result['session_dir']  = l:target_dir

    return result
endfunction

function! s:local_link(_session_dir, _environment)
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    let l:current_dir = boot#standardize($PWD)
    let l:current_cache = s:to_session_cache(l:current_dir)
    let l:cache_link_dir = ""
    " echom "l:current_dir = " . l:current_dir

    let l:cache_prefix = l:current_cache['session_prefix']
    let l:cache_link_dir = l:cache_prefix . l:current_dir

    " echom "l:cache_link_dir = " . l:cache_link_dir
    " Not created yet
    " if filewritable(l:cache_link_dir) == 2
    if has('nvim')
        " nvim -V9~/.vim.log
        " E475: Invalid value for argument cmd: '\mkdir' is not executable
        call boot#chomp(system(['mkdir', '-p', l:cache_link_dir]))
    else
        call boot#chomp(system('mkdir -p '. l:cache_link_dir))
    endif
    " endif

    " let link_exists = boot#chomp(system(['sh', '-c', 'if [ -L "'
    "     \ . l:cache_link_dir . '" ] ;
    "     \ then echo 1 ; else echo 0 ; fi']))
    " if link_exists

    if has('nvim')
        let l:read_link = boot#chomp(system(['readlink'
            \, l:cache_link_dir . '/' . s:fake_session]))
    else
        let l:read_link = boot#chomp(system('readlink '
            \. l:cache_link_dir . '/' . s:fake_session))
    endif

    if a:_session_dir . '/' . s:session_name != l:read_link
        if has('nvim')
            call boot#chomp(system(['rm', '-f', l:cache_link_dir
                \ . '/' . s:fake_session]))
            " local link leads to recursive calling of busybox (ash)
            call boot#chomp(system(['ln', '-sf', a:_session_dir
                \ . '/' . s:session_name,
                \ l:cache_link_dir . '/' . s:fake_session]))
        else
            call boot#chomp(system('rm -f '. l:cache_link_dir
                \ . '/' . s:fake_session))
            " local link leads to recursive calling of busybox (ash)
            call boot#chomp(system('ln -sf '. a:_session_dir
                \ . '/' . s:session_name . " " .
                \ l:cache_link_dir . '/' . s:fake_session))
        endif
    endif

    return l:cache_link_dir . '/' . s:fake_session
endfunction

function! session_auto#make(_file_dir, _environment)
    let l:func_name = boot#function_name('#', expand('<sfile>'))

    if has('nvim')
        let l:session_user  = boot#chomp(system(['whoami']))
        let l:session_group = boot#chomp(system(['id', '-gn', l:session_user]))
    else
        let l:session_user  = boot#chomp(system('whoami'))
        let l:session_group = boot#chomp(system('id -gn ', l:session_user))
    endif

    let l:project_dir = boot#project(a:_file_dir, a:_environment)
    if has('nvim')
        let l:project_dir_user  =
            \ boot#chomp(system(['stat', '-c "%U"', l:project_dir]))
        let l:project_dir_group =
            \ boot#chomp(system(['stat', '-c "%G"', l:project_dir]))
        " https://stackoverflow.com/questions/18431285/check-if-a-user-is-in-a-group
        let l:user_in_groups    =
            \ boot#chomp(system(['id', '-nG', l:session_user]))
    else
        let l:project_dir_user  =
            \ boot#chomp(system('stat -c "%U" '. l:project_dir))
        let l:project_dir_group =
            \ boot#chomp(system('stat -c "%G" '. l:project_dir))
        " https://stackoverflow.com/questions/18431285/check-if-a-user-is-in-a-group
        let l:user_in_groups    = boot#chomp(system('id -nG '. l:session_user))
    endif
    let l:grp_list = split(l:user_in_groups, " ")
    let l:session_user_belongs_to_project_group =
        \ index(l:grp_list, l:project_dir_group) != -1
    " let l:session_user_belongs_to_project_group = boot#chomp(
    "     \system("if id -nG " .
    "     \ l:session_user . " | grep -qw " . l:project_dir_group
    "     \ . "; then echo '1' ; else echo '0' ; fi"))

    " let l:session_user_home = boot#chomp(system(['sh', '-c'
    "     \, "awk -v FS=':' -v user=\"" .
    "     \ l:session_user . "\" '($1==user) {print $6}' \"/etc/passwd\""]))
    let l:session_user_home = $HOME

    let l:session_dir =  ""

    " let l:current_dir = resolve(expand(getcwd()))
    let l:current_dir = boot#standardize($PWD)
    if has('nvim')
        let l:current_dir_user  = boot#chomp(system(['stat', '-c "%U"'
            \, l:current_dir]))
        let l:current_dir_group = boot#chomp(system(['stat', '-c "%G"'
            \, l:current_dir]))
    else
        let l:current_dir_user  = boot#chomp(system('stat -c "%U" '
            \ . l:current_dir))
        let l:current_dir_group = boot#chomp(system('stat -c "%G" '
            \ . l:current_dir))
    endif
    if l:project_dir == ""
        let l:project_dir = l:current_dir
    endif

    let l:project_cache = s:to_session_cache(l:project_dir)
    let l:session_dir = l:project_cache['session_dir']

    " Link to directory is a legacy design
    if has('nvim')
        let l:read_link = boot#chomp(system(['readlink', l:session_dir]))
        " let link_exists = boot#chomp(system(['sh', '-c', 'if [ -L "'
        "     \ . l:session_dir . '" ] ;
        "     \ then echo 1 ; else echo 0 ; fi']))
    else
        let l:read_link = boot#chomp(system('readlink ' . l:session_dir))
    endif
    let link_exists = l:read_link != l:session_dir && "" != l:read_link
    if link_exists
        if filewritable(l:session_dir)
            if has('nvim')
                call boot#chomp(system(['rm', '-rf', l:session_dir]))
                call boot#chomp(system(['mkdir', '-p', l:session_dir]))
            else
                call boot#chomp(system('rm -rf '. l:session_dir))
                call boot#chomp(system('mkdir -p '. l:session_dir))
            endif
        endif
    else
        if has('nvim')
            let dir_exists = boot#chomp(system(['sh', '-c', 'if [ -d "'
                \ . l:session_dir . '" ] ;
                \ then echo 1 ; else echo 0 ; fi']))
        else
            let dir_exists = boot#chomp(system("sh -c 'if [ -d \""
                \ . l:session_dir . "\" ] ;
                \ then echo 1 ; else echo 0 ; fi'"))
        endif
        if ! dir_exists
            silent! exe '!command mkdir -p ' l:session_dir . ' > /dev/null 2>&1'
        endif
    endif

    let l:session_file = l:session_dir . '/' . s:session_name
    silent! exe '!touch ' l:session_file

    if l:session_user != l:project_dir_user || l:session_group
        \ != l:project_dir_group
        if has('nvim')
            call boot#chomp(system(['chown', '-R', '--quiet', '"'
                \ . l:project_dir_user . ':' . l:project_dir_group
                \ . '"', l:session_dir]))
        else
            call boot#chomp(system('chown -R --quiet '. '"' . l:project_dir_user
                \ . ':' . l:project_dir_group . '" '. l:session_dir))
        endif
    endif

    if ! filewritable(l:session_dir)
        call boot#log_silent(l:func_name . '::session_dir '
            \, l:session_dir, a:_environment)
    endif

    return {
        \ 'session_file':      l:session_file,
        \ 'session_dir':       l:session_dir,
        \ 'session_user':      l:session_user,
        \ 'session_group':     l:session_group,
        \ 'session_user_home': l:session_user_home,
        \ 'project_dir':       l:project_dir,
        \ 'project_dir_user':  l:project_dir_user ,
        \ 'project_dir_group': l:project_dir_group,
        \ 'current_dir_user':  l:current_dir_user,
        \ 'current_dir':       l:current_dir
        \ }

endfunction

function! s:view_make(_session_dir, _environment)
    " let local_dir = resolve(expand(getcwd()))    " let l:session_dir = session_auto#make(a:_environment)
    if "" == a:_session_dir
        let target_info = session_auto#make(resolve(expand("#". bufnr()
            \ . ":p:h")), a:_environment)
        let l:session_dir = target_info['session_dir']
    else
        let l:session_dir = a:_session_dir
    endif
    silent! exe 'set viewdir=' . l:session_dir
    " https://gist.github.com/mitry/813151
    " set viewoptions=folds,options,cursor,unix,slash " better unix/windows compatibility
    " set viewoptions-=options
    set viewoptions=folds,cursor,unix,slash " better unix/windows compatibility
    " let s:view_file = local_dir . '/' . s:view_name
    silent! mkview!    " silent! exe 'mkview! ' . s:view_name
    " silent! execute "!clear &" | redraw!
    " redraw!
endfunction

function! s:view_load(_environment)
    " let local_dir = resolve(expand(getcwd()))    " session_auto#make(a:_environment)
    let target_info = session_auto#read(a:_environment)
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
function! s:make(_environment)
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    let l:target_dir = resolve(expand("#". bufnr(). ":p:h"))
    let target_info = session_auto#make(l:target_dir, a:_environment)
    let l:session_file = target_info['session_file']
    set sessionoptions=blank,buffers,curdir,help,tabpages,winsize,terminal
    " set sessionoptions-=options
    set sessionoptions-=tabpages
    set sessionoptions-=help

    set sessionoptions-=buffers
    " Buffer changes won't save until you have following settings in your .vimrc/init.vim
    " " https://stackoverflow.com/questions/2902048/vim-save-a-list-of-open-files-and-later-open-all-files/2902082
    " set viminfo='5,f1,\"50,:20,%,n~/.vim/viminfo

    silent! exe "mksession! " . l:session_file

    " breakadd here
    " debug call s:local_link(l:target_dir, a:_environment)
    let l:local_link = s:local_link(target_info['session_dir'], a:_environment)
    " call boot#chomp(system("!clear & | redraw!"))
    call s:view_make(target_info['session_dir'], a:_environment)
    " redraw!
    execute "redrawstatus!"
    echohl WarningMsg
    echom "Session file saved in " . l:session_file
    echom "Session link saved in " . l:local_link
    call feedkeys("\<CR>")
    echohl None
    call boot#log_silent(l:func_name . '::"' . s:session_name
        \ . '" was saved at', l:session_file, a:_environment)
    call boot#log_silent(l:func_name . '::"l:local_link" was saved at'
        \, l:local_link, a:_environment)
    " silent! execute '!(printf ' . '"\n\%-"' . a:_environment._fixed_tips_width
    "     \ . '"s: \%s\n"' . ' "\"' . s:session_name . '\" was saved at " "'
    "     \ . l:session_file . '")' . ' >> ' . a:_environment._log_address . ' 2>&1 &'
endfunction

" https://stackoverflow.com/questions/5142099/how-to-auto-save-vim-session-on-quit-and-auto-reload-on-start-including-split-wi
function! s:save(_environment)
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    let l:target_dir = resolve(expand("#". bufnr(). ":p:h"))
    let target_info = session_auto#make(l:target_dir, a:_environment)
    let l:session_file = target_info['session_file']
    set sessionoptions=blank,buffers,curdir,help,tabpages,winsize,terminal
    " set sessionoptions-=options
    set sessionoptions-=tabpages
    set sessionoptions-=help

    set sessionoptions-=buffers
    " Buffer changes won't save until you have following settings in your .vimrc/init.vim
    " " https://stackoverflow.com/questions/2902048/vim-save-a-list-of-open-files-and-later-open-all-files/2902082
    " set viminfo='5,f1,\"50,:20,%,n~/.vim/viminfo

    silent! exe "mksession! " . l:session_file

    " breakadd here
    let l:local_link = s:local_link(target_info['session_dir'], a:_environment)
    " call boot#chomp(system("!clear & | redraw!"))
    call s:view_make(target_info['session_dir'], a:_environment)
    " redraw!
    execute "redrawstatus!"
    echohl WarningMsg
    echom "Session file saved in " . l:session_file
    echom "Session link saved in " . l:local_link
    call feedkeys("\<CR>")
    echohl None
    call boot#log_silent(l:func_name . '::"' . s:session_name . '" was saved at'
        \, l:session_file, a:_environment)
    call boot#log_silent(l:func_name . '::"l:local_link" was saved at'
        \, l:local_link, a:_environment)
    " silent! execute '!(printf ' . '"\n\%-"' . a:_environment._fixed_tips_width
    "     \ . '"s: \%s\n"' . ' "\"' . s:session_name . '\" was saved at " "'
    "     \ . l:session_file . '")' . ' >> ' . a:_environment._log_address . ' 2>&1 &'
endfunction

" updates a session, BUT ONLY IF IT ALREADY EXISTS
function! s:update(_environment)
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    let l:target_dir = resolve(expand("#". bufnr(). ":p:h"))
    let target_info = session_auto#make(l:target_dir, a:_environment)
    let l:session_file = target_info['session_file']
    if filereadable(l:session_file)

        silent! exe "mksession! " . l:session_file

        " breakadd here
        let l:local_link = s:local_link(target_info['session_dir'], a:_environment)
        echo "updating session"
        " call boot#chomp(system("!clear & | redraw!"))
        call s:view_make(target_info['session_dir'], a:_environment)
        " redraw!
        execute "redrawstatus!"
        call boot#log_silent(l:func_name . '::"l:local_link" was saved at'
            \, l:local_link, a:_environment)
    endif
    call boot#log_silent(l:func_name, l:session_file, a:_environment)
endfunction

" https://stackoverflow.com/questions/5142099/how-to-auto-save-vim-session-on-quit-and-auto-reload-on-start-including-split-wi
function! s:restore(session_file, _environment)
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    if bufexists(1)
        for l in range(1, bufnr('$'))
            if bufwinnr(l) == -1
                silent! exec 'sbuffer ' . l
            endif
        endfor
    endif
    call boot#log_silent(l:func_name, a:session_file, a:_environment)
endfunction

" loads a session if it exists
function! s:load(_environment)
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    " if argc() == 0
    " if(1 == len(v:argv))
    let target_info = session_auto#read(a:_environment)
    let l:session_file = target_info['session_file']
    echohl WarningMsg
    echom "Located session at " . l:session_file
    call feedkeys("\<CR>")
    echohl None

    " call boot#log_silent(l:func_name, l:session_file, a:_environment)
    if filereadable(l:session_file)
        " silent! echom "session to be loaded."
        silent! exe 'source ' . l:session_file
        " exe 'source ' l:session_file
        "
        if 1 == s:_restore_each_buffer_view
            call s:restore(l:session_file, a:_environment)
        endif

        " silent! echo "session loaded."
        call s:view_load(a:_environment)
        " redraw!

        echohl WarningMsg
        echom "Load session from  " . l:session_file . " succeeded"
        call feedkeys("\<CR>")
        echohl None

        call boot#log_silent(l:func_name, l:session_file . " succeeded"
            \, a:_environment)

        if s:callback_update_setuped
            call s:session_auto_update(1)
        endif

    else
        echohl WarningMsg
        echom "Loading session from " . l:session_file . " failed"
        call feedkeys("\<CR>")
        echohl None
        " silent! echo "No session loaded."
        call boot#log_silent(l:func_name, l:session_file . " failed"
            \, a:_environment)

        if s:callback_update_setuped
            call s:session_auto_update(0)
        endif

    endif
    " endif
endfunction

function! SaveSession()
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    call s:save(s:_environment)
    call boot#log_silent(l:func_name, "job started", a:_environment)
endfunction


function! LoadSession()
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    call s:load(s:_environment)
    call boot#log_silent(l:func_name, "job started", a:_environment)
endfunction

function! MakeSession()
    let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
    call s:make(s:_environment)
    call boot#log_silent(l:func_name, "job started", a:_environment)
endfunction

" if (argc() == 0)
" if (1 == len(v:argv))
augroup auto_load_session
    au!
    au VimEnter * nested if ! argc() | call s:load(s:_environment) | endif
    " au VimEnter * nested call <SID>load(g:_environment)
    " au VimEnter *
    "     \ nested :call function(g:_environment._job_start)("LoadSession")
augroup END
" endif

if ! exists("g:loaded_session_auto")
    execute 'nnoremap <unique><silent> <Plug>(SessionMake)
        \ :call <SID>make(g:_environment)<CR><CR>'
    " execute 'map <leader>m :call <SID>make(' . s:_environment . ')<CR>'
    command! -bar -nargs=0 SA :call s:make(s:_environment)
    " command! -bar -nargs=0 SA
    "     \ :call function(g:_environment._job_start)("MakeSession")

    execute 'nnoremap <unique><silent> <Plug>(SessionLoad)
        \ :call <SID>load(g:_environment)<CR><CR>'

    command! -bar -nargs=0 SL :call s:load(s:_environment)

    let g:loaded_session_auto = 1
endif

augroup save_and_update_session
    au!
    " au VimLeavePre * ++nested :call s:update(s:_environment)
    au VimLeavePre *
        \ if 0 != len(filter(range(1, bufnr('$')), 'buflisted(v:val)'))
        \ | call s:save(s:_environment) | endif
    " au BufEnter,VimLeavePre * :call function(g:_environment._job_start)("SaveSession")
    " au BufEnter * ++nested call s:update(s:_environment)
    " au BufEnter * if 0 != bufnr() | call s:update(s:_environment) | endif
augroup END

function! s:reload()
    " packadd session_auto
    " Don't do this manually before all plugins loaded

    if exists('g:loaded_session_auto')
        unlet g:loaded_session_auto
    endif
    silent! execute "source " . expand('%')
    silent! execute "runtime! " . expand('%')
endfunction

command! -nargs=0 SR :call s:reload()

" " ssop-=buffers
" autocmd BufEnter,VimLeavePre * call s:save(s:_environment)

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

function! s:make_view_check(_environment)
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

    let target_info = session_auto#make(resolve(expand("#". bufnr()
        \ . ":p:h")), a:_environment)
    let l:session_dir  = target_info['session_dir']
    let l:session_file = target_info['session_file']
    " let folder_writable = boot#chomp(system(['sh','-c', 'if [ -w "'
    "     \ . l:session_dir . '" ] ; then echo 1 ; else echo 0 ; fi']))
    " if 0 == folder_writable || ! filewritable(l:session_dir)
    "     \ || ! filewritable(l:session_file)
    if ! filewritable(l:session_dir) || ! filewritable(l:session_file)
        let result = 0
    endif
    return result
endfunction

" if 1 == s:_session_auto_save_view
"     " https://vim.fandom.com/wiki/Make_views_automatic
"     augroup auto_view
"         autocmd!
"         " Autosave & Load Views.
"         autocmd BufWinLeave,BufWritePost,BufLeave,WinLeave ?*
"             \ if s:make_view_check(s:_environment) |
"             \ call s:view_make(s:_environment) | endif
"         autocmd BufWinEnter ?* if s:make_view_check(s:_environment) |
"             \ silent! call s:view_load(s:_environment) | endif
"     augroup end
" endif




















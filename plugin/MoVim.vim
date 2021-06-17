" MoVim ()
" Copyright (C) 2021  Christian Doering
" 
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
" 
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
" 
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <https://www.gnu.org/licenses/>.

if(!hlexists('MoVimTargets'))
    call execute("hi! MoVimTargets ctermfg=Red guifg=Red guibg=" . ReturnHighlightTerm("Visual", "guibg") . " ctermbg=" . ReturnHighlightTerm("Visual", "ctermbg") . "" )
    call execute("hi! MoVimJump ctermfg=White guifg=White guibg=" . ReturnHighlightTerm("Error", "guibg") . " ctermbg=" . ReturnHighlightTerm("Error", "ctermbg") . "" )
endif 

function! MoVimTargets(string, prefix, dir)
    let targets = []
    let orig = getpos('.')
    let orig_virtcol = virtcol('.')
    let pos_first = []

    while 1
        let dir_char = a:dir ? '>' : '<'
        let bound_vert = '\%' . dir_char . string(orig[1]) . 'l\%<' . string(line("w$")+1) . 'l\%>' . string(line("w0")-1) . 'l'
        let bound_curln = '\%' . string(orig[1]) . 'l\%' . dir_char . string(orig_virtcol) . 'v'
        let search = a:string
        let bounded = bound_vert . a:prefix . search . '\|' . bound_curln . a:prefix . search

        call search('\m' . bounded, a:dir ? '' : 'b')
        let pos = getpos('.')
        if(!empty(pos_first) && pos == pos_first)
            break
        endif
        call add(targets, pos)
        if(empty(pos_first))
            let pos_first = pos
        endif

    endwhile

    call setpos('.', orig)
    if(targets[0][1] == orig[1] && targets[0][2] == orig[2])
        return []
    endif
    return targets
endfunction

function! MoVimReplace(targets)

endfunction

function! MoVimSearch(prefix, dir)
    redraw
    echo '>'

    "save undofile
    try
        let undofile = undofile(expand('%'))
        let delundofile = !empty(&buftype)
        execute 'wundo!' fnameescape(undofile)
    catch
        try
            let undofile = tempname()
            let delundofile = 1
            execute 'wundo!' fnameescape(undofile)
        catch
            let manual = 1
            unlet undofile
        endtry
    endtry

    "search for targets
    let max = 2
    let i = 0
    let search = ""
    let highlights = []
    let targets = []
    let orig = getpos('.')
    redraw
    while(1)
        let i += 1
        echo(">" . search)
        let search .= nr2char(getchar())
        let targets_max = pow(10, strlen(search))
        let targets = MoVimTargets(search, a:prefix, a:dir)
        let j = 1
        for target in targets
            call add(highlights, matchaddpos("MoVimTargets", [[target[1], target[2], i]]))

            let number = string(j)
            silent execute "normal! :" . target[1]. "\<CR>" . target[2] . "|gR" . number

            if(j >= targets_max-1)
                break
            endif
            let j += 1
        endfor
        redraw
        if(i >= max)
            break
        endif
        for highlight in highlights
            call matchdelete(highlight)
        endfor
        "undo to get to original state
        silent undo
        "for target in targets
        "    silent execute "normal! :" . target[1]. "\<CR>" . target[2] . "|gR" . search
        "endfor
        call setpos('.', orig)
        let highlights = []
    endwhile

    echo(">" . search)

    if(empty(targets))
        return
    endif


    let num_str = ""
    let num = 0
    let j = 0
    let c = ''
    let highlights_final = []
    let orig = targets[0]
    call setpos('.', orig)
    call add(highlights_final, matchaddpos("MoVimJump", [[targets[0][1], targets[0][2], j]]))
    redraw
    for highlight in highlights_final
        call matchdelete(highlight)
    endfor
    let highlights_final = []

    "goto commands

    while(j < i)
        echo(search . ">" . num_str)
        let c = nr2char(getchar())
        let num_str .= c
        if(c == ';')
            let num += 1
            let num_str = ""
        elseif(!(c >= '0' && c <= '9'))
            let num = 0
            let j += 1
            break
        else
            let num = str2nr(num_str)-1
            let j += 1
        endif
        if(num >= len(targets))
            break
        endif
        let orig = targets[num]
        call setpos('.', orig)
        "let highlight = highlights[num]
        call add(highlights_final, matchaddpos("MoVimJump", [[targets[num][1], targets[num][2], j]]))
        redraw
        for highlight in highlights_final
            call matchdelete(highlight)
        endfor
        let highlights_final = []
    endwhile

    for highlight in highlights
        call matchdelete(highlight)
    endfor
    "reset

    let highlights = []

    "undo to get to original state

    silent undo
    redraw
   
    if(exists("undofile"))
        try
            silent execute 'rundo' fnameescape(undofile)
        catch
        endtry
        if(delundofile)
            call delete(undofile)
        endif
    else
        "for target in targets
        "    execute "normal! :" . target[1]. "\<CR>" . target[2] . "|gR" . search
        "endfor
    endif

    call setpos('.', orig)
    if(i != j)
        call feedkeys(c, 'n')
    endif
    "call execute("normal! " . c)
    "call matchdelete(highlight)
    redraw
endfunction


if !hasmapto("MoVimSearch()")
    nnoremap <unique> <leader>w :call MoVimSearch('\<', 1)<CR>
    nnoremap <unique> <leader>b :call MoVimSearch('\<', 0)<CR>
    nnoremap <unique> <leader>e :call MoVimSearch('\>', 1)<CR>
    nnoremap <unique> <leader>s :call MoVimSearch('', 1)<CR>
    nnoremap <unique> <leader>S :call MoVimSearch('', 0)<CR>
endif

" function! s:Valid(range)
"     for n in a:range
"         if n == 0
"             return 0
"         endif
"     endfor
"     return 1
" endfunction

" function! s:Size(range)
"     if !s:Valid(a:range)
"         return s:HUGE_SIZE
"     endif
"     let [l1, c1, l2, c2] = a:range
"     if l1 == l2
"         return c2 - c1 + 1
"     endif
"     let l = l1
"     let size = 0
"     while l <= l2
"         if (l == l1)
"             let size += strlen(getline(l)) - c1
"         elseif (l == l2)
"             let size += c2 - 1
"         else
"             let size += strlen(getline(l))
"         endif
"         let l += 1
"     endwhile
"     return size
" endfunction
"
" function! s:Contains(range, pos)
"     let [l, c] = a:pos
"     let [l1, c1, l2, c2] = a:range
"     return ((l1 < l) && (l < l2)) ||
"         \((l1 == l) && (l < l2) && (c1 < c)) ||
"         \((l1 < l) && (l == l2) && (c < c2)) ||
"         \((l1 == l) && (l == l2) && (c1 < c) && (c < c2))
" endfunction
"
" function! s:SearchEnclosingPair(pos, start, end)
"     call cursor(a:pos)
"     while 1
"         let [er, ec] = searchpos(a:end, 'W')
"         if (er == 0) && (ec == 0)
"             return [0, 0, 0, 0]
"         endif
"         let [br, bc] = searchpairpos(a:start, '', a:end, 'bW')
"         if (br == 0) && (bc == 0)
"             return [0, 0, 0, 0]
"         endif
"         let range = [br, bc, er, ec]
"         if s:Contains(range, a:pos)
"             return range
"         else
"             call cursor(er, ec)
"         endif
"     endwhile
" endfunction

" function! s:GetSelectionLetter() abort
"     let c_pos = getpos('.')[1:2]

"     let ranges = [
"         \s:SearchEnclosingPair(c_pos, '{', '}'),
"         \s:SearchEnclosingPair(c_pos, '(', ')'),
"         \s:SearchEnclosingPair(c_pos, '\[', '\]'),
"         \s:SearchEnclosingPair(c_pos, '<', '>')
"     \]
"     let min_size = s:HUGE_SIZE
"     let min_index = -1
"     let letters = ['B', 'b', ']', '>']
"     let index = 0
"     for range in ranges
"         let size = s:Size(range)
"         if size < min_size
"             let min_size = size
"             let min_index = index
"         endif
"         let index += 1
"     endfor

"     return min_index == -1 ? -1 : letters[min_index]
" endfunction

let s:HUGE_SIZE = 2147483647

function! s:GetSelection()
    normal! o
    let [l1, c1] = getpos('.')[1:2]
    normal! o
    let [l2, c2] = getpos('.')[1:2]
    return [l1, c1, l2, c2]
endfunction

function! s:SetSelection(range)
    normal! 
    let [l1, c1, l2, c2] = a:range
    call cursor(l1, c1)
    normal! v
    call cursor(l2, c2)
endfunction

function! s:Size(range)
    let [l1, c1, l2, c2] = a:range
    if l1 == l2
        return c2 - c1 + 1
    endif
    let l = l1
    let size = 0
    while l <= l2
        let size +=
            \ (l == l1) ? strlen(getline(l)) - c1 :
            \ (l == l2) ? c2 - 1 :
            \ strlen(getline(l))
        let l += 1
    endwhile
    return size
endfunction

function! s:ChooseTextObject(range)
    let best_size = s:HUGE_SIZE
    let best_text_object = ''
    for text_object in ['b', 'B', ']', '>']
        call s:SetSelection(a:range)
        exec "normal! i" . text_object
        let i_range = s:GetSelection()

        call s:SetSelection(a:range)
        exec "normal! a" . text_object
        let a_range = s:GetSelection()

        if i_range == a_range | continue | endif
        let size = s:Size(i_range)
        if size < best_size
            let best_size = size
            let best_text_object = text_object
        endif
    endfor
    return best_text_object
endfunction

function! s:PostprocessSelection()
    normal! o
    if col('.') == 1
        normal! ^
    endif

    normal! o
    let [c_lnum, c_col] = getpos('.')[1:2]
    if c_col > strlen(getline(c_lnum))
        normal! g_
    endif
endfunction

function! s:DoSelect(range)
    let text_object = s:ChooseTextObject(a:range)
    if !strlen(text_object) | return '' | endif
    call s:SetSelection(a:range)
    exec 'normal! i' . text_object
    call s:PostprocessSelection()
    return text_object
endfunction

function! SelectAnyBracket() abort
    let initial_selection = getpos("'<")[1:2] + getpos("'>")[1:2]
    let text_object = s:DoSelect(initial_selection)
    if !strlen(text_object)
        call s:SetSelection(initial_selection)
        return
    endif

    let after_selection = s:GetSelection()
    if after_selection != initial_selection | return | endif

    exec "normal! a" . text_object
    let text_object = s:DoSelect(s:GetSelection())
    if !strlen(text_object)
        call s:SetSelection(initial_selection)
        return
    endif
endfunction

vnoremap M :<C-u>call SelectAnyBracket()<CR>
nmap M vM
omap ii :normal M<CR>

augroup reload " {
    autocmd!
    autocmd BufWritePost /Users/elricbk/Projects/vim-text-object-any-bracket/any-bracket.vim source /Users/elricbk/Projects/vim-text-object-any-bracket/any-bracket.vim
augroup END " {

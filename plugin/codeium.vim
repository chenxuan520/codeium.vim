if exists('g:loaded_codeium')
  finish
endif
let g:loaded_codeium = 1

command! -nargs=? -complete=customlist,codeium#command#Complete Codeium exe codeium#command#Command(<q-args>)

if !codeium#util#HasSupportedVersion()
    finish
endif

function! s:SetStyle() abort
  if &t_Co == 256
    hi def CodeiumSuggestion guifg=#808080 ctermfg=244
  else
    hi def CodeiumSuggestion guifg=#808080 ctermfg=8
  endif
  hi def link CodeiumAnnotation Normal
endfunction

function! s:MapTab() abort
  if !get(g:, 'codeium_no_map_tab', v:false) && !get(g:, 'codeium_disable_bindings')
    let tab_map = maparg('<Tab>', 'i', 0, 1)
    if !has_key(tab_map, 'rhs')
      imap <script><silent><nowait><expr> <Tab> codeium#Accept()
    elseif tab_map.rhs !~# 'codeium'
      if tab_map.expr
        let tab_fallback = '{ -> ' . tab_map.rhs . ' }'
      else
        let tab_fallback = substitute(json_encode(tab_map.rhs), '<', '\\<', 'g')
      endif
      let tab_fallback = substitute(tab_fallback, '<SID>', '<SNR>' . get(tab_map, 'sid') . '_', 'g')
      if get(tab_map, 'noremap') || get(tab_map, 'script') || mapcheck('<Left>', 'i') || mapcheck('<Del>', 'i')
        exe 'imap <script><silent><nowait><expr> <Tab> codeium#Accept(' . tab_fallback . ')'
      else
        exe 'imap <silent><nowait><expr>         <Tab> codeium#Accept(' . tab_fallback . ')'
      endif
    endif
  endif
endfunction

augroup codeium
  autocmd!
  autocmd InsertEnter,CursorMovedI,CompleteChanged * call codeium#DebouncedComplete()
  autocmd BufEnter     * if codeium#Enabled()|call codeium#command#StartLanguageServer()|endif
  autocmd BufEnter     * if mode() =~# '^[iR]'|call codeium#DebouncedComplete()|endif
  autocmd InsertLeave  * call codeium#Clear()
  autocmd BufLeave     * if mode() =~# '^[iR]'|call codeium#Clear()|endif

  autocmd ColorScheme,VimEnter * call s:SetStyle()
  " Map tab using vim enter so it occurs after all other sourcing.
  autocmd VimEnter             * call s:MapTab()
  autocmd VimLeave             * call codeium#ServerLeave()
augroup END


imap <Plug>(codeium-dismiss)     <Cmd>call codeium#Clear()<CR>
imap <Plug>(codeium-next)     <Cmd>call codeium#CycleCompletions(1)<CR>
imap <Plug>(codeium-next-or-complete)     <Cmd>call codeium#CycleOrComplete()<CR>
imap <Plug>(codeium-previous) <Cmd>call codeium#CycleCompletions(-1)<CR>
imap <Plug>(codeium-complete)  <Cmd>call codeium#Complete()<CR>

if !get(g:, 'codeium_disable_bindings')
  if empty(mapcheck('<C-]>', 'i'))
    imap <silent><script><nowait><expr> <C-]> codeium#Clear() . "\<C-]>"
  endif
  if empty(mapcheck('<M-]>', 'i'))
    imap <M-]> <Plug>(codeium-next-or-complete)
  endif
  if empty(mapcheck('<M-[>', 'i'))
    imap <M-[> <Plug>(codeium-previous)
  endif
  if empty(mapcheck('<M-Bslash>', 'i'))
    imap <M-Bslash> <Plug>(codeium-complete)
  endif
  if empty(mapcheck('<C-k>', 'i'))
    imap <script><silent><nowait><expr> <C-k> codeium#AcceptNextWord()
  endif
  if empty(mapcheck('<C-l>', 'i'))
    imap <script><silent><nowait><expr> <C-l> codeium#AcceptNextLine()
  endif
endif

call s:MapTab()
call s:SetStyle()

let s:dir = expand('<sfile>:h:h')
if getftime(s:dir . '/doc/codeium.txt') > getftime(s:dir . '/doc/tags')
  silent! execute 'helptags' fnameescape(s:dir . '/doc')
endif

function! CodeiumEnable()  " Enable Codeium if it is disabled
  let g:codeium_enabled = v:true
  call codeium#command#StartLanguageServer()
endfun

command! CodeiumEnable :silent! call CodeiumEnable()

function! CodeiumDisable() " Disable Codeium altogether
  let g:codeium_enabled = v:false
endfun

command! CodeiumDisable :silent! call CodeiumDisable()

function! CodeiumToggle()
  if exists('g:codeium_enabled') && g:codeium_enabled == v:false
      call CodeiumEnable()
  else
      call CodeiumDisable()
  endif
endfunction

command! CodeiumToggle :silent! call CodeiumToggle()

function! CodeiumManual() " Disable the automatic triggering of completions
  let g:codeium_manual = v:true
endfun

command! CodeiumManual :silent! call CodeiumManual()

function! CodeiumAuto()  " Enable the automatic triggering of completions
  let g:codeium_manual = v:false
endfun

command! CodeiumAuto :silent! call CodeiumAuto()

function! CodeiumChat()
  call codeium#Chat()
endfun

command! CodeiumChat :silent! call CodeiumChat()

:amenu Plugin.Codeium.Enable\ \Codeium\ \(\:CodeiumEnable\) :call CodeiumEnable() <Esc>
:amenu Plugin.Codeium.Disable\ \Codeium\ \(\:CodeiumDisable\) :call CodeiumDisable() <Esc>
:amenu Plugin.Codeium.Manual\ \Codeium\ \AI\ \Autocompletion\ \(\:CodeiumManual\) :call CodeiumManual() <Esc>
:amenu Plugin.Codeium.Automatic\ \Codeium\ \AI\ \Completion\ \(\:CodeiumAuto\) :call CodeiumAuto() <Esc>
:amenu Plugin.Codeium.Toggle\ \Codeium\ \(\:CodeiumToggle\) :call CodeiumToggle() <Esc>
:amenu Plugin.Codeium.Chat\ \Codeium\ \(\:CodeiumChat\) :call CodeiumChat() <Esc>

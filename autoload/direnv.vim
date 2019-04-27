" direnv.vim - support for direnv <http://direnv.net>
" Author:       zimbatm <http://zimbatm.com/> & Hauleth <lukasz@niemier.pl>
" Version:      0.3

scriptencoding utf-8

let s:direnv_interval = get(g:, 'direnv_interval', 500)
let s:direnv_max_wait = get(g:, 'direnv_max_wait', 5)
let s:direnv_auto = get(g:, 'direnv_auto', 1)

function! direnv#auto() abort
  return s:direnv_auto
endfunction

function! direnv#export() abort
  call s:export_debounced.do()
endfunction

function! direnv#execute(lines) abort
  exec join(a:lines, "\n")
endfunction

function! direnv#export_core() abort
  let l:cmd = ['export', 'vim']
  call direnv#job#start(l:cmd, function('direnv#execute'))
endfunction

let s:export_debounced = {'id': 0, 'counter': 0}

if has('timers')
  function! s:export_debounced.call(...)
    let self.id = 0
    let self.counter = 0
    call direnv#export_core()
  endfunction

  function! s:export_debounced.do()
    call timer_stop(self.id)
    if self.counter < s:direnv_max_wait
      let self.counter = self.counter + 1
      let self.id = timer_start(s:direnv_interval, self.call)
    else
      call self.call()
    endif
  endfunction
else
  function! s:export_debounced.do()
    call direnv#export_core()
  endfunction
endif

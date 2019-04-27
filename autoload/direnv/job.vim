let s:direnv_cmd = get(g:, 'direnv_cmd', 'direnv')
let s:job = {'stdout': [], 'stderr': [], 'callback': 0}

function! s:job.on_stdout(_, data, ...) abort
  call extend(self.stdout, a:data)
endfunction

function! s:job.on_stderr(_, data, ...) abort
  call extend(self.stderr, a:data)
endfunction

function! s:job.on_exit(_, status, ...) abort
  for l:m in self.stderr
    if l:m isnot# ''
      echom l:m
    endif
  endfor
  call self.callback(self.stdout)
endfunction

function! s:job.err_cb(_, data) abort
  call self.on_stderr(0, split(a:data, "\n", 1))
endfunction

function! s:job.out_cb(_, data) abort
  call self.on_stdout(0, split(a:data, "\n", 1))
endfunction

function! s:job.exit_cb(_, status) abort
  call self.on_exit(0, a:status)
endfunction

function! direnv#job#start(cmd, callback) abort
  if !executable(s:direnv_cmd)
    echoerr 'No Direnv executable, add it to your PATH or set correct g:direnv_cmd'
    return
  endif

  let job = deepcopy(s:job)
  let job.callback = a:callback
  let l:cmd = extend([s:direnv_cmd], a:cmd)

  if has('nvim')
    call jobstart(l:cmd, {
          \ 'on_stdout': function(job.on_stdout, job),
          \ 'on_stderr': function(job.on_stderr, job),
          \ 'on_exit': function(job.on_exit, job),
          \ })
  elseif has('job') && has('channel')
    call job_start(l:cmd, {
          \ 'out_cb': function(job.out_cb, job),
          \ 'err_cb': function(job.err_cb, job),
          \ 'exit_cb': function(job.exit_cb, job),
          \ })
  else
    let l:tmp = tempname()
    echom system(printf(join(l:cmd).' '.&shellredir, l:tmp))
    let l:content = readfile(l:tmp)
    call job.callback(l:content)
    call delete(l:tmp)
  endif
endfunction

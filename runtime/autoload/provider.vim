" Common functions for providers

" Start the provider and perform a 'poll' request
"
" Returns a valid channel on success
" DEBUG: dump provider host stderr to $NVIM_PROVIDER_STDERR. With
" stderr_buffered the callback fires once, with the full output, when the
" host process exits or closes its stderr.
function! s:StderrDebugCollector(chan, data, event) abort
  if !empty($NVIM_PROVIDER_STDERR)
    call writefile(['=== provider host stderr (chan ' . a:chan . ') ==='] + a:data,
          \ $NVIM_PROVIDER_STDERR, 'a')
  endif
endfunction

function! provider#Poll(argv, orig_name, log_env, ...) abort
  let job = {'rpc': v:true, 'stderr_buffered': v:true}
  if !empty($NVIM_PROVIDER_STDERR)
    let job.on_stderr = function('s:StderrDebugCollector')
  endif
  if a:0
    let job = extend(job, a:1)
  endif
  try
    let channel_id = jobstart(a:argv, job)
    if channel_id > 0 && rpcrequest(channel_id, 'poll') ==# 'ok'
      return channel_id
    endif
  catch
    echomsg v:throwpoint
    echomsg v:exception
    for row in get(job, 'stderr', [])
      echomsg row
    endfor
  endtry
  throw remote#host#LoadErrorForHost(a:orig_name, a:log_env)
endfunction

" vim-secret-markers
" Maintainer:   TJ DeVries
" Version:      0.1

if exists("g:loaded_secret_markers")
  finish
endif

" Global variable definitions
let g:loaded_secret_markers = 1
let g:debug_secret_markers = 0
let g:secret_markers_file = '.' . expand('%') . '.secret_markers'

function FindMarkers()
    " Store line number
    let initial_pos = line('.')
    if g:debug_secret_markers
        echom 'Finding markers...'
    endif

    goto 1

    let ordered_markers = []
    let ordered_index = 0

    let start_lines = []
    let fold_number = 0
    while search('{{{', 'W') > 0
        let line_num = line('.')
        let line_content = getline(line_num)
        let line_dict = {}
        let line_dict[line_num] = line_content
        call add(start_lines, line_num)
        call add(ordered_markers, line_dict)

        let fold_number = fold_number + 1
    endwhile

    goto 1
    let end_lines = []
    while search('}}}', 'W') > 0
        let line_num = line('.')
        let line_content = getline(line_num)
        let line_dict = {}
        let line_dict[line_num] = line_content

        call add(end_lines, line_num)

        while keys(ordered_markers[ordered_index])[0] < line_num
            let ordered_index = ordered_index + 1

            if ordered_index == len(ordered_markers)
                break
            endif
        endwhile
        call insert(ordered_markers, line_dict, ordered_index)
    endwhile

    if g:debug_secret_markers
        echo start_lines
        echo end_lines
    endif

    goto 1

    " Connect the fold dictionaries
    let start_ind = 0
    let end_ind = 0
    let fold_combinations = {}
    let solved = 0
    while solved < fold_number
        if start_lines[start_ind] < end_lines[end_ind]
            let start_ind = start_ind + 1

            if start_ind >= len(start_lines)
                let fold_combinations[solved] = {}
                let fold_combinations[solved].start = start_lines[0]
                let fold_combinations[solved].end = end_lines[end_ind]
                let solved = solved + 1
            endif
        else
            let fold_combinations[solved] = {}
            let fold_combinations[solved].start = start_lines[start_ind - 1]
            let fold_combinations[solved].end = end_lines[end_ind]
            let solved = solved + 1

            unlet start_lines[start_ind - 1]
            let start_ind = 0
            let end_ind = end_ind + 1

        endif
    endwhile

    " initial_pos

    return [ fold_combinations, ordered_markers ]
endfunction

function RemoveMarkers()
    setlocal nofoldenable

    let res = FindMarkers()
    let fold_combinations = res[0]
    let ordered_markers = res[1]

    if g:debug_secret_markers
        echo fold_combinations
        echo ordered_markers
    endif

    " Send all output to the secret markers file
    execute 'redir! > ' g:secret_markers_file
    silent echo 'let g:secret_markers_dict = '
        \ webapi#json#encode(ordered_markers)

    " End sending output
    silent! redir END

    echo webapi#json#encode(fold_combinations)

    for line_dict in reverse(ordered_markers)
        let line_to_delete = keys(line_dict)[0]
        exec line_to_delete . ',' . line_to_delete . 'd'
    endfor
endfunction

function GetMarkersFromSecretFile()
    " This function sets the g:secret_markers_dict variable
    "   Format: [ {line_num: line_contents}, {line_num: line_contents}, ... ]
    setlocal nofoldenable

    exec "source " . g:secret_markers_file
    if g:debug_secret_markers
        echo g:secret_markers_dict
    endif
endfunction

function InsertMarkersFromDict()
    " This function will insert the lines back into the file
    "   It calls GetMarkersFromSecretFile first to set the
    "       g:secret_markers_dict
    "   Then inserts them into the file!
    call GetMarkersFromSecretFile()

    for line_dict in g:secret_markers_dict
        let line_num = keys(line_dict)[0]
        goto line_num
        " execute 'i' . line_dict[line_num] . '<CR>'
        " execute line_num . ',' . line_num . 's/^/' . line_dict[line_num] . '\\n/'
    endfor
endfunction

#!/usr/bin/env zsh

function choose_from_menu() {
    local prompt="$1" outvar="$2"
    shift
    shift
    local options=("$@") count=${#@} index=0 cur=0 # count=${#options[@]}
    local esc=$(echo -en "\e") # cache ESC as test doesn't allow esc codes
    printf "$prompt\n"
    while true
    do
        # list all options (option list is zero-based)
        index=0
        for o in "${options[@]}"
        do
            if [[ "$index" -eq "$cur" ]]
            then printf '%b\n' " > \e[7m$o\e[0m" # mark & highlight the current option
            else printf "   %s\n" $o
            fi
            index=$(( $index + 1 ))
        done
        read -s -n1 key 2>/dev/null || read -s -k 1 key # wait for user to key in arrows or ENTER
        # printf "key: %q" $key # for debugging (zsh)
        if [[ $key == $esc\[A ]] || [[ $key == 'A' ]] # up arrow
        then cur=$(( $cur - 1 ))
            [ "$cur" -lt 0 ] && cur=0
        elif [[ $key == $esc\[B ]] || [[ $key == 'B' ]] # down arrow
        then cur=$(( $cur + 1 ))
            [ "$cur" -ge $count ] && cur=$(( $count - 1 ))
        elif [[ $key == "q" ]] # exit with q
        then exit
        elif [[ $key == "" ]] || [[ $key == $'\n' ]] # nothing, i.e the read delimiter - ENTER
        then break
        fi
        printf '%b' "\e[${count}A" # go up to the beginning to re-render
    done

    # export the selection to the requested output variable
    printf -v $outvar "${options[@]:$cur:1}" # no direct array access because zsh is index offset 1
}

selections=("empty" "nothing")

# mapfile -t selections < <( cat ~/.ssh/config | grep -v "#" | grep "Host " | cut -d ' ' -f 2 ) # only supported in bash>v4.0
IFS_TEMP=$IFS
IFS=$'\n' selections=($(cat ~/.ssh/config | grep -v "#" | grep "Host " | cut -d ' ' -f 2))
IFS=$IFS_TEMP

choose_from_menu "Please select a ssh connection target:" selected_choice "${selections[@]}"
printf "connecting to $selected_choice ...\n"
ssh $selected_choice

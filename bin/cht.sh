#!/usr/bin/env bash
languages=`echo "nodejs python typescript rust" | tr ' ' '\n'`
core_utils=`echo "xargs find mv sed awk tmux" | tr ' ' '\n'`

selected=`printf "$languages\n$core_utils" | fzf`
read -p "query: " query

if printf "$languages" | grep -qs $selected; then
    curl cht.sh/$selected/`echo $query | tr ' ' '+'`
else
    curl cht.sh/$selected~`echo $query | tr ' ' '+'`
fi

while [ : ]; do sleep 1; done

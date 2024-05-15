#!/bin/bash 

export ELIXIR_ERL_OPTIONS="-kernel shell_history_path '/tmp/history_${1}'"
iex --sname ${1} --cookie "secret" -S mix
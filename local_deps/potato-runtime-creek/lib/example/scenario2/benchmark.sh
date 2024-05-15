#!/bin/bash


netsize=$1
echo "Netsize ${netsize}"

pkill -f tmux ; pkill -f erlang

tmux start-server

tmux new-session -d -s MySession -n Shell0 -d "bash"

for i in $(seq 1 $netsize)
do
  echo "Spawning slm${i}"
  sleep 0.5s
  echo "" >> "slm${i}@salontafel.txt"
  echo "${netsize}" >> "slm${i}@salontafel.txt"
  tmux new-window -t MySession:${i} -n "slm${i}" "iex --sname "slm${i}" --cookie \"secret\" -S mix run -e \"SoundLeveLMeter.run(:typea, :slm) ; Bench.write()\""
done

echo "Phone"
sleep 1s
  echo "" >> "phone@salontafel.txt"
  echo "${netsize}" >> "phone@salontafel.txt"
tmux new-window -t MySession:200 -n "phone" "iex --sname \"phone\" --cookie \"secret\" -S mix run -e \"SmartPhone.run() ; Process.sleep(5000) ; SmartPhone.enable_option() ; Bench.write()\""

echo "Vub"
sleep 1s
  echo "" >> "vub@salontafel.txt"
  echo "${netsize}" >> "vub@salontafel.txt"
tmux new-window -t MySession:201 -n "vub" "iex --sname \"vub\" --cookie \"secret\" -S mix run -e \"VUB.run() ; Bench.write()\""

echo "140 seconds left"
sleep 5s
echo "135 seconds left"
sleep 5s
echo "130 seconds left"
sleep 5s
echo "125 seconds left"
sleep 5s
echo "120 seconds left"
sleep 5s
echo "115 seconds left"
sleep 5s
echo "110 seconds left"
sleep 5s
echo "105 seconds left"
sleep 5s
echo "100 seconds left"
sleep 5s
echo "95 seconds left"
sleep 5s
echo "90 seconds left"
sleep 5s
echo "85 seconds left"
sleep 5s
echo "80 seconds left"
sleep 5s
echo "75 seconds left"
sleep 5s
echo "70 seconds left"
sleep 5s
echo "65 seconds left"
sleep 5s
echo "60 seconds left"
sleep 5s
echo "55 seconds left"
sleep 5s
echo "50 seconds left"
sleep 5s
echo "45 seconds left"
sleep 5s
echo "40 seconds left"
sleep 5s
echo "35 seconds left"
sleep 5s
echo "30 seconds left"
sleep 5s
echo "25 seconds left"
sleep 5s
echo "20 seconds left"
sleep 5s
echo "15 seconds left"
sleep 5s
echo "10 seconds left"
sleep 5s
echo "5 seconds left"
sleep 5s
echo "0 seconds left"
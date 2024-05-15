#!/bin/bash 

input=$1
src=$(basename ${input})
tex="${src}.tex"
touch "${tex}"
dir=$(dirname ${input})
cd $dir

echo '\documentclass{article}' >> ${tex}
echo '\usepackage[utf8]{inputenc}' >> ${tex}
echo '\usepackage[margin=0in]{geometry}' >> ${tex}
echo '\usepackage{minted}' >> ${tex}
echo '\begin{document}' >> ${tex}
echo '\begin{minted}[escapeinside=``]{elixir}' >> ${tex}

cat $src >> $tex

echo '\end{minted}' >> ${tex}
echo '\end{document}' >> ${tex}

latexmk -pdf -shell-escape -pdf  ${tex} 
latexmk -pdf -shell-escape -c  ${tex} 
rm -f ${tex}
pdftoppm -png "${tex}.pdf" "${tex}.png"

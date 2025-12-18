#!/bin/zsh

set -euo pipefail

help_text() {
	cat <<EOF
Usage: arxiv_tag.sh "TAG" file.pdf
Create a version of file.pdf with an arXiv-like tag on the first page
EOF
}

if [ $# -ne 2 ]; then
	help_text
	exit 1
fi

tag="${1}"
file="${2}"

# tmp folder
dir="$(mktemp -d -t custom_XXX)"

echo "Working in directory '${dir}'."


cp $file $dir/main.pdf

echo "${tag}" > $dir/tag.txt

# preparing the first page
cat <<'EOF' |  > $dir/main_firstPage.tex
\documentclass[tikz]{standalone}
\usepackage[
    colorlinks=true,
    linkcolor=arxivgrey,
]{hyperref}
\usepackage{graphicx,xcolor}
\definecolor{arxivgrey}{HTML}{808080} % actual colour is \definecolor{arxivgrey}{HTML}{737373}
\usepackage{fontspec}
\usepackage{tikz}
\usetikzlibrary{calc}
\setmainfont{Times New Roman}

\begin{document}
\begin{tikzpicture}[
    inner sep=0pt,
    anchor=north west
]
{
    \node[use as bounding box] (page) {\includegraphics[page=1,]{main.pdf}};
    \node[anchor=center] at ($(page.west)+(1.0,0)$) 
        {%
            \selectfont \huge%
            \rotatebox{90}{%
	    	% for url, use the following
		%\href{https://arxiv.org/abs/2508.12975v1}{\textcolor{arxivgrey}{arXiv:2508.12975v1  [q-bio.NC]  18 Aug 2025}}%
		\textcolor{arxivgrey}{\input{tag.txt}}%
	   }%
        };
}
\end{tikzpicture}
\end{document}
EOF

# putting everything together
cat <<'EOF' |  > $dir/main_merge.tex
\documentclass[a4paper]{article}
\usepackage{pdfpages}
    \pdfinclusioncopyfonts=1
\begin{document}
\includepdf[pages={1},]{main_firstPage.pdf}
\includepdf[pages={2-},]{main.pdf}
\end{document}
EOF

(cd $dir; latexmk -lualatex main_firstPage.tex)

(cd $dir; latexmk -pdflatex main_merge.tex)


cp $dir/main_merge.pdf tagged_${file}

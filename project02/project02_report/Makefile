filename=project_02_polo_riccardo

pdf:
	pdflatex ${filename}
	biber ${filename} || true
	pdflatex ${filename}
	pdflatex ${filename}

read:
	evince ${filename}.pdf &


clean:
	rm -f ${filename}.out ${filename}.log ${filename}.bbl ${filename}.blg ${filename}.aux ${filename}.ps ${filename}.dvi ${filename}.toc ${filename}.nav ${filename}.vrb ${filename}.snm ${filename}.bcf ${filename}.run.xml

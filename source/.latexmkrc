# Build with pdflatex: main.tex needs the pdfTeX-only \pdfgentounicode primitive.
$pdf_mode = 1;

# Final PDF lands in the project root; scratch files stay out of the way in source/build.
$out_dir = '..';
$aux_dir = 'build';

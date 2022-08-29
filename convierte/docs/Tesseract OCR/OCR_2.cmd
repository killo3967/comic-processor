rem @echo off
echo "ESCANEANDO COMIC:" %1
echo
echo
"C:\Program Files\Tesseract-OCR\tesseract.exe" %1 stdout --dpi 1200 --psm 6 --oem 1 -c preserve_interword_spaces=1,textord_min_xheight=6 tsv quiet 
rem -l eng+spa+fra
pause
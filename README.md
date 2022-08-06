DO NOT USE THIS SCRIPT YET. I AM STILL WORKING IN IT AND CHECKING THE RESULTS. (06/08/2022)

This script does the following:

- It cleans up and formats comic names according to the Anansi standard.
- It cleans up the images inside the comics by removing the images of the compilers and other ads. It does this using three methods, by image name, by comparing with saved images or by OCRing the text content of the image.
- It converts the images to the format you want (jpg,png,webp) and reprocesses the image, reducing it in size, recompressing it or whatever you want as configured.
- It does a scrapping of the comic on the comicvine web to download the information of the comic and to put to the file the name and correct year or the data that you want to put to them). This is the most complex part and requires several methods such as: extracting the series name from the directory or comic name, using ocr to get the year of the series or the ISBN and then searching for the year of the series. 
- Translation using DeepL of the comic or series name to test in other languages, as sometimes it doesn't find them in our language.
- Rename the comic file according to the data obtained from the scraping. 

TODO:
- Rename the image files according to the Anansi standard.
- Improve the configuration filter and put it in text mode instead of as a script.
- Allow to define profiles per directory to process.
- Move the processed comics depending on whether they have been scraped or the profile.
- Replace comictagger by own routines (in process). 
- Routine to access tesseract.dll to remove calls to the executable.
- Routine for accessing 7zip.dll to remove executable calls.
- Routine for accessing imagemagick dll's to remove calls to the executable.
- Routine to manage the comic metadata file.
- Creation of a database to store data received from comicvine, to use it as a cache.
- Scrapping routine from other websites, such as Tebeosfera. 
- Replace the linux shell script of image processiong with a similimar powershell script 

REQUIREMENTS:

You must have the following programs installed:
- Tesseract-OCR (https://github.com/tesseract-ocr/tesseract)
- Comictagger (https://github.com/comictagger/comictagger)
- ImageMagick (https://imagemagick.org/index.php)

You must have the following powershell module installed:
- Anglesharp POSH module (https://github.com/AngleSharp/AngleSharp)

You must have the following keys:
- Comicvine API key (https://comicvine.gamespot.com/api/)
- DeepL API key (https://www.deepl.com/docs-api/accessing-the-api/)

If you are interested in participating in the script development send me an email to killo3967@gmail.com

# Scan2Doc

Scan2Doc is a smartphone application to scan documents via smartphone camera and extract the text from the picture with ocr tesseract. After scanning and extracting the document page will be send and saved to Apache Solr Server via the HTTP-Server Node.JS.


## Features

- **Scan documents:** Let the camera scan the document, it automatically detects the document.
- **Edit document:** Edit your scanned document with cutting the size or use some filters like black and white or better light.
- **Extract the text from your document:** Extract the text in every language from your document with help from OCR Tesseract. After scanning you can copy and use it.
- **See all your documents:** See all your scanned documents with important data, saved in the database Apache Solr and delete one if needed.
- **See all pages:** See all your scanned pages in one screen and move the site in the wished position.
- **Edit already scanned document:** On the detailpage of a documentsite, you can scan the text again or replace the image from this site with a new one or delete it if you don't need it anymore.
- **Filter documents:** With the filteroptions you can filter your documents after scandate, scantime, document pages and languages.
- **Search documents:** Search your documents after filename or a special word, which can be in a scanned Text. The app will show you a part of the text with a highlighted background.


## Technologies Used

- **Flutter**
- **Apache Solr Server** for saving the documents
- **Node.JS Server** for communication with solr

## Getting Started

- Set up an Apache Solr Server on your computer and start it
- Go into the backend folder and type "npm start" for starting node.js server
- Install Debug Mode of the application with F5 when you have installed Flutter in your Editor or IDE

Now you can use the Scan2Doc document scanner! 
Have Fun! 📷

#### Made by Juliana Kühn 🌸

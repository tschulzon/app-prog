# Scan2Doc

Scan2Doc is a smartphone application designed to scan documents using your smartphone camera and extract text from images using OCR (Tesseract). Scanned and processed documents are saved to an Apache Solr Server via a Node.js HTTP server.


## Features

- **Document Scanning:** Automatically detect and scan documents using your smartphone camera.
- **Document Editing:** Adjust your scanned documents by cropping or applying filters like black-and-white or brightness enhancement.
- **Text Extraction:** Extract text from documents in various languages using OCR (Tesseract). The extracted text can be copied and reused.
- **Document Management:** View all scanned documents stored in the Apache Solr database, with options to delete specific documents if needed.
- **Page Management:** View all pages of a document in a single interface, reorder them as desired, and make adjustments.
- **Detailed Page Editing:** Rescan text, replace images, or delete individual pages directly from the document details view.
- **Advanced Filtering:** Filter documents based on scan date, scan time, page count, and language.
- **Search Functionality:** Search for documents by filename or keywords. Matches are displayed with highlighted text snippets.


## Technologies Used

- **Flutter:** Cross-platform app development framework
- **Apache Solr:** Powerful search and storage backend for document data
- **Node.js:** Backend server to facilitate communication between the app and Solr

## Getting Started

**Prerequisites**
1. Install and configure an Apache Solr Server on your system.
2. Ensure Node.js is installed on your machine.

**Setup Instructions**
1. Start the Apache Solr Server
2. Navigate to the backend folder of the project and start the Node.js server: **npm start**
3. Install the app in debug mode:
   - Open the project in your preferred IDE (e.g., Visual Studio Code or Android Studio) with Flutter installed
   - Run the app in debug mode (e.g., press F5 in VS Code)


Now you’re ready to use Scan2Doc for efficient document scanning and management! 
Have Fun! 📷

#### Made by Juliana Kühn 🌸

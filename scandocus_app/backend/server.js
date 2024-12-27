const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bodyParser = require('body-parser');
const moment = require('moment-timezone');
const axios = require('axios');
const PORT = 3000;

const app = express();

// Middleware for parsing JSON requests
app.use(bodyParser.json());
app.use(express.json());

// Destination directory for uploading the taken pictures
const UPLOADS_DIR = path.join(__dirname, 'uploads');

// Check if the directory exists
// If not, create a new one
if (!fs.existsSync(UPLOADS_DIR)) {
    fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Saving and filename configuration for the uploaded files
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, UPLOADS_DIR); // Set the destination directory for uploads
    },
    filename: (req, file, cb) => {
        // Create a unique filename using the current timestamp
        const uniqueName = `${Date.now()}-${file.originalname}`;
        cb(null, uniqueName);
    },
});

const upload = multer({ storage });

// Route for uploading the taken document pictures
app.post('/upload', upload.single('image'), (req, res) => {
    const filePath = `/uploads/${req.file.filename}`; // // Relative path to uploaded file
    res.status(200).send({ message: 'Bild hochgeladen', filePath });
});

// Serve uploaded files from the /uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Route for sending documents data to Apache Solr Server
app.post('/api/solr', async (req, res) => {
  const { fileName, images, docText, language, scanDate, siteNumber, id, scanTime } = req.body;

  // Safety check for the most important fields filename and doctext
  if (!fileName || !docText) {
      return res.status(400).json({ message: 'fileName und docText sind erforderlich!' });
  }

  try {
    // Solr-Update for creating a new Document Object with the metadata we get from the App
    const solrResponse = await axios.post(
      'http://localhost:8983/solr/scan2doc/update?commit=true',  // Solr-Core-URL
      [
        {
          id: id ?? `${fileName}-${Date.now()}`, // Create a unique ID if no ID was given
          fileName: fileName,
          docText: docText,
          language: language || 'unknown',  // Default Value is unknown
          scanDate: moment().tz('Europe/Berlin').format('YYYY-MM-DDTHH:mm:ss.SSS') + 'Z',
          scanTime: scanTime,
          images: images,
          siteNumber: siteNumber,
        }
      ],
      {
        headers: {
          'Content-Type': 'application/json',
        }
      }
    );

    res.status(200).json({
      message: 'Daten erfolgreich an Solr gesendet!',
      solrResponse: solrResponse.data,
    });
  } catch (error) {
    console.error('Fehler beim Senden an Solr:', error);
    res.status(500).json({
      message: 'Fehler beim Senden an Solr',
      error: error.message,
    });
  }
});

// Route for updating a specific pagenumber 
app.post('/api/updatepagenumber', async (req, res) => {
  const { id, siteNumber } = req.body;

  // Safety Check
  if (!id || !siteNumber) {
      return res.status(400).json({ message: 'id und siteNumber sind erforderlich!' });
  }

  try {
    // Getting the current documentpage with the ID from the app
    const solrResponse = await axios.get(
      `http://localhost:8983/solr/scan2doc/select?q=id:${id}&wt=json`
    );

    // Check if the page exists
    if (!solrResponse.data.response || solrResponse.data.response.numFound === 0) {
      return res.status(404).json({ message: 'Dokument nicht gefunden!' });
    }

    // Here we unescape the id for the correct format in solr
    const originalId = unescapeSolrQuery(id);

    const existingDocument = solrResponse.data.response.docs[0];

    // Only the page number in this page will be updatet, other data will be the same
    // like the data from the existing document
    const updatedDocument = {
      "id": originalId,
      "siteNumber": {"set": siteNumber},
      "filename": existingDocument.filename,
      "text": existingDocument.text,
      "image": existingDocument.image,
      "language": existingDocument.language,
    };

    // Update the document in solr
    const updateResponse = await axios.post(
      'http://localhost:8983/solr/scan2doc/update?commit=true',
      [updatedDocument],
      {
        headers: {
          'Content-Type': 'application/json',
        }
      }
    );

    res.status(200).json({
      message: 'Update-Daten erfolgreich an Solr gesendet!',
      solrResponse: updateResponse.data,
    });
  } catch (error) {
    console.error('Fehler beim Senden an Solr:', error);
    res.status(500).json({
      message: 'Fehler beim Senden an Solr',
      error: error.message,
    });
  }
});

// Method for converting the query for having a correct form to find the document in solr
function unescapeSolrQuery(escapedQuery) {
  return escapedQuery
    .replace(/\\ /g, ' ')
    .replace(/\\-/g, '-')
    .replace(/\\:/g, ':')
    .replace(/\\"/g, '"')
    .replace(/\\\\/g, '\\');
}

// Route for searching documents with used Filter information
app.get('/search', async (req, res) => {
  const { query, start = 0, rows = 50, startDate, endDate, startTime, endTime, startPage, endPage, language } = req.query;
  
  // Save used Filteroptions for the Solr-Query-Filter
  const filters = [];

  if (startDate && endDate) {
    filters.push(`scanDate:[${startDate} TO ${endDate}]`);
  }
  if (startTime && endTime) {
    filters.push(`scanTime:[${startTime} TO ${endTime}]`);
  }
  if (startPage && endPage) {
    filters.push(`siteNumber:[${startPage} TO ${endPage}]`);
  }
  if (language) {
    filters.push(`language:${language}`);
  }

  // Build the Solr-Filter-Query based on Filteroptions in Filter-Array
  const filterQuery = filters.map(fq => `&fq=${encodeURIComponent(fq)}`).join('');
  const solrQuery = query ? encodeURIComponent(query) : '*:*';

  // Get all Documents where the filter matches
  try {
    const solrResponse = await axios.get(
      `http://localhost:8983/solr/scan2doc/select?indent=true&q=${solrQuery}${filterQuery}&start=${start}&rows=${rows}&fl=id,fileName,scanDate,scanTime,siteNumber,language,images,docText`
    );
    res.json(solrResponse.data.response); // Nur relevante Daten senden
    console.log(solrResponse.data.response);
  } catch (error) {
    console.error('Error querying Solr:', error);
    res.status(500).send('Error querying Solr');
  }
});

// Route for getting Documents with the search term used in searchbar
// Find documents with a specific filename or word in the scanned text
app.get('/searchtext', async (req, res) => {
  const searchTerm = req.query.query;

  try {
    const solrResponse = await axios.get(`http://localhost:8983/solr/scan2doc/select`, {
      params: {
        q: `(fileName:${searchTerm} OR docText:${searchTerm})`,
        wt: 'json'
      }
    });

    console.log(solrResponse);

    res.json(solrResponse.data.response.docs);
  } catch (error) {
    console.error('Fehler bei der Solr-Abfrage:', error);
    res.status(500).send('Fehler bei der Abfrage an Solr');
  }
});

// Route for deleting more than one document with the same filename
// (when user deletes a whole document on homepage)
app.delete('/api/deleteDocsByFileName', async (req, res) => {
  const fileName = req.body.fileName;

  // Safety Check
  if (!fileName) {
      return res.status(400).json({ message: 'Dokumenten-Name ist erforderlich!' });
  }

  try {
    // Solr Update for deleting all documents with the same filename
    const solrUrl = 'http://localhost:8983/solr/scan2doc/update?commit=true';
    
    const deleteQuery = {
      "delete": {
        "query": `fileName:"${fileName}"`
      }
    };

    // Solr DELETE-Request
    const solrResponse = await axios.post(solrUrl, deleteQuery, {
      headers: { 'Content-Type': 'application/json' }
    });

    res.status(200).json({
      success: true,
      message: `Alle Dokumente mit dem Dateinamen ${fileName} wurden erfolgreich gelöscht!`,
    });
  } catch (error) {
    console.error('Fehler beim Löschen von Solr:', error);
    res.status(500).json({
      success: false,
      message: 'Fehler beim Löschen von Solr',
      error: error.message,
    });
  }
});

// Route for deleting a single Documentpage
app.delete('/api/deleteDocById', async (req, res) => {
  const id = req.body.id;
  const fileName = req.body.fileName;

  // Safety Check
  if (!id || !fileName) {
      return res.status(400).json({ message: 'Dokumenten-Id ist erforderlich!' });
  }

  try {
    // Solr-Update for deleting one documentpage with the specific id
    const solrUrl = 'http://localhost:8983/solr/scan2doc/update?commit=true';
    
    const deleteQuery = {
      "delete": {
        "query": `id:"${id}"`
      }
    };

    // Solr DELETE-Request
    const solrResponse = await axios.post(solrUrl, deleteQuery, {
      headers: { 'Content-Type': 'application/json' }
    });

    // Get all the other documents with the same filename and sort it by pagenumber in ascending order
    // because we need to update the pagenumbers from the other documentpages if one page is deleted
    const solrResponse2 = await axios.get(
      `http://localhost:8983/solr/scan2doc/select?q=fileName:"${fileName}"&sort=siteNumber asc`
    );

    const remainingDocs = solrResponse2.data.response.docs;

    // update the pagenumbers from the other documentpages, so the order is correct again
    const updatePayload = remainingDocs.map((doc, index) => ({
      id: doc.id,
      siteNumber: { set: index + 1 } // change pagenumber to index + 1
    }));

    // Solr Request
    await axios.post('http://localhost:8983/solr/scan2doc/update?commit=true', updatePayload, {
      headers: { 'Content-Type': 'application/json' }
    });

    res.status(200).json({
      success: true,
      message: `Das Dokument mit der ID ${id} wurde erfolgreich gelöscht!`,
    });
  } catch (error) {
    console.error('Fehler beim Löschen von Solr:', error);
    res.status(500).json({
      success: false,
      message: 'Fehler beim Löschen von Solr',
      error: error.message,
    });
  }
});

// start the node server as a middleware for communication with apache solr server
app.listen(PORT, () => {
    console.log(`Middleware läuft auf http://localhost:${PORT}`);
});

app.use((req, res, next) => {
next();
});

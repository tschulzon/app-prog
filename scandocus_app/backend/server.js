const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bodyParser = require('body-parser');
const moment = require('moment-timezone');
const axios = require('axios');
const PORT = 3000;

const app = express();

// Body-Parser Middleware (zum Verarbeiten von JSON)
app.use(bodyParser.json());

// Solr-URL
const SOLR_URL = 'http://localhost:8983/solr/scan2doc/update';
// const SOLR_URL = 'http://localhost:8983/solr/scan2doc/select?indent=true&q.op=OR&q=*%3A*&useParams=';

// Middleware für JSON-Parsing
app.use(express.json());

// Zielordner für hochgeladene Bilder
const UPLOADS_DIR = path.join(__dirname, 'uploads');

// Check, dass der Ordner existiert
if (!fs.existsSync(UPLOADS_DIR)) {
    fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Speicher- und Dateinamenkonfiguration
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, UPLOADS_DIR); // Zielordner
    },
    filename: (req, file, cb) => {
        // Eindeutigen Dateinamen erzeugen
        const uniqueName = `${Date.now()}-${file.originalname}`;
        cb(null, uniqueName);
    },
});

const upload = multer({ storage });

// Endpunkt zum Hochladen von Bildern
app.post('/upload', upload.single('image'), (req, res) => {
    const filePath = `/uploads/${req.file.filename}`; // Relativer Pfad
    res.status(200).send({ message: 'Bild hochgeladen', filePath });
});

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));


// POST-Route für /api/solr
app.post('/api/solr', async (req, res) => {
  const { fileName, images, docText, language, scanDate, siteNumber } = req.body;

  // Sicherheitsüberprüfung
  if (!fileName || !docText) {
      return res.status(400).json({ message: 'fileName und docText sind erforderlich!' });
  }

  try {
    // Solr-Update
    const solrResponse = await axios.post(
      'http://localhost:8983/solr/scan2doc/update?commit=true',  // Solr-Core-URL
      [
        {
          id: `${fileName}-${Date.now()}`, // Generiere eine eindeutige ID
          fileName: fileName,
          docText: docText,
          language: language || 'unknown',  // Falls keine Sprache übergeben wurde, 'unknown' verwenden
          scanDate: moment().tz('Europe/Berlin').format('YYYY-MM-DDTHH:mm:ss.SSS') + 'Z',
          images: images, // Das Base64-kodierte Bild
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

app.get('/search', async (req, res) => {
  const { query, start = 0, rows = 50 } = req.query; // Pagination und Suchparameter
  const solrQuery = query ? encodeURIComponent(query) : '*:*';

  try {
    const solrResponse = await axios.get(
      `http://localhost:8983/solr/scan2doc/select?indent=true&q=${solrQuery}&start=${start}&rows=${rows}&fl=id,fileName,scanDate,scanTime,siteNumber,language,images,docText`
    );
    res.json(solrResponse.data.response); // Nur relevante Daten senden
  } catch (error) {
    console.error('Error querying Solr:', error);
    res.status(500).send('Error querying Solr');
  }
});

// Route zum Löschen mehrere Dokumente mit gleichen Namen (quasi auf der Homepage)
app.delete('/api/deleteDocsByFileName', async (req, res) => {
  const fileName = req.body.fileName;

  console.log('Dokument-Filename erhalten:', fileName); // Für Debugging

  // Sicherheitsüberprüfung
  if (!fileName) {
      return res.status(400).json({ message: 'Dokumenten-Name ist erforderlich!' });
  }

  try {
    // Solr-Update
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

// Route zum Löschen mehrere Dokumente mit gleichen Namen (quasi auf der Homepage)
app.delete('/api/deleteDocById', async (req, res) => {
  const id = req.body.id;
  const fileName = req.body.fileName;

  console.log('Dokument-ID erhalten:', id); // Für Debugging
  console.log('Dokument-Name erhalten:', fileName); // Für Debugging


  // Sicherheitsüberprüfung
  if (!id || !fileName) {
      return res.status(400).json({ message: 'Dokumenten-Id ist erforderlich!' });
  }

  try {
    // Solr-Update
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

    // Hole alle Dokumente mit dem gleichen Dateinamen und sortiere nach Seitenzahl
    const solrResponse2 = await axios.get(
      `http://localhost:8983/solr/scan2doc/select?q=fileName:"${fileName}"&sort=siteNumber asc`
    );

    const remainingDocs = solrResponse2.data.response.docs;

    // Aktualisiere die Seitenzahlen der verbleibenden Dokumente
    const updatePayload = remainingDocs.map((doc, index) => ({
      id: doc.id,
      siteNumber: { set: index + 1 } // Setzt die Seitenzahl auf index + 1
    }));

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


// // API-Route für Solr-Suche
// app.post('/search', async (req, res) => {
//     try {
//         // App sendet Suchparameter
//         const { query, filters } = req.body;

//         // Solr-Query erstellen
//         const solrParams = {
//             q: query || '*:*',       // Standardabfrage, falls nichts übergeben
//             fq: filters || '',       // Filter (z. B. Datum oder Sprache)
//             wt: 'json',              // Antwortformat JSON
//         };

//         // Anfrage an Solr senden
//         const response = await axios.get("http://localhost:8983/solr/your_core/select", { params: solrParams });

//         // Relevante Daten zurückgeben
//         res.json({
//             success: true,
//             data: response.data.response.docs,
//         });
//     } catch (error) {
//         console.error('Fehler bei Solr-Abfrage:', error.message);
//         res.status(500).json({ success: false, message: 'Fehler bei Solr-Abfrage' });
//     }
// });

// Beispiel einer API-Route
app.get('/api/test', (req, res) => {
    res.json({ message: 'Verbindung erfolgreich!' });
  });

// Server starten
app.listen(PORT, () => {
    console.log(`Middleware läuft auf http://localhost:${PORT}`);
});

app.use((req, res, next) => {
console.log(`Request Method: ${req.method}, Request URL: ${req.url}`);
next();
});

const express = require('express');
const bodyParser = require('body-parser');
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

// app.post('/api/solr', (req, res) => {
//   console.log(req.body); // Logge die empfangenen Daten
//   res.json({ message: 'Anfrage empfangen!', data: req.body });
// });

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
          scanDate: scanDate || new Date().toISOString(), // Verwende das übergebene scanDate oder das aktuelle Datum
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

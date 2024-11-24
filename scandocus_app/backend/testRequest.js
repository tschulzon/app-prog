const axios = require('axios');

async function testPost() {
    try {
        const response = await axios.get('http://localhost:8983/solr/scan2doc/select', {
            query: 'language:Deutsch',
        });
        console.log('Antwort:', response.data);
    } catch (error) {
        console.error('Fehler:', error.message);
    }
}

testPost();

const FormData = require('form-data');
const https = require('https');
const http = require('http');

const UPLOAD_URL = process.env.IMAGE_UPLOAD_URL || 'https://rentpe.store/uploads/upload.php';
const UPLOAD_SECRET = process.env.IMAGE_UPLOAD_SECRET || '';

/**
 * Upload an image to the hosting server.
 * @param {Buffer} buffer - image data
 * @param {string} filename - original filename
 * @param {string} mimeType - e.g. image/jpeg
 * @param {string} folder - subfolder under images/ (e.g. "items/abc123" or "avatars/xyz")
 * @returns {Promise<string>} the generated filename (NOT the full URL)
 */
function uploadToHosting(buffer, filename, mimeType, folder) {
  return new Promise((resolve, reject) => {
    const form = new FormData();
    form.append('image', buffer, { filename, contentType: mimeType });
    form.append('folder', folder);

    const parsed = new URL(UPLOAD_URL);
    const transport = parsed.protocol === 'https:' ? https : http;

    const req = transport.request(
      {
        method: 'POST',
        hostname: parsed.hostname,
        port: parsed.port,
        path: parsed.pathname + parsed.search,
        headers: {
          ...form.getHeaders(),
          'X-Upload-Secret': UPLOAD_SECRET,
        },
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => {
          try {
            const json = JSON.parse(data);
            if (res.statusCode >= 200 && res.statusCode < 300 && json.filename) {
              resolve(json.filename);
            } else {
              reject(new Error(json.error || 'Image upload failed'));
            }
          } catch {
            reject(new Error('Invalid response from image server'));
          }
        });
      },
    );

    req.on('error', reject);
    form.pipe(req);
  });
}

module.exports = { uploadToHosting };

<?php
// =============================================================
// RentIt Image Upload API — place this at:
//   rentpe.store/uploads/upload.php
//
// Also create a writable folder:
//   rentpe.store/uploads/images/
//
// Set permissions: chmod 755 images/
// =============================================================

header('Content-Type: application/json');

// --- Configuration ---
$UPLOAD_SECRET = getenv('UPLOAD_SECRET') ?: 'CHANGE_THIS_TO_A_STRONG_SECRET';
$BASE_DIR      = __DIR__ . '/images/';
$MAX_SIZE      = 5 * 1024 * 1024; // 5 MB
$ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

// --- Auth check ---
$authHeader = $_SERVER['HTTP_X_UPLOAD_SECRET'] ?? '';
if ($authHeader !== $UPLOAD_SECRET) {
    http_response_code(403);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

// --- Only POST allowed ---
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// --- Must have a file ---
if (!isset($_FILES['image'])) {
    http_response_code(400);
    echo json_encode(['error' => 'No image file provided']);
    exit;
}

// --- Folder is required (e.g. "items/abc123" or "avatars/xyz789") ---
$folder = $_POST['folder'] ?? '';
if (empty($folder) || !preg_match('/^[a-zA-Z0-9_\-\/]+$/', $folder)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid or missing folder parameter']);
    exit;
}

$file = $_FILES['image'];

// --- Validate upload ---
if ($file['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['error' => 'Upload failed with code ' . $file['error']]);
    exit;
}

if ($file['size'] > $MAX_SIZE) {
    http_response_code(400);
    echo json_encode(['error' => 'File too large (max 5MB)']);
    exit;
}

$finfo = new finfo(FILEINFO_MIME_TYPE);
$mimeType = $finfo->file($file['tmp_name']);
if (!in_array($mimeType, $ALLOWED_TYPES, true)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid file type: ' . $mimeType]);
    exit;
}

// --- Ensure upload directory exists (images/{folder}/) ---
$uploadDir = $BASE_DIR . $folder . '/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

// --- Generate unique filename ---
$ext = match ($mimeType) {
    'image/jpeg' => '.jpg',
    'image/png'  => '.png',
    'image/gif'  => '.gif',
    'image/webp' => '.webp',
    default      => '.jpg',
};
$filename = bin2hex(random_bytes(16)) . $ext;
$destination = $uploadDir . $filename;

if (!move_uploaded_file($file['tmp_name'], $destination)) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to save file']);
    exit;
}

// --- Return just the filename (DB stores only the name) ---
echo json_encode(['filename' => $filename]);

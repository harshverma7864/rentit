// Category-specific spec schemas.
// Each category defines fields that get stored in the items.specs JSONB column.
// The frontend reads this schema from GET /api/items/categories to dynamically
// build creation forms and browse filters.
//
// Field types:
//   select   – dropdown / chip selector (options required)
//   text     – free-form text input
//   number   – numeric input
//   boolean  – toggle switch
//
// filterable: true  → field appears as a filter in browse / search

const CATEGORY_SPECS = {
  clothing: {
    name: 'Clothing',
    icon: '👗',
    subcategories: [
      { id: 'lehenga', name: 'Lehenga' },
      { id: 'saree', name: 'Saree' },
      { id: 'gown', name: 'Gown' },
      { id: 'sherwani', name: 'Sherwani' },
      { id: 'suit', name: 'Suit' },
      { id: 'kurta', name: 'Kurta' },
      { id: 'dress', name: 'Dress' },
      { id: 'bridal', name: 'Bridal' },
      { id: 'indo_western', name: 'Indo-Western' },
      { id: 'accessories', name: 'Accessories' },
    ],
    fields: [
      { key: 'size', label: 'Size', type: 'select', options: ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Free Size', 'Custom'], filterable: true },
      { key: 'color', label: 'Color', type: 'select', options: ['Red', 'Blue', 'Green', 'Pink', 'Gold', 'Silver', 'White', 'Black', 'Maroon', 'Beige', 'Yellow', 'Multi'], filterable: true },
      { key: 'fabric', label: 'Fabric', type: 'text', filterable: true },
      { key: 'occasion', label: 'Occasion', type: 'select', options: ['wedding', 'engagement', 'reception', 'party', 'festive', 'casual', 'formal', 'other'], filterable: true },
      { key: 'brand', label: 'Brand', type: 'text', filterable: false },
      { key: 'gender', label: 'Gender', type: 'select', options: ['women', 'men', 'unisex'], filterable: true },
      { key: 'alterationAvailable', label: 'Alteration Available', type: 'boolean', filterable: false },
    ],
  },
  electronics: {
    name: 'Electronics',
    icon: '📱',
    fields: [
      { key: 'brand', label: 'Brand', type: 'text', filterable: true },
      { key: 'model', label: 'Model', type: 'text', filterable: false },
      { key: 'warranty', label: 'Has Warranty', type: 'boolean', filterable: false },
      { key: 'powerSource', label: 'Power Source', type: 'select', options: ['battery', 'plug', 'both'], filterable: false },
    ],
  },
  vehicles: {
    name: 'Vehicles',
    icon: '🚗',
    fields: [
      { key: 'vehicleType', label: 'Vehicle Type', type: 'select', options: ['car', 'bike', 'scooter', 'bicycle', 'other'], filterable: true },
      { key: 'fuelType', label: 'Fuel Type', type: 'select', options: ['petrol', 'diesel', 'electric', 'cng', 'hybrid'], filterable: true },
      { key: 'transmission', label: 'Transmission', type: 'select', options: ['automatic', 'manual'], filterable: true },
      { key: 'seatingCapacity', label: 'Seating Capacity', type: 'number', filterable: false },
      { key: 'brand', label: 'Brand', type: 'text', filterable: true },
    ],
  },
  furniture: {
    name: 'Furniture',
    icon: '🪑',
    fields: [
      { key: 'material', label: 'Material', type: 'select', options: ['wood', 'metal', 'plastic', 'glass', 'fabric', 'leather'], filterable: true },
      { key: 'color', label: 'Color', type: 'text', filterable: true },
      { key: 'dimensions', label: 'Dimensions', type: 'text', filterable: false },
      { key: 'style', label: 'Style', type: 'select', options: ['modern', 'traditional', 'contemporary', 'minimalist', 'vintage'], filterable: true },
    ],
  },
  sports: {
    name: 'Sports',
    icon: '⚽',
    fields: [
      { key: 'sportType', label: 'Sport', type: 'select', options: ['cricket', 'football', 'badminton', 'tennis', 'gym', 'cycling', 'swimming', 'other'], filterable: true },
      { key: 'brand', label: 'Brand', type: 'text', filterable: true },
      { key: 'size', label: 'Size', type: 'text', filterable: false },
    ],
  },
  tools: {
    name: 'Tools',
    icon: '🔧',
    fields: [
      { key: 'toolType', label: 'Type', type: 'select', options: ['power_tool', 'hand_tool', 'garden', 'cleaning', 'other'], filterable: true },
      { key: 'powerSource', label: 'Power Source', type: 'select', options: ['electric', 'battery', 'manual', 'gas'], filterable: false },
      { key: 'brand', label: 'Brand', type: 'text', filterable: true },
    ],
  },
  books: {
    name: 'Books',
    icon: '📚',
    fields: [
      { key: 'genre', label: 'Genre', type: 'select', options: ['fiction', 'non_fiction', 'textbook', 'academic', 'comics', 'self_help', 'other'], filterable: true },
      { key: 'language', label: 'Language', type: 'select', options: ['english', 'hindi', 'other'], filterable: true },
      { key: 'author', label: 'Author', type: 'text', filterable: false },
    ],
  },
  party: {
    name: 'Party & Events',
    icon: '🎉',
    fields: [
      { key: 'eventType', label: 'Event Type', type: 'select', options: ['wedding', 'birthday', 'corporate', 'festival', 'other'], filterable: true },
      { key: 'itemType', label: 'Item Type', type: 'select', options: ['decoration', 'sound_system', 'lighting', 'tent', 'catering', 'other'], filterable: true },
      { key: 'capacity', label: 'Capacity / Count', type: 'text', filterable: false },
    ],
  },
  cameras: {
    name: 'Cameras',
    icon: '📷',
    fields: [
      { key: 'cameraType', label: 'Type', type: 'select', options: ['dslr', 'mirrorless', 'action', 'drone', 'instant', 'video', 'other'], filterable: true },
      { key: 'brand', label: 'Brand', type: 'text', filterable: true },
      { key: 'resolution', label: 'Resolution (MP)', type: 'text', filterable: false },
      { key: 'lensIncluded', label: 'Lens Included', type: 'boolean', filterable: false },
    ],
  },
  other: {
    name: 'Other',
    icon: '📦',
    fields: [],
  },
};

// Clothing subcategory IDs for quick lookup
const CLOTHING_SUBCATEGORY_IDS = (CATEGORY_SPECS.clothing.subcategories || []).map(s => s.id);

// Resolve a category string to its parent category ID.
// e.g. 'lehenga' → 'clothing', 'electronics' → 'electronics'
function resolveParentCategory(category) {
  if (CATEGORY_SPECS[category]) return category;
  if (CLOTHING_SUBCATEGORY_IDS.includes(category)) return 'clothing';
  return null;
}

module.exports = { CATEGORY_SPECS, CLOTHING_SUBCATEGORY_IDS, resolveParentCategory };

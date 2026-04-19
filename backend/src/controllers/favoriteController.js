const { Favorite, Item, User } = require('../models');

exports.toggleFavorite = async (req, res) => {
  try {
    const { itemId } = req.params;
    const userId = req.user.id;

    const existing = await Favorite.findOne({ where: { userId, itemId } });
    if (existing) {
      await existing.destroy();
      return res.json({ favorited: false });
    }

    // Verify item exists
    const item = await Item.findByPk(itemId);
    if (!item) return res.status(404).json({ error: 'Item not found' });

    await Favorite.create({ userId, itemId });
    res.json({ favorited: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getMyFavorites = async (req, res) => {
  try {
    const favorites = await Favorite.findAll({
      where: { userId: req.user.id },
      order: [['createdAt', 'DESC']],
      include: [{
        model: Item,
        as: 'item',
        include: [{ model: User, as: 'owner', attributes: ['id', 'name', 'avatar', 'rating', 'totalRatings'] }],
      }],
    });
    const items = favorites
      .filter(f => f.item)
      .map(f => f.item);
    res.json({ items });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.checkFavorite = async (req, res) => {
  try {
    const exists = await Favorite.findOne({
      where: { userId: req.user.id, itemId: req.params.itemId },
    });
    res.json({ favorited: !!exists });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

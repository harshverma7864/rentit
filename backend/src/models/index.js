const sequelize = require('../config/database');

const User = require('./User');
const Address = require('./Address');
const Item = require('./Item');
const Booking = require('./Booking');
const NegotiationEntry = require('./NegotiationEntry');
const Chat = require('./Chat');
const ChatParticipant = require('./ChatParticipant');
const Message = require('./Message');
const Notification = require('./Notification');
const Review = require('./Review');
const Subscription = require('./Subscription');
const ContactView = require('./ContactView');
const Wallet = require('./Wallet');
const WalletTransaction = require('./WalletTransaction');
const Dispute = require('./Dispute');
const Favorite = require('./Favorite');

// ---- User associations ----
User.hasMany(Address, { foreignKey: 'userId', as: 'addresses', onDelete: 'CASCADE' });
Address.belongsTo(User, { foreignKey: 'userId' });

User.hasMany(Item, { foreignKey: 'ownerId', as: 'items' });
Item.belongsTo(User, { foreignKey: 'ownerId', as: 'owner' });

User.hasOne(Subscription, { foreignKey: 'userId', as: 'subscription' });
Subscription.belongsTo(User, { foreignKey: 'userId' });

User.hasOne(Wallet, { foreignKey: 'userId', as: 'wallet' });
Wallet.belongsTo(User, { foreignKey: 'userId' });

// ---- Booking associations ----
Booking.belongsTo(Item, { foreignKey: 'itemId', as: 'item' });
Item.hasMany(Booking, { foreignKey: 'itemId', as: 'bookings' });

Booking.belongsTo(User, { foreignKey: 'renterId', as: 'renter' });
Booking.belongsTo(User, { foreignKey: 'ownerId', as: 'owner' });

Booking.hasMany(NegotiationEntry, { foreignKey: 'bookingId', as: 'negotiationHistory', onDelete: 'CASCADE' });
NegotiationEntry.belongsTo(Booking, { foreignKey: 'bookingId' });

// ---- Chat associations ----
Chat.belongsTo(Item, { foreignKey: 'itemId', as: 'item' });
Chat.belongsTo(Booking, { foreignKey: 'bookingId', as: 'booking' });

Chat.hasMany(ChatParticipant, { foreignKey: 'chatId', as: 'chatParticipants', onDelete: 'CASCADE' });
ChatParticipant.belongsTo(Chat, { foreignKey: 'chatId' });
ChatParticipant.belongsTo(User, { foreignKey: 'userId' });

Chat.hasMany(Message, { foreignKey: 'chatId', as: 'messages', onDelete: 'CASCADE' });
Message.belongsTo(Chat, { foreignKey: 'chatId' });
Message.belongsTo(User, { foreignKey: 'senderId', as: 'sender' });

// Many-to-many: Chat <-> User through ChatParticipant
Chat.belongsToMany(User, { through: ChatParticipant, foreignKey: 'chatId', otherKey: 'userId', as: 'participants' });
User.belongsToMany(Chat, { through: ChatParticipant, foreignKey: 'userId', otherKey: 'chatId', as: 'chats' });

// ---- Review associations ----
Review.belongsTo(User, { foreignKey: 'reviewerId', as: 'reviewer' });
Review.belongsTo(User, { foreignKey: 'revieweeId', as: 'reviewee' });
Review.belongsTo(Booking, { foreignKey: 'bookingId', as: 'booking' });
Review.belongsTo(Item, { foreignKey: 'itemId', as: 'item' });
Item.hasMany(Review, { foreignKey: 'itemId', as: 'reviews' });

// ---- Subscription / ContactView ----
Subscription.hasMany(ContactView, { foreignKey: 'subscriptionId', as: 'contactViews', onDelete: 'CASCADE' });
ContactView.belongsTo(Subscription, { foreignKey: 'subscriptionId' });
ContactView.belongsTo(User, { foreignKey: 'viewedUserId', as: 'viewedUser' });

// ---- Wallet associations ----
Wallet.hasMany(WalletTransaction, { foreignKey: 'walletId', as: 'transactions', onDelete: 'CASCADE' });
WalletTransaction.belongsTo(Wallet, { foreignKey: 'walletId' });
WalletTransaction.belongsTo(Booking, { foreignKey: 'bookingId', as: 'booking' });

// ---- Dispute associations ----
Dispute.belongsTo(Booking, { foreignKey: 'bookingId', as: 'booking' });
Dispute.belongsTo(User, { foreignKey: 'raisedById', as: 'raisedBy' });
Dispute.belongsTo(User, { foreignKey: 'againstUserId', as: 'againstUser' });

// ---- Notification ----
Notification.belongsTo(User, { foreignKey: 'userId' });

// ---- Favorite associations ----
User.hasMany(Favorite, { foreignKey: 'userId', as: 'favorites', onDelete: 'CASCADE' });
Favorite.belongsTo(User, { foreignKey: 'userId' });
Favorite.belongsTo(Item, { foreignKey: 'itemId', as: 'item' });
Item.hasMany(Favorite, { foreignKey: 'itemId', as: 'favorites', onDelete: 'CASCADE' });

module.exports = {
  sequelize,
  User,
  Address,
  Item,
  Booking,
  NegotiationEntry,
  Chat,
  ChatParticipant,
  Message,
  Notification,
  Review,
  Subscription,
  ContactView,
  Wallet,
  WalletTransaction,
  Dispute,
  Favorite,
};

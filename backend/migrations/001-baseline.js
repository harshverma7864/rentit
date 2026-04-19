'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // 1. users
    await queryInterface.createTable('users', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      name: {
        type: Sequelize.STRING,
        allowNull: true,
        defaultValue: '',
      },
      email: {
        type: Sequelize.STRING,
        allowNull: true,
        unique: true,
      },
      password: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      phone: {
        type: Sequelize.STRING,
        allowNull: false,
        unique: true,
      },
      firebase_uid: {
        type: Sequelize.STRING,
        allowNull: true,
        unique: true,
      },
      avatar: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      latitude: {
        type: Sequelize.DOUBLE,
        defaultValue: 0,
      },
      longitude: {
        type: Sequelize.DOUBLE,
        defaultValue: 0,
      },
      location_address: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      location_city: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      rating: {
        type: Sequelize.DOUBLE,
        defaultValue: 0,
      },
      total_ratings: {
        type: Sequelize.INTEGER,
        defaultValue: 0,
      },
      is_seller: {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
      },
      is_verified: {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    // 2. addresses (FK: user_id → users)
    await queryInterface.createTable('addresses', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      user_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      label: {
        type: Sequelize.STRING,
        defaultValue: 'Home',
      },
      address_line1: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      address_line2: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      street: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      city: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      state: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      pincode: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      landmark: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      latitude: {
        type: Sequelize.DOUBLE,
        defaultValue: 0,
      },
      longitude: {
        type: Sequelize.DOUBLE,
        defaultValue: 0,
      },
      is_default: {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    // 3. items (FK: owner_id → users)
    await queryInterface.createTable('items', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      owner_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE',
      },
      title: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      description: {
        type: Sequelize.TEXT,
        allowNull: false,
      },
      category: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      specs: {
        type: Sequelize.JSONB,
        defaultValue: {},
      },
      images: {
        type: Sequelize.ARRAY(Sequelize.TEXT),
        defaultValue: [],
      },
      price_per_hour: {
        type: Sequelize.DOUBLE,
        defaultValue: 0,
      },
      price_per_day: {
        type: Sequelize.DOUBLE,
        allowNull: false,
      },
      price_per_week: {
        type: Sequelize.DOUBLE,
        defaultValue: 0,
      },
      price: {
        type: Sequelize.DOUBLE,
        defaultValue: 0,
      },
      security_deposit: {
        type: Sequelize.DOUBLE,
        allowNull: false,
      },
      condition: {
        type: Sequelize.STRING,
        defaultValue: 'good',
      },
      latitude: {
        type: Sequelize.DOUBLE,
        defaultValue: 0,
      },
      longitude: {
        type: Sequelize.DOUBLE,
        defaultValue: 0,
      },
      location_address: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      location_address_line1: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      location_address_line2: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      location_street: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      location_city: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      location_state: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      location_pincode: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      location_landmark: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      quantity: {
        type: Sequelize.INTEGER,
        defaultValue: 1,
      },
      is_available: {
        type: Sequelize.BOOLEAN,
        defaultValue: true,
      },
      tags: {
        type: Sequelize.ARRAY(Sequelize.TEXT),
        defaultValue: [],
      },
      rules: {
        type: Sequelize.TEXT,
        defaultValue: '',
      },
      max_rental_days: {
        type: Sequelize.INTEGER,
        defaultValue: 30,
      },
      delivery_available: {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
      },
      delivery_fee: {
        type: Sequelize.DOUBLE,
        defaultValue: 0,
      },
      delivery_options: {
        type: Sequelize.ARRAY(Sequelize.TEXT),
        defaultValue: [],
      },
      is_boosted: {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
      },
      boost_expires_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      boost_priority: {
        type: Sequelize.INTEGER,
        defaultValue: 0,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    // Item indexes
    await queryInterface.addIndex('items', ['owner_id']);
    await queryInterface.addIndex('items', ['category']);
    await queryInterface.addIndex('items', ['is_available']);
    await queryInterface.addIndex('items', ['is_boosted']);
    await queryInterface.addIndex('items', ['latitude', 'longitude']);
    await queryInterface.addIndex('items', ['specs'], { using: 'gin' });

    // 4. bookings (FK: item_id → items, renter_id → users, owner_id → users)
    await queryInterface.createTable('bookings', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      item_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'items', key: 'id' },
        onUpdate: 'CASCADE',
      },
      renter_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE',
      },
      owner_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE',
      },
      start_date: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      end_date: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      quantity: {
        type: Sequelize.INTEGER,
        defaultValue: 1,
      },
      total_price: {
        type: Sequelize.DOUBLE,
        allowNull: false,
      },
      security_deposit: {
        type: Sequelize.DOUBLE,
        allowNull: false,
      },
      status: {
        type: Sequelize.STRING,
        defaultValue: 'pending',
      },
      delivery_option: {
        type: Sequelize.STRING,
        defaultValue: 'pickup',
      },
      delivery_status: {
        type: Sequelize.STRING,
        defaultValue: 'none',
      },
      estimated_delivery_time: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      scheduled_pickup_time: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      renter_note: {
        type: Sequelize.TEXT,
        defaultValue: '',
      },
      owner_note: {
        type: Sequelize.TEXT,
        defaultValue: '',
      },
      event_date: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      renter_size: {
        type: Sequelize.STRING,
        defaultValue: '',
      },
      size_details: {
        type: Sequelize.JSONB,
        defaultValue: {},
      },
      alteration_requests: {
        type: Sequelize.TEXT,
        defaultValue: '',
      },
      alteration_status: {
        type: Sequelize.STRING,
        defaultValue: 'none',
      },
      security_deposit_status: {
        type: Sequelize.STRING,
        defaultValue: 'unpaid',
      },
      return_status: {
        type: Sequelize.STRING,
        defaultValue: 'none',
      },
      return_note: {
        type: Sequelize.TEXT,
        defaultValue: '',
      },
      renter_rating: {
        type: Sequelize.INTEGER,
        allowNull: true,
      },
      owner_rating: {
        type: Sequelize.INTEGER,
        allowNull: true,
      },
      payment_status: {
        type: Sequelize.STRING,
        defaultValue: 'unpaid',
      },
      payment_date: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      proposed_price: {
        type: Sequelize.DOUBLE,
        allowNull: true,
      },
      negotiation_status: {
        type: Sequelize.STRING,
        defaultValue: 'none',
      },
      final_price: {
        type: Sequelize.DOUBLE,
        allowNull: true,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    // Booking indexes
    await queryInterface.addIndex('bookings', ['renter_id']);
    await queryInterface.addIndex('bookings', ['owner_id']);
    await queryInterface.addIndex('bookings', ['item_id']);
    await queryInterface.addIndex('bookings', ['status']);
    await queryInterface.addIndex('bookings', ['renter_id', 'status']);
    await queryInterface.addIndex('bookings', ['owner_id', 'status']);

    // 5. negotiation_entries (FK: booking_id → bookings)
    await queryInterface.createTable('negotiation_entries', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      booking_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'bookings', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      from_role: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      amount: {
        type: Sequelize.DOUBLE,
        allowNull: false,
      },
      message: {
        type: Sequelize.TEXT,
        defaultValue: '',
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    // 6. chats (FK: booking_id → bookings, item_id → items)
    await queryInterface.createTable('chats', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      booking_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: { model: 'bookings', key: 'id' },
        onUpdate: 'CASCADE',
      },
      item_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: { model: 'items', key: 'id' },
        onUpdate: 'CASCADE',
      },
      last_message: {
        type: Sequelize.TEXT,
        defaultValue: '',
      },
      last_message_at: {
        type: Sequelize.DATE,
        defaultValue: Sequelize.NOW,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    // Chat indexes
    await queryInterface.addIndex('chats', ['last_message_at']);

    // 7. chat_participants (FK: chat_id → chats, user_id → users)
    await queryInterface.createTable('chat_participants', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      chat_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'chats', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      user_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE',
      },
      last_read_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
    });

    // ChatParticipant indexes
    await queryInterface.addIndex('chat_participants', ['chat_id', 'user_id'], { unique: true });
    await queryInterface.addIndex('chat_participants', ['user_id']);

    // 8. messages (FK: chat_id → chats, sender_id → users)
    await queryInterface.createTable('messages', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      chat_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'chats', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      sender_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE',
      },
      text: {
        type: Sequelize.TEXT,
        allowNull: false,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    // Message indexes
    await queryInterface.addIndex('messages', ['chat_id', 'created_at']);
    await queryInterface.addIndex('messages', ['sender_id']);

    // 9. notifications (FK: user_id → users)
    await queryInterface.createTable('notifications', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      user_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE',
      },
      type: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      title: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      message: {
        type: Sequelize.TEXT,
        allowNull: false,
      },
      data: {
        type: Sequelize.JSONB,
        defaultValue: {},
      },
      is_read: {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    // Notification indexes
    await queryInterface.addIndex('notifications', ['user_id', 'is_read']);
    await queryInterface.addIndex('notifications', ['user_id', 'created_at']);

    // 10. reviews (FK: reviewer_id → users, reviewee_id → users, booking_id → bookings)
    await queryInterface.createTable('reviews', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      reviewer_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE',
      },
      reviewee_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE',
      },
      booking_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: { model: 'bookings', key: 'id' },
        onUpdate: 'CASCADE',
      },
      item_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: { model: 'items', key: 'id' },
        onUpdate: 'CASCADE',
      },
      rating: {
        type: Sequelize.INTEGER,
        allowNull: false,
      },
      comment: {
        type: Sequelize.TEXT,
        defaultValue: '',
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    // Review indexes
    await queryInterface.addIndex('reviews', ['reviewee_id', 'created_at']);
    await queryInterface.addIndex('reviews', ['booking_id', 'reviewer_id'], { unique: true });
    await queryInterface.addIndex('reviews', ['item_id', 'created_at']);

    // 11. subscriptions (FK: user_id → users)
    await queryInterface.createTable('subscriptions', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      user_id: { type: Sequelize.UUID, allowNull: false, unique: true, references: { model: 'users', key: 'id' }, onUpdate: 'CASCADE' },
      plan: { type: Sequelize.STRING, defaultValue: 'free' },
      free_listings_remaining: { type: Sequelize.INTEGER, defaultValue: 3 },
      free_contact_views_remaining: { type: Sequelize.INTEGER, defaultValue: 5 },
      expires_at: { type: Sequelize.DATE, allowNull: true },
      auto_renew: { type: Sequelize.BOOLEAN, defaultValue: false },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    });

    // 12. contact_views (FK: subscription_id → subscriptions, viewed_user_id → users)
    await queryInterface.createTable('contact_views', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      subscription_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'subscriptions', key: 'id' }, onDelete: 'CASCADE', onUpdate: 'CASCADE' },
      viewed_user_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'users', key: 'id' }, onUpdate: 'CASCADE' },
      created_at: { type: Sequelize.DATE, allowNull: false },
    });
    await queryInterface.addIndex('contact_views', ['subscription_id', 'viewed_user_id'], { unique: true });

    // 13. wallets (FK: user_id → users)
    await queryInterface.createTable('wallets', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      user_id: { type: Sequelize.UUID, allowNull: false, unique: true, references: { model: 'users', key: 'id' }, onUpdate: 'CASCADE' },
      balance: { type: Sequelize.DOUBLE, defaultValue: 0 },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    });

    // 14. wallet_transactions (FK: wallet_id → wallets, booking_id → bookings)
    await queryInterface.createTable('wallet_transactions', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      wallet_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'wallets', key: 'id' }, onDelete: 'CASCADE', onUpdate: 'CASCADE' },
      type: { type: Sequelize.STRING, allowNull: false },
      amount: { type: Sequelize.DOUBLE, allowNull: false },
      description: { type: Sequelize.TEXT, defaultValue: '' },
      booking_id: { type: Sequelize.UUID, allowNull: true, references: { model: 'bookings', key: 'id' }, onUpdate: 'CASCADE' },
      created_at: { type: Sequelize.DATE, allowNull: false },
    });
    await queryInterface.addIndex('wallet_transactions', ['wallet_id', 'created_at']);

    // 15. disputes (FK: booking_id → bookings, raised_by_id → users, against_user_id → users)
    await queryInterface.createTable('disputes', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      booking_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'bookings', key: 'id' }, onUpdate: 'CASCADE' },
      raised_by_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'users', key: 'id' }, onUpdate: 'CASCADE' },
      against_user_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'users', key: 'id' }, onUpdate: 'CASCADE' },
      reason: { type: Sequelize.STRING, allowNull: false },
      description: { type: Sequelize.TEXT, allowNull: false },
      images: { type: Sequelize.ARRAY(Sequelize.TEXT), defaultValue: [] },
      status: { type: Sequelize.STRING, defaultValue: 'open' },
      resolution: { type: Sequelize.TEXT, defaultValue: '' },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    });
    await queryInterface.addIndex('disputes', ['booking_id']);
    await queryInterface.addIndex('disputes', ['raised_by_id']);

    // 16. favorites (FK: user_id → users, item_id → items)
    await queryInterface.createTable('favorites', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      user_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'users', key: 'id' }, onDelete: 'CASCADE', onUpdate: 'CASCADE' },
      item_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'items', key: 'id' }, onDelete: 'CASCADE', onUpdate: 'CASCADE' },
      created_at: { type: Sequelize.DATE, allowNull: false },
    });
    await queryInterface.addIndex('favorites', ['user_id', 'item_id'], { unique: true });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('favorites');
    await queryInterface.dropTable('disputes');
    await queryInterface.dropTable('wallet_transactions');
    await queryInterface.dropTable('wallets');
    await queryInterface.dropTable('contact_views');
    await queryInterface.dropTable('subscriptions');
    await queryInterface.dropTable('reviews');
    await queryInterface.dropTable('notifications');
    await queryInterface.dropTable('messages');
    await queryInterface.dropTable('chat_participants');
    await queryInterface.dropTable('chats');
    await queryInterface.dropTable('negotiation_entries');
    await queryInterface.dropTable('bookings');
    await queryInterface.dropTable('items');
    await queryInterface.dropTable('addresses');
    await queryInterface.dropTable('users');
  },
};

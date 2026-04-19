'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // wallets: balance
    await queryInterface.changeColumn('wallets', 'balance', {
      type: Sequelize.DECIMAL(10, 2),
      defaultValue: 0,
    });

    // wallet_transactions: amount
    await queryInterface.changeColumn('wallet_transactions', 'amount', {
      type: Sequelize.DECIMAL(10, 2),
      allowNull: false,
    });

    // bookings: total_price, security_deposit, proposed_price, final_price
    await queryInterface.changeColumn('bookings', 'total_price', {
      type: Sequelize.DECIMAL(10, 2),
      allowNull: false,
    });
    await queryInterface.changeColumn('bookings', 'security_deposit', {
      type: Sequelize.DECIMAL(10, 2),
      allowNull: false,
    });
    await queryInterface.changeColumn('bookings', 'proposed_price', {
      type: Sequelize.DECIMAL(10, 2),
      allowNull: true,
    });
    await queryInterface.changeColumn('bookings', 'final_price', {
      type: Sequelize.DECIMAL(10, 2),
      allowNull: true,
    });

    // items: price_per_day, price_per_hour, price_per_week, price, security_deposit, delivery_fee
    await queryInterface.changeColumn('items', 'price_per_day', {
      type: Sequelize.DECIMAL(10, 2),
      allowNull: false,
    });
    await queryInterface.changeColumn('items', 'price_per_hour', {
      type: Sequelize.DECIMAL(10, 2),
      defaultValue: 0,
    });
    await queryInterface.changeColumn('items', 'price_per_week', {
      type: Sequelize.DECIMAL(10, 2),
      defaultValue: 0,
    });
    await queryInterface.changeColumn('items', 'price', {
      type: Sequelize.DECIMAL(10, 2),
      defaultValue: 0,
    });
    await queryInterface.changeColumn('items', 'security_deposit', {
      type: Sequelize.DECIMAL(10, 2),
      allowNull: false,
    });
    await queryInterface.changeColumn('items', 'delivery_fee', {
      type: Sequelize.DECIMAL(10, 2),
      defaultValue: 0,
    });

    // negotiation_entries: amount
    await queryInterface.changeColumn('negotiation_entries', 'amount', {
      type: Sequelize.DECIMAL(10, 2),
      allowNull: false,
    });
  },

  async down(queryInterface, Sequelize) {
    // wallets: balance
    await queryInterface.changeColumn('wallets', 'balance', {
      type: Sequelize.DOUBLE,
      defaultValue: 0,
    });

    // wallet_transactions: amount
    await queryInterface.changeColumn('wallet_transactions', 'amount', {
      type: Sequelize.DOUBLE,
      allowNull: false,
    });

    // bookings: total_price, security_deposit, proposed_price, final_price
    await queryInterface.changeColumn('bookings', 'total_price', {
      type: Sequelize.DOUBLE,
      allowNull: false,
    });
    await queryInterface.changeColumn('bookings', 'security_deposit', {
      type: Sequelize.DOUBLE,
      allowNull: false,
    });
    await queryInterface.changeColumn('bookings', 'proposed_price', {
      type: Sequelize.DOUBLE,
      allowNull: true,
    });
    await queryInterface.changeColumn('bookings', 'final_price', {
      type: Sequelize.DOUBLE,
      allowNull: true,
    });

    // items: price_per_day, price_per_hour, price_per_week, price, security_deposit, delivery_fee
    await queryInterface.changeColumn('items', 'price_per_day', {
      type: Sequelize.DOUBLE,
      allowNull: false,
    });
    await queryInterface.changeColumn('items', 'price_per_hour', {
      type: Sequelize.DOUBLE,
      defaultValue: 0,
    });
    await queryInterface.changeColumn('items', 'price_per_week', {
      type: Sequelize.DOUBLE,
      defaultValue: 0,
    });
    await queryInterface.changeColumn('items', 'price', {
      type: Sequelize.DOUBLE,
      defaultValue: 0,
    });
    await queryInterface.changeColumn('items', 'security_deposit', {
      type: Sequelize.DOUBLE,
      allowNull: false,
    });
    await queryInterface.changeColumn('items', 'delivery_fee', {
      type: Sequelize.DOUBLE,
      defaultValue: 0,
    });

    // negotiation_entries: amount
    await queryInterface.changeColumn('negotiation_entries', 'amount', {
      type: Sequelize.DOUBLE,
      allowNull: false,
    });
  },
};

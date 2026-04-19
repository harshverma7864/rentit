'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('items', 'approval_status', {
      type: Sequelize.STRING,
      defaultValue: 'pending_approval',
    });
    await queryInterface.addColumn('items', 'rejection_reason', {
      type: Sequelize.TEXT,
      defaultValue: '',
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('items', 'rejection_reason');
    await queryInterface.removeColumn('items', 'approval_status');
  },
};

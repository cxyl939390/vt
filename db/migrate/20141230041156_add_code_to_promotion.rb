class AddCodeToPromotion < ActiveRecord::Migration
  def change
    add_column :sdb_imodec_promotions, :code, :integer

  end
  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

  def connection
    @connection = Ecstore::Base.connection
  end
end
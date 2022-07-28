class CreateBadgrBadges < ActiveRecord::Migration[7.0]
  def change
    create_table :badgr_badges do |t|
      t.string :class_name
      t.string :name
      t.string :description
      t.string :image

      t.timestamps
    end
  end
end

class CreateBadgrTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :badgr_tokens do |t|
      t.string :token, null: false
      t.string :refresh_token, null: false
      t.datetime :expired_at, default: nil

      t.timestamps
    end
  end
end

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :google_uid
      t.text :token
      t.text :refresh_token
      t.string :image

      t.timestamps
    end
  end
end

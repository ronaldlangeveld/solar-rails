class CreateTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :tokens do |t|
      t.text :access
      t.text :refresh
      t.integer :expires

      t.timestamps
    end
  end
end

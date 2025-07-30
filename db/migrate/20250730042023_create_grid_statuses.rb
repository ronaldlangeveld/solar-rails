class CreateGridStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_statuses do |t|
      t.float :status
      t.float :battery_level
      t.float :production
      t.float :consumption

      t.timestamps
    end
  end
end

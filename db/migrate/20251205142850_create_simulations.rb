class CreateSimulations < ActiveRecord::Migration[7.1]
  def change
    create_table :simulations do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :generation
      t.integer :rows
      t.integer :cols
      t.jsonb :grid
      t.string :status

      t.timestamps
    end
  end
end

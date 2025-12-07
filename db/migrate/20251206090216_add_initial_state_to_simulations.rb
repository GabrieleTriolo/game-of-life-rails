class AddInitialStateToSimulations < ActiveRecord::Migration[7.1]
  def change
    add_column :simulations, :grid_initial, :jsonb
    add_column :simulations, :generation_initial, :integer
  end
end

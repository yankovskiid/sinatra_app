class AddEmails < ActiveRecord::Migration[5.1]
  def change
    add_column :models, :email, :string
  end
end

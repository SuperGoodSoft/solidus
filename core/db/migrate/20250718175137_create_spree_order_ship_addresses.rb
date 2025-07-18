class CreateSpreeOrderShipAddresses < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_order_ship_addresses do |t|
      t.string "firstname", index: true
      t.string "lastname", index: true
      t.string "address1"
      t.string "address2"
      t.string "city"
      t.string "zipcode"
      t.string "phone"
      t.string "state_name"
      t.string "alternative_phone"
      t.string "company"
      t.string "vat_id"
      t.string "email"
      t.integer "reverse_charge_status",
        default: 0,
        null: false,
        comment: "Enum values: 0 = disabled, 1 = enabled, 2 = not_validated"
      t.references "state", index: true
      t.references "country", index: true
      t.string "name", index: true
      t.timestamps
    end
  end
end

class LineItem
  attr_reader :product_id, :quantity, :unit_price_cents

  # unit_price_cents is a snapshot of the product's price at the time the item
  # was added, so the order's total stays correct even if the catalog changes.
  def initialize(product_id:, quantity:, unit_price_cents:)
    @product_id = product_id
    @quantity = quantity
    @unit_price_cents = unit_price_cents
  end

  def subtotal_cents
    quantity * unit_price_cents
  end
end

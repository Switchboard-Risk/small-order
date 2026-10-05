require_relative "product"

# Maps Product domain objects to/from the `products` table.
class ProductRepository
  def initialize(db)
    @db = db
  end

  def find(id)
    row = @db.get_first_row("SELECT * FROM products WHERE id = ?", [id])
    row && to_product(row)
  end

  def find_by_sku(sku)
    row = @db.get_first_row("SELECT * FROM products WHERE sku = ?", [sku])
    row && to_product(row)
  end

  def all
    @db.execute("SELECT * FROM products ORDER BY sku").map { |row| to_product(row) }
  end

  # A saved product (has an id) is UPDATEd by id. A new product is inserted, or
  # updates the existing row with the same sku, and gets its id assigned.
  def save(product)
    if product.id
      @db.execute(<<~SQL, params(product).merge("id" => product.id))
        UPDATE products
        SET sku = :sku, name = :name, price_cents = :price_cents,
            stock_quantity = :stock_quantity, reserved_quantity = :reserved_quantity
        WHERE id = :id
      SQL
    else
      @db.execute(<<~SQL, params(product))
        INSERT INTO products (sku, name, price_cents, stock_quantity, reserved_quantity)
        VALUES (:sku, :name, :price_cents, :stock_quantity, :reserved_quantity)
        ON CONFLICT(sku) DO UPDATE SET
          name              = excluded.name,
          price_cents       = excluded.price_cents,
          stock_quantity    = excluded.stock_quantity,
          reserved_quantity = excluded.reserved_quantity
      SQL
      id = @db.get_first_value("SELECT id FROM products WHERE sku = ?", [product.sku])
      product.instance_variable_set(:@id, id)
    end
    product
  end

  private

  def params(product)
    {
      "sku" => product.sku,
      "name" => product.name,
      "price_cents" => product.price_cents,
      "stock_quantity" => product.stock_quantity,
      "reserved_quantity" => product.reserved_quantity
    }
  end

  def to_product(row)
    Product.new(
      id: row["id"],
      sku: row["sku"],
      name: row["name"],
      price_cents: row["price_cents"],
      stock_quantity: row["stock_quantity"],
      reserved_quantity: row["reserved_quantity"]
    )
  end
end

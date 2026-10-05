require "spec_helper"

RSpec.describe ProductRepository do
  let(:repo) { described_class.new(fresh_db) }

  it "round-trips a product through the database" do
    repo.save(Product.new(sku: "WIDGET-1", name: "Widget", price_cents: 999,
                          stock_quantity: 10, reserved_quantity: 2))

    found = repo.find_by_sku("WIDGET-1")
    expect(found.name).to eq("Widget")
    expect(found.price_cents).to eq(999)
    expect(found.stock_quantity).to eq(10)
    expect(found.reserved_quantity).to eq(2)
  end

  it "assigns an integer id when saving a new product" do
    product = repo.save(Product.new(sku: "WIDGET-1", name: "Widget", price_cents: 999))
    expect(product.id).to be_a(Integer)
    expect(repo.find(product.id).sku).to eq("WIDGET-1")
  end

  it "returns nil for an unknown id or sku" do
    expect(repo.find(999)).to be_nil
    expect(repo.find_by_sku("NOPE")).to be_nil
  end

  it "updates a saved product by id, including a sku change" do
    product = repo.save(Product.new(sku: "OLD-1", name: "Old", price_cents: 100))
    renamed = Product.new(id: product.id, sku: "NEW-1", name: "New", price_cents: 100)
    repo.save(renamed)

    expect(repo.all.length).to eq(1)
    expect(repo.find(product.id).sku).to eq("NEW-1")
    expect(repo.find_by_sku("OLD-1")).to be_nil
  end

  it "keeps the same id when a sku is saved again" do
    first = repo.save(Product.new(sku: "GIZMO-3", name: "Gizmo", price_cents: 499))
    second = repo.save(Product.new(sku: "GIZMO-3", name: "Gizmo v2", price_cents: 599))
    expect(second.id).to eq(first.id)
  end

  it "upserts on save by sku" do
    repo.save(Product.new(sku: "GIZMO-3", name: "Gizmo", price_cents: 499, stock_quantity: 3))
    repo.save(Product.new(sku: "GIZMO-3", name: "Gizmo v2", price_cents: 599, stock_quantity: 5))

    expect(repo.all.length).to eq(1)
    expect(repo.find_by_sku("GIZMO-3").name).to eq("Gizmo v2")
    expect(repo.find_by_sku("GIZMO-3").stock_quantity).to eq(5)
  end

  it "lists all products ordered by sku" do
    repo.save(Product.new(sku: "B", name: "B", price_cents: 1, stock_quantity: 1))
    repo.save(Product.new(sku: "A", name: "A", price_cents: 1, stock_quantity: 1))

    expect(repo.all.map(&:sku)).to eq(%w[A B])
  end
end

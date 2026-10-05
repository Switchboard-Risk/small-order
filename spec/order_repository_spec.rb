require "spec_helper"

RSpec.describe OrderRepository do
  let(:db) { fresh_db }
  let(:repo) { described_class.new(db) }
  let(:products) { ProductRepository.new(db) }
  let!(:widget) { products.save(Product.new(sku: "WIDGET-1", name: "Widget", price_cents: 999, stock_quantity: 10)) }
  let!(:gadget) { products.save(Product.new(sku: "GADGET-7", name: "Gadget", price_cents: 1950, stock_quantity: 8)) }

  it "assigns an id when saving a new order" do
    order = repo.save(Order.new)
    expect(order.id).to be_a(Integer)
  end

  it "round-trips an order with line items and audit log" do
    order = Order.new(line_items: [
      LineItem.new(product_id: widget.id, quantity: 2, unit_price_cents: 999),
      LineItem.new(product_id: gadget.id, quantity: 1, unit_price_cents: 1950)
    ])
    order.submit!
    order.pay!
    repo.save(order)

    found = repo.find(order.id)
    expect(found.state).to eq(:paid)
    expect(found.paid_at).to be_a(Time)
    expect(found.line_items.map(&:product_id)).to eq([widget.id, gadget.id])
    expect(found.total).to eq(2 * 999 + 1950)
    expect(found.audit_log.map { |e| e[:to] }).to eq(%i[submitted paid])
    expect(found.audit_log.first[:at]).to be_a(Time)
  end

  it "rewrites child rows on update rather than duplicating them" do
    order = repo.save(Order.new(line_items: [
      LineItem.new(product_id: widget.id, quantity: 1, unit_price_cents: 999)
    ]))
    order.submit!
    repo.save(order)

    found = repo.find(order.id)
    expect(found.line_items.length).to eq(1)
    expect(found.audit_log.length).to eq(1)
  end

  it "rejects a line item that references a missing product" do
    order = Order.new(line_items: [LineItem.new(product_id: 999, quantity: 1, unit_price_cents: 1)])
    expect { repo.save(order) }.to raise_error(SQLite3::ConstraintException)
  end

  it "returns nil for an unknown id" do
    expect(repo.find(999)).to be_nil
  end
end

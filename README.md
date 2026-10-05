# tiny-orders

A small order app in pure Ruby: an order **state machine** backed by a **product
catalog with inventory** and **SQLite persistence**. Clone it, push orders
through their lifecycle, and watch stock get reserved and drawn down.

## Requirements

Running the app is optional — see [Before the interview](#before-the-interview).
If you'd like to run it, you need:

- Ruby 3.2 or newer
- Bundler

If you don't have Ruby, the easiest way to install it on macOS or Linux is via
[rbenv](https://github.com/rbenv/rbenv) or [asdf](https://asdf-vm.com/):

```
rbenv install 3.3.6     # or: asdf install ruby 3.3.6
gem install bundler
```

Any Ruby from 3.2 up works. The `sqlite3` gem ships precompiled for macOS and
Linux, so `bundle install` needs no compiler or system SQLite.

## Setup

```
bundle install
```

## Quick start

```
bin/orders catalog              # see products, prices, and stock
bin/orders create               # -> Created order #1 (state: draft)
bin/orders add 1 WIDGET-1 2     # add 2x WIDGET-1 (price snapshotted onto the order)
bin/orders submit 1             # reserves 2 units of WIDGET-1
bin/orders pay 1
bin/orders fulfill 1            # permanently decrements stock
bin/orders show 1               # full detail + audit log
bin/orders list                 # all orders
```

Orders and stock live in a SQLite file at `db/orders.sqlite3` and persist between
runs. The repo ships with a populated catalog and some order history.

## How it behaves like a real order app

- **Catalog** — every line item is backed by a real `Product` (id, sku, name, price,
  stock). `id` is the primary key; `sku` is a unique code you use on the CLI. You can't order a SKU that doesn't exist.
- **Inventory that can't oversell** — `submit!` reserves stock all-or-nothing. If
  any product is short, the whole submit fails with `InsufficientStock` and the
  order stays in `draft`. Fulfilling an order turns its reservations into a
  permanent stock decrement.
- **Money as integer cents** — prices are stored as cents and snapshotted onto the
  line item at add-time, so an order's total stays correct even if the catalog
  price later changes.

```
bin/orders demo                 # self-contained end-to-end run (in-memory DB)
```

The demo builds a throwaway in-memory catalog, runs an order
`draft → submitted → paid → fulfilled`, and prints the catalog before and after so
you can see stock drop.

## All commands

```
bin/orders catalog           List products with price and stock
bin/orders create            Create a new draft order, print its id
bin/orders add ID SKU QTY    Add QTY of SKU to draft order ID
bin/orders submit ID         Submit order ID (reserves stock)
bin/orders pay ID            Mark order ID paid
bin/orders fulfill ID        Fulfill order ID (decrements stock)
bin/orders cancel ID         Cancel order ID
bin/orders show ID           Show one order in detail
bin/orders list              List all orders
bin/orders demo              Self-contained end-to-end run (in-memory)
bin/orders help              Show this message
```

## Run the tests

```
bundle exec rspec
```

## What's in here

Domain (plain Ruby, no SQL):

- `lib/order.rb` — the state machine. Legal transitions: `draft → submitted → paid
  → fulfilled`, plus `draft → canceled` and `submitted → canceled`. Every
  transition is recorded in `audit_log`.
- `lib/product.rb` — a catalog product that owns its inventory invariants
  (`reserve!`, `release!`, `ship!`, `available`); refuses to oversell.
- `lib/line_item.rb` — a single row in an order (product_id, quantity, unit price in cents).
- `lib/illegal_transition.rb` / `lib/insufficient_stock.rb` — the errors raised when
  a state transition or a reservation isn't allowed.

Persistence & coordination:

- `lib/db.rb` — SQLite connection + schema bootstrap.
- `lib/product_repository.rb` / `lib/order_repository.rb` — map domain objects ↔ rows.
- `lib/order_service.rb` — runs each stock-touching transition (submit/cancel/fulfill)
  and its persistence inside one SQLite transaction, so the order and the affected
  products commit together or not at all.

## Before the interview

This repo is the codebase we'll work in during your interview. The interview is a
practical session: we'll work through the app together and see how you work and
think through problems. We'll hand you the tasks when we meet, so please spend some
time with the code beforehand so you already know how it works and where things live.

**You don't need to know Ruby.** The codebase is small and plain, and we care about
how you navigate an unfamiliar codebase, make decisions, and verify your work — not
about language trivia.

**You don't need to run it.** This isn't a test of installing Ruby. We won't be
running the command line during the interview, and you won't need to either. If
`bundle install` works on your machine, great — running the app and the specs is one
way to see how it behaves. If it doesn't, don't spend time on it; reading the code is
enough. The command line is a tool you can use if it helps, not a requirement, now or
during the interview.

**Use your normal workflow.** We want to see how you actually work, including your
AI tools. Use whatever editor, terminal, and assistants you'd normally reach for, both
while getting familiar and during the interview itself.

A few ways to get oriented:

- Read through `lib/` — it's small. Start with `lib/order.rb` and
  `lib/order_service.rb`.
- Skim the specs in `spec/` to see what's covered.
- If you have Ruby: run `bundle install`, then `bin/orders catalog`,
  `bin/orders list`, and `bin/orders show ID` to see what's already in the store,
  and walk an order through `create`, `add`, `submit`, `pay`, and `fulfill`.

There's nothing to submit ahead of time.

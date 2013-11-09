require 'stripe'

module Pubs
  module Concerns
    module Customer

      def customer
        unless self.meta['stripe_customer_id'].nil?
          Stripe::Customer.retrieve(self.meta['stripe_customer_id'])
        end
      end

      def add_product product
        if _ii = product.invoices.first
          amount = product.price * 100 / ((_ii['created_at'] + 1.month) - Time.now) / 60 / 60 / 24
        else
          amount = product.price * 100
        end
        ii = Stripe::InvoiceItem.create(
        :customer => customer,
        :amount => amount ,
        :currency => "gbp",
        :description => "#{product.class.name}: #{product.name} - #{Time.now}"
        )
        product.invoices << {"id" => ii.id, "created_at" => Time.now}
        product.save!
      end

      def remove_product product
        if _ii = product.invoices.last
          ii = Stripe::InvoiceItem.retrieve(_ii["id"])
          ii.amount = ((product.price * 100) * (Time.now - _ii["created_at"]) / 60 / 60 / 24).to_i
          ii.description = "#{ii.description} | #{Time.now}"
          ii.save
        end
      end

      def update_product product
        remove_product product
        add_product product
      end

      def create_customer! token, plan
        unless self.meta['stripe_customer_id']

          # Create a Customer
          customer = Stripe::Customer.create(
          :card => token,
          :plan => plan,
          :email => self.email
          )

          self.meta['stripe_customer_id'] = customer.id
          if self.save
            self.meta['stripe_customer_id']
          else
            customer.delete
          end
        else
          ap self.meta['stripe_customer_id']
          customer = Stripe::Customer.retrieve(self.meta['stripe_customer_id'])
          customer.update_subscription(card: token, plan: plan)
          self.meta['stripe_customer_id']
        end
      end

    end
  end
end
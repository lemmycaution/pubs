require 'mail'
require 'erb'
require 'pubs/endpoints/helpers/template'
module Pubs
  class Mailer
    
    class << self
      
      include Pubs::Endpoints::Helpers::Template::Helpers
      
      def deliver from, to, subject, body
        mail = Mail.new do
          from    from
          to      to
          subject subject
          body    body
        end
        unless Pubs.env.production?
          mail.delivery_method :sendmail 
        else
          mail.delivery_method :smtp, { 
            :address   => "smtp.sendgrid.net",
            :port      => 587,
            :domain    => "pubs.io",
            :user_name => ENV['SENDGRID_USERNAME'],
            :password  => ENV['SENDGRID_PASSWORD'],
            :authentication => 'plain',
            :enable_starttls_auto => true 
          }
        end
        puts mail if Pubs.env.development?
        mail.deliver
      end
      
      private
      
      def find_template view
        ERB.new(File.read("#{Pubs.root}/app/views/mails/#{view}.erb")).result(binding)
      end
    end
  end
end
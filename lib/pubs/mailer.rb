require 'mail'
require 'erb'
require 'pubs/endpoints/helpers/template'
module Pubs
  class Mailer

    class << self

      include Pubs::Endpoints::Helpers::Template::Helpers

      def deliver from, to, subject, body, headers = {}
        mail = Mail.new do
          from    from
          to      to
          subject subject
        end

        body = { "text" => body } if body.is_a?(String)

        text_part = Mail::Part.new do
          body body['text']
        end
        mail.text_part = text_part

        if body['html']
          html_part = Mail::Part.new do
            content_type 'text/html; charset=UTF-8'
            body body['html']
          end
          mail.html_part = html_part
        end


        headers.each{ |k,v| mail.header[k]=v }

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
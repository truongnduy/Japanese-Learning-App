# frozen_string_literal: true

# Fix compatibility between json gem 3.x and ActiveSupport::JSON.decode on Ruby 4.0
module ActiveSupport
  module JSON
    class << self
      def decode(json, options = {})
        data = if options.nil? || options.empty?
                 ::JSON.parse(json)
               else
                 ::JSON.parse(json, **options)
               end

        if ActiveSupport.parse_json_times
          convert_dates_from(data)
        else
          data
        end
      end
    end
  end
end

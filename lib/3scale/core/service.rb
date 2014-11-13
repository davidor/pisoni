module ThreeScale
  module Core
    class Service
      include Storable

      ATTRIBUTES = %w(provider_key id backend_version referrer_filters_required
        user_registration_required default_user_plan_id default_user_plan_name
        version default_service)

      attr_accessor(*(ATTRIBUTES.map { |attr| attr.to_sym }))

      class << self

        def load_by_id(service_id)
          response = Core.faraday.get "services/#{service_id}"

          if response.status == 200
            service = JSON.parse(response.body)

            instantiate_from_api_data(service)
          elsif response.status == 404
            nil
          else
            raise "Error getting a Service: #{service_id}, code: #{response.status},
              body: #{response.body.inspect}"
          end
        end

        def delete_by_id!(service_id, options = {})
          response = Core.faraday.delete "services/#{service_id}", options

          if response.status != 200
            raise ServiceIsDefaultService, service_id if response.status == 400
            raise "Error deleting a Service: #{service_id}, options: #{options.inspect},
              response code: #{response.status}, response body: #{response.body.inspect}"
          end
          return true
        end

        def save!(attributes)
          update_backend(:put, attributes, attributes[:id])
        end

        def change_provider_key!(old_key, new_key)
          response = Core.faraday.put "services/change_provider_key/#{old_key}",
            {new_key: new_key}.to_json

          status = response.status
          status == 200 or handle_change_provider_key_failure status, response,
                                                              old_key, new_key
        end

        # Public: Sets a service as default.
        #
        # service_id ID of the Service to set as default
        #
        # Returns the changed Service object.
        def make_default(service_id)
          update_backend :put, {default_service: true}, service_id
        end

        private

        def provider_key_exception(error, old_key, new_key)
          case error
          when /does not exist/
            ProviderKeyNotFound.new old_key
          when /already exists/
            ProviderKeyExists.new new_key
          when /are not valid/
            InvalidProviderKeys.new
          else
            nil
          end
        end

        def handle_change_provider_key_failure(status, response, old_key, new_key)
          ex = if status == 400
                 json_error = json(response)['error']
                 provider_key_exception(json_error, old_key, new_key) if json_error
               end

          raise ex || "Error changing a provider key, old_key: #{old_key.inspect}" \
            ", new_key: #{new_key.inspect}, response code: #{response.status}" \
            ", response body: #{response.body.inspect}"
        end

        def update_backend(method, attributes, service_id = '')
          response = Core.faraday.send method, "services/#{service_id}", {service: attributes}.to_json

          expected_status = method == :post ? 201 : 200
          handle_update_errors response, expected_status, attributes

          instantiate_from_api_data json(response)['service']
        end

        def handle_update_errors(response, expected_status, attributes)
          if response.status != expected_status
            if response.status == 400 &&
              (json = json(response))['error'] =~ /require a default user plan/
              raise ServiceRequiresDefaultUserPlan
            else
              raise "Error saving a Service, attributes: #{attributes.inspect},
                response code: #{response.status}, response body: #{response.body.inspect}"
            end
          end
        end

        def instantiate_from_api_data(service)
          attributes = {}
          ATTRIBUTES.each { |attr| attributes[attr] = service[attr] }

          new attributes
        end

        def json(response)
          JSON.parse(response.body)
        end
      end

      def referrer_filters_required?
        @referrer_filters_required
      end

      def user_registration_required?
        @user_registration_required
      end

      def save!
        self.class.save! attributes
      end

      def attributes
        attrs = {}
        ATTRIBUTES.each{ |attr| attrs[attr.to_sym] = self.send(attr.to_sym) }

        attrs
      end

      # TODO: Remove once unused.
      def self.incr_version(id)
        storage.incrby(storage_key(id,:version), 1)
      end

      # TODO: Remove once unused.
      def self.storage_key(id, attribute)
        encode_key("service/id:#{id}/#{attribute}")
      end

      def user_add(username)
        Core.faraday.post "services/#{id}/users", {username: username}.to_json
      end

      def user_delete(username)
        Core.faraday.delete "services/#{id}/users/#{username}"
      end

    end
  end
end

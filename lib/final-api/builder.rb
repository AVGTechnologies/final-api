module FinalAPI
  module Builder
    require 'travis/api/formats'
    require 'final-api/v1/http'

    DEFAULT_VERSION = 'v1'

    class << self
      def data(resource, options = {})
        new(resource, options).data
      end

      def builder(resource, options = {})
        target  = (options[:for] || 'http').to_s.camelize
        version = (options[:version] || default_version(options)).to_s.camelize
        type    = (options[:type] || type_for(resource)).to_s.camelize.split('::')
        ([version, target] + type).inject(FinalAPI) do |const, name|
          begin
            if const && const.const_defined?(name.to_s.camelize, false)
              const.const_get(name, false)
            else
              nil
            end
          rescue NameError
            nil
          end
        end
      end

      def new(resource, options = {})
        builder = builder(resource, options) || raise(ArgumentError, "cannot serialize #{resource.inspect}, options: #{options.inspect}")
        builder.new(resource, options[:params] || {})
      end

      private

        def type_for(resource)
          if arel_relation?(resource)
            type = resource.klass.name.pluralize
          else
            type = resource.class
            type = type.base_class if active_record?(type)
            type = type.name
          end
          type.split('::').last
        end

        def arel_relation?(object)
          object.respond_to?(:klass)
        end

        def active_record?(object)
          object.respond_to?(:base_class)
        end

        def default_version(options)
          DEFAULT_VERSION
        end
    end
  end
end

module ActiveRecord
  class FirewalledIDType < ActiveRecord::Type::Integer
    class FirewalledAccess < ActiveRecord::RecordNotFound; end

    def initialize(model, protected_type, report_only: false)
      super()
      @model = model
      @protected_type = protected_type.to_sym
      @report_only = report_only
    end

    def deserialize(*)
      super.tap do |id|
        check_attribute!(id)
      end
    end

    def serialize(*)
      super.tap do |id|
        check_attribute!(id)
      end
    end

    def check_attribute!(id)
      current = ActiveSupport::CurrentAttributes.subclasses.first.send(@protected_type)
      humanized_protected_type = @protected_type.to_s.humanize
      if current&.id && id && current.id != id
        message = <<~END.gsub("\n", " ")
        #{@model || 'Record'} from #{humanized_protected_type}
        #{id} was accessed from #{humanized_protected_type} #{current&.id}
        END

        if @report_only
          Rails.logger.info "[activerecord-firewall] #{message}"
        else
          raise FirewalledAccess, message
        end
      end
    end
  end
end

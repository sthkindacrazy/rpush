module Rpush
  module Client
    module ActiveModel
      module Gcm
        module Notification
          GCM_PRIORITY_HIGH = Rpush::Client::ActiveModel::Apns::Notification::APNS_PRIORITY_IMMEDIATE
          GCM_PRIORITY_NORMAL = Rpush::Client::ActiveModel::Apns::Notification::APNS_PRIORITY_CONSERVE_POWER
          GCM_PRIORITIES = [GCM_PRIORITY_HIGH, GCM_PRIORITY_NORMAL]

          def self.included(base)
            base.instance_eval do
              validates :registration_ids, presence: true
              validates :priority, inclusion: { in: GCM_PRIORITIES }, allow_nil: true

              validates_with Rpush::Client::ActiveModel::PayloadDataSizeValidator, limit: 4096
              validates_with Rpush::Client::ActiveModel::RegistrationIdsCountValidator, limit: 1000

              validates_with Rpush::Client::ActiveModel::Gcm::ExpiryCollapseKeyMutualInclusionValidator
            end
          end

          # This is a hack. The schema defines `priority` to be an integer, but GCM expects a string.
          # But for users of rpush to have an API they might expect (setting priority to `high`, not 10)
          # we do a little conversion here.
          # I'm not happy about it, but this will have to do until I can take a further look.
          def priority=(priority)
            case priority
              when 'high'
                super(GCM_PRIORITY_HIGH)
              when 'normal'
                super(GCM_PRIORITY_NORMAL)
              else
                errors.add(:priority, 'must be one of either "normal" or "high"')
            end
          end

          def as_json(options = nil)
            json = {
                'registration_ids' => registration_ids,
                'data' => data
            }
            json['collapse_key'] = collapse_key if collapse_key
            json['content_available'] = content_available if content_available
            json['notification'] = notification if notification
            json['priority'] = priority_for_notification if priority
            json['time_to_live'] = expiry if expiry
            json
          end

          def priority_for_notification
            return 'high' if priority == GCM_PRIORITY_HIGH
            'normal' if priority == GCM_PRIORITY_NORMAL
          end
        end
      end
    end
  end
end

module Spree
  class OrderBaseAddress < Spree::Base
    # TODO
    #mattr_accessor :state_validator_class
    #self.state_validator_class = Spree::Address::StateValidator
    #validate do
    #  self.class.state_validator_class.new(self).perform
    #end

    belongs_to :country, class_name: "Spree::Country", optional: true
    belongs_to :state, class_name: "Spree::State", optional: true

    validates :address1, :city, :country_id, :name, presence: true
    validates :zipcode, presence: true, if: :require_zipcode?
    validates :phone, presence: true, if: :require_phone?

    self.allowed_ransackable_attributes = %w[name]

    enum :reverse_charge_status, {
      disabled: 0,
      enabled: 1,
      not_validated: 2
    }, prefix: true

    unless ActiveRecord::Relation.method_defined? :with_values # Rails 7.1+
      scope :with_values, ->(attributes) do
        where(value_attributes(attributes))
      end
    end

    # @return [Address] an address with default attributes
    def self.build_default(*args, &block)
      where(country: Spree::Country.default).build(*args, &block)
    end

    # @return [String] a string representation of this state
    def state_text
      state.try(:abbr) || state.try(:name) || state_name
    end

    def to_s
      "#{name}: #{address1}"
    end


    # @return [Hash] hash of attributes contributing to value equality
    def value_attributes
      self.class.value_attributes(attributes)
    end
    # @note This compares the addresses based on only the fields that make up
    #   the logical "address" and excludes the database specific fields (id, created_at, updated_at).
    # @return [Boolean] true if the two addresses have the same address fields
    def ==(other_address)
      return false unless other_address && other_address.respond_to?(:value_attributes)
      value_attributes == other_address.value_attributes
    end

    # @return [Hash] an ActiveMerchant compatible address hash
    def active_merchant_hash
      {
        name:,
        address1:,
        address2:,
        city:,
        state: state_text,
        zip: zipcode,
        country: country.try(:iso),
        phone:
      }
    end

    # @todo Remove this from the public API if possible.
    # @return [true] whether or not the address requires a phone number to be
    #   present
    def require_phone?
      Spree::Config[:address_requires_phone]
    end

    # @todo Remove this from the public API if possible.
    # @return [true] whether or not the address requires a zipcode to be present
    def require_zipcode?
      true
    end

    # @param iso [String] 2 letter Country ISO
    # @return [Country] setter that sets self.country to the Country with a matching 2 letter iso
    # @raise [ActiveRecord::RecordNotFound] if country with the iso doesn't exist
    def country_iso=(iso)
      self.country = Spree::Country.find_by!(iso:)
    end

    def country_iso
      country && country.iso
    end
  end
end

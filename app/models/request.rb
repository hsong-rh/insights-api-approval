class Request < ApplicationRecord
  include Filterable
  include ApprovalStates
  include ApprovalDecisions

  acts_as_tenant(:tenant)

  belongs_to :workflow
  has_many :stages, -> { order(:id => :asc) }, :inverse_of => :request, :dependent => :destroy

  validates :name,      :presence => true
  validates :content,   :presence => true

  validates :state,    :inclusion => { :in => STATES }
  validates :decision, :inclusion => { :in => DECISIONS }

  scope :decision,  ->(decision)  { where(:decision => decision) }
  scope :state,     ->(state)     { where(:state => state) }
  scope :requester, ->(requester) { where(:requester => requester) }

  before_create :set_context

  def switch_context
    if context.present?
      ManageIQ::API::Common::Request.with_request(context.transform_keys(&:to_sym)) do
        ActsAsTenant.with_tenant(tenant) { yield }
      end
    else
      ActsAsTenant.with_tenant(tenant) { yield }
    end
  end

  private

  def set_context
    self.context = ManageIQ::API::Common::Request.current.to_h
  end
end

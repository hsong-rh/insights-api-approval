RSpec.describe Api::V1x0::GraphqlController, :type => :request do
  include_context "approval_rbac_objects"
  let(:encoded_user) { encoded_user_hash }
  let(:headers) { { 'x-rh-identity' => encoded_user } }
  let(:tenant) { create(:tenant) }

  let!(:template) { create(:template) }
  let(:template_id) { template.id }
  let!(:workflows) { create_list(:workflow, 4, :template => template, :tenant => tenant) }
  let(:id) { workflows.first.id }
  let(:roles_obj) { instance_double(Insights::API::Common::RBAC::Roles, :roles => roles) }

  let(:api_version) { version }

  let(:graphql_source_query) { { 'query' => '{ workflows {  id template_id name  } }' } }

  before do
    allow(Insights::API::Common::RBAC::Roles).to receive(:new).with('approval').and_return(roles_obj)
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(rs_class).to receive(:paginate).and_return([])
  end

  describe 'a simple graphql query' do
    context 'rbac allows' do
      let(:roles) { [admin_role] }

      it 'selects attributes in workflows' do
        post "#{api_version}/graphql", :headers => headers, :params => graphql_source_query

        expect(response.status).to eq(200)

        results = JSON.parse(response.body).fetch_path("data", "workflows")
        expect(results.size).to eq(4)
        results.each do |hash|
          expect(hash.keys).to contain_exactly('id', 'template_id', 'name')
        end
      end
    end

    context 'rbac rejects' do
      let(:roles) { [] }

      it 'selects attributes in workflows' do
        post "#{api_version}/graphql", :headers => headers, :params => graphql_source_query
        expect(response.status).to eq(403)
      end
    end
  end
end

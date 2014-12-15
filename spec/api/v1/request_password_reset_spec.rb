module V1
  describe RequestPasswordReset do
    include Rack::Test::Methods
    before { current_session.header('Accept', 'application/json') }

    describe "request a password reset" do
      let(:url) { 'v1/users/password' }
      let(:user) { create(:user) }

      subject { post url, params }

      context "with valid params" do
        let(:params) { { user: { email: user.email } } }

        it_behaves_like "a successful JSON POST request"

        it "sends reset instructions to a user" do
          expect{ subject }.to change(ActionMailer::Base.deliveries, :count).by(1)
        end

        it "returns empty json body" do
          expect(subject.body).to eq '{}'
        end
      end

      context "there is no such user" do
        let(:params) { { user: { email: 'non_existent' } } }

        it_behaves_like "a successful JSON POST request"

        it "doesn't send any email" do
          expect{ subject }.to change(ActionMailer::Base.deliveries, :count).by(0)
        end

        it "returns empty json body" do
          expect(subject.body).to eq '{}'
        end
      end
    end
  end
end

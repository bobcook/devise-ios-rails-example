module V1
  describe AuthorizedUsers do
    include Rack::Test::Methods
    before { current_session.header('Accept', 'application/json') }

    describe "Update User" do
      before { build(:authentication, user: user).set_headers(current_session) }

      let(:url) { "v1/users" }
      let(:user) { create(:user) }
      let(:params) { { user: attributes_for(:user) } }

      subject { put url, params }

      it_behaves_like "needs authorization"

      context "with valid token" do
        it_behaves_like "a successful JSON PUT request"

        it "doesn't create a new record" do
          expect{ subject }.not_to change(User, :count)
        end

        it "returns a user" do
          json_response = json_for(subject)
          expect(json_response).to have_key('user')
        end

        it "serializes user with user serializer" do
          json_response = json_for(subject)
          expected_keys = UserSerializer.new(user).serializable_object.keys.map(&:to_s)
          expect(json_response['user'].keys).to eq expected_keys
        end
      end

      context "with invalid params" do
        let(:params) { { user: attributes_for(:user, email: 'not_valid_email') } }

        it_behaves_like "a bad JSON request", 422

        it "returns error object" do
          error = {
            message: 'Validation failed: Email is invalid',
            code: 0,
            status: 422
          }.stringify_keys
          json_response = json_for(subject)

          expect(json_response).to eq('error' => error)
        end
      end
    end

    describe "Delete Own Account" do
      before { build(:authentication, user: user).set_headers(current_session) }

      let(:url) { "v1/users" }
      let(:user) { create(:user) }
      let(:params) { {} }

      subject { delete url, params }

      it_behaves_like "needs authorization"

      context "with valid token" do
        it_behaves_like "a successful JSON DELETE request"

        it "removes a user" do
          expect{ subject }.to change(User, :count).by(-1)
        end

        it "returns a user" do
          json_response = json_for(subject)
          expect(json_response).to have_key('user')
        end

        it "serializes user with user serializer" do
          expect(subject.body).to eq UserSerializer.new(user).to_json
        end
      end
    end

    describe "Change User password" do
      before { build(:authentication, user: user).set_headers(current_session) }

      let(:url) { "v1/users/password" }
      let(:user) { create(:user) }
      let(:params) do
        {
          user: {
            password: 'new_pass',
            passwordConfirmation: 'new_pass',
          }
        }
      end

      subject { put url, params }

      it_behaves_like "needs authorization"

      context "with valid token" do
        it_behaves_like "a successful JSON PUT request"

        it "doesn't create a new record" do
          expect{ subject }.not_to change(User, :count)
        end

        it "returns a user" do
          json_response = json_for(subject)
          expect(json_response).to have_key('user')
        end

        it "changes user password" do
          expect{ json_for(subject)['user']['password'] }
            .to change{ user.reload.encrypted_password }
        end
      end

      context "with invalid params" do
        let(:params) do
          {
            user: {
              password: 'new_pass',
              passwordConfirmation: 'not_match',
            }
          }
        end

        it_behaves_like "a bad JSON request", 422

        it "returns error object" do
          error = {
            message: "Validation failed: Password confirmation doesn't match Password",
            code: 0,
            status: 422
          }.stringify_keys
          json_response = json_for(subject)

          expect(json_response).to eq('error' => error)
        end
      end
    end


  end
end

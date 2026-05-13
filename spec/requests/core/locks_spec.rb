require "rails_helper"

RSpec.describe "Core::Locks", type: :request do
  let(:business)       { create(:business) }
  let(:user)           { create(:user, business: business) }
  let(:location)       { create(:location, business: business) }
  let!(:lock)          { create(:lock, location: location, unit_identifier: "42") }

  let(:other_business) { create(:business) }
  let(:other_location) { create(:location, business: other_business) }
  let!(:other_lock)    { create(:lock, location: other_location, unit_identifier: "99") }

  describe "GET /locks" do
    context "when not signed in" do
      it "redirects to sign in" do
        get core_locks_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "is accessible" do
        get core_locks_path
        expect(response).to have_http_status(:ok)
      end

      it "shows only locks belonging to the user's business" do
        get core_locks_path
        expect(response.body).to include(core_lock_path(lock))
        expect(response.body).not_to include(core_lock_path(other_lock))
      end

      context "with a search query matching unit identifier" do
        it "returns matching locks and excludes non-matching ones" do
          other_own_lock = create(:lock, location: location, unit_identifier: "7")
          get core_locks_path, params: { q: "42" }
          expect(response.body).to include(core_lock_path(lock))
          expect(response.body).not_to include(core_lock_path(other_own_lock))
        end
      end

      context "with a search query matching device UUID" do
        it "returns the matching lock" do
          get core_locks_path, params: { q: lock.device_uuid }
          expect(response.body).to include(core_lock_path(lock))
        end
      end

      context "with a search query that matches nothing" do
        it "shows the empty state" do
          get core_locks_path, params: { q: "zzznomatch" }
          expect(response.body).to include("No locks found matching")
        end
      end
    end
  end

  describe "GET /locks/:id" do
    context "when not signed in" do
      it "redirects to sign in" do
        get core_lock_path(lock)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "shows the lock's device UUID" do
        get core_lock_path(lock)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(lock.device_uuid)
      end

      it "returns 404 for a lock belonging to another business" do
        get core_lock_path(other_lock)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
